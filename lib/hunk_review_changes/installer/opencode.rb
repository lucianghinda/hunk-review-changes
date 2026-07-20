# frozen_string_literal: true

require_relative "directory_installer"

module HunkReviewChanges
  module Installer
    # OpenCode reads user-level skills from ~/.config/opencode/skills.
    class OpenCode < DirectoryInstaller
      def key = :opencode
      def label = "OpenCode"

      def detected?
        command_on_path?("opencode") || File.directory?(config_dir)
      end

      def skills_root
        File.join(config_dir, "skills")
      end

      private

      def config_dir
        File.join(ENV.fetch("XDG_CONFIG_HOME", home(".config")), "opencode")
      end
    end
  end
end
