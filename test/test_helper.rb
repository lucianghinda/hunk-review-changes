# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "minitest/mock"
require "tmpdir"
require "fileutils"
require "json"

require "hunk_review_changes"

module HunkReviewChanges
  module TestHelpers
    FIXTURE = File.expand_path("fixtures/sample_bundle.json", __dir__)

    # Runs the block with a fresh copy of the sample bundle in a temp dir, yielding
    # the loaded Bundle and the directory.
    def with_sample_bundle
      Dir.mktmpdir("rhc-test-") do |dir|
        path = File.join(dir, "bundle.json")
        FileUtils.cp(FIXTURE, path)
        yield Bundle.load(path), dir
      end
    end

    def write_bundle(dir, data)
      path = File.join(dir, "bundle.json")
      File.write(path, JSON.generate(data))
      path
    end
  end
end
