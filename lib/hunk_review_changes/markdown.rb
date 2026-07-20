# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"

module HunkReviewChanges
  # Renders the prose fields (what/why/framing/flags) as GitHub-flavored Markdown.
  module Markdown
    module_function

    # Schemes allowed on rendered links and images. Kramdown does not sanitize URLs,
    # so anything else (javascript:, data:, vbscript:, file:, ...) is neutralized to
    # keep bundle prose from running script in the local app origin.
    SAFE_SCHEMES = %w[http https mailto tel].freeze

    def html(text)
      return "" if text.nil? || text.to_s.strip.empty?

      rendered = Kramdown::Document.new(
        text.to_s,
        input: "GFM",
        hard_wrap: true,
        auto_ids: false,
        parse_block_html: false,
        parse_span_html: false
      ).to_html.strip
      sanitize_urls(rendered)
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

    # Replace the value of any href/src whose scheme is not allowlisted with "#", so a
    # link like [x](javascript:alert(1)) renders inert while safe URLs pass untouched.
    def sanitize_urls(html)
      html.gsub(/(\s(?:href|src)=)(["'])(.*?)\2/im) do
        attr = Regexp.last_match(1)
        quote = Regexp.last_match(2)
        url = Regexp.last_match(3)
        "#{attr}#{quote}#{safe_url?(url) ? url : "#"}#{quote}"
      end
    end

    def safe_url?(url)
      scheme = url_scheme(url)
      scheme.nil? || SAFE_SCHEMES.include?(scheme)
    end

    # The scheme a browser would act on: it decodes numeric entities and ignores
    # control/whitespace characters before parsing the scheme, so normalize the same
    # way. Returns nil for relative/fragment/protocol-relative URLs (which are safe).
    def url_scheme(url)
      candidate = url
                  .gsub(/&#x([0-9a-f]+);/i) { [Regexp.last_match(1).to_i(16)].pack("U") }
                  .gsub(/&#(\d+);/) { [Regexp.last_match(1).to_i].pack("U") }
                  .gsub(/&amp;/i, "&")
                  .gsub(/[[:cntrl:][:space:]]/, "")
      candidate[/\A([a-z][a-z0-9+.-]*):/i, 1]&.downcase
    end
  end
end
