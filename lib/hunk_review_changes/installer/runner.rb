# frozen_string_literal: true

require_relative "skill_source"
require_relative "claude_code"
require_relative "codex"
require_relative "cursor"
require_relative "opencode"

module HunkReviewChanges
  module Installer
    # Drives the `install` command: detect which agents are present, let the user pick
    # (or take an explicit list), install the skill into each, and print a summary.
    class Runner
      ADAPTERS = [ClaudeCode, Codex, Cursor, OpenCode].freeze

      # Accepts agent keys plus a few friendly aliases from --agent.
      ALIASES = {
        "claude-code" => :claude, "claudecode" => :claude,
        "cursor-agent" => :cursor, "open-code" => :opencode
      }.freeze

      def initialize(repo: MARKETPLACE_REPO, only: nil, input: $stdin, output: $stdout)
        @source = SkillSource.new(repo)
        @only = only
        @input = input
        @output = output
        @adapters = ADAPTERS.map(&:new)
      end

      def run
        if @only
          ensure_known!(@only)
          selected = by_keys(@only)
        else
          selected = prompt
        end
        if selected.empty?
          @output.puts "Nothing selected — no changes made."
          return []
        end

        @output.puts "\nInstalling from #{@source.repo}"
        results = selected.map do |adapter|
          @output.puts "  → #{adapter.label}…"
          adapter.install!(@source)
        end
        report(results)
        results
      end

      private

      # An explicit --agent list naming an unknown agent must fail loudly: otherwise
      # it selects nothing, "installs" nothing, and still exits 0 as if it worked.
      def ensure_known!(keys)
        known = @adapters.map(&:key)
        unknown = Array(keys).flat_map { |k| expand(k) }.uniq - known
        return if unknown.empty?

        raise CLI::Error, "unknown agent#{"s" if unknown.size > 1}: #{unknown.join(", ")}. " \
                          "Valid agents: #{known.join(", ")} (or 'all')."
      end

      def by_keys(keys)
        wanted = Array(keys).flat_map { |k| expand(k) }.uniq
        @adapters.select { |adapter| wanted.include?(adapter.key) }
      end

      def expand(key)
        normalized = key.to_s.strip.downcase
        return @adapters.map(&:key) if %w[all every].include?(normalized)

        [ALIASES.fetch(normalized, normalized.to_sym)]
      end

      def prompt
        @output.puts "Install the hunk-review-changes skill for which agents?\n\n"
        @adapters.each_with_index do |adapter, index|
          mark = adapter.detected? ? "detected" : "not detected"
          @output.puts "  #{index + 1}. #{adapter.label} (#{mark})"
        end
        detected = @adapters.each_index.select { |i| @adapters[i].detected? }
        default = detected.empty? ? "none" : detected.map { |i| i + 1 }.join(",")
        @output.print "\nEnter numbers (comma-separated), 'all', or Enter for detected [#{default}]: "

        answer = read_line
        resolve_selection(answer, detected)
      end

      def resolve_selection(answer, detected)
        answer = answer.to_s.strip.downcase
        return @adapters if answer == "all"
        return detected.map { |i| @adapters[i] } if answer.empty?

        indexes = answer.split(/[,\s]+/).filter_map do |token|
          num = Integer(token, exception: false)
          num - 1 if num&.between?(1, @adapters.length)
        end
        indexes.uniq.map { |i| @adapters[i] }
      end

      def read_line
        @input.gets
      rescue StandardError
        nil
      end

      def report(results)
        @output.puts "\nSummary:"
        results.each do |result|
          icon = result.ok ? "✓" : "✗"
          @output.puts "  #{icon} #{result.label}: #{result.message}"
        end
        failures = results.reject(&:ok)
        return if failures.empty?

        @output.puts "\n#{failures.length} of #{results.length} did not complete. " \
                     "See messages above."
      end
    end
  end
end
