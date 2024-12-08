package mustache
import std.io.{StringWriter, ByteBuffer}
import std.collection.LinkedList
import std.deriving.*

interface State {
    func state(lex:Lexer): ?State
}

type StateFn = (State) -> State

@Derive[Equatable, ToString]
enum TokenType {
    Error 
    | EOF 
    | Identifier // alphanumeric identifier
    | LeftDelim  // {{ left action delimiter
    | RightDelim // }} right action delimiter
    | Text // plain text
    | Comment        // {{! this is a comment and is ignored}}
    | SectionStart   // {{#foo}} denotes a section start
    | SectionInverse // {{^foo}} denotes an inverse section start
    | SectionEnd     // {{/foo}} denotes the closing of a section
    | RawStart       // { denotes the beginning of an unencoded identifier
    | RawEnd         // } denotes the end of an unencoded identifier
    | RawAlt         // {{&foo}} is an alternative way to define raw tags
    | Partial        // {{>foo}} denotes a partial
    | SetDelim       // {{={% %}=}} sets delimiters to {% and %}
    | SetLeftDelim   // denotes a custom left delimiter
    | SetRightDelim  // denotes a custom right delimiter
}

class Token <: ToString {
    Token(let typ: TokenType, let val: String, let line: Int64, let col: Int64) {}
    public func toString(): String {
        return "${typ}:${val}"
    }
}

class Lexer  <: ToString {
    let input: String
    let runes: Array<Rune>
    var leftDelim: String
    var rightDelim: String
    var state: ?State = None
    var pos: Int64 = 0
    var start: Int64 = 0
    // var width: Int64 = 0
    let tokens = LinkedList<Token>()
    init(input: String, leftDelim: String, rightDelim: String) {
        super()
        this.input = input
        this.runes = input.toRuneArray()
        this.leftDelim = leftDelim
        this.rightDelim = rightDelim
        this.state = StateText()
    }
    func next(): ?Rune {
        if (this.pos >= this.runes.size) {
            return None
        }
        let r = this.runes[this.pos]
        this.pos += 1
        return r
    }
    func seek(n: Int64) {
        this.pos += n
    }
    func peek(): ?Rune {
        let r = this.next()
        this.backup()
        return r
    }
    func backup():Unit {
        this.pos -= 1
    }
    func emit(t: TokenType):Unit {
       this.tokens.append(Token(t, String(this.runes[this.start..this.pos]), this.lineNum(), this.columnNum()))
       this.start = this.pos
    }
    func ignore():Unit {
       this.start = this.pos    
    }
    func lineNum(): Int64 {
        return 1 + String(this.runes[..this.pos]).count("\n")
    }
    func columnNum(): Int64 {
        let lf = String(this.runes[..this.pos]).lastIndexOf("\n")
        if (let Some(l) <- lf) {
            return this.runes[l+1..this.pos].size
        }
        return this.runes[..this.pos].size
    }
    func errorf(format:String): ?State {
        this.tokens.append(Token(TokenType.Error, format, this.lineNum(), this.columnNum()))
        return None
    }
    func token(): Token {
        var t:?Token = None
        while (true) {
            if (let Some(v) <- this.tokens.popFirst()) {
                t = v
                break
            }
            this.state = this.state?.state(this) ?? None
        }
        return t.getOrThrow()
    }
    func setLeftDelim(s:String):Unit {
        this.leftDelim = s
    }
     func setRightDelim(s:String):Unit {
        this.rightDelim = s
    }
    public func toString(): String {
        let sb = StringBuilder()
        sb.append("Template: ")
        sb.append(this.input)
        sb.append("\nIndex: ")
        sb.append(this.pos)
        sb.append("\nCurrent: ")
        sb.append(this.runes[this.pos])
        sb.append("\nBuffer: ")
        sb.append(String(this.runes[this.start..this.pos]))
        sb.append("\n")
        return sb.toString()
    }
}

