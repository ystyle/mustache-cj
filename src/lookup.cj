package mustache

import serialization.serialization.*
import std.reflect.TypeInfo
import std.collection.{HashMap, ArrayList}

@Annotation[target: [MemberFunction]]
public class MustacheFunc {
    let name:String
    const init(name:String) {
        this.name = name
    }
}

let funcref = HashMap<String, MustacheFunCommonent>()


public interface MustacheFunCommonent {
    
}


func lookup(name: String, context: Array<DataModel>): ?DataModel {
    if (name != "." && name.contains(".")) {
        let parts = name.split(".", 2)
        if (let Some(v) <- lookup(parts[0], context)) {
            return lookup(parts[1], context)
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
                case _:DataModelNull => 
                    println("todo call method")
                    if (let Some(funcCommonent) <- funcref.get(name)) {
                        let ti = TypeInfo.of(funcCommonent)
                        for (f in ti.instanceFunctions) {
                            if (f.name == name) {
                                // var args = ArrayList<Any>(f.parameters.size)
                                // for (arg in f.parameters) {
                                    
                                // }
                                // f.apply(funcCommonent, args)
                            }
                        }
                    }
                    
                case _ => return value
               }
            case _ => ()
        }
    }
    return None
}
