module RailsRefdocs
  class Updater
    def initialize(reference, command:, out: $stdout, registry: Topics)
      @reference = reference
      @command = command
      @out = out
      @registry = registry
    end

    def update(wanted = [], force: false)
      topics_file = TopicsFile.load(@reference.topics_file)
      FileUtils.mkdir_p(@reference.dir)
      Dir.mktmpdir("rails-refdocs") do |work_dir|
        topics_file.select(wanted).each do |name|
          topic = @registry.fetch(name)
          resolution = resolve(topic, topics_file)
          recorded = @reference.manifest[name]&.version
          if !force && recorded == resolution.version && File.directory?(@reference.topic_dir(name))
            RailsRefdocs.log("#{name} #{resolution.version}: up to date")
          else
            fetch(topic, resolution.version, File.join(work_dir, name))
          end
        end
      end
      Readme.new(@reference, topics_file.topics, @command).write
      RailsRefdocs.log("done; versions recorded in #{@reference.manifest.path}, index in #{@reference.readme}")
    ensure
      FileUtils.rm_rf(@reference.staging)
    end

    def check(wanted = [])
      topics_file = TopicsFile.load(@reference.topics_file)
      behind = topics_file.select(wanted).count do |name|
        topic = @registry.fetch(name)
        resolution = resolve(topic, topics_file)
        recorded = @reference.manifest[name]&.version
        @out.puts(format("%-18s %-26s recorded=%-40s resolved=%s",
          name, "from=#{resolution.origin}", recorded || "none", resolution.version))
        recorded != resolution.version
      end
      behind.zero?
    end

    def check_locked(wanted = [])
      topics_file = TopicsFile.load(@reference.topics_file)
      behind = topics_file.select(wanted).count do |name|
        topic = @registry.fetch(name)
        next false if topics_file.pins[name]
        locked = topic.locked(@reference.lock)
        next false unless locked
        recorded = @reference.manifest[name]&.version
        current = recorded && topic.locked_part(recorded)
        next false if current == locked.version
        @out.puts("#{name}: #{locked.source} has #{locked.version}, #{@reference.manifest.path} has #{current || "nothing"}; run #{@command} update #{name}")
        true
      end
      behind.zero?
    end

    private

    def resolve(topic, topics_file)
      pin = topics_file.pins[topic.name]
      resolution = topic.resolve(pin, @reference.lock)
      raise Error, "#{topic.name}: no release matches pin '#{pin}'" unless resolution.version
      resolution
    end

    def fetch(topic, version, work_dir)
      stage = File.join(@reference.staging, topic.name)
      FileUtils.rm_rf(stage)
      FileUtils.mkdir_p([ stage, work_dir ])
      topic.fetch(version, stage, work_dir)
      target = @reference.topic_dir(topic.name)
      FileUtils.rm_rf(target)
      FileUtils.mv(stage, target)
      @reference.manifest.record(topic.name, version, topic.source)
    ensure
      FileUtils.rm_rf(work_dir)
    end
  end
end
