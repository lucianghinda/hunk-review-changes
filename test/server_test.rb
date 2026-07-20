# frozen_string_literal: true

require "test_helper"

module HunkReviewChanges
  class ServerTest < Minitest::Test
    include TestHelpers

    # port is fixed and open: false so constructing the server touches no sockets.
    def server
      Server.new(Bundle.load(TestHelpers::FIXTURE), port: 1234, open: false)
    end

    def test_browser_command_is_platform_appropriate
      url = "http://127.0.0.1:1234/"
      assert_equal ["open", url], server.send(:browser_command, url, host_os: "x86_64-darwin23")
      assert_equal ["xdg-open", url], server.send(:browser_command, url, host_os: "x86_64-linux")
      assert_equal ["cmd", "/c", "start", "", url], server.send(:browser_command, url, host_os: "x64-mingw-ucrt")
    end

    def test_launch_browser_warns_instead_of_raising_when_open_fails
      s = server
      s.stub(:system, false) do
        assert_output(nil, /open .* to start the review/i) do
          s.send(:launch_browser, "http://127.0.0.1:1234/")
        end
      end
    end
  end
end
