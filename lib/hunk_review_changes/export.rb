# frozen_string_literal: true

module HunkReviewChanges
  # Builds export.md: the pieces that need action, as a paste-ready markdown block the
  # launching agent reads to implement each requested change.
  class Export
    def initialize(bundle, state)
      @bundle = bundle
      @state = state
    end

    def to_markdown
      lines = header
      actionable = @bundle.pieces.select { |piece| State.actionable?(@state[piece["id"]]) }

      if actionable.empty?
        lines << no_changes_note
        return "#{lines.join("\n").strip}\n"
      end

      lines << "The pieces below have comments to act on. Implement each `change`; " \
               "list each `flag` for the user to decide before touching it."
      lines << ""
      actionable.each { |piece| lines.concat(piece_lines(piece)) }
      "#{lines.join("\n").strip}\n"
    end

    private

    # No piece needs action, but "reviewed and left as-is" and "never looked at" are
    # different signals to the agent — the UI lets the user finish with pieces still
    # unreviewed, and those must not read as approval.
    def no_changes_note
      unreviewed = @bundle.pieces.select { |piece| State.status_for(@state[piece["id"]]) == "unreviewed" }
      return "_No changes requested — every piece was reviewed and left as-is._" if unreviewed.empty?

      ids = unreviewed.map { |piece| piece["id"] }.join(", ")
      "_No changes requested, but #{unreviewed.size} of #{@bundle.pieces.size} piece(s) were left " \
        "unreviewed (skipped, not approved): #{ids}. Treat them as pending, not accepted._"
    end

    def header
      lines = ["# Hunk review — #{@bundle.target}"]
      lines << "Resolved by: #{@bundle.resolved_by}" if @bundle.resolved_by
      lines << ""
      lines << @bundle.framing.to_s.strip
      lines << ""
      lines
    end

    def piece_lines(piece)
      entry = @state[piece["id"]]
      status = State.status_for(entry)
      comment = entry["comment"].to_s.strip
      [
        "## Piece #{piece["id"]} of #{@bundle.pieces.size} — #{piece["file"]}: #{piece["label"]}",
        "Status: #{status}",
        "",
        "```diff",
        piece["diff"].to_s.rstrip,
        "```",
        "Comment: #{comment.empty? ? "—" : comment}",
        ""
      ]
    end
  end
end
