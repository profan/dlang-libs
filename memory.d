module profan.memory;

import core.stdc.stdio : printf;
import core.stdc.stdlib : malloc, free;
import std.conv : emplace;
import core.memory : GC;

auto allocate(T, Args...)(Args args) {

	size_t size;
	static if (is(T == class)) {
		size = __traits(classInstanceSize, T);
	} else if (is(T == struct)) {
		size = T.sizeof;
	}

	auto memory = malloc(size)[0..size];

	if (!memory) {
		printf("Memory allocation failed, tried to allocate %d bytes.", size);
		return null;
	}

	GC.addRange(memory.ptr, size);
	return emplace!(T, Args)(memory, args);

}

class ClassTest {

	this(int v1, int v2) {
		this.var1 = v1;
		this.var2 = v2;
		printf("ClassTest created. \n");
	}

	~this() {
		printf("ClassTest destroyed. \n");
	}

	int var1;
	int var2;

}

struct StructTest {

	~this() {
		printf("StructTest destroyed. \n");
	}

	int var1 = 0;
	int var2 = 0;

}

//smart pointer with polymorphism, and possibly the ability to select a memory allocator.
struct SmartPtr(T) {

	alias RefCount = uint*;

	this(T objectref) {
		this.object = objectref;
		this.refs = cast(uint*)malloc(uint.sizeof);
		*this.refs = 1;
	}

	this(this) {
		refs = refs;
		++(*refs);
	}

	~this() {

		*refs -= 1;
		if (*refs == 0) {

			static if (is(T == class)) {
				destroy(object);
			} else {
				destroy(*object);
			}

			GC.removeRange(cast(void*)object);
			free(cast(void*)object);
			free(refs);
			mixin("printf(\"SmartPtr: " ~ typeof(object).stringof ~ " Memory deallocated. \n\");");

		}

	}

	T object;
	alias object this;
	RefCount refs;

}

unittest {
	
	import std.stdio : writefln;

	auto ptr1 = SmartPtr!(ClassTest)(allocate!(ClassTest)(10, 10));
	writefln("Test var1: %d" , ptr1.var1);
	writefln("Test var2: %d" , ptr1.var2);

	auto ptr2 = SmartPtr!(StructTest*)(allocate!(StructTest)());
	writefln("Test var1: %d" , ptr2.var1);
	writefln("Test var2: %d" , ptr2.var2);
	

}
