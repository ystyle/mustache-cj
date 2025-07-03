package mustache

import stdx.serialization.serialization.*
import std.collection.{HashMap, ArrayList}


func lookup(name: String, context: Array<DataModel>): ?DataModel {
    if (name != "." && name.contains(".")) {
        let parts = name.split(".", 2)
        if (let Some(v) <- lookup(parts[0], context)) {
            return lookup(parts[1], v)
        }
        return None
    }
    for (ctx in context) {
        if (name == ".") {
            return ctx
        }
        match (ctx) {
            case v:DataModelStruct => 
               let value = v.get(name)
               match (value) {
                case _:DataModelNull => return None
                case _ => return value
               }
            case _ => ()
        }
    }
    return None
}
