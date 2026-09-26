module RailsRefdocs
  class TopicsFile
    attr_reader :path, :topics, :pins

    def self.load(path)
      raise Error, "#{path} is missing; list one topic per line (known: #{Topics.names.join(" ")})" unless File.file?(path)
      new(path, File.read(path))
    end

    def initialize(path, content)
      @path = path
      @pins = {}
      listed = []
      content.each_line do |raw|
        topic, pin, extra = raw.sub(/#.*/, "").split
        next unless topic
        raise Error, "#{path}: '#{raw.strip}' has more than a topic and a pin" if extra
        topic_class = Topics.fetch(topic) { raise Error, "#{path}: unknown topic '#{topic}' (known: #{Topics.names.join(" ")})" }
        if pin
          raise Error, "#{path}: #{topic} takes no pin" unless topic_class.pinnable?
          raise Error, "#{path}: pin '#{pin}' for #{topic} is not a version prefix" unless pin.match?(Versions::RELEASE)
          @pins[topic] = pin
        end
        listed << topic
      end
      @topics = Topics.names & listed
      raise Error, "#{path} lists no topics" if @topics.empty?
    end

    def select(wanted)
      return topics if wanted.empty?
      wanted.each { |name| raise Error, "#{name} is not listed in #{path}" unless topics.include?(name) }
      topics & wanted
    end
  end
end
