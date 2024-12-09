package mustache

import std.unittest.*
import std.unittest.testmacro.*
import std.collection.{HashMap, ArrayList}
import std.deriving.*
// import std.reflect.*

struct LookupTestItem {
    LookupTestItem(let context: Any, let assertions: Array<LookupTestAssertion>) {}
    init() {
        this.context = 1
        this.assertions = ArrayList<LookupTestAssertion>().toArray()
    }
}

struct LookupTestAssertion {
    LookupTestAssertion(let name: String, let value: Any, let truth: Bool) {}
}

public struct Item <: ToString {
    Item(let a:Int64) {}

    @MustacheFunc["say"]
    public func say():String {
        return "hello"
    }
    public func toString():String {
        return "Item(a: ${a})"
    }
}

let lookupTests = ArrayList<LookupTestItem>(
    LookupTestItem(
        HashMap<String, Any>(
            ("integer", 123),
            ("string", "abc"),
            ("boolean", true),
            ("map", HashMap<String, Any>(("in", "I'm nested!"))),
            ("struct", Item(1)),
        ),
        LookupTestAssertion("integer", 123, true),
        LookupTestAssertion("string", "abc", true),
        LookupTestAssertion("boolean", true, true),
        LookupTestAssertion("map.in", "I'm nested!", true),
        LookupTestAssertion("struct", "Item(a: 1)", true),
        LookupTestAssertion("struct.say", "hello", true),
    ),
)

@Tag[lookup]
@Test
class LookupTest {
    @TestCase
    func testLookup_1_v2() {
        let data = HashMap<String, Any>(("a", "1"),)
        let a = lookup_v2("a", data)
        match (a) {
            case v: String => println(v)
            case _ => ()
        }
    }
    @TestCase
    func testLookup_v2() {
        var i = 0
        for (test in lookupTests) {
            var j = 0
            for (assertion in test.assertions) {
                let a = lookup_v2(assertion.name, test.context)
                let v1 = anyToString(a)
                let v2 = anyToString(assertion.value)
                println("${i}/${j} Unexpected value ${v1} != ${v2}")
                if (v1 != v2) {
                    @Fail("${i}/${j} Unexpected value ${v1} != ${v2}")
                }
                j++
            }
            i ++
        }
    }
    @Tag[AnyToString]
    @TestCase
    func testAnyToString() {
        let a = anyToString("1")
        if (a != "1") {
            @Fail("Unexpected string value 1 != ${a}")
        }
        let b = anyToString(1)
        if (b != "1") {
            @Fail("Unexpected int value 1 != ${b}")
        }
        let c = anyToString(1.1)
        if (c != "1.100000") {
            @Fail("Unexpected float value 1.1 != ${c}")
        }
        let d = anyToString(true)
        if (d != "true") {
            @Fail("Unexpected bool value true != ${c}")
        }
    }
    @Tag[collection]
    @TestCase
    func testInterface() {
        let a = ArrayList<Item>(Item(1), Item(2), Item(3))
        list(a)
        println("------")
        list(a.toArray())
    }
}
