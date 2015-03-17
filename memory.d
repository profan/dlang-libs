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
	}

	int var1;
	int var2;

}

struct StructTest {

	int var1 = 0;
	int var2 = 0;

}

//smart pointer with polymorphism, and possibly the ability to select a memory allocator.
struct SmartPtr(T) {

	this(T objectref) {
		this.object = objectref;
	}

	T object;
	alias object this;

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
