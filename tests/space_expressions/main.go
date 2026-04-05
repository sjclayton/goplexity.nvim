package main

// Test: Space Detection with Expression Sizes
// Expected Time Complexity: O(1) - just allocations, no loops
// Expected Space Complexity: O(n) - variable-sized allocations

func testExpressions(n int) []int {
	// Arithmetic expression size
	buf := make([]byte, n+1)

	// Function call size
	data := make([]int, len(buf))

	// Multiplication expression
	tree := make([]int, 4*n)

	// Subtraction expression
	slice := make([]int, n-1)

	_ = data
	_ = tree
	_ = slice
	return data
}

func main() {
	_ = testExpressions(100)
}
