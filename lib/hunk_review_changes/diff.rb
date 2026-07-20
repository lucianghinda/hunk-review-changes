# frozen_string_literal: true

require "rouge"
require "diff/lcs"
require "cgi"

module HunkReviewChanges
  # Parses a unified-diff hunk and renders it as an HTML table with line-number
  # gutters. Two layers of highlighting:
  #
  #   * Rouge syntax highlighting on context lines and unpaired add/del lines. The
  #     class-based HTML formatter emits <span class="k"> tokens whose colours come
  #     from CSS (app.css), which is what lets the same markup render light or dark.
  #   * Word-level diff on lines that were modified in place: a run of deletions
  #     immediately followed by a run of additions is paired line-by-line, and the
  #     changed words are wrapped in dw-del / dw-add spans so the eye lands on exactly
  #     what moved.
  module Diff
    module_function

    FORMATTER = Rouge::Formatters::HTML.new

    # Metadata lines that carry no reviewable content; always dropped. None of these
    # collide with an in-hunk content line, whose raw form always begins with +, -,
    # or a space.
    SKIP_PREFIXES = [
      "diff --git", "index ", "new file", "deleted file",
      "similarity", "rename ", "old mode", "new mode", "\\ No newline"
    ].freeze

    # File header markers that DO collide with content once the line marker is added:
    # a deleted "-- x" reads "--- x" and an added "++ x" reads "+++ x". Drop them only
    # outside a hunk, where they are genuinely headers.
    FILE_HEADER_PREFIXES = ["--- ", "+++ "].freeze

    # A single rendered diff line. :html is filled in lazily: word-diff for paired
    # modifications, Rouge highlighting for everything else.
    Row = Struct.new(:kind, :old_ln, :new_ln, :text, :html, keyword_init: true)

    def to_html(diff_text, file)
      rows = parse(diff_text)
      pair_modifications!(rows)
      lexer = lexer_for(file)
      render(rows, lexer)
    end

    def parse(diff_text)
      old_ln = new_ln = nil
      in_hunk = false
      rows = []
      diff_text.to_s.each_line do |raw|
        line = raw.chomp
        if line.start_with?("@@")
          old_ln, new_ln = hunk_bounds(line, old_ln, new_ln)
          in_hunk = true
          rows << Row.new(kind: :hunk, text: line)
          next
        end

        # A new file section ends the current hunk, so its ---/+++ lines are headers.
        in_hunk = false if line.start_with?("diff --git")
        next if skip_metadata?(line, in_hunk)

        old_ln, new_ln = push_content(rows, line, old_ln, new_ln)
      end
      rows
    end

    # Line numbers the next content line starts from, read off the @@ header.
    def hunk_bounds(line, old_ln, new_ln)
      return [old_ln, new_ln] unless (m = line.match(/@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@/))

      [m[1].to_i, m[2].to_i]
    end

    # File-metadata lines are dropped; the ---/+++ pair only outside a hunk, where it
    # is a real header rather than an added/deleted line that happens to start with +/-.
    def skip_metadata?(line, in_hunk)
      return true if SKIP_PREFIXES.any? { |prefix| line.start_with?(prefix) }

      !in_hunk && FILE_HEADER_PREFIXES.any? { |prefix| line.start_with?(prefix) }
    end

    # Append the add/del/context row for a content line and return the advanced
    # [old_ln, new_ln] cursor (nil bounds stay nil).
    def push_content(rows, line, old_ln, new_ln)
      content = line.length > 1 ? line[1..] : ""
      case line[0]
      when "+"
        rows << Row.new(kind: :add, new_ln: new_ln, text: content)
        [old_ln, new_ln && (new_ln + 1)]
      when "-"
        rows << Row.new(kind: :del, old_ln: old_ln, text: content)
        [old_ln && (old_ln + 1), new_ln]
      else # context (space marker or blank line)
        rows << Row.new(kind: :ctx, old_ln: old_ln, new_ln: new_ln, text: content)
        [old_ln && (old_ln + 1), new_ln && (new_ln + 1)]
      end
    end

    # Find each run of deletions followed immediately by a run of additions and pair
    # them line-by-line, filling :html with word-level highlighting on both sides.
    def pair_modifications!(rows)
      index = 0
      while index < rows.length
        unless rows[index].kind == :del
          index += 1
          next
        end

        del_start = index
        index += 1 while index < rows.length && rows[index].kind == :del
        add_start = index
        index += 1 while index < rows.length && rows[index].kind == :add

        dels = rows[del_start...add_start]
        adds = rows[add_start...index]
        [dels.length, adds.length].min.times do |offset|
          del_html, add_html = word_diff(dels[offset].text, adds[offset].text)
          dels[offset].html = del_html
          adds[offset].html = add_html
        end
      end
    end

    # Split a line into an alternating stream of identifiers, whitespace runs, and
    # single punctuation characters so the word diff aligns on meaningful units.
    def tokenize(text)
      text.scan(/\w+|\s+|[^\w\s]/)
    end

    # Returns [del_html, add_html] with changed tokens wrapped in dw-del / dw-add.
    def word_diff(old_text, new_text)
      changes = ::Diff::LCS.sdiff(tokenize(old_text), tokenize(new_text))
      del = +""
      add = +""
      changes.each do |change|
        case change.action
        when "=" # unchanged on both sides
          del << esc(change.old_element)
          add << esc(change.new_element)
        when "-" # only in the old line
          del << %(<span class="dw-del">#{esc(change.old_element)}</span>)
        when "+" # only in the new line
          add << %(<span class="dw-add">#{esc(change.new_element)}</span>)
        when "!" # replaced
          del << %(<span class="dw-del">#{esc(change.old_element)}</span>)
          add << %(<span class="dw-add">#{esc(change.new_element)}</span>)
        end
      end
      [del, add]
    end

    def render(rows, lexer)
      out = +%(<table class="diff highlight">)
      rows.each do |row|
        out << render_row(row, lexer)
      end
      out << "</table>"
      out
    end

    def render_row(row, lexer)
      return %(<tr class="diff-hunk"><td colspan="3">#{esc(row.text)}</td></tr>) if row.kind == :hunk

      sign =
        case row.kind
        when :add then "+"
        when :del then "-"
        else " "
        end
      code = row.html || highlight(lexer, row.text)
      %(<tr class="diff-row diff-#{row.kind}">) <<
        gutter(row.old_ln) <<
        gutter(row.new_ln) <<
        %(<td class="diff-code"><span class="diff-sign">#{sign}</span>#{code}</td></tr>)
    end

    def gutter(num)
      %(<td class="diff-gutter">#{num}</td>)
    end

    def highlight(lexer, content)
      return "" if content.empty?

      FORMATTER.format(lexer.lex(content)).chomp
    end

    def lexer_for(file)
      lexer =
        begin
          Rouge::Lexer.guess_by_filename(file.to_s)
        rescue Rouge::Guesser::Ambiguous => e
          e.alternatives.first
        rescue StandardError
          nil
        end
      (lexer || Rouge::Lexers::PlainText).new
    end

    def esc(str)
      CGI.escapeHTML(str.to_s)
    end
  end
end
