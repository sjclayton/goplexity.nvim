package main

// Test: 2D Space Complexity
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n²) - initialization loops over 2D structure
// Expected Space Complexity: O(n²) - 2D slice allocation

// Expected Time Complexity: O(n²)
// Expected Space Complexity: O(n²)
func test2DSpace(n int) {
	// 2D slice - O(n²) space
	matrix := make([][]int, n)
	for i := range matrix {
		matrix[i] = make([]int, n)
	}

	// Slice of maps - O(n) space
	sliceOfMaps := make([]map[string]int, n)
	for i := range sliceOfMaps {
		sliceOfMaps[i] = make(map[string]int)
	}

	_ = matrix
	_ = sliceOfMaps
}

func main() {
	test2DSpace(10)
}
