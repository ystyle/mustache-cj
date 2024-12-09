package mustache

import serialization.serialization.*
import std.reflect.*
import std.collection.{HashMap, ArrayList, Map, Set}
import encoding.json.stream.{JsonSerializable, JsonWriter}
import std.io.{StringWriter, ByteBuffer, readToEnd}

public class VarNoFoundException <: Exception {
    init(message: String) {
        super(message)
    }
    init() {
    }
}

@Annotation[target: [MemberFunction]]
public class MustacheFunc {
    let name: String
    const init(name: String) {
        this.name = name
    }
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
            case v: DataModelStruct =>
                let value = v.get(name)
                match (value) {
                    case _: DataModelNull => println("todo call method")
                    case _ => return value
                }
            case _ => ()
        }
    }
    return None
}

func lookup_v2(name: String, context: Array<Any>): Any {
    println("lookup_v2 name: ${name}")
    if (name != "." && name.contains(".")) {
        let parts = name.split(".", 2)
        let v = lookup_v2(parts[0], context)
        return lookup_v2(parts[1], v)
    }
    if (name == ".") {
        return context
    }
    for (ctx in context) {
        let ti = TypeInfo.of(ctx)
        println("lookup_v2 type: ${ti.name}: ${ti.qualifiedName}")
        match (ti) {
            case cti: ClassTypeInfo =>
                // 变量 
                for (fi in cti.instanceVariables) {
                    if (fi.name == name) {
                        return fi.getValue(ctx)
                    }
                }
                // 方法
                for (fni in cti.instanceFunctions) {
                    if (fni.name == name) {
                        if (fni.parameters.size == 0) {
                            return fni.apply(ctx)
                        } else {
                            throw VarNoFoundException("fucntion [${fni.name}] can not support args.")
                        }
                    }
                }
                // 处理map或集合
                match (ctx) {
                    case v: HashMap<String, Int8> => return v[name]
                    case v: HashMap<String, Int16> => return v[name]
                    case v: HashMap<String, Int32> => return v[name]
                    case v: HashMap<String, Int64> =>
                        println("lookup_v2: HashMap<String, Int64>")
                        return v[name]
                    case v: HashMap<String, UInt8> => return v[name]
                    case v: HashMap<String, UInt16> => return v[name]
                    case v: HashMap<String, UInt32> => return v[name]
                    case v: HashMap<String, UInt64> => return v[name]
                    case v: HashMap<String, Float16> => return v[name]
                    case v: HashMap<String, Float32> => return v[name]
                    case v: HashMap<String, Float64> => return v[name]
                    case v: HashMap<String, Bool> => return v[name]
                    case v: HashMap<String, String> => return v[name]
                    case v: HashMap<String, Any> => return v[name]
                    case _ => throw VarNoFoundException()
                }
            case sti: StructTypeInfo =>
                for (fi in sti.instanceVariables) {
                    if (fi.name == name) {
                        return fi.getValue(ctx)
                    }
                }
                for (fni in sti.instanceFunctions) {
                    if (fni.name == name) {
                        if (fni.parameters.size == 0) {
                            return fni.apply(ctx)
                        } else {
                            throw VarNoFoundException("fucntion [${fni.name}] can not support args.")
                        }
                    }
                }
                throw VarNoFoundException()
            case pti: PrimitiveTypeInfo => throw VarNoFoundException()
            case _ => throw VarNoFoundException()
        }
    }
}

func anyToString(any: Any): String {
    println("anyToString")
    match (any) {
        case v: String => return v
        case v: Int8 => return "${v}"
        case v: Int16 => return "${v}"
        case v: Int32 => return "${v}"
        case v: Int64 => return "${v}"
        case v: UInt8 => return "${v}"
        case v: UInt16 => return "${v}"
        case v: UInt32 => return "${v}"
        case v: UInt64 => return "${v}"
        case v: JsonSerializable =>
            var buf = ByteBuffer()
            var jw = JsonWriter(buf)
            v.toJson(jw)
            return String.fromUtf8(readToEnd(buf))
        case v: ToString => return v.toString()
        case _ => match (TypeInfo.of(any)) {
            case cti: ClassTypeInfo =>
                println("Var (type: ${cti.qualifiedName}) can not toString, it will be implement ToString.")
                return ""
            case sti: StructTypeInfo =>
                println("Var (type: ${sti.qualifiedName}) can not toString, it will be implement ToString.")
                return ""
            case _ => return ""
        }
    }
    return ""
}

func list(a:Any) {
    let ti= TypeInfo.of(a)
    for (sif in ti.superInterfaces) {
        println(sif)
    }
}