# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"

module HunkReviewChanges
  # Renders the prose fields (what/why/framing/flags) as GitHub-flavored Markdown.
  module Markdown
    module_function

    def html(text)
      return "" if text.nil? || text.to_s.strip.empty?

      Kramdown::Document.new(
        text.to_s,
        input: "GFM",
        hard_wrap: true,
        auto_ids: false,
        parse_block_html: false,
        parse_span_html: false
      ).to_html.strip
    end

    # Unwrap a single top-level <p> so the prose can sit inline after a bold lead-in
    # label ("What it does — ..."); multi-paragraph / list output is returned as-is.
    def inline(text)
      rendered = html(text)
      if rendered.start_with?("<p>") && rendered.end_with?("</p>") && !rendered[3..-5].include?("<p")
        rendered[3..-5]
      else
        rendered
      end
    end
  end
end
