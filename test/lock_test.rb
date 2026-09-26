require "test_helper"

class LockTest < Minitest::Test
  LOCKFILE = <<~LOCK
    GIT
      remote: https://github.com/example/thing.git
      revision: abc
      specs:
        thing (0.3.0)
          rails (>= 7)

    GEM
      remote: https://rubygems.org/
      specs:
        bootstrap (5.3.8)
          popper_js (>= 2.11.8, < 3)
        nokogiri (1.18.9-aarch64-linux-gnu)
        nokogiri (1.18.9-x86_64-linux-gnu)
        rails (8.1.4)
          railties (= 8.1.4)
        railties (8.1.4)

    PLATFORMS
      x86_64-linux

    DEPENDENCIES
      rails (~> 8.1)

    RUBY VERSION
       ruby 4.0.6p0

    BUNDLED WITH
       4.0.20
  LOCK

  def test_reads_locked_gem_versions_without_platform_suffixes
    gems = RailsRefdocs::Lock.parse_gems(LOCKFILE)
    assert_equal "8.1.4", gems["rails"]
    assert_equal "1.18.9", gems["nokogiri"]
    assert_equal "0.3.0", gems["thing"]
    refute gems.key?("popper_js")
  end

  def test_ruby_prefers_ruby_version_file
    in_tmpdir do |dir|
      write(File.join(dir, "Gemfile.lock"), LOCKFILE)
      assert_equal [ "4.0.6", "Gemfile.lock" ], RailsRefdocs::Lock.load(dir).ruby.to_a
      write(File.join(dir, ".ruby-version"), "ruby-4.0.7\n")
      assert_equal [ "4.0.7", ".ruby-version" ], RailsRefdocs::Lock.load(dir).ruby.to_a
    end
  end

  def test_missing_files_lock_nothing
    in_tmpdir do |dir|
      lock = RailsRefdocs::Lock.load(dir)
      assert_nil lock.gem("rails")
      assert_nil lock.ruby
    end
  end
end
