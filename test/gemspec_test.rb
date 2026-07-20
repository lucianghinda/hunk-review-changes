# frozen_string_literal: true

require "test_helper"

module HunkReviewChanges
  class GemspecTest < Minitest::Test
    def spec
      Gem::Specification.load(File.expand_path("../hunk_review_changes.gemspec", __dir__))
    end

    def test_declares_rackup_runtime_dependency
      # Sinatra 4 only soft-requires rackup, so App.run! exits with a missing-gem
      # warning unless the gem pulls rackup in for a fresh install.
      assert_includes spec.runtime_dependencies.map(&:name), "rackup"
    end
  end
end
