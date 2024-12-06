package mustache

interface State {
    func state(): State
}

struct StateText <: State {
    StateText(let lex: Lexer) {}
    public func state(): State {
        while (true) {
            if (lex.input[lex.pos..].startsWith(lex.leftDelim)) {
            }
        }
        return this
    }
}

type StateFn = (State) -> State

enum TokenType <: ToString {
    Error | EOF | Identifier

    public func toString(): String {
        match (this) {
            case Error => "error"
            case _ => ""
        }
    }
}

class Token <: ToString {
    Token(let typ: TokenType, let val: String, let line: Int64, let col: Int64) {}
    public func toString(): String {
        return "${typ}:${val}"
    }
}

class Lexer {
    let input: String
    let runes: Array<Rune>
    let leftDelim: String
    let rightDelim: String
    var state: ?State = None
    var pos: Int64 = 0
    var start: Int64 = 0
    // var width: Int64 = 0
    var _token: ?Token = None
    init(input: String, leftDelim: String, rightDelim: String) {
        super()
        this.input = input
        this.runes = input.toRuneArray()
        this.leftDelim = leftDelim
        this.rightDelim = rightDelim
        this.state = StateText(this)
    }
    func next(): Rune {
        if (this.pos >= this.runes.size) {
            return Rune(UInt32(-1))
        }
        let r = this.runes[this.pos]
        this.pos += 1
        return r
    }
    func seek(n: Int64) {
        this.pos += n
    }
    func peek(): Rune {
        let r = this.next()
        this.backup()
        return r
    }
    func backup() {
        this.pos -= 1
    }
    func emit(t: TokenType) {
    }
    func lineNum(): Int64 {
        return 0
    }
    func columnNum(): Int64 {
        return 0
    }
    func token(): Token {
        while (true) {
            if (let Some(v) <- this._token) {
                return v
            }
            if (this.state.isNone()) {
                this.state = StateText(this)
            }
            this.state?.state()
        }
    }
}
