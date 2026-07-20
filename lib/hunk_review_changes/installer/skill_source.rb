# frozen_string_literal: true

require "fileutils"
require "tmpdir"

module HunkReviewChanges
  module Installer
    # Provides a local checkout of the marketplace repo so adapters can read the skill
    # from it. The marketplace repo is the single source of truth for the skill across
    # agents; the gem never ships its own copy. A local path is used as-is (handy for
    # testing); a remote URL is shallow-cloned to a temp dir on first use.
    class SkillSource
      class Error < StandardError
      end

      attr_reader :repo

      def initialize(repo)
        @repo = repo
      end

      def local?
        File.directory?(@repo)
      end

      # Path to a local checkout of the marketplace repo.
      def checkout
        @checkout ||= local? ? File.expand_path(@repo) : clone
      end

      # Directory holding the skill (SKILL.md and any support files) in the checkout.
      def skill_dir
        dir = File.join(checkout, "plugins", PLUGIN_NAME, "skills", SKILL_NAME)
        unless File.exist?(File.join(dir, "SKILL.md"))
          raise Error, "no SKILL.md at #{dir} — is #{@repo} the marketplace repo?"
        end

        dir
      end

      private

      def clone
        target = Dir.mktmpdir("hunk-review-changes-skill-")
        ok = system("git", "clone", "--depth", "1", @repo, target,
                    out: File::NULL, err: File::NULL)
        raise Error, "could not clone #{@repo} (is git installed and the URL reachable?)" unless ok

        target
      end
    end
  end
end
