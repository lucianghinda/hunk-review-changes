# frozen_string_literal: true

require "socket"

require_relative "app"
require_relative "bundle"
require_relative "lifecycle"

module HunkReviewChanges
  # Boots the review UI for a bundle: configures the app, picks a free localhost port,
  # opens the browser, arms the watchdog, and runs Puma. Blocks until the user clicks
  # Done (which writes export.md and exits) or the watchdog fires.
  class Server
    def initialize(bundle, port: nil, open: true)
      @bundle = bundle
      @port = port || free_port
      @open = open
      @lifecycle = Lifecycle.new
    end

    def url = "http://127.0.0.1:#{@port}/"
    def export_path = File.join(@bundle.dir, "export.md")

    def run
      configure_app
      open_browser
      arm_watchdog
      announce
      App.run!(port: @port, server: "puma")
    end

    private

    def configure_app
      App.set(:bundle, @bundle)
      App.set(:state_path, File.join(@bundle.dir, "state.json"))
      App.set(:export_path, export_path)
      App.set(:lifecycle, @lifecycle)
      App.on_done = method(:shutdown)
    end

    def shutdown
      Thread.new do
        sleep 0.6
        exit!(0)
      end
    end

    def open_browser
      return unless @open

      Thread.new do
        sleep 1.0
        system("open", url, out: File::NULL, err: File::NULL)
      end
    end

    def arm_watchdog
      boot_time = Time.now
      Thread.new do
        loop do
          sleep 2
          exit!(0) if @lifecycle.expired?(boot_time)
        end
      end
    end

    def announce
      warn "Review UI: #{url}"
      warn "Bundle:    #{@bundle.path}"
      warn "Export →   #{export_path} (written when you click Done)"
    end

    def free_port
      server = TCPServer.new("127.0.0.1", 0)
      port = server.addr[1]
      server.close
      port
    end
  end
end
