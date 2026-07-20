# frozen_string_literal: true

require "sinatra/base"
require "ipaddr"
require "json"

require_relative "markdown"
require_relative "diff"
require_relative "state"
require_relative "export"
require_relative "lifecycle"

module HunkReviewChanges
  # The Sinatra app that serves the review UI and collects per-piece comments. It is
  # configured per run through Sinatra settings so tests can drive it with rack-test
  # against a fixture bundle and a shutdown stub, instead of a real port and exit!.
  class App < Sinatra::Base
    set :views, File.expand_path("views", __dir__)
    set :public_folder, File.expand_path("public", __dir__)
    set :bind, "127.0.0.1"
    set :logging, false
    enable :static

    # The server only ever binds to loopback, so restrict host authorization to
    # loopback hosts (guards against DNS-rebinding without depending on the Sinatra
    # environment, whose default only applies the check in development).
    set :host_authorization, {
      permitted_hosts: ["localhost", ".localhost", IPAddr.new("127.0.0.0/8"), IPAddr.new("::1")]
    }

    # Configured by the server (or a test) before the app handles a request.
    set :bundle, nil
    set :state_path, nil
    set :export_path, nil
    set :lifecycle, nil

    class << self
      # The shutdown callback is stored outside Sinatra settings on purpose: a setting
      # whose value responds to #call is auto-invoked when read, which would fire the
      # shutdown the moment a route touched it. A plain accessor holds the callable.
      attr_accessor :on_done
    end

    helpers do
      def bundle = settings.bundle
      def state = State.new(settings.state_path)
      def esc(str) = str.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
    end

    get "/" do
      review_state = state
      total = bundle.pieces.size
      @target = bundle.target
      @resolved_by = bundle.resolved_by
      @framing = Markdown.inline(bundle.framing)
      @pieces = bundle.pieces.map do |piece|
        entry = review_state[piece["id"]]
        {
          id: piece["id"],
          n: "#{piece["id"]} of #{total}",
          file: piece["file"],
          label: piece["label"],
          kind: piece["kind"] || "code",
          what: Markdown.inline(piece["what"]),
          why: Markdown.inline(piece["why"]),
          flags: Array(piece["flags"]).map { |flag| Markdown.inline(flag) },
          comment: entry["comment"].to_s,
          flagged: !!entry["flag"],
          reviewed: !!entry["reviewed"],
          status: State.status_for(entry),
          diff: Diff.to_html(piece["diff"], piece["file"])
        }
      end
      erb :index
    end

    post "/pieces/:id" do
      content_type :json
      body = parse_body
      status = state.update(
        params["id"],
        comment: body["comment"],
        flag: body["flag"],
        reviewed: body["reviewed"]
      )
      { ok: true, status: status }.to_json
    end

    get "/export.md" do
      content_type "text/plain"
      Export.new(bundle, state).to_markdown
    end

    post "/done" do
      content_type :json
      File.write(settings.export_path, Export.new(bundle, state).to_markdown)
      self.class.on_done&.call
      { ok: true, export: settings.export_path }.to_json
    end

    post "/heartbeat" do
      settings.lifecycle&.heartbeat!
      204
    end

    post "/bye" do
      settings.lifecycle&.bye!
      204
    end

    private

    def parse_body
      JSON.parse(request.body.read)
    rescue StandardError
      {}
    end
  end
end
