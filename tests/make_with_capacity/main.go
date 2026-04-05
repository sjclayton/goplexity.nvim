package main

// Test: make() with Capacity Parameter
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(1) - just allocations, no loops
// Expected Space Complexity: O(n) - capacity-based allocations

// Expected Time Complexity: O(1)
// Expected Space Complexity: O(n)
func testCapacity(n int) {
	// Literal capacity - O(n) (non-zero capacity means allocation)
	buf := make([]byte, 0, 1024)

	// Variable capacity - O(n)
	slice := make([]int, 0, n)

	// Function call capacity - O(n)
	data := make([]string, 0, len(buf))

	_ = buf
	_ = slice
	_ = data
}

func main() {
	testCapacity(100)
}
