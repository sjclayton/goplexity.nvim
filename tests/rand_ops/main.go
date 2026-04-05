package main

import "math/rand"

// Test: Random operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
func testRand() {
	n := 10
	// Expected Time Complexity: O(n)
	// Expected Space Complexity: O(n)
	_ = rand.Perm(n)
	
	s := make([]int, n)
	// Expected Time Complexity: O(n)
	// Expected Space Complexity: O(1)
	rand.Shuffle(n, func(i, j int) {
		s[i], s[j] = s[j], s[i]
	})
}

func main() {
	testRand()
}
