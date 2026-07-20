# frozen_string_literal: true

require "test_helper"

module HunkReviewChanges
  class DiffTest < Minitest::Test
    def test_parses_line_numbers_from_hunk_header
      diff = "@@ -8,3 +8,4 @@ class Foo\n ctx\n-old\n+new\n more\n"
      rows = Diff.parse(diff)
      hunk = rows.find { |r| r.kind == :hunk }
      refute_nil hunk

      del = rows.find { |r| r.kind == :del }
      add = rows.find { |r| r.kind == :add }
      assert_equal 9, del.old_ln # 8 (ctx) then 9 (del)
      assert_equal 9, add.new_ln
    end

    def test_skips_file_header_lines
      diff = "diff --git a/x b/x\nindex 1..2 100644\n--- a/x\n+++ b/x\n@@ -1 +1 @@\n-a\n+b\n"
      rows = Diff.parse(diff)
      refute(rows.any? { |r| r.text.to_s.start_with?("diff --git", "index", "---", "+++") })
    end

    def test_keeps_hunk_lines_that_look_like_file_headers
      # Inside a hunk, a deleted "-- x" reads "--- x" and an added "++ x" reads
      # "+++ x"; both are real content, not file headers, and must survive.
      diff = "@@ -1,2 +1,2 @@\n keep\n--- sql comment\n+++ sql added\n"
      rows = Diff.parse(diff)
      del = rows.find { |r| r.kind == :del }
      add = rows.find { |r| r.kind == :add }
      assert_equal "-- sql comment", del.text
      assert_equal "++ sql added", add.text
    end

    def test_multiple_hunks_in_one_piece
      diff = "@@ -1,2 +1,2 @@\n-a\n+b\n@@ -10,2 +10,2 @@\n-c\n+d\n"
      rows = Diff.parse(diff)
      assert_equal(2, rows.count { |r| r.kind == :hunk })
      assert_equal(2, rows.count { |r| r.kind == :add })
    end

    def test_word_diff_isolates_changed_token
      del_html, add_html = Diff.word_diff("tz = shift.venue.timezone", "tz = shift.location.timezone")
      assert_includes del_html, %(<span class="dw-del">venue</span>)
      assert_includes add_html, %(<span class="dw-add">location</span>)
      refute_includes del_html, %(<span class="dw-del">timezone</span>)
    end

    def test_to_html_pairs_modifications_and_highlights_context
      diff = "@@ -1,2 +1,2 @@\n def call\n-  a = venue\n+  a = location\n"
      html = Diff.to_html(diff, "foo.rb")
      assert_includes html, "diff-hunk"
      assert_includes html, %(<span class="dw-del">venue</span>)
      assert_includes html, %(<span class="dw-add">location</span>)
      assert_includes html, "class=\"diff highlight\""
    end

    def test_html_escapes_content
      diff = "@@ -1 +1 @@\n-<script>\n+<safe>\n"
      html = Diff.to_html(diff, "x.txt")
      refute_includes html, "<script>"
      assert_includes html, "&lt;"
    end

    def test_unpaired_addition_is_not_word_diffed
      diff = "@@ -1,1 +1,2 @@\n context\n+brand new line\n"
      html = Diff.to_html(diff, "x.rb")
      refute_includes html, "dw-add"
    end
  end
end
