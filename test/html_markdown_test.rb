require "test_helper"

class HtmlMarkdownTest < Minitest::Test
  Dir.glob(File.join(FIXTURES, "html_markdown", "*.html")).sort.each do |html|
    name = File.basename(html, ".html")
    define_method("test_#{name.tr("-", "_")}_matches_pandoc") do
      expected = File.read(html.sub(/\.html\z/, ".md"))
      assert_equal expected, RailsRefdocs::HtmlMarkdown.convert(File.read(html, encoding: "UTF-8"))
    end
  end

  def convert(body)
    RailsRefdocs::HtmlMarkdown.convert("<html><body>#{body}</body></html>")
  end

  def test_escapes_markdown_punctuation
    assert_equal "a\\*b \\[c\\] \\<d\\> \\| \\$e \\_f g_h i\\_ \\#1 a\\\\\\* c:\\temp\n",
      convert("<p>a*b [c] &lt;d&gt; | $e _f g_h i_ #1 a\\* c:\\temp</p>")
    assert_equal "\\- dash\n\n1\\. one\n", convert("<p>- dash</p><p>1. one</p>")
  end

  def test_links_point_at_markdown_pages_and_drop_anchor_marks
    assert_equal "See [Section 1](intro.md#X). [site](https://example.com/a.html)\n",
      convert('<p>See <a href="intro.html#X" title="t">Section 1</a>. <a href="#X">#</a><a href="https://example.com/a.html">site</a></p>')
  end

  def test_tables_become_lists_of_rows
    html = "<table><thead><tr><th>Name</th><th>Size</th></tr></thead><tbody><tr><td><code>int</code></td><td>4 bytes</td></tr></tbody></table>"
    assert_equal "- Name\n  Size\n- `int`\n  4 bytes\n", convert(html)
  end

  def test_navigation_is_dropped
    assert_equal "Body\n", convert('<div class="navheader"><table><tr><td>Prev</td></tr></table><hr/></div><p>Body</p><div class="navfooter"><hr/>Next</div>')
  end

  def test_superscripts_use_unicode_when_they_can
    assert_equal "10⁻⁶ and x^(a)\n", convert("<p>10<sup>-6</sup> and x<sup>a</sup></p>")
  end
end
