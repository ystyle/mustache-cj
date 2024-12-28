package mustache

import std.collection.{ArrayList, HashMap, HashSet}
public import serialization.serialization.*

extend Int8 <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelInt(Int64(this))
    }
}
extend Int16 <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelInt(Int64(this))
    }
}
extend Int32 <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelInt(Int64(this))
    }
}
extend Int64 <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelInt(this)
    }
}

extend UInt8 <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelInt(Int64(this))
    }
}
extend UInt16 <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelInt(Int64(this))
    }
}
extend UInt32 <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelInt(Int64(this))
    }
}
extend UInt64 <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelInt(Int64(this))
    }
}

extend Float16 <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelFloat(Float64(this))
    }
}
extend Float32 <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelFloat(Float64(this))
    }
}
extend Float64 <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelFloat(this)
    }
}

extend Rune <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelString(String(this))
    }
}
extend String <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelString(this)
    }
}

extend Bool <: MustacheComponent{
    public func mustache(): DataModel {
        return DataModelBool(this)
    }
}

extend<T> Array<T> <: MustacheComponent where T <: MustacheComponent  {
     public func mustache(): DataModel {
        let data = DataModelSeq()
        for (item in this) {
            data.add(item.mustache())
        }
        return data
    }
}
extend<T> ArrayList<T> <: MustacheComponent where T <: MustacheComponent{
    public func mustache(): DataModel {
        let data = DataModelSeq()
        for (item in this) {
            data.add(item.mustache())
        }
        return data
    }
}
extend<T> HashSet<T> <: MustacheComponent where T <: MustacheComponent {
    public func mustache(): DataModel {
        let data = DataModelSeq()
        for (item in this) {
            data.add(item.mustache())
        }
        return data
    }
}
extend<K, V> HashMap<K, V> <: MustacheComponent where K <: ToString & MustacheComponent, V <: MustacheComponent {
    public func mustache(): DataModel {
        let data = DataModelStruct()
        for ((key, value) in this) {
            data.add(Field(key.toString(), value.mustache()))
        }
        return data
    }
}

extend<T> Option<T> <: MustacheComponent where T <: MustacheComponent{
    public func mustache(): DataModel {
        if (let None <- this) {
            return DataModelNull()
        }
        return this.getOrThrow().mustache()
    }
}