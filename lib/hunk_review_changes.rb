# frozen_string_literal: true

require_relative "hunk_review_changes/version"
require_relative "hunk_review_changes/markdown"
require_relative "hunk_review_changes/diff"
require_relative "hunk_review_changes/bundle"
require_relative "hunk_review_changes/state"
require_relative "hunk_review_changes/export"
require_relative "hunk_review_changes/lifecycle"

module HunkReviewChanges
  # The git repo that hosts the companion skill as a Claude Code plugin marketplace and
  # the source of truth for the skill across every agent the installer supports.
  MARKETPLACE_REPO = "https://github.com/ghinda/hunk-review-changes-skills"

  # Names used across the marketplace manifest and the installed skill folder.
  MARKETPLACE_NAME = "hunk-review-changes-skills"
  PLUGIN_NAME = "hunk-review-changes"
  SKILL_NAME = "hunk-review-changes"

  autoload :App, "hunk_review_changes/app"
  autoload :Server, "hunk_review_changes/server"
  autoload :CLI, "hunk_review_changes/cli"
  autoload :Assets, "hunk_review_changes/assets"

  module Installer
    autoload :Base, "hunk_review_changes/installer/base"
    autoload :ClaudeCode, "hunk_review_changes/installer/claude_code"
    autoload :Codex, "hunk_review_changes/installer/codex"
    autoload :Cursor, "hunk_review_changes/installer/cursor"
    autoload :OpenCode, "hunk_review_changes/installer/opencode"
    autoload :Runner, "hunk_review_changes/installer/runner"
    autoload :SkillSource, "hunk_review_changes/installer/skill_source"
  end
end
