require "test_helper"

class VersionsTest < Minitest::Test
  def test_pick_takes_the_highest_release_under_a_prefix
    candidates = %w[8.0.2 8.1.0 8.1.10 8.1.9 8.2.0.beta1 9.0.0]
    assert_equal "8.1.10", RailsRefdocs::Versions.pick(candidates, "8.1")
    assert_equal "9.0.0", RailsRefdocs::Versions.pick(candidates)
    assert_equal "8.0.2", RailsRefdocs::Versions.pick(candidates, "8.0.2")
  end

  def test_pick_does_not_treat_a_prefix_as_a_substring
    assert_nil RailsRefdocs::Versions.pick(%w[18.1 1.8], "1.80")
    assert_equal "1.8", RailsRefdocs::Versions.pick(%w[18.1 1.8], "1")
  end

  def test_component_reads_one_part_of_a_compound_version
    version = "turbo-8.0.23+turbo-rails-2.0.23+site-4f4c385ae8b6"
    assert_equal "8.0.23", RailsRefdocs::Versions.component(version, "turbo")
    assert_equal "2.0.23", RailsRefdocs::Versions.component(version, "turbo-rails")
    assert_equal "4f4c385ae8b6", RailsRefdocs::Versions.component(version, "site")
    assert_nil RailsRefdocs::Versions.component(version, "stimulus")
    assert_equal "b8398e25befc", RailsRefdocs::Versions.component("stimulus-3.2.2+stimulus-rails-1.3.4+site-b8398e25befc", "site")
  end
end
