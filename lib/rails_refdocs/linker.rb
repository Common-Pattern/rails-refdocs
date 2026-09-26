module RailsRefdocs
  class Linker
    def initialize(reference, command:, err: $stderr)
      @reference = reference
      @command = command
      @err = err
    end

    def link
      checkout = Checkout.find(@reference.dir) or raise Error, "#{@reference.dir} is not inside a git checkout"
      main = checkout.main_root
      return [] if main == checkout.root
      relative = @reference.dir.delete_prefix("#{checkout.root}/")
      source = File.join(main, relative)
      topics = Dir.glob("*/", base: source).map { |dir| dir.chomp("/") }.reject { |dir| dir.start_with?(".") }
      if topics.empty?
        @err.puts("rails-refdocs link: #{source} has no topics; run #{@command} update there")
        return []
      end
      FileUtils.mkdir_p(@reference.dir)
      topics.filter_map do |name|
        target = @reference.topic_dir(name)
        next if File.exist?(target) && !File.symlink?(target)
        FileUtils.rm_f(target)
        File.symlink(File.join(source, name), target)
        name
      end
    end
  end
end
