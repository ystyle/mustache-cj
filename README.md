# mustache-cj
基于仓颉实现的mustache模板引擎

# 安装
>分支说明: master版本因为extend扩展的bug，现在还无法使用。 custome-interface版本现在是用自定义序列化接口extend的，可以正常使用。 reflect版本因为反射无法调用Collection<T>相关接口，而无法使用，仓颉可能会改反射，先留着。
```toml
[dependencies]
mustache = {git = "https://github.com/ystyle/mustache-cj", branch = "custome-interface"}
```
### 使用
如果是自定义类型的话需要实现`MustacheSerializable`接口, 自带的类型已经用扩展功能实现过了。

自定义类型示例: 
```cj
import mustache.*
class MyData <: MustacheSerializable {
    MyData(let string: String) {}
    public func toDataModel(): DataModel {
        return DataModelStruct().add(field<String>("string", string))
    }
}
```

渲染模板
```cj
import mustache.*

main(): Int64 {
    let t = Template("tpl_name")
    t.parse("some text {{foo}} here")
    let data = HashMap<String, String>(
        ("foo", "bar")
    )
    let out = t.render(data)
    println(out)
    // some text bar here
    return 0
}
```

使用类渲染模板:
```cj
import mustache.*
import std.collection.HashMap
import serialization.serialization.*

class TestData <: MustacheSerializable {
    TestData(let integer: Int64, let string: String, let boolean: Bool, let map: HashMap<String, String>, let list:Array<Int64>) {}
    public func toDataModel(): DataModel {
        return DataModelStruct()
            .add(field<Int64>("integer", integer))
            .add(field<String>("string", string))
            .add(field<Bool>("boolean", boolean))
            .add(field<HashMap<String, String>>("map", map))
            .add(field<Array<Int64>>("list", list))
    }
}
main() {
    let t = Template("tpl_name")
    t.parse("integer:\t{{integer}}\nstring:\t{{string}}\nboolean:\t{{boolean}}\nmap.in:\t{{map.in}}\nlist:\t{{^list}}{{.}}{{/list}}")
    let data = TestData(123, "abc", true, HashMap<String, String>(("in", "I'm nested!")), 1,2,3)
    let out = t.render(data)
    println(out)
    // integer:        123
    // string: abc
    // boolean:        true
    // map.in: I&apos;m nested!
    // list:   123
}
```

引用模板
```cj
main() {
    println("Partials:")
    let t1 = Template("text")
    t1.parse("from partial")
    let t2 = Template("index", partial(t1))
    t2.parse("{{>text}}")
    let out = t2.render(1)
    println(out) // from partial
}
```

### api
- `Template()`: 实例化一个模板
- `Template(name: String, options: Array<OptionFn>)`: 自定义名称和变量标记
  - `public func parse(input: InputStream): Unit`: 从流加载模板
  - `public func parse(content: String): Unit`: 从字符串加载模板
  - `public func parse(bs: Array<Byte>): Unit`: 从字节数组加载模板
  - `public func render<T>(w: OutputStream, context: Array<T>): Unit where T <: MustacheSerializable`: 渲染模板到输出流
  - `public func render<T>(context: Array<T>): String where T <: MustacheSerializable`: 渲染模板为字符串
  - `public func renderBytes<T>(context: Array<T>): Array<Byte> where T <: MustacheSerializable`: 渲染模板到字节数组
- `OptionFn(t:Template):Unit`: 设置引擎参数， 有以下lambda
    - `delimiters("{{", "}}")`: 设置变量标记
    - `partial(t:Template)`:  设置模板， 以便引用模板
    - `enableErrors()`： 启用错误， 找不到变量时会抛出异常
    - `silentMiss()`： 禁用错误， 找不到变量时不处理
    - `Template(name: String, delimiters("{{", "}}"), partial(t:Template), partial(t:Template))`: 可以多个一起设置