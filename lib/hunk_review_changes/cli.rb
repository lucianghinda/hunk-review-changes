# frozen_string_literal: true

require "optparse"

require_relative "version"
require_relative "bundle"

module HunkReviewChanges
  # Command-line entry point. Two commands:
  #
  #   hunk-review-changes <bundle.json> [--port N] [--no-open]   serve the review UI
  #   hunk-review-changes install [--agent ...] [--marketplace-repo ...]
  #
  # `serve` is the default, so a bare bundle path just works (that is how the skill
  # launches it).
  class CLI
    class Error < StandardError
    end

    def self.start(argv)
      new.run(argv)
    rescue Bundle::Error, Error, OptionParser::ParseError => e
      warn "hunk-review-changes: #{e.message}"
      1
    end

    def run(argv)
      argv = argv.dup
      case argv.first
      when "install" then install(argv.drop(1))
      when "-v", "--version" then print_version
      when "-h", "--help", nil then print_help
      else serve(argv)
      end
    end

    private

    def serve(argv)
      options = { open: open_by_default? }
      parser = OptionParser.new do |o|
        o.banner = "Usage: hunk-review-changes <bundle.json> [--port N] [--no-open]"
        o.on("--port N", Integer, "Port to bind (default: a free port)") { |n| options[:port] = n }
        o.on("--no-open", "Do not open the browser automatically") { options[:open] = false }
      end
      rest = parser.parse(argv)
      path = rest.first
      raise Error, "no bundle given\n#{parser}" unless path

      require_relative "server"
      bundle = Bundle.load(path)
      Server.new(bundle, port: options[:port], open: options[:open]).run
      0
    end

    def install(argv)
      options = { repo: MARKETPLACE_REPO }
      parser = OptionParser.new do |o|
        o.banner = "Usage: hunk-review-changes install [--agent claude,codex,...] " \
                   "[--marketplace-repo URL_OR_PATH]"
        o.on("--agent LIST", Array, "Agents to install for (skips the prompt); or 'all'") do |list|
          options[:only] = list
        end
        o.on("--marketplace-repo REPO", "Marketplace repo URL or local path") do |repo|
          options[:repo] = repo
        end
      end
      parser.parse(argv)

      require_relative "installer/runner"
      results = Installer::Runner.new(repo: options[:repo], only: options[:only]).run
      results.all?(&:ok) ? 0 : 1
    end

    def open_by_default?
      ENV["REVIEW_WEB_NO_OPEN"] != "1"
    end

    def print_version
      puts "hunk-review-changes #{VERSION}"
      0
    end

    def print_help
      puts <<~HELP
        hunk-review-changes #{VERSION}

        Review a diff hunk-by-hunk in your browser, then hand the comments back to
        your AI coding agent.

        Usage:
          hunk-review-changes <bundle.json> [--port N] [--no-open]
              Serve the review UI for a bundle written by the companion skill.

          hunk-review-changes install [--agent claude,codex,cursor,opencode]
                                      [--marketplace-repo URL_OR_PATH]
              Install the companion skill into your AI agents. With no --agent flag it
              asks which agents to install for.

          hunk-review-changes --version
          hunk-review-changes --help
      HELP
      0
    end
  end
end
