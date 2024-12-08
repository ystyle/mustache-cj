package mustache

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.ArrayList

class ParserTestItem {
    ParserTestItem(let template: String, let expected: Array<Node>) {}
}

var parserTests = ArrayList<ParserTestItem>(
    ParserTestItem(
        "{{#foo}}\n\t{{#foo}}hello nested{{/foo}}{{/foo}}",
        SectionNode(
            "foo",
            false,
            ArrayList<Node>(
                TextNode("\n\t"),
                SectionNode("foo", false, ArrayList<Node>(TextNode("hello nested")))
            )
        ),
    ),
    ParserTestItem(
        "\nfoo {{bar}} {{#alex}}\r\n\tbaz\n{{/alex}} {{!foo}}",
        TextNode("\nfoo "),
        VarNode("bar", true),
        TextNode(" "),
        SectionNode("alex", false, ArrayList<Node>(TextNode("\r\n\tbaz\n"),)),
        TextNode(" "),
        CommentNode("foo")
    ),
    ParserTestItem(
        "this will{{^foo}}not{{/foo}} be rendered",
        TextNode("this will"),
        SectionNode("foo", true, ArrayList<Node>(TextNode("not"))),
        TextNode(" be rendered"),
    ),
    ParserTestItem(
        "{{#list}}({{.}}){{/list}}",
        SectionNode("list", false, ArrayList<Node>(
            TextNode("("),
            VarNode(".", true),
            TextNode(")"),
        )),
    )
)

@Test
class ParserTest {
    @TestCase
    func test() {
        for (test in parserTests) {
            println("Template: ${test.template}")
            let parser = Parser(Lexer(test.template, "{{", "}}"))
            let elems = parser.parse()
            var i = 0
            for (elem in elems) {
                let pelem = test.expected[i]
                println("expected: ${elem}")
                println("got: ${pelem}")
                if (elem.toString() != pelem.toString()) {
                    @Fail("elements are not equal ${elem} != ${pelem}")
                }
                i++
            }
        }
    }
}
