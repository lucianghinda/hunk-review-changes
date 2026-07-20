# frozen_string_literal: true

module HunkReviewChanges
  module Installer
    # Common interface for a per-agent install adapter. An adapter knows how to detect
    # its agent and how to register the skill for it — either by calling the agent's
    # own CLI (Claude Code) or by copying the skill out of the marketplace checkout
    # into the directory that agent scans (Codex, Cursor, OpenCode).
    class Base
      # Outcome of one adapter run, rendered in the install summary.
      Result = Struct.new(:key, :label, :ok, :message, keyword_init: true)

      def key = raise NotImplementedError
      def label = raise NotImplementedError

      # True when the agent is present on this machine (CLI on PATH or config dir).
      def detected? = raise NotImplementedError

      # Perform the install against a SkillSource; return a Result.
      def install!(_source) = raise NotImplementedError

      protected

      def ok(message) = Result.new(key: key, label: label, ok: true, message: message)
      def failure(message) = Result.new(key: key, label: label, ok: false, message: message)

      def command_on_path?(name)
        ENV.fetch("PATH", "").split(File::PATH_SEPARATOR).any? do |dir|
          path = File.join(dir, name)
          File.executable?(path) && !File.directory?(path)
        end
      end

      def home(*parts)
        File.join(Dir.home, *parts)
      end
    end
  end
end
