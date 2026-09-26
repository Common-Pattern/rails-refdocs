require "test_helper"

class ArchiveTest < Minitest::Test
  def tarball(dir, entries)
    path = File.join(dir, "archive.tar.gz")
    File.open(path, "wb") do |file|
      Zlib::GzipWriter.wrap(file) do |gzip|
        Gem::Package::TarWriter.new(gzip) do |tar|
          entries.each do |name, content|
            if content
              tar.add_file_simple(name, 0o644, content.bytesize) { |io| io.write(content) }
            else
              tar.mkdir(name, 0o755)
            end
          end
        end
      end
    end
    path
  end

  def test_strips_the_top_folder_and_selects_paths
    in_tmpdir do |dir|
      long = "project-1.0/#{"deep/" * 25}file.md"
      path = tarball(dir, [ [ "project-1.0", nil ], [ "project-1.0/README.md", "readme" ],
        [ "project-1.0/docs/guide.md", "guide" ], [ "project-1.0/lib/code.rb", "code" ], [ long, "long" ] ])
      out = File.join(dir, "out")
      RailsRefdocs::Archive.extract(path, out) { |relative| !relative.start_with?("lib/") }
      assert_equal "readme", File.read(File.join(out, "README.md"))
      assert_equal "guide", File.read(File.join(out, "docs/guide.md"))
      assert_equal "long", File.read(File.join(out, long.delete_prefix("project-1.0/")))
      refute File.exist?(File.join(out, "lib/code.rb"))
    end
  end

  def test_pax_path_records
    assert_equal "a/very/long/name.md", RailsRefdocs::Archive.pax_path("30 mtime=1\n27 path=a/very/long/name.md\n")
    assert_nil RailsRefdocs::Archive.pax_path("20 comment=abc\n")
  end

  def test_refuses_paths_that_leave_the_destination
    in_tmpdir do |dir|
      path = tarball(dir, [ [ "top/../../escape.txt", "x" ] ])
      assert_raises(RailsRefdocs::Error) { RailsRefdocs::Archive.extract(path, File.join(dir, "out")) }
    end
  end
end
