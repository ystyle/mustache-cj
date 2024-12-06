package mustache

import std.collection.{ArrayList, HashMap}
import serialization.serialization.Serializable
import std.io.{InputStream, StringReader}

public interface Node {
    func render(t: Template, w: Writer, c: Serializable<Any>): Unit
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
    => return { t => 
      t.silentMiss = false
    }
}

public let silentMiss: () -> OptionFn = {
    => return { t => 
      t.silentMiss = true
    }
}

public class Template {
    let name: String
    let elems = ArrayList<Node>()
    let partials = HashMap<String, Template>()
    var startDelim = "{{"
    var endDelim = "}}"
    var silentMiss = false
    public init(name: String, options: Array<OptionFn>) {
        super()
        this.name = name
        for (opt in options) {
            opt(this)
        }
    }

    public func parse(input:InputStream) {
        let sr = StringReader(input)
        let content = sr.readToEnd()
        this.parse(content)
    }

    public func parse(content:String) {
        
    }
}
