package main

// Test: 2D Space Complexity
// Expected Time Complexity: O(n) - initialization loops over 2D structure
// Expected Space Complexity: O(n²) - 2D slice allocation

func test2DSpace() {
	// 2D slice - O(n²) space
	matrix := make([][]int, 10)
	for i := range matrix {
		matrix[i] = make([]int, 10)
	}

	// Slice of maps - O(n²) space
	sliceOfMaps := make([]map[string]int, 5)
	for i := range sliceOfMaps {
		sliceOfMaps[i] = make(map[string]int)
	}

	_ = matrix
	_ = sliceOfMaps
}

func main() {
	test2DSpace()
}
