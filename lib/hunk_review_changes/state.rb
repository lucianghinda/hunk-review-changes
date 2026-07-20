# frozen_string_literal: true

require "json"

module HunkReviewChanges
  # Per-piece review state (comment, flag, reviewed), persisted as state.json next to
  # the bundle so a closed tab loses nothing and re-running the same bundle resumes.
  #
  # State is scoped to a bundle fingerprint: when a directory is reused for a
  # different (or overwritten) bundle, the previous review's comments are discarded
  # rather than replayed against unrelated pieces that happen to share an id.
  #
  # Status precedence, highest first:
  #   flag        - checked "flag for discussion"
  #   change      - has a non-blank comment
  #   ok          - reviewed and left as-is ("Looks good")
  #   unreviewed  - not yet looked at
  class State
    STATUSES = %w[flag change ok unreviewed].freeze

    # One Mutex per state.json path, shared across the request threads Puma runs, so
    # overlapping saves serialize instead of clobbering each other's pieces.
    @locks = {}
    @locks_guard = Mutex.new

    def self.lock_for(path)
      @locks_guard.synchronize { @locks[path] ||= Mutex.new }
    end

    def initialize(path, bundle_id: nil)
      @path = path
      @bundle_id = bundle_id
      @entries = load_entries
    end

    def [](id)
      @entries[id.to_s] || {}
    end

    def update(id, comment:, flag:, reviewed:)
      entry = {
        "comment" => comment.to_s,
        "flag" => !!flag,
        "reviewed" => !!reviewed
      }
      # Serialize the whole read-modify-write: re-read the current file so a save
      # racing on another thread merges its piece instead of overwriting it.
      self.class.lock_for(@path).synchronize do
        @entries = load_entries
        @entries[id.to_s] = entry
        save
      end
      self.class.status_for(entry)
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

    # Reads the entries for the current bundle. State written for a different bundle
    # (same directory, new/overwritten bundle.json) is treated as absent so stale
    # comments never leak into an unrelated review.
    def load_entries
      return {} unless File.exist?(@path)

      data = JSON.parse(File.read(@path))
      return {} unless data.is_a?(Hash)
      return {} if @bundle_id && data["bundle_id"] && data["bundle_id"] != @bundle_id

      data["entries"].is_a?(Hash) ? data["entries"] : {}
    rescue JSON::ParserError
      {}
    end

    # Atomic write (tmp + rename) so a crash or a concurrent reader never sees a
    # half-written file. Callers hold lock_for(@path) around the read-modify-write.
    def save
      tmp = "#{@path}.#{Process.pid}.#{object_id}.tmp"
      File.write(tmp, JSON.pretty_generate("bundle_id" => @bundle_id, "entries" => @entries))
      File.rename(tmp, @path)
    end
  end
end
