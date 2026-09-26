require "nokogiri"

module RailsRefdocs
  class HtmlMarkdown
    Para = Struct.new(:inlines)
    Plain = Struct.new(:inlines)
    Header = Struct.new(:level, :inlines)
    CodeBlock = Struct.new(:text)
    BulletList = Struct.new(:items)
    OrderedList = Struct.new(:start, :items)
    DefinitionList = Struct.new(:items)
    BlockQuote = Struct.new(:blocks)
    HorizontalRule = Struct.new(:none)
    Div = Struct.new(:blocks)

    Str = Struct.new(:text)
    Space = Struct.new(:none)
    Code = Struct.new(:text)
    Emph = Struct.new(:inlines)
    Strong = Struct.new(:inlines)
    Link = Struct.new(:inlines, :target)
    Image = Struct.new(:inlines, :source)
    Superscript = Struct.new(:inlines)
    Subscript = Struct.new(:inlines)
    Span = Struct.new(:inlines)
    Break = Struct.new(:none)

    SPACE = Space.new.freeze
    BREAK = Break.new.freeze
    BLOCK_TAGS = %w[
      address article aside blockquote body center dd div dl dt fieldset figure footer form
      h1 h2 h3 h4 h5 h6 header hr li main nav ol p pre section table tbody td tfoot th thead tr ul
    ].freeze
    SKIPPED_TAGS = %w[head script style title meta link colgroup col].freeze
    DROPPED_CLASSES = %w[navheader navfooter].freeze
    ESCAPED = /[`*\[\]<>|$]|\\(?=[[:punct:]]|\z)|(?<![[:alnum:]])_|_(?![[:alnum:]])|\A#/
    SUPERSCRIPTS = "0123456789+-=()in".chars.zip("⁰¹²³⁴⁵⁶⁷⁸⁹⁺⁻⁼⁽⁾ⁱⁿ".chars).to_h.freeze
    SUBSCRIPTS = "0123456789+-=()".chars.zip("₀₁₂₃₄₅₆₇₈₉₊₋₌₍₎".chars).to_h.freeze

    def self.convert(html)
      new.convert(html)
    end

    def convert(html)
      document = Nokogiri::HTML4(html)
      body = document.at("body") || document.root
      text = render_blocks(read_blocks(body))
      text.delete("\u200B").gsub(/[ \t]+$/, "").sub(/\A\n+/, "").sub(/\n*\z/, "\n")
    end

    private

    def read_blocks(node)
      blocks = []
      pending = []
      flush = lambda do
        inlines = trim(pending.flat_map { |child| read_inline(child) })
        blocks << Plain.new(inlines) unless inlines.empty?
        pending.clear
      end
      node.children.each do |child|
        if child.element? && BLOCK_TAGS.include?(child.name)
          flush.call
          blocks.concat(read_block(child))
        elsif child.element? && SKIPPED_TAGS.include?(child.name)
          next
        else
          pending << child
        end
      end
      flush.call
      blocks
    end

    def read_block(node)
      case node.name
      when "p" then [ Para.new(trim(read_inlines(node))) ]
      when /\Ah([1-6])\z/
        inlines = trim(read_inlines(node))
        inlines.empty? ? [] : [ Header.new($1.to_i, inlines) ]
      when "pre" then [ CodeBlock.new(node.text.sub(/\A(?:[ \t]*\r?\n)+/, "").sub(/\s+\z/, "")) ]
      when "ul" then [ BulletList.new(list_items(node)) ]
      when "ol" then [ OrderedList.new((node["start"] || 1).to_i, list_items(node)) ]
      when "dl" then definition_list(node)
      when "table" then [ BulletList.new(table_rows(node)) ]
      when "blockquote" then [ BlockQuote.new(read_blocks(node)) ]
      when "hr" then [ HorizontalRule.new ]
      else
        dropped?(node) ? [] : [ Div.new(read_blocks(node)) ]
      end
    end

    def fix_plains(blocks, in_list)
      return blocks unless blocks.any? { |block| paraish?(block, in_list) }
      blocks.map { |block| block.is_a?(Plain) ? Para.new(block.inlines) : block }
    end

    def paraish?(block, in_list)
      case block
      when Para, CodeBlock, Header, BlockQuote, HorizontalRule then true
      when BulletList, OrderedList, DefinitionList then !in_list
      else false
      end
    end

    def dropped?(node)
      (node["class"].to_s.split & DROPPED_CLASSES).any?
    end

    def list_items(node)
      node.element_children.select { |child| child.name == "li" }.map { |item| fix_plains(read_blocks(item), true) }
    end

    def definition_list(node)
      return definition_fallback(node) unless definition_structure?(node) && node.css("dl").all? { |dl| definition_structure?(dl) }
      items = []
      node.element_children.each do |child|
        case child.name
        when "dt"
          term = trim(read_inlines(child))
          if items.empty? || !items.last[1].empty?
            items << [ term, [] ]
          else
            items.last[0] = items.last[0] + [ BREAK ] + term
          end
        when "dd" then items.last[1] << fix_plains(read_blocks(child), true)
        end
      end
      [ DefinitionList.new(items) ]
    end

    def definition_structure?(node)
      node.element_children.map(&:name).grep(/\Ad[td]\z/).join(" ").match?(/\A(?:(?:dt )+dd(?: dd)*(?: |\z))+\z/)
    end

    def definition_fallback(node)
      node.element_children.flat_map do |child|
        next [] unless %w[dt dd].include?(child.name)
        next read_blocks(child) if child.name == "dd"
        inlines = trim(read_inlines(child))
        inlines.empty? ? [] : [ Para.new(inlines) ]
      end
    end

    def table_rows(table)
      sections = table.element_children
      rows = sections.select { |child| child.name == "thead" }.flat_map { |head| head.css("> tr").to_a }
      sections.each do |section|
        case section.name
        when "tbody" then rows.concat(section.css("> tr").to_a)
        when "tr" then rows << section
        end
      end
      rows.map do |row|
        row.element_children.select { |cell| %w[td th].include?(cell.name) }.flat_map { |cell| read_blocks(cell) }
      end
    end

    def read_inlines(node)
      normalize(node.children.flat_map { |child| read_inline(child) })
    end

    def read_inline(node)
      return text_inlines(node.text) if node.text? || node.cdata?
      return [] unless node.element?
      return [] if SKIPPED_TAGS.include?(node.name) || dropped?(node)
      case node.name
      when "br" then [ BREAK ]
      when "code", "tt", "kbd", "samp" then code(node)
      when "em", "i", "cite", "var", "dfn" then wrap(Emph, read_inlines(node))
      when "strong", "b" then wrap(Strong, read_inlines(node))
      when "sup" then wrap(Superscript, read_inlines(node))
      when "sub" then wrap(Subscript, read_inlines(node))
      when "a" then link(node, read_inlines(node))
      when "span" then [ Span.new(read_inlines(node)) ]
      when "img" then [ Image.new(text_inlines(node["alt"].to_s), node["src"].to_s) ]
      else read_inlines(node)
      end
    end

    def code(node)
      node.children.flat_map do |child|
        if child.text?
          text = child.text.gsub(/[ \t\r\n]+/, " ")
          text.empty? ? [] : [ Code.new(text) ]
        elsif !child.element? || SKIPPED_TAGS.include?(child.name)
          []
        else
          case child.name
          when "em", "i", "cite", "var", "dfn" then wrap(Emph, code(child))
          when "strong", "b" then wrap(Strong, code(child))
          when "sup" then wrap(Superscript, code(child))
          when "sub" then wrap(Subscript, code(child))
          when "a" then link(child, code(child))
          when "br" then [ Code.new(" ") ]
          else code(child)
          end
        end
      end
    end

    def text_inlines(text)
      text.split(/([ \t\r\n]+)/).reject(&:empty?).map { |part| part.match?(/\A[ \t\r\n]+\z/) ? SPACE : Str.new(part) }
    end

    def wrap(type, inlines)
      leading = inlines.first.is_a?(Space) ? [ SPACE ] : []
      trailing = inlines.last.is_a?(Space) && inlines.size > 1 ? [ SPACE ] : []
      inner = trim(inlines)
      return leading if inner.empty?
      leading + [ type.new(inner) ] + trailing
    end

    def link(node, inlines)
      href = node["href"]
      return [ Span.new(inlines) ] if href.nil?
      return [] if plain_text(inlines) == "#"
      href = href.sub(".html", ".md") unless href.match?(/\A[A-Za-z]+:/)
      leading = inlines.first.is_a?(Space) ? [ SPACE ] : []
      trailing = inlines.last.is_a?(Space) && inlines.size > 1 ? [ SPACE ] : []
      leading + [ Link.new(trim(inlines), href) ] + trailing
    end

    def normalize(inlines)
      inlines.each_with_object([]) do |inline, result|
        next if inline.is_a?(Space) && blank?(result.last)
        result.pop if inline.is_a?(Break) && result.last.is_a?(Space)
        result << inline
      end
    end

    def trim(inlines)
      result = normalize(inlines).drop_while { |inline| blank?(inline) }
      result.pop while blank?(result.last)
      result
    end

    def blank?(inline)
      inline.is_a?(Space) || inline.is_a?(Break)
    end

    def plain_text(inlines)
      inlines.map do |inline|
        case inline
        when Str, Code then inline.text
        when Space, Break then " "
        when Emph, Strong, Link, Superscript, Subscript, Image, Span then plain_text(inline.inlines)
        else ""
        end
      end.join
    end

    def render_blocks(blocks, in_list: false, after_marker: false)
      out = +""
      previous = nil
      adjacent = nil
      blank = false
      unwrap(blocks).each do |block|
        block = Para.new(block.inlines) if block.is_a?(Plain) && !in_list
        text = render_block(block, in_list, after_marker && previous.nil?)
        separate_lists = list?(adjacent) && (adjacent.class == block.class || block.is_a?(CodeBlock))
        adjacent = block
        if text.empty?
          blank ||= block.is_a?(Para)
          next
        end
        if previous
          out << (blank ? "\n\n" : separator(previous, block))
        elsif blank
          out << "\n"
        end
        blank = false
        out << "&nbsp;\n\n" if separate_lists
        out << text
        previous = block
      end
      out
    end

    def unwrap(blocks)
      blocks.flat_map { |block| block.is_a?(Div) ? unwrap(block.blocks) : [ block ] }
    end

    def separator(previous, block)
      previous.is_a?(Plain) && !blank_before?(block) ? "\n" : "\n\n"
    end

    def list?(block)
      block.is_a?(BulletList) || block.is_a?(OrderedList) || block.is_a?(DefinitionList)
    end

    def blank_before?(block)
      !block.is_a?(Plain) && !block.is_a?(Para) && !list?(block)
    end

    def render_block(block, in_list, after_marker)
      case block
      when Plain, Para
        text = escape_block_start(render_inlines(block.inlines))
        after_marker ? text : text.delete_prefix(" ")
      when Header then "#{"#" * block.level} #{render_inlines(block.inlines)}"
      when CodeBlock then block.text.lines.map { |line| line.strip.empty? ? "\n" : "    #{line}" }.join.chomp
      when BulletList then render_list(block.items) { "- " }
      when OrderedList then render_list(block.items) { |index| "#{block.start + index}.".ljust(3) + " " }
      when DefinitionList then render_definitions(block.items, in_list)
      when BlockQuote then render_blocks(block.blocks, in_list: in_list).lines.map { |line| line.strip.empty? ? ">\n" : "> #{line}" }.join.chomp
      when HorizontalRule then "-" * 72
      end
    end

    def render_list(items)
      tight = items.all? { |blocks| unwrap(blocks).empty? || unwrap(blocks).first.is_a?(Plain) }
      rendered = items.each_with_index.map do |blocks, index|
        marker = yield(index)
        body = render_blocks(blocks, in_list: true, after_marker: true)
        indent = " " * marker.length
        lines = body.lines.map { |line| line.strip.empty? ? line : indent + line }
        next "#{marker.rstrip}\n#{lines.join}".rstrip if body.start_with?("\n")
        (marker + lines.join.delete_prefix(indent)).rstrip
      end
      rendered.join(tight ? "\n" : "\n\n")
    end

    def render_definitions(items, in_list)
      items.map do |term, definitions|
        text = nowrap { render_inlines(term) }
        rendered = definitions.map { |blocks| render_blocks(blocks, in_list: in_list) }.reject(&:empty?)
        rendered.empty? ? text : "#{text}\n#{rendered.join("\n\n")}"
      end.join("\n\n")
    end

    def nowrap
      @nowrap = true
      yield
    ensure
      @nowrap = false
    end

    def render_inlines(inlines)
      flatten(inlines).map { |inline| render_inline(inline) }.join
    end

    def flatten(inlines)
      inlines.each_with_object([]) do |inline, result|
        children = inline.is_a?(Span) ? flatten(inline.inlines) : [ inline.is_a?(Break) ? SPACE : inline ]
        children.each do |child|
          result << child unless child.is_a?(Space) && result.last.is_a?(Space) && !@nowrap
        end
      end
    end

    def render_inline(inline)
      case inline
      when Str then escape(inline.text)
      when Space then " "
      when Code then code_span(inline.text)
      when Emph then "*#{render_inlines(inline.inlines)}*"
      when Strong then "**#{render_inlines(inline.inlines)}**"
      when Link then render_link(inline)
      when Image then "![#{render_inlines(inline.inlines)}](#{inline.source})"
      when Superscript then script(inline.inlines, SUPERSCRIPTS, "^")
      when Subscript then script(inline.inlines, SUBSCRIPTS, "_")
      end
    end

    def render_link(link)
      "[#{render_inlines(link.inlines)}](#{link.target})"
    end

    def script(inlines, table, marker)
      text = plain_text(inlines)
      return text.chars.map { |char| table[char] }.join if !text.empty? && text.chars.all? { |char| table.key?(char) }
      "#{marker}(#{render_inlines(inlines)})"
    end

    def code_span(text)
      longest = text.scan(/`+/).map(&:length).max || 0
      fence = "`" * (longest + 1)
      padded = text.start_with?("`") || text.end_with?("`") ? " #{text} " : text
      "#{fence}#{padded}#{fence}"
    end

    def escape_block_start(text)
      text.sub(/\A([-+])(?= |\z)/, "\\\\\\1").sub(/\A(\d+)([.)])(?= |\z)/, "\\1\\\\\\2")
    end

    def escape(text)
      text.gsub(ESCAPED) { |char| "\\#{char}" }
    end
  end
end
