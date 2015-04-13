module profan.collections;

import std.string : format;

struct StaticArray(T, uint size) {

	uint elements = 0;
	T[size] array;

	alias array this;

	void opOpAssign(string op: "~")(T item) {
		array[elements++] = item;
	}

	void opOpAssign(string op: "~")(in T[] items) {
		foreach(e; items) {
			array[elements++] = e;
		}
	}

	T opIndex(size_t i) {
		return array[i];
	}

	T[] opSlice(size_t h, size_t t) {
		return array[h..t];
	}

	T opIndexAssign(T value, size_t i) {
		return array[i] = value;
	}

	void opAssign(StaticArray!(T, size) other) {
		this.array = other.array;
		this.elements = other.elements;
	}

}

//for pathfinding and stuff, cache efficiency to be performance tested.
struct DHeap(T) {

	import core.stdc.stdlib : malloc, free;

	T* heap;

	this(size_t initial_size = 32) {

		size_t size = initial_size * T.sizeof;
		heap = cast(T*)malloc(size);

	}

	T deleteMin() {
		return heap[0];
	}

	void insert(T data) {
		heap[0] = data;
	}

}

unittest {

	import std.conv : to;

	//StaticArray
	const int size = 10;
	auto arr = StaticArray!(int, size)();
	arr[size-1] = 100;
	assert(arr[size-1] == 100, format("expected arr[%d] to be %d, was %d", size-1, 100, arr[size-1]));

	int[5] int_a = [1, 2, 3, 4, 5];
	arr ~= int_a;
	assert(arr.elements == 5, "expected num of elements to be 5, was: " ~ to!string(arr.elements));

}

unittest {

	import std.stdio : writefln;

	//DHeap
	auto heap = DHeap!(int)(32);
	heap.insert(24);

}
