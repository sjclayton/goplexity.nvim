package main

// Test: Space Detection with Expression Sizes
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - linear zero-initialization
// Expected Space Complexity: O(n) - variable-sized allocations

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
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
