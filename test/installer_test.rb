# frozen_string_literal: true

require "test_helper"
require "stringio"

module HunkReviewChanges
  class InstallerTest < Minitest::Test
    # Builds a minimal marketplace checkout on disk and yields its root path.
    def with_marketplace_repo
      Dir.mktmpdir("rhc-market-") do |root|
        skill_dir = File.join(root, "plugins", PLUGIN_NAME, "skills", SKILL_NAME)
        FileUtils.mkdir_p(skill_dir)
        File.write(File.join(skill_dir, "SKILL.md"), "---\nname: #{SKILL_NAME}\n---\nbody\n")
        yield root
      end
    end

    def with_fake_home
      Dir.mktmpdir("rhc-home-") do |home|
        original = ENV.fetch("HOME", nil)
        ENV["HOME"] = home
        begin
          yield home
        ensure
          ENV["HOME"] = original
        end
      end
    end

    def test_skill_source_finds_the_skill_dir
      with_marketplace_repo do |root|
        source = Installer::SkillSource.new(root)
        assert_path_exists File.join(source.skill_dir, "SKILL.md")
      end
    end

    def test_skill_source_reports_a_bad_repo
      Dir.mktmpdir do |empty|
        error = assert_raises(Installer::SkillSource::Error) do
          Installer::SkillSource.new(empty).skill_dir
        end
        assert_match(/no SKILL.md/, error.message)
      end
    end

    def test_directory_installer_copies_the_skill
      with_marketplace_repo do |root|
        with_fake_home do |home|
          source = Installer::SkillSource.new(root)
          result = Installer::Codex.new.install!(source)
          assert result.ok, result.message
          assert_path_exists File.join(home, ".agents", "skills", SKILL_NAME, "SKILL.md")
        end
      end
    end

    def test_runner_installs_selected_agent
      with_marketplace_repo do |root|
        with_fake_home do |home|
          runner = Installer::Runner.new(
            repo: root, only: ["codex"], output: StringIO.new, input: StringIO.new
          )
          results = runner.run
          assert_equal 1, results.size
          assert results.first.ok
          assert_path_exists File.join(home, ".agents", "skills", SKILL_NAME, "SKILL.md")
        end
      end
    end

    def test_runner_expands_all_keyword
      runner = Installer::Runner.new(repo: "x", only: ["all"], output: StringIO.new)
      selected = runner.send(:by_keys, ["all"])
      assert_equal Installer::Runner::ADAPTERS.size, selected.size
    end

    def test_runner_resolves_aliases
      runner = Installer::Runner.new(repo: "x", only: ["claude-code"], output: StringIO.new)
      selected = runner.send(:by_keys, ["claude-code"])
      assert_equal [:claude], selected.map(&:key)
    end

    def test_runner_rejects_unknown_explicit_agent
      runner = Installer::Runner.new(repo: "x", only: ["codez"], output: StringIO.new, input: StringIO.new)
      error = assert_raises(CLI::Error) { runner.run }
      assert_match(/unknown agent/, error.message)
    end

    def test_claude_adapter_fails_without_cli_but_does_not_raise
      # No `claude` on PATH in CI; install! should return a failure Result, not raise.
      adapter = Installer::ClaudeCode.new
      adapter.stub(:command_on_path?, false) do
        result = adapter.install!(Object.new)
        refute result.ok
        assert_match(/claude/, result.message)
      end
    end
  end
end
