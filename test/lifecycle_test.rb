# frozen_string_literal: true

require "test_helper"

module HunkReviewChanges
  class LifecycleTest < Minitest::Test
    def test_expires_when_no_tab_ever_connects
      now = Time.now
      clock = -> { now }
      life = Lifecycle.new(clock: clock)
      boot = now - (Lifecycle::CONNECT_LIMIT + 1)
      assert life.expired?(boot)
    end

    def test_does_not_expire_right_after_boot
      now = Time.now
      life = Lifecycle.new(clock: -> { now })
      refute life.expired?(now)
    end

    def test_heartbeat_keeps_it_alive
      t = Time.now
      clock = -> { t }
      life = Lifecycle.new(clock: clock)
      life.heartbeat!
      refute life.expired?(t - 10_000)
    end

    def test_expires_after_bye_grace
      t = Time.now
      current = t
      life = Lifecycle.new(clock: -> { current })
      life.heartbeat!
      life.bye!
      current = t + Lifecycle::BYE_GRACE + 1
      assert life.expired?(t)
    end

    def test_heartbeat_cancels_pending_bye
      t = Time.now
      current = t
      life = Lifecycle.new(clock: -> { current })
      life.bye!
      life.heartbeat! # e.g. a reload arrived
      current = t + Lifecycle::BYE_GRACE + 1
      refute life.expired?(t)
    end
  end
end
