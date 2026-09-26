require "test_helper"
require "rails/generators"
require "rails/generators/test_case"
require "generators/rails_refdocs/install/install_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests RailsRefdocs::Generators::InstallGenerator
  destination File.expand_path("../tmp/generator", __dir__)

  setup do
    prepare_destination
    File.write(File.join(destination_root, "Gemfile.lock"), <<~LOCK)
      GEM
        remote: https://rubygems.org/
        specs:
          pg (1.6.2)
          rails (8.1.4)
          turbo-rails (2.0.23)
          solid_queue (1.7.0)
    LOCK
    File.write(File.join(destination_root, ".gitignore"), "/log/*\n")
  end

  def test_writes_topics_from_the_lockfile_gitignore_and_binstub
    output = run_generator
    assert_file "reference/TOPICS", "ruby\nrails\npostgres\nturbo\nsolid_queue\n"
    assert_file ".gitignore", %r{/log/\*\n\n/reference/\*\n!/reference/README.md\n!/reference/TOPICS\n!/reference/VERSIONS\n}
    assert_file "bin/refdocs", /RailsRefdocs::CLI.start\(ARGV, command: ENV.fetch\("REFDOCS_COMMAND", "bin\/refdocs"\)\)/
    assert File.executable?(File.join(destination_root, "bin/refdocs"))
    assert_match(/Pin postgres/, output)
  end

  def test_is_idempotent
    run_generator
    File.write(File.join(destination_root, "reference/TOPICS"), "rails 8.1\n")
    run_generator
    assert_file "reference/TOPICS", "rails 8.1\n"
    assert_equal 1, File.read(File.join(destination_root, ".gitignore")).scan("/reference/*").size
  end
end
