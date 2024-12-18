package mustache

import std.collection.{ArrayList, HashMap, HashSet}
public import serialization.serialization.*

extend Int8 <: MustacheSerializable{}
extend Int16 <: MustacheSerializable{}
extend Int32 <: MustacheSerializable{}
extend Int64 <: MustacheSerializable{}

extend UInt8 <: MustacheSerializable{}
extend UInt16 <: MustacheSerializable{}
extend UInt32 <: MustacheSerializable{}
extend UInt64 <: MustacheSerializable{}

extend Float16 <: MustacheSerializable{}
extend Float32 <: MustacheSerializable{}
extend Float64 <: MustacheSerializable{}

extend Rune <: MustacheSerializable{}
extend String <: MustacheSerializable{}

extend Bool <: MustacheSerializable{}

extend<T> Array<T> <: MustacheSerializable where T <: Serializable<T> & MustacheSerializable  {}
extend<T> ArrayList<T> <: MustacheSerializable where T <: Serializable<T> & MustacheSerializable{}
extend<T> HashSet<T> <: MustacheSerializable where T <: Serializable<T> & MustacheSerializable {}
extend<K, V> HashMap<K, V> <: MustacheSerializable where K <: Serializable<K> & MustacheSerializable, V <: Serializable<V> & MustacheSerializable {}

extend<T> Option<T> <: MustacheSerializable where T <: Serializable<T> & MustacheSerializable{}