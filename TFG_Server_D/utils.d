// Copyright (c) 2015, maldicion069 (Cristian Rodríguez) <ccrisrober@gmail.con>
//
// Permission to use, copy, modify, and/or distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.package com.example

module utils;
import std.variant;
import std.json;
import std.traits;
import std.conv;
import map;
import object_user;
import key_object;
import std.stdio : writeln, writefln, sprintf;

string toJson(T)(T a) {
	auto v = toJsonValue(a);
	return toJSON(&v);
}

JSONValue toJsonValue(T)(T a) {
	JSONValue val;
	static if(is(T == JSONValue)) {
		val = a;
	} else static if(__traits(compiles, val = a.makeJsonValue())) {
		val = a.makeJsonValue();
	} else static if(isIntegral!(T)) {
		val.type = JSON_TYPE.INTEGER;
		val.integer = to!long(a);
	/*} else static if(isFloatingPoint!(T)) {
		val.type = JSON_TYPE.FLOAT;
		val.floating = to!real(a);
		static assert(0);
	*/} else static if(is(T == void*)) {
		val.type = JSON_TYPE.NULL;
	} else static if(is(T == float)) {
		val.type = JSON_TYPE.FLOAT;
		val.floating = to!real(a);
	} else static if(is(T == bool)) {
		if(a == true)
			val.type = JSON_TYPE.TRUE;
		if(a == false)
			val.type = JSON_TYPE.FALSE;
	} else static if(isSomeString!(T)) {
		val.type = JSON_TYPE.STRING;
		val.str = to!string(a);
	} else static if(isAssociativeArray!(T)) {
		val.type = JSON_TYPE.OBJECT;
		foreach(k, v; a) {
			if (is(isPointer!(k))) {
				writeln("Es puntero");
			}
			if (is(isPointer!(v))) {
				writeln("Es puntero");
			}
			val.object[to!string(k)] = toJsonValue(v);
		}
	} else static if(isArray!(T)) {
		val.type = JSON_TYPE.ARRAY;
		val.array.length = a.length;
		foreach(i, v; a) {
			val.array[i] = toJsonValue(v);
		}
	} else static if(is(T == struct)) {
		val.type = JSON_TYPE.OBJECT;
		foreach(i, member; a.tupleof) {
			string name = a.tupleof[i].stringof[2..$];
			static if(a.tupleof[i].stringof[2] != '_')
				val.object[name] = toJsonValue(member);
		}
	} else { /* our catch all is to just do strings */
		val.type = JSON_TYPE.STRING;
		val.str = to!string(a);
	}

	return val;
}

Variant jsonToVariant(string json) {
	auto decoded = parseJSON(json);
	return jsonValueToVariant(decoded);
}

Variant jsonValueToVariant(JSONValue v) {
	Variant ret;

	final switch(v.type) {
		case JSON_TYPE.STRING:
			ret = v.str;
			break;
		case JSON_TYPE.UINTEGER:
		case JSON_TYPE.INTEGER:
			ret = v.integer;
			break;
		case JSON_TYPE.FLOAT:
			ret = v.floating;
			break;
		case JSON_TYPE.OBJECT:
			Variant[string] obj;
			foreach(k, val; v.object) {
				obj[k] = jsonValueToVariant(val);
			}

			ret = obj;
			break;
		case JSON_TYPE.ARRAY:
			Variant[] arr;
			foreach(i; v.array) {
				arr ~= jsonValueToVariant(i);
			}

			ret = arr;
			break;
		case JSON_TYPE.TRUE:
			ret = true;
			break;
		case JSON_TYPE.FALSE:
			ret = false;
			break;
		case JSON_TYPE.NULL:
			ret = null;
			break;
	}

	return ret;
}


struct NewConnection {
	string Action;
	TMap Map;
	float X;
	float Y;
	int Id;
	ObjectUser[int] Users;
	
	// TODO: show how to do with refs!
	this(string a, TMap m, float x, float y, int i, ObjectUser[int] us) {
		this.Action = a;
		this.Map = m;
		this.X = x;
		this.Y = y;
		this.Id = i;
		this.Users = us;
	}
}

struct Exit {
	string Action;
	int Id;
	this(string a, int i) {
		this.Action = a;
		this.Id = i;
	}
}
struct ExitStr {
	string Action;
	string Id;
	this(string a, string i) {
		this.Action = a;
		this.Id = i;
	}
}

struct SendFightAnotherClient {
	string Action;
	int[2] Ids;

	this(string a, int[2] ids) {
		this.Action = a;
		this.Ids = ids;
	}
}

struct AddObj {
	string Action;
	KeyObject Obj;
	this(string a, KeyObject o) {
		this.Action = a;
		this.Obj = o;
	}
}