package mustache

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.HashMap
import std.deriving.Derive
import stdx.serialization.serialization.*

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
class FalsyTemplateData <: MustacheComponent {
    FalsyTemplateData(let foo:Int64, let bar:Bool){}
    public func mustache(): DataModel {
        return DataModelStruct().add(field<Int64>("foo", foo)).add(field<Bool>("bar", bar))
    }
}