require "rubygems/package"
require "zlib"

module RailsRefdocs
  module Archive
    module_function

    def extract(path, dest, strip: 1, &select)
      FileUtils.mkdir_p(dest)
      File.open(path, "rb") do |file|
        Zlib::GzipReader.wrap(file) do |gzip|
          each_entry(Gem::Package::TarReader.new(gzip)) do |name, entry|
            relative = strip_components(name, strip)
            next if relative.nil? || (select && !select.call(relative))
            write_entry(entry, File.join(dest, relative))
          end
        end
      end
      dest
    end

    def each_entry(reader)
      long_name = nil
      reader.each do |entry|
        case entry.header.typeflag
        when "g" then next
        when "x"
          long_name = pax_path(entry.read.to_s) || long_name
          next
        when "L"
          long_name = entry.read.to_s.delete("\0")
          next
        end
        name = long_name || entry.full_name
        long_name = nil
        yield name, entry
      end
    end

    def pax_path(records)
      records.each_line do |line|
        match = line.chomp.match(/\A\d+ path=(.*)\z/)
        return match[1] if match
      end
      nil
    end

    def strip_components(name, strip)
      parts = name.split("/").reject(&:empty?).drop(strip)
      return nil if parts.empty?
      raise Error, "unsafe path in archive: #{name}" if parts.include?("..") || name.start_with?("/")
      parts.join("/")
    end

    def write_entry(entry, target)
      if entry.directory?
        FileUtils.mkdir_p(target)
      elsif entry.file?
        FileUtils.mkdir_p(File.dirname(target))
        File.open(target, "wb") { |out| IO.copy_stream(entry, out) }
      end
    end
  end
end
