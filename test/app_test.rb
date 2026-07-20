# frozen_string_literal: true

require "test_helper"
require "rack/test"

module HunkReviewChanges
  class AppTest < Minitest::Test
    include TestHelpers
    include Rack::Test::Methods

    # The app permits only loopback hosts; rack-test defaults to example.org.
    def default_host = "127.0.0.1"

    def setup
      @dir = Dir.mktmpdir("rhc-app-")
      path = File.join(@dir, "bundle.json")
      FileUtils.cp(TestHelpers::FIXTURE, path)
      @bundle = Bundle.load(path)
      @shutdown_called = false

      App.set(:bundle, @bundle)
      App.set(:state_path, File.join(@dir, "state.json"))
      App.set(:export_path, File.join(@dir, "export.md"))
      App.set(:lifecycle, Lifecycle.new)
      App.on_done = -> { @shutdown_called = true }
    end

    def teardown
      FileUtils.remove_entry(@dir)
    end

    def app = App

    def test_index_renders_pieces_and_assets
      get "/"
      assert_equal 200, last_response.status
      assert_includes last_response.body, "/app.css"
      assert_includes last_response.body, "class=\"diff highlight\""
      assert_includes last_response.body, "Looks good"
      assert_includes last_response.body, "guard against a nil venue"
    end

    def test_saving_a_comment_marks_it_a_change
      post "/pieces/1", { comment: "rename venue", flag: false, reviewed: false }.to_json,
           "CONTENT_TYPE" => "application/json"
      assert_equal 200, last_response.status
      assert_equal "change", JSON.parse(last_response.body)["status"]
    end

    def test_reviewed_without_comment_is_ok
      post "/pieces/2", { comment: "", flag: false, reviewed: true }.to_json,
           "CONTENT_TYPE" => "application/json"
      assert_equal "ok", JSON.parse(last_response.body)["status"]
    end

    def test_export_reflects_saved_state
      post "/pieces/1", { comment: "rename venue", flag: false, reviewed: false }.to_json,
           "CONTENT_TYPE" => "application/json"
      post "/pieces/2", { comment: "", flag: false, reviewed: true }.to_json,
           "CONTENT_TYPE" => "application/json"
      get "/export.md"
      assert_equal 200, last_response.status
      assert_includes last_response.body, "## Piece 1 of 2"
      refute_includes last_response.body, "## Piece 2 of 2"
    end

    def test_done_writes_export_and_calls_shutdown
      post "/pieces/1", { comment: "fix it", flag: false, reviewed: false }.to_json,
           "CONTENT_TYPE" => "application/json"
      post "/done"
      assert_equal 200, last_response.status
      assert @shutdown_called, "shutdown callable should be invoked"
      assert_path_exists App.settings.export_path
      assert_includes File.read(App.settings.export_path), "fix it"
    end

    def test_heartbeat_and_bye_return_204
      post "/heartbeat"
      assert_equal 204, last_response.status
      post "/bye"
      assert_equal 204, last_response.status
    end

    def test_rejects_non_loopback_host
      get "/", {}, "HTTP_HOST" => "evil.example.com"
      assert_equal 403, last_response.status
    end
  end
end
