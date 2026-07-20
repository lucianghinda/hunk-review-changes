# frozen_string_literal: true

require "test_helper"

module HunkReviewChanges
  class StateTest < Minitest::Test
    def test_status_precedence
      assert_equal "flag", State.status_for("flag" => true, "comment" => "x", "reviewed" => true)
      assert_equal "change", State.status_for("comment" => "please fix", "reviewed" => true)
      assert_equal "ok", State.status_for("comment" => "", "reviewed" => true)
      assert_equal "unreviewed", State.status_for("comment" => "", "reviewed" => false)
      assert_equal "unreviewed", State.status_for({})
    end

    def test_actionable_only_for_flag_and_change
      assert State.actionable?("comment" => "do it")
      assert State.actionable?("flag" => true)
      refute State.actionable?("reviewed" => true)
      refute State.actionable?({})
    end

    def test_round_trips_through_disk
      Dir.mktmpdir do |dir|
        path = File.join(dir, "state.json")
        state = State.new(path)
        status = state.update(1, comment: "rename this", flag: false, reviewed: false)
        assert_equal "change", status

        reloaded = State.new(path)
        assert_equal "rename this", reloaded[1]["comment"]
        assert_equal "change", reloaded.status(1)
      end
    end

    def test_reviewed_without_comment_is_ok
      Dir.mktmpdir do |dir|
        state = State.new(File.join(dir, "state.json"))
        assert_equal "ok", state.update(2, comment: "", flag: false, reviewed: true)
      end
    end
  end
end
