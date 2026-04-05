package main

import "math"

// Test: Square Root Loop Pattern
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(√n)
// Expected Space Complexity: O(1)

// i * i <= n pattern - O(√n)
// Expected Time Complexity: O(√n)
// Expected Space Complexity: O(1)
func sqrtLoop1(n int) int {
	count := 0
	for i := 1; i*i <= n; i++ {
		count++
	}
	return count
}

// math.Sqrt in condition pattern - O(√n)
// Expected Time Complexity: O(√n)
// Expected Space Complexity: O(1)
func sqrtLoop2(n int) int {
	count := 0
	limit := int(math.Sqrt(float64(n)))
	for i := 1; i <= limit; i++ {
		count++
	}
	return count
}

func main() {
	_ = sqrtLoop1(10000)
	_ = sqrtLoop2(10000)
}
