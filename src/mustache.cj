package mustache

import std.collection.{ArrayList, HashMap}
import serialization.serialization.*
import std.io.{InputStream, StringReader, OutputStream, ByteBuffer, StringWriter}
import encoding.json.*
import std.reflect.*

interface Node <: ToString {
    func render(t: Template, w: Writer, c: Array<Any>): Unit
}

public class MustacheException <: Exception {
    init(message: String) {
        super(message)
    }
}

class TextNode <: Node {
    TextNode(let text: String) {
    }
    public func render(_: Template, w: Writer, _: Array<Any>): Unit {
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
    public func render(_: Template, w: Writer, c: Array<Any>): Unit {
        w.text()
        let v = lookup_v2(this.name, c)
        let text = anyToString(v)
        if (this.escape) {
            w.write(escapeFn(text).toArray())
        } else {
            w.write(text.toArray())
        }
    }
    public func toString(): String {
        return "[var: ${this.name} escaped: ${this.escape}]"
    }
}

class SectionNode <: Node & ToString {
    SectionNode(let name: String, let inverted: Bool, let elems: ArrayList<Node>) {
    }
    public func render(t: Template, w: Writer, c: Array<Any>): Unit {
        w.tag()
        let elemFn = { v: Array<Any> => 
            let l = ArrayList<Any>()
            l.appendAll(v)
            l.appendAll(c)
            let ctx = l.toArray()
            for (elem in elems) {
                elem.render(t, w, ctx)
            }
        }
        let v = lookup_v2(this.name, c)
        if (this.inverted) {
                for (sif in TypeInfo.of(v).superInterfaces) {
                    println(sif.name)
                }
                match (v) {
                    case vv: Collection<Any> =>
                        if (vv.size > 0) {
                            for (item in vv) {
                                elemFn(item)
                            }
                        } else {
                            elemFn(v)
                        }
                    case _ => elemFn(v)
                }
                w.tag()
                return
            }
        w.tag()
        throw MustacheException("failed to lookup ${name}")
    }
    public func toString(): String {
        return "[section: ${name} inv: ${inverted} elems: ${elems}]"
    }
}

class CommentNode <: Node & ToString {
    CommentNode(let text: String) {
    }
    public func render(_: Template, w: Writer, _: Array<Any>): Unit {
        w.tag()
    }
    public func toString(): String {
        return "[comment: ${text}]"
    }
}

class PartialNode <: Node & ToString {
    PartialNode(let name: String) {
    }
    public func render(t: Template, w: Writer, c: Array<Any>): Unit {
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
    public func render(_: Template, w: Writer, _: Array<Any>): Unit {
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

public class Template {
    let name: String
    let elems = ArrayList<Node>()
    var partials = HashMap<String, Template>()
    var startDelim = "{{"
    var endDelim = "}}"
    var silentMiss = true
    public init(name: String, options: Array<OptionFn>) {
        super()
        this.name = name
        for (opt in options) {
            opt(this)
        }
    }

    public func parse(input: InputStream):Unit {
        let sr = StringReader(input)
        let content = sr.readToEnd()
        this.parse(content)
    }

    public func parse(content: String):Unit {
        let lex = Lexer(content, this.startDelim, this.endDelim)
        let parser = Parser(lex)
        let elems = parser.parse()
        this.elems.clear()
        this.elems.appendAll(elems)
    }

     public func parse(bs:Array<Byte>):Unit {
        this.parse(String.fromUtf8(bs))
    }

    func render(w: Writer, context: Any): Unit  {
        for (elem in this.elems) {
            try {
                elem.render(this, w, context)
            } catch (e:Exception) {
                if (!this.silentMiss) {
                    throw e
                } else {
                    e.printStackTrace()
                }
            }
        }
        w.flush()
    }

    func render(w: OutputStream, context: Any): Unit {
        this.render(Writer(w), context)
    }

    public func render(context: Any): String {
        var buf = ByteBuffer()
        let w = Writer(buf)
        this.render(w, context)
        return String.fromUtf8(buf.bytes())
    }
    public func renderBytes(context: Any): Array<Byte> {
        var buf = ByteBuffer()
        let w = Writer(buf)
        this.render(w, context)
        return buf.bytes()
    }
}

// func dmToString(data: DataModel): String {
//     match (data) {
//         case v: ToString => v.toString()
//         case v: DataModelString => v.getValue()
//         case v: DataModelInt => "${v.getValue()}"
//         case v: DataModelFloat => "${v.getValue()}"
//         case v: DataModelNull => ""
//         case _ => data.toJson().toJsonString()
//     }
// }

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

func toDataModel<T>(context: Array<T>): Array<DataModel> where T <: Serializable<T> & ToString {
    let list = ArrayList<DataModel>(context.size)
    for (ctx in context) {
        list.append(ctx.serialize())
    }
    return list.toArray()
}
