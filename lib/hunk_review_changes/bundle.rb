# frozen_string_literal: true

require "json"

module HunkReviewChanges
  # Loads and validates a bundle.json written by the companion skill. Validation
  # exists to catch the exact failure modes the skill warns about (a malformed diff,
  # missing pieces, non-sequential ids) and report them with a message the agent that
  # wrote the bundle can act on, instead of a blank or broken page.
  class Bundle
    class Error < StandardError
    end

    attr_reader :path, :data

    def self.load(path)
      new(path).tap(&:validate!)
    end

    def initialize(path)
      @path = path
      raise Error, "no such bundle: #{path}" unless File.exist?(path)

      @data = JSON.parse(File.read(path))
    rescue JSON::ParserError => e
      raise Error, "bundle is not valid JSON (#{e.message}). " \
                   "Write it with real JSON — no trailing commas or comments."
    end

    def target = data["target"]
    def resolved_by = data["resolved_by"]
    def framing = data["framing"]
    def pieces = data["pieces"]
    def dir = File.dirname(File.expand_path(path))

    def validate!
      raise Error, "bundle must be a JSON object with a \"pieces\" array" unless data.is_a?(Hash)

      list = data["pieces"]
      raise Error, "bundle has no \"pieces\" array" unless list.is_a?(Array)
      raise Error, "bundle \"pieces\" array is empty — nothing to review" if list.empty?

      list.each_with_index { |piece, index| validate_piece!(piece, index) }
      self
    end

    private

    def validate_piece!(piece, index)
      position = index + 1
      raise Error, "piece ##{position} must be a JSON object" unless piece.is_a?(Hash)

      expected_id = index + 1
      unless piece["id"] == expected_id
        raise Error, "piece ##{position} has id #{piece["id"].inspect}; ids must be " \
                     "1-based and sequential (expected #{expected_id})"
      end

      %w[file label].each do |field|
        if piece[field].to_s.strip.empty?
          raise Error, "piece #{expected_id} is missing a non-empty \"#{field}\""
        end
      end

      validate_diff!(piece, expected_id)
    end

    def validate_diff!(piece, id)
      diff = piece["diff"].to_s
      if diff.strip.empty?
        raise Error, "piece #{id} has an empty \"diff\" — copy a real unified-diff hunk from git"
      end

      unless diff.include?("@@")
        raise Error, "piece #{id} \"diff\" has no @@ hunk header — copy the whole hunk " \
                     "including the @@ ... @@ line so line numbers can render"
      end

      return unless diff.include?('\n') && !diff.include?("\n")

      raise Error, "piece #{id} \"diff\" looks escaped (literal \\n, no real newlines) — " \
                   "the diff must contain actual newlines, not \\n sequences"
    end
  end
end
