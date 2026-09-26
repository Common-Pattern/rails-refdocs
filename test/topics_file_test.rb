require "test_helper"

class TopicsFileTest < Minitest::Test
  def parse(content)
    RailsRefdocs::TopicsFile.new("TOPICS", content)
  end

  def test_orders_topics_as_known_and_reads_pins
    file = parse("# stack\nturbo\nrails 8.1\n\npostgres 18 # server\nruby\n")
    assert_equal %w[ruby rails postgres turbo], file.topics
    assert_equal({ "rails" => "8.1", "postgres" => "18" }, file.pins)
  end

  def test_rejects_bad_lines
    assert_raises(RailsRefdocs::Error) { parse("rails 8.1 extra\n") }
    assert_raises(RailsRefdocs::Error) { parse("django\n") }
    assert_raises(RailsRefdocs::Error) { parse("turbo 8\n") }
    assert_raises(RailsRefdocs::Error) { parse("rails latest\n") }
    assert_raises(RailsRefdocs::Error) { parse("# nothing\n") }
  end

  def test_select_keeps_known_order_and_rejects_unlisted_topics
    file = parse("ruby\nrails\npostgres\n")
    assert_equal %w[ruby rails postgres], file.select([])
    assert_equal %w[ruby postgres], file.select(%w[postgres ruby])
    assert_raises(RailsRefdocs::Error) { file.select(%w[bootstrap]) }
  end
end
