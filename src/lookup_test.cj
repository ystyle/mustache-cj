package mustache

import std.unittest.*
import std.unittest.testmacro.*
import serialization.serialization.*
import std.collection.{HashMap, ArrayList}

struct LookupTestItem<T> where T <: MustacheSerializable {
    LookupTestItem(let context: T, let assertions: Array<LookupTestAssertion<T>>) {}
}

struct LookupTestAssertion<T> where T <: MustacheSerializable {
    LookupTestAssertion(let name: String, let value: T, let truth: Bool) {}
}

class TestLookupClass <: MustacheSerializable {
    TestLookupClass(let integer: Int64, let string: String, let boolean: Bool, let map: HashMap<String, String>) {}
    public func toDataModel(): DataModel {
        return DataModelStruct()
            .add(field<Int64>("integer", integer))
            .add(field<String>("string", string))
            .add(field<Bool>("boolean", boolean))
            .add(field<HashMap<String, String>>("map", map))
    }
}

let lookupTests = ArrayList<LookupTestItem<MustacheSerializable>>(
    LookupTestItem<MustacheSerializable>(
        TestLookupClass(123, "abc", true, HashMap<String, String>(("in", "I'm nested!"))),
        [
            LookupTestAssertion("integer", 123, true),
            LookupTestAssertion("string", "abc", true),
            LookupTestAssertion("boolean", true, true),
            LookupTestAssertion("map.in", "I'm nested!", true)
        ]
    ),
)

@Tag[lookup]
@Test
class LookupTest {
    @TestCase
    func testLookupMap() {
        let data = HashMap<String, String>(("a", "1"))
        let a = lookup("a", toDataModel(data))
        if (let Some(v) <- a) {
            println(dmToString(v))
        }
    }
    @TestCase
    func testLookup_v2() {
        var i = 0
        for (test in lookupTests) {
            var j = 0
            for (assertion in test.assertions) {
                let a = lookup(assertion.name, toDataModel(test.context))
                let a1 = a.getOrThrow()
                let v1 = dmToString(a1)
                let v2 = dmToString(assertion.value.toDataModel())
                println("${i}/${j} Unexpected value ${v1} != ${v2}")
                if (v1 != v2) {
                    @Fail("${i}/${j} Unexpected value ${v1} != ${v2}")
                }
                j++
            }
            i++
        }
    }
}
