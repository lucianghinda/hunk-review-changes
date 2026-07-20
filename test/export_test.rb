# frozen_string_literal: true

require "test_helper"

module HunkReviewChanges
  class ExportTest < Minitest::Test
    include TestHelpers

    def test_no_changes_when_all_ok
      with_sample_bundle do |bundle, dir|
        state = State.new(File.join(dir, "state.json"))
        bundle.pieces.each { |p| state.update(p["id"], comment: "", flag: false, reviewed: true) }
        md = Export.new(bundle, state).to_markdown
        assert_includes md, "No changes requested"
        refute_includes md, "## Piece"
      end
    end

    def test_includes_change_and_flag_excludes_ok
      with_sample_bundle do |bundle, dir|
        state = State.new(File.join(dir, "state.json"))
        state.update(1, comment: "rename venue", flag: false, reviewed: false)
        state.update(2, comment: "", flag: true, reviewed: false)
        md = Export.new(bundle, state).to_markdown

        assert_includes md, "## Piece 1 of 2"
        assert_includes md, "Status: change"
        assert_includes md, "rename venue"
        assert_includes md, "## Piece 2 of 2"
        assert_includes md, "Status: flag"
        assert_includes md, "```diff"
      end
    end

    def test_ok_piece_is_excluded
      with_sample_bundle do |bundle, dir|
        state = State.new(File.join(dir, "state.json"))
        state.update(1, comment: "do it", flag: false, reviewed: false)
        state.update(2, comment: "", flag: false, reviewed: true)
        md = Export.new(bundle, state).to_markdown
        assert_includes md, "## Piece 1 of 2"
        refute_includes md, "## Piece 2 of 2"
      end
    end
  end
end
