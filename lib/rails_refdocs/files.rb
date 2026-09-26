module RailsRefdocs
  module Files
    module_function

    def copy(src, dest, *patterns)
      FileUtils.mkdir_p(dest)
      Dir.glob(patterns.map { |pattern| "**/#{pattern}" }, File::FNM_DOTMATCH, base: src).each do |relative|
        from = File.join(src, relative)
        next unless File.file?(from)
        to = File.join(dest, relative)
        FileUtils.mkdir_p(File.dirname(to))
        FileUtils.cp(from, to)
      end
    end

    def copy_if_exists(from, to)
      return unless File.file?(from)
      FileUtils.mkdir_p(File.dirname(to))
      FileUtils.cp(from, to)
    end
  end
end
