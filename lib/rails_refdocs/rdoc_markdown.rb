require "rdoc"
require "fileutils"

class RDoc::Markup::ToReferenceMarkdown < RDoc::Markup::ToMarkdown
  def add_tag(_tag, simple_tag, content)
    emit_inline("#{simple_tag}#{content}#{simple_tag}")
  end

  def handle_tag(nodes, simple_tag, tag)
    return super if nodes.size == 1 && String === nodes[0]
    emit_inline(simple_tag)
    traverse_inline_nodes(nodes)
    emit_inline(simple_tag)
  end
end

class RDoc::Generator::ReferenceMarkdown
  RDoc::RDoc.add_generator self

  def self.setup_options(options)
  end

  def initialize(store, options)
    @store = store
    @options = options
  end

  def class_dir
    nil
  end

  def file_dir
    nil
  end

  def generate
    root = File.expand_path(@options.op_dir)
    class_index = []
    method_index = []
    @store.all_classes_and_modules.sort_by(&:full_name).each do |mod|
      next unless mod.display?
      relative = "api/" + mod.full_name.split("::").join("/") + ".md"
      write_file(File.join(root, relative), render_module(mod))
      class_index << [mod.full_name, relative, summary_of(mod)]
      visible_methods(mod).each do |meth|
        method_index << ["#{mod.full_name}#{meth.singleton ? "." : "#"}#{meth.name}", relative]
      end
    end
    @store.all_files.each do |file|
      next unless file.text? && file.display?
      relative = file.relative_name.sub(%r{\A\.?/}, "")
      target = relative.end_with?(".md") ? relative : "#{relative}.md"
      write_file(File.join(root, "pages", target), to_markdown(file, file.comment) + "\n")
    end
    write_file(File.join(root, "CLASSES.tsv"), class_index.map { |row| row.join("\t") }.join("\n") + "\n")
    write_file(File.join(root, "METHODS.tsv"), method_index.sort.map { |row| row.join("\t") }.join("\n") + "\n")
  end

  private

  def write_file(path, content)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, content)
  end

  def to_markdown(code_object, comment)
    return "" if comment.nil? || (comment.respond_to?(:empty?) && comment.empty?)
    code_object.parse(comment).accept(RDoc::Markup::ToReferenceMarkdown.new).strip
  rescue StandardError
    comment.to_s.strip
  end

  def summary_of(mod)
    paragraphs = to_markdown(mod, mod.comment_location).split(/\n[ \t]*\n/)
    first = paragraphs.find { |para| !para.strip.empty? && !para.start_with?("#", "    ", "```") } || ""
    first.strip.gsub(/\s+/, " ")[0, 200]
  end

  def visible_methods(mod)
    mod.method_list
      .select { |meth| meth.display? && meth.visibility != :private }
      .sort_by { |meth| [meth.singleton ? 0 : 1, meth.name] }
  end

  def kind_line(mod)
    return "module #{mod.full_name}" if mod.module?
    parent = mod.superclass
    parent_name = parent.respond_to?(:full_name) ? parent.full_name : parent.to_s
    parent_name.empty? ? "class #{mod.full_name}" : "class #{mod.full_name} < #{parent_name}"
  end

  def render_module(mod)
    out = ["# #{mod.full_name}", "", "`#{kind_line(mod)}`", ""]
    files = mod.in_files.map(&:relative_name).uniq
    out << "Defined in: #{files.map { |f| "`#{f}`" }.join(", ")}" unless files.empty?
    includes = mod.includes.map(&:name)
    extends = mod.extends.map(&:name)
    out << "Includes: #{includes.join(", ")}" unless includes.empty?
    out << "Extends: #{extends.join(", ")}" unless extends.empty?
    out << ""
    description = to_markdown(mod, mod.comment_location)
    out << description << "" unless description.empty?
    out.concat(render_constants(mod))
    out.concat(render_attributes(mod))
    methods = visible_methods(mod)
    [[true, "Class methods"], [false, "Instance methods"]].each do |singleton, title|
      group = methods.select { |meth| meth.singleton == singleton }
      next if group.empty?
      out << "## #{title}" << ""
      group.each { |meth| out.concat(render_method(meth)) }
    end
    out.join("\n").gsub(/\n{3,}/, "\n\n") + "\n"
  end

  def render_constants(mod)
    constants = mod.constants.select(&:display?)
    return [] if constants.empty?
    out = ["## Constants", ""]
    constants.each do |const|
      out << "### #{const.name}" << ""
      value = const.value.to_s
      value = value[0, 300] + " ..." if value.length > 300
      out << "```ruby\n#{const.name} = #{value}\n```" << "" unless value.empty?
      text = to_markdown(const, const.comment)
      out << text << "" unless text.empty?
    end
    out
  end

  def render_attributes(mod)
    attributes = mod.attributes.select { |attr| attr.display? && attr.visibility != :private }
    return [] if attributes.empty?
    out = ["## Attributes", ""]
    attributes.each do |attr|
      out << "### #{attr.singleton ? "." : "#"}#{attr.name} [#{attr.rw}]" << ""
      text = to_markdown(attr, attr.comment)
      out << text << "" unless text.empty?
    end
    out
  end

  def render_method(meth)
    visibility = meth.visibility == :public ? "" : " (#{meth.visibility})"
    out = ["### #{meth.singleton ? "." : "#"}#{meth.name}#{visibility}", ""]
    signature = meth.call_seq ? meth.call_seq.strip : "#{meth.name}#{meth.params}"
    out << "```ruby\n#{signature}\n```" << ""
    if meth.is_alias_for
      target = meth.is_alias_for
      out << "Alias for `#{target.respond_to?(:full_name) ? target.full_name : target}`." << ""
    end
    text = to_markdown(meth, meth.comment)
    out << text << "" unless text.empty?
    out << "Source: `#{meth.file.relative_name}#{meth.line ? ":#{meth.line}" : ""}`" << "" if meth.file
    out
  end
end
