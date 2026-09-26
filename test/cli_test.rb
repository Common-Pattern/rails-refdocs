require "test_helper"

class CliTest < Minitest::Test
  def run_cli(*args)
    out = StringIO.new
    err = StringIO.new
    status = RailsRefdocs::CLI.start(args, command: "bin/refdocs", out: out, err: err)
    [ status, out.string, err.string ]
  end

  def test_topics_lists_known_topics
    status, out, = run_cli("topics")
    assert_equal 0, status
    assert_equal RailsRefdocs::Topics.names.join("\n") + "\n", out
  end

  def test_help_and_errors
    status, out, = run_cli("--help")
    assert_equal 0, status
    assert_includes out, "Usage: bin/refdocs"

    status, _, err = run_cli("frobnicate")
    assert_equal 1, status
    assert_includes err, "error: unknown command: frobnicate"

    status, _, err = run_cli("update", "--quick")
    assert_equal 1, status
    assert_includes err, "error: unknown option: --quick"
  end

  def test_missing_topics_file_is_an_error
    in_tmpdir do |dir|
      status, _, err = run_cli("--dir", File.join(dir, "reference"), "check", "--locked")
      assert_equal 1, status
      assert_match(/TOPICS is missing/, err)
    end
  end

  def test_check_locked_exit_status
    in_tmpdir do |dir|
      write(File.join(dir, "reference", "TOPICS"), "rails\n")
      write(File.join(dir, "Gemfile.lock"), "GEM\n  specs:\n    rails (8.1.4)\n")
      status, out, = run_cli("--dir=#{File.join(dir, "reference")}", "check", "--locked")
      assert_equal 1, status
      assert_includes out, "run bin/refdocs update rails"
      write(File.join(dir, "reference", "VERSIONS"), "topic\tversion\tfetched\tsource\nrails\t8.1.4\t2026-09-26\tx\n")
      assert_equal 0, run_cli("--dir", File.join(dir, "reference"), "check", "--locked").first
    end
  end
end
