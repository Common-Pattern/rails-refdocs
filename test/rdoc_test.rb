require "test_helper"

class RdocTest < Minitest::Test
  def test_generates_markdown_api_files_and_indexes
    in_tmpdir do |dir|
      src = File.join(dir, "src")
      write(File.join(src, "lib", "greeter.rb"), <<~RUBY)
        module Tools
          # Greets people. Uses +name+, *bold* and _emphasis_.
          class Greeter
            # The default greeting, e.g. <tt>"Hello, #{"{"}name}!"</tt>.
            GREETING = "Hello"

            # Returns a greeting for +name+.
            def greet(name)
              "\#{GREETING}, \#{name}!"
            end

            # Builds a greeter.
            def self.build
              new
            end
          end
        end
      RUBY
      stage = File.join(dir, "stage")
      FileUtils.mkdir_p(stage)
      RailsRefdocs::Rdoc.generate(src, stage, [ "lib/greeter.rb" ])
      page = File.read(File.join(stage, "api", "Tools", "Greeter.md"))
      assert_includes page, "# Tools::Greeter"
      assert_includes page, "Greets people. Uses `name`, **bold** and *emphasis*."
      assert_includes page, "### #greet"
      assert_includes page, "### .build"
      assert_includes page, "Source: `lib/greeter.rb:"
      assert_includes page, '`"Hello, {name}!"`'
      refute_includes page, "<code>"
      assert_includes File.read(File.join(stage, "CLASSES.tsv")), "Tools::Greeter\tapi/Tools/Greeter.md\tGreets people."
      methods = File.read(File.join(stage, "METHODS.tsv"))
      assert_includes methods, "Tools::Greeter#greet\tapi/Tools/Greeter.md"
      assert_includes methods, "Tools::Greeter.build\tapi/Tools/Greeter.md"
      refute File.exist?("#{src}-rdoc")
    end
  end
end
