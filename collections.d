module profan.collections;

import std.string : format;

struct StaticArray(T, uint size) {

	uint elements = 0;
	T[size] array;

	alias array this;

	void opOpAssign(string op: "~")(T element) {
		array[elements++] = element;
	}

	T opIndex(size_t i) {
		return array[i];
	}

	T opIndexAssign(T value, size_t i) {
		return array[i] = value;
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

	//StaticArray
	const int size = 10;
	auto arr = StaticArray!(int, size)();
	arr[size-1] = 100;
	assert(arr[size-1] == 100, format("expected arr[%d] to be %d, was %d", size-1, 100, arr[size-1]));

}

unittest {

	import std.stdio : writefln;

	//DHeap
	auto heap = DHeap!(int)(32);
	heap.insert(24);
	writefln("heap[0]: %d", heap.deleteMin());

}
