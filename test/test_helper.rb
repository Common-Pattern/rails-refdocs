$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "rails_refdocs"
require "minitest/autorun"
require "stringio"

RailsRefdocs.log_io = StringIO.new

module TestHelpers
  FIXTURES = File.expand_path("fixtures", __dir__)

  def fixture(*parts)
    File.join(FIXTURES, *parts)
  end

  def in_tmpdir
    Dir.mktmpdir("rails-refdocs-test") { |dir| yield File.realpath(dir) }
  end

  def write(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
    path
  end
end

Minitest::Test.include(TestHelpers)
