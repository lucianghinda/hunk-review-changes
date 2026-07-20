# frozen_string_literal: true

require "test_helper"

module HunkReviewChanges
  class BundleTest < Minitest::Test
    include TestHelpers

    def test_loads_a_valid_bundle
      with_sample_bundle do |bundle, _dir|
        assert_equal "feature/venue-guard vs main", bundle.target
        assert_equal 2, bundle.pieces.size
        assert_equal "app/services/shift_booking.rb", bundle.pieces.first["file"]
      end
    end

    def test_missing_file_raises
      error = assert_raises(Bundle::Error) { Bundle.load("/no/such/bundle.json") }
      assert_match(/no such bundle/, error.message)
    end

    def test_invalid_json_raises_actionable_error
      Dir.mktmpdir do |dir|
        path = File.join(dir, "bundle.json")
        File.write(path, "{ not json,,, }")
        error = assert_raises(Bundle::Error) { Bundle.load(path) }
        assert_match(/not valid JSON/, error.message)
      end
    end

    def test_empty_pieces_raises
      Dir.mktmpdir do |dir|
        path = write_bundle(dir, { "target" => "x", "pieces" => [] })
        error = assert_raises(Bundle::Error) { Bundle.load(path) }
        assert_match(/empty/, error.message)
      end
    end

    def test_non_sequential_ids_raise
      Dir.mktmpdir do |dir|
        path = write_bundle(dir, {
                              "pieces" => [
                                { "id" => 1, "file" => "a.rb", "label" => "x", "diff" => "@@ -1 +1 @@\n-a\n+b\n" },
                                { "id" => 3, "file" => "b.rb", "label" => "y", "diff" => "@@ -1 +1 @@\n-a\n+b\n" }
                              ]
                            })
        error = assert_raises(Bundle::Error) { Bundle.load(path) }
        assert_match(/1-based and sequential/, error.message)
      end
    end

    def test_diff_without_hunk_header_raises
      Dir.mktmpdir do |dir|
        path = write_bundle(dir, {
                              "pieces" => [{ "id" => 1, "file" => "a.rb", "label" => "x", "diff" => "-a\n+b\n" }]
                            })
        error = assert_raises(Bundle::Error) { Bundle.load(path) }
        assert_match(/no @@ hunk header/, error.message)
      end
    end

    def test_escaped_diff_raises
      Dir.mktmpdir do |dir|
        path = write_bundle(dir, {
                              "pieces" => [{ "id" => 1, "file" => "a.rb", "label" => "x",
                                             "diff" => '@@ -1 +1 @@\n-a\n+b\n' }]
                            })
        error = assert_raises(Bundle::Error) { Bundle.load(path) }
        assert_match(/looks escaped/, error.message)
      end
    end

    def test_missing_label_raises
      Dir.mktmpdir do |dir|
        path = write_bundle(dir, {
                              "pieces" => [{ "id" => 1, "file" => "a.rb", "diff" => "@@ -1 +1 @@\n-a\n+b\n" }]
                            })
        error = assert_raises(Bundle::Error) { Bundle.load(path) }
        assert_match(/label/, error.message)
      end
    end

    def test_fingerprint_is_stable_for_the_same_content
      with_sample_bundle do |bundle, dir|
        reloaded = Bundle.load(File.join(dir, "bundle.json"))
        assert_equal bundle.fingerprint, reloaded.fingerprint
      end
    end

    def test_fingerprint_changes_with_content
      Dir.mktmpdir do |dir|
        piece = { "id" => 1, "file" => "a.rb", "label" => "x", "diff" => "@@ -1 +1 @@\n-a\n+b\n" }
        one = Bundle.load(write_bundle(dir, { "pieces" => [piece] }))
        two = Bundle.load(write_bundle(dir, { "pieces" => [piece.merge("label" => "y")] }))
        refute_equal one.fingerprint, two.fingerprint
      end
    end
  end
end
