# frozen_string_literal: true

require "test_helper"
require "stringio"

module HunkReviewChanges
  class CLITest < Minitest::Test
    include TestHelpers

    def capture_stdout
      original = $stdout
      $stdout = StringIO.new
      yield
      $stdout.string
    ensure
      $stdout = original
    end

    def test_version
      out = capture_stdout { assert_equal 0, CLI.new.run(["--version"]) }
      assert_includes out, VERSION
    end

    def test_help
      out = capture_stdout { assert_equal 0, CLI.new.run(["--help"]) }
      assert_includes out, "hunk-review-changes"
      assert_includes out, "install"
    end

    def test_no_args_prints_help
      out = capture_stdout { assert_equal 0, CLI.new.run([]) }
      assert_includes out, "Usage:"
    end

    def test_serve_requires_a_bundle
      # A flag but no bundle path -> handled error, exit 1 (not a crash).
      err = capture_stderr { assert_equal 1, CLI.start(["--port", "5"]) }
      assert_match(/no bundle given/, err)
    end

    def capture_stderr
      original = $stderr
      $stderr = StringIO.new
      yield
      $stderr.string
    ensure
      $stderr = original
    end

    def test_serve_loads_bundle_and_starts_server
      fake_server = Object.new
      def fake_server.run = :ran
      captured = nil
      builder = lambda do |bundle, **opts|
        captured = [bundle, opts]
        fake_server
      end

      Server.stub(:new, builder) do
        assert_equal 0, CLI.new.run([TestHelpers::FIXTURE, "--no-open"])
      end
      assert_instance_of Bundle, captured[0]
      assert_equal false, captured[1][:open]
    end

    def test_install_dispatches_to_runner
      results = [Installer::Base::Result.new(key: :codex, label: "Codex", ok: true, message: "done")]
      fake_runner = Object.new
      fake_runner.define_singleton_method(:run) { results }
      captured = nil
      builder = lambda do |**opts|
        captured = opts
        fake_runner
      end

      Installer::Runner.stub(:new, builder) do
        assert_equal 0, CLI.new.run(["install", "--agent", "codex", "--marketplace-repo", "/tmp/x"])
      end
      assert_equal ["codex"], captured[:only]
      assert_equal "/tmp/x", captured[:repo]
    end
  end
end
