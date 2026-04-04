package main

import "math/bits"

// Test: math/bits Package Operations
// Expected Time Complexity: O(1) - hardware instructions
// Expected Space Complexity: O(1) - no allocations

func testBitsOps() {
	n := uint(42)

	// bits.OnesCount - O(1)
	_ = bits.OnesCount(n)

	// bits.LeadingZeros - O(1)
	_ = bits.LeadingZeros(n)

	// bits.TrailingZeros - O(1)
	_ = bits.TrailingZeros(n)

	// bits.RotateLeft - O(1)
	_ = bits.RotateLeft(n, 3)
}

func main() {
	testBitsOps()
}
