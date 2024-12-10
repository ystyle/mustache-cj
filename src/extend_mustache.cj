package mustache

import std.collection.{ArrayList, HashMap, HashSet}
import serialization.serialization.*

extend Int8 <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend Int16 <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend Int32 <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend Int64 <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}

extend UInt8 <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend UInt16 <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend UInt32 <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend UInt64 <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}

extend Float16 <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend Float32 <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend Float64 <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}

extend Rune <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend String <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}

extend Bool <: MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}

extend<T> Array<T> <: MustacheSerializable where T <: Serializable<T> & MustacheSerializable  {
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend<T> ArrayList<T> <: MustacheSerializable where T <: Serializable<T> & MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend<T> HashSet<T> <: MustacheSerializable where T <: Serializable<T> & MustacheSerializable {
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}
extend<K, V> HashMap<K, V> <: MustacheSerializable where K <: Serializable<K> & MustacheSerializable, V <: Serializable<V> & MustacheSerializable {
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}

extend<T> Option<T> <: MustacheSerializable where T <: Serializable<T> & MustacheSerializable{
    public func toDataModel(): DataModel {
        return this.serialize()
    }
}