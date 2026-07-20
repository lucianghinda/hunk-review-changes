# frozen_string_literal: true

require_relative "lib/hunk_review_changes/version"

Gem::Specification.new do |spec|
  spec.name = "hunk_review_changes"
  spec.version = HunkReviewChanges::VERSION
  spec.authors = ["Lucian Ghinda"]
  spec.email = ["dev@ghinda.com"]

  spec.summary = "Review a diff hunk-by-hunk in your browser, then hand the comments back to your AI agent."
  spec.description = <<~DESC
    hunk_review_changes serves a local browser UI for reviewing a diff one hunk at a
    time. An AI coding agent writes a bundle of pieces (each a diff hunk with a
    what/why explanation), launches this server, and you comment on each piece at your
    own pace. Clicking Done writes a paste-ready export the agent picks up to implement
    every requested change. Ships a companion skill installable into Claude Code,
    Codex, Cursor, and OpenCode.
  DESC
  spec.homepage = "https://github.com/ghinda/hunk-review-changes"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir[
    "lib/**/*",
    "exe/*",
    "README.md",
    "LICENSE.txt",
    "CHANGELOG.md"
  ]
  spec.bindir = "exe"
  spec.executables = ["hunk-review-changes"]
  spec.require_paths = ["lib"]

  spec.add_dependency "diff-lcs", "~> 1.5"
  spec.add_dependency "kramdown", "~> 2.4"
  spec.add_dependency "kramdown-parser-gfm", "~> 1.1"
  spec.add_dependency "puma", ">= 6.0", "< 9.0"
  spec.add_dependency "rouge", "~> 4.0"
  spec.add_dependency "sinatra", "~> 4.0"
end
