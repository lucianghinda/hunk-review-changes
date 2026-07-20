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
      assert_equal ["open"], server.send(:browser_command, "x86_64-darwin23")
      assert_equal ["xdg-open"], server.send(:browser_command, "x86_64-linux")
      assert_equal ["cmd", "/c", "start", ""], server.send(:browser_command, "x64-mingw-ucrt")
    end
  end
end
