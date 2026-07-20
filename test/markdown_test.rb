# frozen_string_literal: true

require "test_helper"

module HunkReviewChanges
  class MarkdownTest < Minitest::Test
    def test_blank_input_is_empty
      assert_equal "", Markdown.inline(nil)
      assert_equal "", Markdown.inline("   ")
    end

    def test_inline_unwraps_single_paragraph
      assert_equal "hello <code>world</code>", Markdown.inline("hello `world`")
    end

    def test_inline_keeps_multi_paragraph_wrapping
      html = Markdown.inline("first\n\nsecond")
      assert_includes html, "<p>first</p>"
      assert_includes html, "<p>second</p>"
    end

    def test_renders_lists
      html = Markdown.inline("- one\n- two")
      assert_includes html, "<li>one</li>"
      assert_includes html, "<ul>"
    end

    def test_escapes_html_inside_code_spans
      # The common case: identifiers/types wrapped in backticks are escaped, so a
      # quoted `<Generic>` renders literally rather than as markup.
      html = Markdown.inline("call `render<T>()`")
      assert_includes html, "<code>render&lt;T&gt;()</code>"
    end
  end
end
