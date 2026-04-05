package main

import (
	"container/ring"
)

// Test: Ring operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
func testRing() {
	n := 10
	r := ring.New(n)
	
	// Expected Time Complexity: O(n)
	// Expected Space Complexity: O(1)
	_ = r.Len()
	
	// Expected Time Complexity: O(n)
	// Expected Space Complexity: O(1)
	r.Move(5)
}

func main() {
	testRing()
}
