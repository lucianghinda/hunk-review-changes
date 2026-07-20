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

    def test_same_bundle_resumes_prior_state
      Dir.mktmpdir do |dir|
        path = File.join(dir, "state.json")
        State.new(path, bundle_id: "bundle-A").update(1, comment: "keep me", flag: false, reviewed: false)

        resumed = State.new(path, bundle_id: "bundle-A")
        assert_equal "keep me", resumed[1]["comment"]
        assert_equal "change", resumed.status(1)
      end
    end

    def test_state_is_scoped_to_the_bundle_id
      Dir.mktmpdir do |dir|
        path = File.join(dir, "state.json")
        State.new(path, bundle_id: "bundle-A").update(1, comment: "note for A", flag: false, reviewed: false)

        # A different bundle reusing the same directory must not see A's comments.
        other = State.new(path, bundle_id: "bundle-B")
        assert_equal "", other[1]["comment"].to_s
        assert_equal "unreviewed", other.status(1)
      end
    end

    def test_concurrent_updates_do_not_lose_pieces
      Dir.mktmpdir do |dir|
        path = File.join(dir, "state.json")
        threads = (1..25).map do |id|
          Thread.new { State.new(path).update(id, comment: "c#{id}", flag: false, reviewed: false) }
        end
        threads.each(&:join)

        final = State.new(path)
        (1..25).each { |id| assert_equal "c#{id}", final[id]["comment"], "piece #{id} was lost" }
      end
    end
  end
end
