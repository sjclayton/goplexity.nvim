package main

import "time"

// Test: Time Package Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(1) - all operations are constant time
// Expected Space Complexity: O(1) - no allocations

// Expected Time Complexity: O(1)
// Expected Space Complexity: O(1)
func testTimeOps() {
	// time.Now - O(1)
	_ = time.Now()

	// time.Sleep - O(1)
	time.Sleep(0)

	// time.Since - O(1)
	start := time.Now()
	_ = time.Since(start)

	// time.Until - O(1)
	future := time.Now().Add(time.Hour)
	_ = time.Until(future)
}

func main() {
	testTimeOps()
}
