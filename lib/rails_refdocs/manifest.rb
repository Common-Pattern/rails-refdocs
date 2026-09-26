module RailsRefdocs
  class Manifest
    HEADER = "topic\tversion\tfetched\tsource\n".freeze

    Row = Struct.new(:topic, :version, :fetched, :source)

    attr_reader :path

    def initialize(path)
      @path = path
      @rows = {}
      return unless File.file?(path)
      File.readlines(path, chomp: true).drop(1).each do |line|
        topic, version, fetched, source = line.split("\t", 4)
        @rows[topic] = Row.new(topic, version, fetched, source) if topic && !topic.empty?
      end
    end

    def [](topic)
      @rows[topic]
    end

    def record(topic, version, source, fetched: Time.now.utc.strftime("%F"))
      @rows[topic] = Row.new(topic, version, fetched, source)
      File.write(path, HEADER + @rows.keys.sort.map { |key| @rows[key].to_a.join("\t") + "\n" }.join)
    end
  end
end
