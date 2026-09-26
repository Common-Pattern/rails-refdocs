module RailsRefdocs
  module Github
    module_function

    def extract(repo, ref, dest, work_dir, &select)
      tarball = File.join(work_dir, "#{repo.tr("/", "-")}-#{ref.tr("/", "-")}.tar.gz")
      Http.download("https://codeload.github.com/#{repo}/tar.gz/#{ref}", tarball)
      Archive.extract(tarball, dest, &select)
    ensure
      FileUtils.rm_f(tarball) if tarball
    end

    def raw_file(repo, ref, path, dest)
      Http.download("https://raw.githubusercontent.com/#{repo}/#{ref}/#{path}", dest)
    end

    def head_sha(repo)
      refs = Http.get("https://github.com/#{repo}.git/info/refs?service=git-upload-pack")
      refs[/([0-9a-f]{40}) HEAD(?:\0|\n)/, 1] or raise Error, "#{repo}: no HEAD in the advertised refs"
    end
  end
end
