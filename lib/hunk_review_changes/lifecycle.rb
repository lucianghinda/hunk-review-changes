# frozen_string_literal: true

module HunkReviewChanges
  # Tracks the browser tab's liveness so the server can shut itself down shortly after
  # the tab closes and never leak a process. The app records events here; the server's
  # watchdog thread reads them.
  class Lifecycle
    BYE_GRACE = 8      # seconds to wait after a tab says it is closing
    SILENT_LIMIT = 900 # a live tab that goes quiet this long is treated as crashed
    CONNECT_LIMIT = 180 # give up if no tab ever connects

    def initialize(clock: -> { Time.now })
      @clock = clock
      @mutex = Mutex.new
      @last_heartbeat = nil
      @bye_at = nil
    end

    # A fresh heartbeat (e.g. from a reload) also cancels a pending goodbye.
    def heartbeat!
      @mutex.synchronize do
        @last_heartbeat = @clock.call
        @bye_at = nil
      end
    end

    def bye!
      @mutex.synchronize { @bye_at = @clock.call + BYE_GRACE }
    end

    # Whether the server should exit now, given when it booted.
    def expired?(boot_time)
      now = @clock.call
      last, bye = @mutex.synchronize { [@last_heartbeat, @bye_at] }
      return true if bye && now >= bye
      return true if last && now - last > SILENT_LIMIT
      return true if last.nil? && now - boot_time > CONNECT_LIMIT

      false
    end
  end
end
