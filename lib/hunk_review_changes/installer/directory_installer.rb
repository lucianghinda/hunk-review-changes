# frozen_string_literal: true

require "fileutils"

require_relative "base"

module HunkReviewChanges
  module Installer
    # Base for agents that have no install CLI (Codex, Cursor, OpenCode). They all scan
    # a skills directory for `<name>/SKILL.md`, so installing means copying the skill
    # out of the marketplace checkout into that directory. Subclasses supply the
    # directory and how the agent is detected.
    class DirectoryInstaller < Base
      # Absolute path to the agent's user-level skills directory.
      def skills_root = raise NotImplementedError

      def install!(source)
        target = File.join(skills_root, SKILL_NAME)
        FileUtils.mkdir_p(target)
        FileUtils.cp_r(File.join(source.skill_dir, "."), target)
        ok("copied skill to #{pretty(target)} (restart #{label} to pick it up)")
      rescue SkillSource::Error => e
        failure(e.message)
      rescue StandardError => e
        failure("could not copy skill: #{e.message}")
      end

      private

      def pretty(path)
        home = Dir.home
        path.start_with?(home) ? path.sub(home, "~") : path
      end
    end
  end
end
