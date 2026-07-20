# frozen_string_literal: true

require_relative "directory_installer"

module HunkReviewChanges
  module Installer
    # Codex reads user-level skills from the shared, tool-agnostic ~/.agents/skills.
    class Codex < DirectoryInstaller
      def key = :codex
      def label = "Codex"

      def detected?
        command_on_path?("codex") || File.directory?(home(".codex")) || File.directory?(home(".agents"))
      end

      def skills_root
        home(".agents", "skills")
      end
    end
  end
end
