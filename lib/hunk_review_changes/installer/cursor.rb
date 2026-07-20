# frozen_string_literal: true

require_relative "directory_installer"

module HunkReviewChanges
  module Installer
    # Cursor reads user-level skills from ~/.cursor/skills.
    class Cursor < DirectoryInstaller
      def key = :cursor
      def label = "Cursor"

      def detected?
        command_on_path?("cursor-agent") || command_on_path?("cursor") ||
          File.directory?(home(".cursor"))
      end

      def skills_root
        home(".cursor", "skills")
      end
    end
  end
end
