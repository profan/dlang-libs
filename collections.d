module profan.collections;

import std.string : format;

struct StaticArray(T, uint size) {

	uint elements = 0;
	T[size] array;

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

unittest {

	const int size = 10;
	auto arr = StaticArray!(int, size)();
	arr[size-1] = 100;
	assert(arr[size-1] == 100, format("expected arr[%d] to be %d, was %d", size-1, 100, arr[size-1]));

}
