package mustache

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.ArrayList

class LexerTestItem {
    LexerTestItem(let template: String, let expected: Array<Token>) {}
}

var lexerTests = ArrayList<LexerTestItem>([
    LexerTestItem("foo {{{bar}}}\nbaz {{! this is ignored }}",
        Token(TokenType.Text, "foo ", 0, 0),
        Token(TokenType.LeftDelim, "{{", 0, 0),
        Token(TokenType.RawStart, "{", 0, 0),
        Token(TokenType.Identifier, "bar", 0, 0),
        Token(TokenType.RawEnd, "}", 0, 0),
        Token(TokenType.RightDelim, "}}", 0, 0),
        Token(TokenType.Text, "\nbaz ", 0, 0),
        Token(TokenType.LeftDelim, "{{", 0, 0),
        Token(TokenType.Comment, "!", 0, 0),
        Token(TokenType.Text, " this is ignored ", 0, 0),
        Token(TokenType.RightDelim, "}}", 0, 0),
        Token(TokenType.EOF, "", 0, 0)
    ),
    LexerTestItem(
        "\nfoo {{bar}} baz {{=| |=}}\r\n |foo| |={{ }}=| {{bar}}",
        Token(TokenType.Text, "\nfoo ", 0, 0),
        Token(TokenType.LeftDelim, "{{", 0, 0),
        Token(TokenType.Identifier, "bar", 0, 0),
        Token(TokenType.RightDelim, "}}", 0, 0),
        Token(TokenType.Text, " baz ", 0, 0),
        Token(TokenType.SetDelim, "", 0, 0),
        Token(TokenType.Text,  "\r\n ", 0, 0),
        Token(TokenType.LeftDelim, "|", 0, 0),
        Token(TokenType.Identifier,  "foo", 0, 0),
        Token(TokenType.RightDelim, "|", 0, 0),
        Token(TokenType.Text,  " ", 0, 0),
        Token(TokenType.SetDelim, "", 0, 0),
        Token(TokenType.Text,  " ", 0, 0),
        Token(TokenType.LeftDelim, "{{", 0, 0),
        Token(TokenType.Identifier, "bar", 0, 0),
        Token(TokenType.RightDelim, "}}", 0, 0),
        Token(TokenType.EOF, "", 0, 0)
    )
])

@Test
class LexerTest {
    @TestCase
    func test() {
        for (test in lexerTests) {
            var lexer = Lexer(test.template, "{{", "}}")
            var i = 0
            while (true) {
                var token = lexer.token()
                println(token)
                if (i >= test.expected.size) {
                    @Fail("${i}/token stream exceeded the length of expected tokens.")
                }
                let excepted = test.expected[i]
                if (token.typ != excepted.typ) {
                    @Fail("${i}/unexpected token ${token.typ}, expected ${excepted.typ}")
                }
                if (token.val != excepted.val) {
                    @Fail("${i}/unexpected token ${token.typ}, expected ${excepted.typ}")
                }
                if (token.typ == TokenType.EOF) {
                    break
                }
                i++
            }
        }
    }
}
