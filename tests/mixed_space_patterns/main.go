package main

// Test: Mixed Space Patterns - Literals and Variables
// Expected Time Complexity: O(n) - initialization loops
// Expected Space Complexity: O(n²) - 2D slice dominates

func testMixed(n int) [][]int {
	// Literal size - O(1)
	small := make([]int, 10)

	// 2D slice - O(n²)
	large := make([][]int, n)
	for i := range large {
		large[i] = make([]int, n)
	}

	_ = small
	return large
}

func main() {
	_ = testMixed(10)
}
