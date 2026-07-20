# frozen_string_literal: true

require "open3"

require_relative "base"

module HunkReviewChanges
  module Installer
    # Claude Code is the one agent with a real, non-interactive plugin install CLI, so
    # this adapter uses it: register the marketplace repo, then install the plugin from
    # it. Skills inside the plugin are auto-discovered once it is installed.
    class ClaudeCode < Base
      def key = :claude
      def label = "Claude Code"

      def detected?
        command_on_path?("claude") || File.directory?(home(".claude"))
      end

      def install!(source)
        return failure("`claude` CLI not found on PATH") unless command_on_path?("claude")

        added, add_out = run("claude", "plugin", "marketplace", "add", source.repo)
        return failure("`claude plugin marketplace add` failed: #{add_out}") unless added

        installed, install_out = run(
          "claude", "plugin", "install", "#{PLUGIN_NAME}@#{MARKETPLACE_NAME}"
        )
        return failure("`claude plugin install` failed: #{install_out}") unless installed

        ok("installed plugin #{PLUGIN_NAME}@#{MARKETPLACE_NAME} (user scope)")
      end

      private

      def run(*command)
        out, status = Open3.capture2e(*command)
        [status.success?, out.strip]
      rescue StandardError => e
        [false, e.message]
      end
    end
  end
end
