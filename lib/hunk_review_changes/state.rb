# frozen_string_literal: true

require "json"

module HunkReviewChanges
  # Per-piece review state (comment, flag, reviewed), persisted as state.json next to
  # the bundle so a closed tab loses nothing and re-running the same bundle resumes.
  #
  # Status precedence, highest first:
  #   flag        - checked "flag for discussion"
  #   change      - has a non-blank comment
  #   ok          - reviewed and left as-is ("Looks good")
  #   unreviewed  - not yet looked at
  class State
    STATUSES = %w[flag change ok unreviewed].freeze

    def initialize(path)
      @path = path
      @entries = File.exist?(path) ? JSON.parse(File.read(path)) : {}
    end

    def [](id)
      @entries[id.to_s] || {}
    end

    def update(id, comment:, flag:, reviewed:)
      @entries[id.to_s] = {
        "comment" => comment.to_s,
        "flag" => !!flag,
        "reviewed" => !!reviewed
      }
      save
      status(id)
    end

    def status(id)
      self.class.status_for(self[id])
    end

    def self.status_for(entry)
      return "flag" if entry && entry["flag"]
      return "change" if entry && entry["comment"].to_s.strip != ""
      return "ok" if entry && entry["reviewed"]

      "unreviewed"
    end

    # Status counts a piece needs the agent to act on (everything but ok/unreviewed).
    def self.actionable?(entry)
      status = status_for(entry)
      %w[flag change].include?(status)
    end

    private

    def save
      File.write(@path, JSON.pretty_generate(@entries))
    end
  end
end
