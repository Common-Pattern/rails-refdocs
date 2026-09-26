require "test_helper"

class ManifestTest < Minitest::Test
  def test_records_rows_sorted_by_topic
    in_tmpdir do |dir|
      path = File.join(dir, "VERSIONS")
      manifest = RailsRefdocs::Manifest.new(path)
      manifest.record("rails", "8.1.4", "rails source", fetched: "2026-09-01")
      manifest.record("bootstrap", "5.3.8", "bootstrap source", fetched: "2026-09-02")
      manifest.record("rails", "8.1.5", "rails source", fetched: "2026-09-03")
      assert_equal <<~TSV, File.read(path)
        topic\tversion\tfetched\tsource
        bootstrap\t5.3.8\t2026-09-02\tbootstrap source
        rails\t8.1.5\t2026-09-03\trails source
      TSV
      assert_equal "8.1.5", RailsRefdocs::Manifest.new(path)["rails"].version
    end
  end
end
