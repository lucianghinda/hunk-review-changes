# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

desc "Build public/app.css from assets/tailwind.css plus the Rouge theme CSS"
task :css do
  require "tailwindcss/ruby"
  require_relative "lib/hunk_review_changes/assets"

  root = __dir__
  input = File.join(root, "assets", "tailwind.css")
  output = File.join(root, "lib", "hunk_review_changes", "public", "app.css")

  puts "Building Tailwind CSS…"
  ok = system(
    Tailwindcss::Ruby.executable,
    "-i", input, "-o", output, "--cwd", root, "--minify"
  )
  abort "tailwind build failed" unless ok

  puts "Appending Rouge theme CSS…"
  File.open(output, "a") { |f| f.write("\n#{HunkReviewChanges::Assets.rouge_css}") }
  puts "Wrote #{output} (#{File.size(output)} bytes)"
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  # rubocop is a development dependency; skip the task if it is absent.
end

task default: %i[test rubocop]
