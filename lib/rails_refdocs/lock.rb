module RailsRefdocs
  class Lock
    SPEC = /\A {4}([^ ]+) \(([^)]+)\)\z/

    Locked = Struct.new(:version, :source)

    def self.load(root)
      lockfile = File.join(root, "Gemfile.lock")
      ruby_version_file = File.join(root, ".ruby-version")
      new(
        gems: File.file?(lockfile) ? parse_gems(File.read(lockfile)) : {},
        lockfile_ruby: File.file?(lockfile) ? parse_ruby(File.read(lockfile)) : nil,
        ruby_version_file: File.file?(ruby_version_file) ? File.read(ruby_version_file) : nil
      )
    end

    def self.parse_gems(content)
      gems = {}
      in_specs = false
      content.each_line(chomp: true) do |line|
        if line == "  specs:"
          in_specs = true
        elsif !line.start_with?(" ")
          in_specs = false
        elsif in_specs && (match = line.match(SPEC))
          gems[match[1]] ||= match[2].split("-").first
        end
      end
      gems
    end

    def self.parse_ruby(content)
      section = content[/^RUBY VERSION\n(.*?)(?:\n\n|\z)/m, 1]
      section && section[/ruby (\d+\.\d+\.\d+)/, 1]
    end

    def initialize(gems: {}, lockfile_ruby: nil, ruby_version_file: nil)
      @gems = gems
      @lockfile_ruby = lockfile_ruby
      @ruby_version_file = ruby_version_file
    end

    def gem(name)
      version = @gems[name]
      version && Locked.new(version, "Gemfile.lock")
    end

    def ruby
      from_file = @ruby_version_file.to_s.strip.sub(/\Aruby-/, "")[/\A\d+\.\d+\.\d+/]
      return Locked.new(from_file, ".ruby-version") if from_file
      Locked.new(@lockfile_ruby, "Gemfile.lock") if @lockfile_ruby
    end
  end
end