struct StateText <: State {
    init() {}
    public func state(lex: Lexer): ?State {
        while (true) {
            let str = String(lex.runes[lex.pos..])
            if (str.startsWith(lex.leftDelim)) {
               if (lex.pos > lex.start) {
                  lex.emit(TokenType.Text)
               }
               return StateLeftDelim()
            }
            if (let None <- lex.next()) {
                break
            }
        }
        if (lex.pos > lex.start) {
            lex.emit(TokenType.Text)
        }
        lex.emit(TokenType.EOF)
        return None
    }
}

struct StateLeftDelim <: State  {
    init() {}
    public func state(lex: Lexer): ?State {
        lex.seek(lex.leftDelim.size)
        if (lex.peek() == r'=') {
            lex.next()
            return StateSetDelim()
        }
        lex.emit(TokenType.LeftDelim)
        return StateTag()
    }
}

struct StateRightDelim <: State  {
    init() {}
    public func state(lex: Lexer): ?State {
        lex.seek(lex.leftDelim.size)
        lex.emit(TokenType.RightDelim)
        return StateText()
    }
}

struct StateSetDelim <: State  {
    init() {}
    public func state(lex: Lexer): ?State {
        let end = "=${lex.rightDelim}"
        let i = String(lex.runes[lex.pos..]).indexOf(end)
        if (i.isNone()) {
            return lex.errorf("unclosed tag")
        }
        let ii = i.getOrThrow()
        let delims = String(lex.runes[lex.pos..lex.pos+ii]).split(" ")
        if (delims.size < 2)  {
            lex.errorf("set delimiters should be separated by a space")
        }
        var hasLeft = false
        for (delim in delims) {
            if (delim != "") {
                if (!hasLeft) {
                    lex.setLeftDelim(delim)
                    hasLeft = true
                } else {
                    lex.setRightDelim(delim)
                }
            }
        }
        lex.seek(ii + end.size)
        lex.ignore()
        lex.emit(TokenType.SetDelim)
        return StateText()
    }
}

struct StateTag <: State  {
    init() {}
    public func state(lex: Lexer): ?State {
        if (String(lex.runes[lex.pos..]).startsWith("}${lex.rightDelim}")) {
            lex.seek(1)
            lex.emit(TokenType.RawEnd)
            return StateRightDelim()
        }
        if (String(lex.runes[lex.pos..]).startsWith(lex.rightDelim)) {
            return StateRightDelim()
        }
        let r =lex.next() 
        if (r.isNone()) {
           return lex.errorf("unclosed action")
        } 
        let rr = r.getOrThrow()
        if (rr == r'\n') {
            return lex.errorf("unclosed action")
        } else if (rr.isAsciiWhiteSpace()) {
            lex.ignore()
        } else if (rr == r'!') {
            lex.emit(TokenType.Comment)
            return StateComment()
        } else if (rr == r'#') {
            lex.emit(TokenType.SectionStart)
        } else if (rr == r'^') {
            lex.emit(TokenType.SectionInverse)
        } else if (rr == r'/') {
            lex.emit(TokenType.SectionEnd)
        } else if (rr == r'&') {
            lex.emit(TokenType.RawAlt)
        } else if (rr == r'>') {
            lex.emit(TokenType.Partial)
        } else if (rr == r'{') {
            lex.emit(TokenType.RawStart)
        } else if (alphanum(rr)) {
            lex.backup()
            return StateIdent()
        } else {
            return lex.errorf("unrecognized character in action: %#U")
        }

        return StateTag()
    }
}

struct StateComment <: State  {
    init() {}
    public func state(lex: Lexer): ?State {
        let i = String(lex.runes[lex.pos..]).indexOf(lex.rightDelim)
        if (i.isNone()) {
            return lex.errorf("unclosed tag")
        }
        lex.seek(i.getOrThrow())
        lex.emit(TokenType.Text)
        return StateRightDelim()
    }
}

struct StateIdent <: State  {
    init() {}
    public func state(lex: Lexer): ?State {
        while (true) {
            let r = lex.next()
            if (let Some(v) <- r) {
                if (alphanum(v)) {
                    continue
                }
             }
             lex.backup()
             lex.emit(TokenType.Identifier)
             break
        }
        return StateTag()
    }
}

func alphanum(r:Rune):Bool {
    return r == r'_' || r == r'.' || r.isAsciiNumber() || r.isAsciiLetter()
}