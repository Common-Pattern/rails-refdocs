require "test_helper"

class UpdaterTest < Minitest::Test
  class FakeTopic < RailsRefdocs::Topic
    attr_reader :fetched

    def initialize(name, version)
      @name = name
      @version = version
      @fetched = []
    end

    attr_reader :name

    def source = "fake #{name}"
    def layout = "- `#{name}/` fake\n"
    def lock_gem = name
    def latest(_pin) = @version

    def fetch(version, stage, _work_dir)
      @fetched << version
      File.write(File.join(stage, "README.md"), "#{name} #{version}\n")
    end
  end

  class FakeRegistry
    def initialize(topics)
      @topics = topics.to_h { |topic| [ topic.name, topic ] }
    end

    def fetch(name)
      @topics.fetch(name)
    end
  end

  def setup_app(dir, topics: "rails\nview_component\n", lock: nil)
    write(File.join(dir, "reference", "TOPICS"), topics)
    write(File.join(dir, "Gemfile.lock"), lock) if lock
    RailsRefdocs::Reference.new(File.join(dir, "reference"))
  end

  def test_update_fetches_what_is_behind_and_writes_the_index
    in_tmpdir do |dir|
      reference = setup_app(dir, lock: "GEM\n  specs:\n    rails (8.1.4)\n")
      rails = FakeTopic.new("rails", "9.9.9")
      view_component = FakeTopic.new("view_component", "4.15.0")
      updater = RailsRefdocs::Updater.new(reference, command: "bin/refdocs", registry: FakeRegistry.new([ rails, view_component ]))
      updater.update
      assert_equal [ "8.1.4" ], rails.fetched
      assert_equal [ "4.15.0" ], view_component.fetched
      assert_equal "rails 8.1.4\n", File.read(File.join(reference.dir, "rails", "README.md"))
      assert_equal "8.1.4", RailsRefdocs::Manifest.new(File.join(reference.dir, "VERSIONS"))["rails"].version
      readme = File.read(reference.readme)
      assert_includes readme, "| `rails/` | 8.1.4 |"
      assert_includes readme, "bin/refdocs update rails"
      refute File.exist?(reference.staging)

      RailsRefdocs::Updater.new(RailsRefdocs::Reference.new(reference.dir), command: "x",
        registry: FakeRegistry.new([ rails, view_component ])).update([ "rails" ])
      assert_equal [ "8.1.4" ], rails.fetched
    end
  end

  def test_check_locked_reports_topics_behind_the_lockfile
    in_tmpdir do |dir|
      reference = setup_app(dir, topics: "ruby\nrails\npostgres 18\nturbo\n",
        lock: "GEM\n  specs:\n    rails (8.1.5)\n    turbo-rails (2.0.23)\n")
      write(File.join(dir, ".ruby-version"), "4.0.7\n")
      write(File.join(reference.dir, "VERSIONS"), <<~TSV)
        topic\tversion\tfetched\tsource
        postgres\t18.5\t2026-09-01\tx
        rails\t8.1.4\t2026-09-01\tx
        ruby\t4.0.7\t2026-09-01\tx
        turbo\tturbo-8.0.23+turbo-rails-2.0.23+site-4f4c385ae8b6\t2026-09-01\tx
      TSV
      out = StringIO.new
      refute RailsRefdocs::Updater.new(reference, command: "bin/refdocs", out: out).check_locked
      assert_equal "rails: Gemfile.lock has 8.1.5, #{reference.manifest.path} has 8.1.4; run bin/refdocs update rails\n", out.string
      assert RailsRefdocs::Updater.new(reference, command: "x", out: StringIO.new).check_locked(%w[ruby turbo])
    end
  end
end
