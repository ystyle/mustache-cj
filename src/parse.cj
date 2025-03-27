package mustache

import std.collection.ArrayList

public class ParserException <: Exception {
    init(t: Token, message: String) {
        super("${t.line}:${t.col} syntax error: ${message}")
    }
    init(message: String) {
        super(message)
    }
}

class Parser {
    var lexer: ?Lexer = None
    var buf = ArrayList<Token>()
    let ast = ArrayList<Node>()
    init(lex: Lexer) {
        this.lexer = lex
    }
    init(b: ArrayList<Token>) {
        this.buf.add(all:b)
        this.buf.add(Token(TokenType.EOF, "", 0, 0))
    }
    func read(): Token {
        if (this.buf.size > 0) {
            let r = this.buf[0]
            this.buf = this.buf[1..]
            return r
        }
        let t = this.lexer?.token()
        return t.getOrThrow()
    }

    func readn(n: Int64): ArrayList<Token> {
        let tokens = ArrayList<Token>(n)
        while (true) {
            let token = this.read()
            tokens.add(token)
            if (token.typ == TokenType.EOF) {
                break
            }
            if (tokens.size == n) {
                break
            }
        }
        return tokens
    }

    func readt(t: TokenType): ArrayList<Token> {
        let tokens = ArrayList<Token>()
        while (true) {
            let token = this.read()
            tokens.add(token)
            if (token.typ == TokenType.EOF) {
                throw ParserException("token ${t} not found")
            }
            if (token.typ == t) {
                break
            }
        }
        return tokens
    }

    func readv(t: Token): ArrayList<Token> {
        let tokens = ArrayList<Token>()
        while (true) {
            let read = this.readt(t.typ)
            tokens.add(all:read)
            if (read.size > 0 && read[read.size - 1].val == t.val) {
                break
            }
        }
        return tokens
    }

    func peek(): Token {
        if (this.buf.size > 0) {
            return this.buf[0]
        }
        let t = this.lexer?.token()
        let tt = t.getOrThrow()
        this.buf.add(tt)
        return tt
    }

    func peekn(n: Int64): ArrayList<Token> {
        if (this.buf.size > n) {
            return this.buf[..n]
        }
        var i = this.buf.size
        while (i < n) {
            let t = this.lexer?.token()
            let tt = t.getOrThrow()
            this.buf.add(tt)
            if (tt.typ == TokenType.EOF) {
                return this.buf
            }
        }
        return this.buf
    }

    func parse(): ArrayList<Node> {
        var nodes = ArrayList<Node>()
        while (true) {
            let token = this.read()
            match (token.typ) {
                case TokenType.EOF => break
                case TokenType.Error => throw ParserException(token, token.val)
                case TokenType.Text => nodes.add(TextNode(token.val))
                case TokenType.LeftDelim =>
                    let node = this.parseTag()
                    nodes.add(node)
                case TokenType.RawStart =>
                    let node = this.parseRawTag()
                    nodes.add(node)
                case TokenType.SetDelim => nodes.add(DelimNode())
                case _ => ()
            }
        }
        return nodes
    }
    func parseTag(): Node {
        let token = this.read()
        match (token.typ) {
            case TokenType.Identifier => return this.parseVar(token, true)
            case TokenType.RawStart => return this.parseRawTag()
            case TokenType.RawAlt => return this.parseVar(this.read(), false)
            case TokenType.Comment => return this.parseComment()
            case TokenType.SectionInverse => return this.parseSection(true)
            case TokenType.SectionStart => return this.parseSection(false)
            case TokenType.Partial => return this.parsePartial()
            case _ => throw ParserException(token, "unreachable code ${token}")
        }
    }
    func parseRawTag(): Node {
        let t = this.read()
        let e = ParserException(t, "unexpected token ${t}")
        if (t.typ != TokenType.Identifier) {
            throw e
        }
        var next = this.read()
        if (next.typ != TokenType.RawEnd) {
            throw e
        }
        next = this.read()
        if (next.typ != TokenType.RightDelim) {
            throw e
        }
        return VarNode(t.val, false)
    }
    func parseVar(ident: Token, escape: Bool): Node {
        let t = this.read()
        if (t.typ != TokenType.RightDelim) {
            throw ParserException(t, "unexpected token ${t}")
        }
        return VarNode(ident.val, escape)
    }
    func parseComment(): Node {
        var comment: String = ""
        var node: Node = TextNode("text: String")
        while (true) {
            let t = this.read()
            match (t.typ) {
                case TokenType.EOF => throw ParserException(t, "unexpected token ${t}")
                case TokenType.Error => throw ParserException(t, t.val)
                case TokenType.RightDelim => return CommentNode(comment)
                case _ => comment += t.val
            }
        }
        return node
    }
    func parseSection(inverse: Bool): Node {
        let t = this.read()
        if (t.typ != TokenType.Identifier) {
            throw ParserException(t, "unexpected token ${t}")
        }
        let next = this.read()
        if (next.typ != TokenType.RightDelim) {
            throw ParserException(t, "unexpected token ${t}")
        }
        var tokens = ArrayList<Token>()
        var stack = 1
        while (true) {
            let read = this.readv(t)
            tokens.add(all:read)
            if (read.size > 1) {
                let tt = read[read.size - 2]
                match (tt.typ) {
                    case TokenType.SectionStart | TokenType.SectionInverse => stack++
                    case TokenType.SectionEnd => stack--
                    case _ => ()
                }
            }
            if (stack == 0) {
                break
            }
        }
        let nodes = Parser(tokens[..tokens.size - 3]).parse()
        return SectionNode(t.val, inverse, nodes)
    }
    func parsePartial(): Node {
        let t = this.read()
        if (t.typ != TokenType.Identifier) {
            throw ParserException(t, "unexpected token ${t}")
        }
        let next = this.read()
        if (next.typ != TokenType.RightDelim) {
            throw ParserException(t, "unexpected token ${t}")
        }
        return PartialNode(t.val)
    }
}
