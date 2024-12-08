package mustache

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.HashMap
import serialization.serialization.*
import std.deriving.Derive

@Test
class TemplateTest {
    @TestCase
    func testTemplate() {
        let t = Template("testTemplate")
        t.parse("some text {{foo}} here")
        let data = HashMap<String, String>(
            ("foo", "bar")
        )
        let out = t.render(data)
        let expected = "some text bar here"
        if (out != expected) {
            @Fail("expected ${expected} got ${out}")
        }
    }

    @TestCase
    func testFalsyTemplate() {
        let t = Template("testFalsyTemplate")
        t.parse("some text {{^foo}}{{foo}}{{/foo}} {{bar}} here")
        let data =FalsyTemplateData(0, false)
        let out = t.render(data)
        let expected = "some text 0 false here"
        if (out != expected) {
            @Fail("expected [${expected}] got [${out}]")
        }
    }
}

@Derive[ToString]
class FalsyTemplateData <: Serializable<FalsyTemplateData> {
    FalsyTemplateData(let foo:Int64, let bar:Bool){}
     public func serialize(): DataModel {
        return DataModelStruct().add(field<Int64>("foo", foo)).add(field<Bool>("bar", bar))
    }

    /* 实现反序列化方法 */
    public static func deserialize(dm: DataModel): FalsyTemplateData {
        let dms = match (dm) {
            case data: DataModelStruct => data
            case _ => throw Exception("this data is not DataModelStruct")
        }
        let foo = Int64.deserialize(dms.get("foo"))
        let bar = Bool.deserialize(dms.get("bar"))
        return FalsyTemplateData(foo, bar)
    }
}