module profan.collections;

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
