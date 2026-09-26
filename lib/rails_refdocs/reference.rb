module RailsRefdocs
  class Reference
    attr_reader :dir, :root

    def self.default_dir(from = Dir.pwd)
      checkout = Checkout.find(from)
      File.join(checkout ? checkout.root : File.expand_path(from), "reference")
    end

    def initialize(dir, root: nil)
      @dir = File.expand_path(dir)
      @root = root ? File.expand_path(root) : File.dirname(@dir)
    end

    def topics_file
      File.join(dir, "TOPICS")
    end

    def manifest
      @manifest ||= Manifest.new(File.join(dir, "VERSIONS"))
    end

    def lock
      @lock ||= Lock.load(root)
    end

    def staging
      File.join(dir, ".staging")
    end

    def readme
      File.join(dir, "README.md")
    end

    def topic_dir(name)
      File.join(dir, name)
    end
  end
end
