module RailsRefdocs
  module Rdoc
    EXCLUDES = [ '\.ja\.', "/ja/", "COPYING", "LEGAL" ].freeze
    OUTPUTS = [ "api", "pages", "CLASSES.tsv", "METHODS.tsv" ].freeze

    module_function

    def generate(src, stage, files)
      out = "#{src}-rdoc"
      FileUtils.rm_rf(out)
      run(src, arguments(out, files))
      OUTPUTS.each do |name|
        FileUtils.mv(File.join(out, name), stage) if File.exist?(File.join(out, name))
      end
      FileUtils.rm_rf(out)
    end

    def arguments(out, files)
      [ "--quiet", "--format=referencemarkdown", "--output=#{out}", "--encoding=UTF-8",
        *EXCLUDES.flat_map { |pattern| [ "-x", pattern ] }, *files ]
    end

    def run(src, args)
      pid = fork do
        status = 1
        begin
          Dir.chdir(src)
          require "rails_refdocs/rdoc_markdown"
          RDoc::RDoc.new.document(args)
          status = 0
        rescue Exception => e
          warn "rdoc: #{e.class}: #{e.message}"
        ensure
          $stdout.flush
          $stderr.flush
          exit!(status)
        end
      end
      Process.wait(pid)
      raise Error, "rdoc failed in #{src}" unless $?.success?
    end
  end
end
