# Copyright (C) 2014-2015  Kouhei Sutou <kou@cozmixng.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

require "rabbit-test-utils"

require "rabbit/slide"
require "rabbit/source/memory"
require "rabbit/parser/markdown"

class RabbitParserMarkdownTest < Test::Unit::TestCase
  private
  def parse(markdown)
    canvas = []
    def canvas.logger
      nil
    end
    source = Rabbit::Source::Memory.new("UTF-8", nil)
    source.source = markdown
    parser = Rabbit::Parser::Markdown.new(canvas, source)
    parser.parse
    canvas
  end

  def inspect_canvas(canvas)
    canvas.collect do |page|
      inspect_element(page)
    end
  end

  def inspect_element(element)
    name = element.class.name.split(/::/).last
    if element.respond_to?(:elements)
      children = element.elements.collect {|child| inspect_element(child)}
    else
      children = [element.text]
    end
    [name, *children]
  end

  class TitlePageTest < self
    def parse(markdown)
      inspect_canvas(super(markdown))
    end

    def test_title
      assert_equal([
                     [
                       "TitleSlide", [
                         "Title", [
                           "Text",
                           "Title",
                         ],
                       ],
                     ],
                   ],
                   parse("# Title"))
    end
  end

  class BodyTest < self
    def parse(markdown)
      full_markdown = <<-MARKDOWN
\# Title

\# Page

#{markdown}
      MARKDOWN
      inspect_element(super(full_markdown)[1].body)
    end

    class TextEscapeTest < self
      def test_html_tag
        assert_equal([
                       "Body", [
                         "Paragraph", [
                           "Code", [
                             "Text",
                             "&#60;pre&#62;",
                           ],
                         ],
                       ],
                     ],
                     parse("`<pre>`"))
      end
    end

    class WaitTest < self
      def test_in_list_item
        assert_equal([
                       "Body", [
                         "ItemList", [
                           "ItemListItem", [
                             "Paragraph",
                             ["Text", "Hello"],
                             ["WaitTag", ""],
                             ["Text", " World"],
                           ],
                         ],
                       ],
                     ],
                     parse("* Hello{::wait/} World"))
      end
    end

    class SyntaxHighlightTest < self
      def test_indent_lang
        assert_equal([
                       "Body", [
                         "SyntaxHighlightingBlock", [
                           "TextContainer",
                           [
                             "CustomTag",
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "\""],
                             ],
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "Hello World"],
                             ],
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "\""],
                             ],
                           ],
                         ],
                       ],
                     ],
                     parse(<<-MARKDOWN))
    "Hello World"
{: lang="ruby"}
                           MARKDOWN
      end

      def test_indent_language
        assert_equal([
                       "Body", [
                         "SyntaxHighlightingBlock", [
                           "TextContainer",
                           [
                             "CustomTag",
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "\""],
                             ],
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "Hello World"],
                             ],
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "\""],
                             ],
                           ],
                         ],
                       ],
                     ],
                     parse(<<-MARKDOWN))
    "Hello World"
{: language="ruby"}
                           MARKDOWN
      end

      def test_fence_kramdown
        assert_equal([
                       "Body", [
                         "SyntaxHighlightingBlock", [
                           "TextContainer",
                           [
                             "CustomTag",
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "\""],
                             ],
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "Hello World"],
                             ],
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "\""],
                             ],
                           ],
                         ],
                       ],
                     ],
                     parse(<<-MARKDOWN))
~~~ruby
"Hello World"
~~~
                           MARKDOWN
      end

      def test_fence_gfm
        assert_equal([
                       "Body", [
                         "SyntaxHighlightingBlock", [
                           "TextContainer",
                           [
                             "CustomTag",
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "\""],
                             ],
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "Hello World"],
                             ],
                           ],
                           [
                             "CustomTag", [
                               "SyntaxHighlightingText", ["Text", "\""],
                             ],
                           ],
                         ],
                       ],
                     ],
                     parse(<<-MARKDOWN))
```ruby
"Hello World"
```
                           MARKDOWN
      end
    end

    class BlockDiagTest < self
      def test_codeblock_fence
        assert_equal([
                       "Body", [
                         "Image",
                         ""
                       ],
                     ],
                     parse(<<-MARKDOWN))
```blockdiag
{
  A -> B -> C;
}
```
                           MARKDOWN
      end
    end
  end
end
