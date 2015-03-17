module profan.memory;

import core.stdc.stdlib : malloc, free;
import std.conv : emplace;
import core.memory : GC;

T allocate(T, Args...)(Args args) {
	auto size = __traits(classInstanceSize, T);
	auto memory = malloc(size)[0..size];
	GC.addRange(memory.ptr, size);
	return emplace!(T, Args)(memory, args);
}

class Test {

	this(int v1, int v2) {
		this.var1 = v1;
		this.var2 = v2;
	}

	int var1;
	int var2;

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

	auto ptr = SmartPtr!Test(allocate!(Test)(10, 10));
	writefln("Test var1: %d" , ptr.var1);
	writefln("Test var2: %d" , ptr.var2);

}
