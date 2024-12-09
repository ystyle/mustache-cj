package mustache

import std.io.{InputStream, ByteBuffer, OutputStream, BufferedOutputStream}

public class WriterException <: Exception {
    init(i:Int64, e:Exception) {
        super("write length: ${i}, errmsg: ${e}")
    }
}

public class Writer <: OutputStream {
    var hasText =false
    var hasTag = false
    let w:OutputStream
    let b:BufferedOutputStream<OutputStream>
    init(w:OutputStream) {
        this.w = w
        this.b = BufferedOutputStream(this.w)
    }
    func text():Unit {
        this.hasText = true
    }
    func tag():Unit {
        this.hasTag =true
    }
    func reset():Unit {
        this.hasTag = false
        this.hasText = false
    }
    public func flush():Unit {
        if (this.hasTag && !this.hasText) {
            this.b.reset(this.w)
            return
        }
        this.b.flush()
    }
    func write(r:Rune):Unit {
        this.b.write(r.toString().toArray())
        if (r == r'\n') {
            this.flush()
        }
    }
    public func write(b:Array<Byte>):Unit {
        let runes = String.fromUtf8(b).toRuneArray()
        for (r in runes) {
            this.write(r)
        }
    }
}