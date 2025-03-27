package mustache

import std.collection.{ArrayList, HashMap}
import serialization.serialization.*
import std.io.{InputStream, StringReader, OutputStream, ByteBuffer, StringWriter}
import encoding.json.*

interface Node <: ToString {
    func render(t: Template, w: Writer, c: Array<DataModel>): Unit
}

public interface MustacheComponent {
    func mustache(): DataModel
}

public class MustacheException <: Exception {
    init(message: String) {
        super(message)
    }
}

class TextNode <: Node {
    TextNode(let text: String) {
    }
    public func render(t: Template, w: Writer, c: Array<DataModel>): Unit {
        for (r in this.text.toRuneArray()) {
            if (r.isAsciiWhiteSpace()) {
                w.text()
            }
            w.write(r)
        }
    }
    public func toString(): String {
        return "[text: ${text}]"
    }
}

class VarNode <: Node & ToString {
    VarNode(let name: String, let escape: Bool) {}
    public func render(t: Template, w: Writer, c: Array<DataModel>): Unit {
        w.text()
        let v = lookup(this.name, c)
        if (let Some(dm) <- v) {
            let text = dmToString(dm)
            if (t.escape && this.escape) {
                w.write(escapeFn(text).toArray())
            } else {
                w.write(text.toArray())
            }
            return
        }
        throw MustacheException("failed to lookup ${name}")
    }
    public func toString(): String {
        return "[var: ${this.name} escaped: ${this.escape}]"
    }
}

class SectionNode <: Node & ToString {
    SectionNode(let name: String, let inverted: Bool, let elems: ArrayList<Node>) {
    }
    public func render(t: Template, w: Writer, c: Array<DataModel>): Unit {
        w.tag()
        let elemFn = {
            v: Array<DataModel> =>
            let l = ArrayList<DataModel>()
            l.add(all:v)
            l.add(all:c)
            let ctx = l.toArray()
            for (elem in elems) {
                elem.render(t, w, ctx)
            }
        }
        let v = lookup(this.name, c)
        let truthv = truth(v)
        if (truthv != this.inverted) {
            if (let Some(dm) <- v) {
                match (dm) {
                    case vv: DataModelSeq =>
                        if (vv.getItems().size > 0) {
                            for (item in vv.getItems()) {
                                elemFn(item)
                            }
                        } else {
                            elemFn()
                        }
                    case _ => elemFn(dm)
                }
                w.tag()
                return
            }
        }
        w.tag()
        // todo: 列表后如果有inverted section会被忽略
        // throw MustacheException("failed to lookup ${name}")
    }
    public func toString(): String {
        return "[section: ${name} inv: ${inverted} elems: ${elems}]"
    }
}

class CommentNode <: Node & ToString {
    CommentNode(let text: String) {
    }
    public func render(t: Template, w: Writer, c: Array<DataModel>): Unit {
        w.tag()
    }
    public func toString(): String {
        return "[comment: ${text}]"
    }
}

class PartialNode <: Node & ToString {
    PartialNode(let name: String) {
    }
    public func render(t: Template, w: Writer, c: Array<DataModel>): Unit {
        w.tag()
        if (let Some(template) <- t.partials.get(this.name)) {
            template.partials = t.partials
            template.render(w, c)
        }
    }
    public func toString(): String {
        return "[partial: ${name}]"
    }
}

class DelimNode <: Node & ToString {
    DelimNode() {}
    public func render(t: Template, w: Writer, c: Array<DataModel>): Unit {
        w.tag()
    }
    public func toString(): String {
        return "[delim]"
    }
}

public type OptionFn = (Template) -> Unit

public let delimiters: (String, String) -> OptionFn = {
    start: String, end: String => return {
        t =>
        t.startDelim = start
        t.endDelim = end
    }
}
public let partial: (Template) -> OptionFn = {
    p: Template => return {
        t => t.partials[p.name] = p
    }
}
public let enableErrors: () -> OptionFn = {
    => return {
        t => t.silentMiss = false
    }
}
public let silentMiss: () -> OptionFn = {
    => return {
        t => t.silentMiss = true
    }
}

public let disableEscape: () -> OptionFn = {
    => return {
        t => t.escape = false
    }
}

public class Template {
    protected let name: String
    let elems = ArrayList<Node>()
    protected var partials = HashMap<String, Template>()
    protected var startDelim = "{{"
    protected var endDelim = "}}"
    protected var silentMiss = true
    var escape = true
    public init() {
        this.name = ""
    }
    public init(name: String, options: Array<OptionFn>) {
        super()
        this.name = name
        for (opt in options) {
            opt(this)
        }
    }

    public func parse(input: InputStream): Unit {
        let sr = StringReader(input)
        let content = sr.readToEnd()
        this.parse(content)
    }

    public func parse(content: String): Unit {
        let lex = Lexer(content, this.startDelim, this.endDelim)
        let parser = Parser(lex)
        let elems = parser.parse()
        this.elems.clear()
        this.elems.add(all:elems)
    }

    public func parse(bs: Array<Byte>): Unit {
        this.parse(String.fromUtf8(bs))
    }

    func render(w: Writer, context: Array<DataModel>): Unit {
        for (elem in this.elems) {
            try {
                elem.render(this, w, context)
            } catch (e: Exception) {
                if (!this.silentMiss) {
                    throw e
                }
            }
        }
        w.flush()
    }

    public func render<T>(w: OutputStream, context: Array<T>): Unit where T <: MustacheComponent {
        this.render(Writer(w), toDataModel(context))
    }

    public func render<T>(context: Array<T>): String where T <: MustacheComponent {
        var buf = ByteBuffer()
        let w = Writer(buf)
        this.render(w, toDataModel(context))
        return String.fromUtf8(buf.bytes())
    }
    public func renderBytes<T>(context: Array<T>): Array<Byte> where T <: MustacheComponent {
        var buf = ByteBuffer()
        let w = Writer(buf)
        this.render(w, toDataModel(context))
        return buf.bytes()
    }
}

func dmToString(data: DataModel): String {
    match (data) {
        case v: DataModelString => v.getValue()
        case v: DataModelInt => "${v.getValue()}"
        case v: DataModelFloat => "${v.getValue()}"
        case v: DataModelNull => ""
        case v: ToString => v.toString()
        case _ => data.toJson().toJsonString()
    }
}
func truth(data: ?DataModel): Bool {
    match (data) {
        case None => false
        case Some(v: DataModelNull) => false
        case Some(v: DataModelInt) => v.getValue() != 0
        case Some(v: DataModelFloat) => v.getValue() != 0.0
        case Some(v: DataModelString) => v.getValue() != ""
        case Some(v: DataModelBool) => v.getValue()
        case Some(v: DataModelSeq) => v.getItems().size > 0
        case _ => true
    }
}

func escapeFn(s: String): String {
    if (s.indexOf(#"'"&<>"#).isSome()) {
        return s
    }
    var b = StringBuilder()
    for (r in s.toRuneArray()) {
        match (r) {
            case r'"' => b.append("&quot;")
            case r'\'' => b.append("&apos;")
            case r'&' => b.append("&amp;")
            case r'<' => b.append("&lt;")
            case r'>' => b.append("&gt;")
            case _ => b.append(r)
        }
    }
    return b.toString()
}

func toDataModel<T>(context: Array<T>): Array<DataModel> where T <: MustacheComponent {
    let list = ArrayList<DataModel>(context.size)
    for (ctx in context) {
        list.add(ctx.mustache())
    }
    return list.toArray()
}
