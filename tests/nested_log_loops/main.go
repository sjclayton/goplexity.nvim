package main

// Test: Nested Complexity Multiplication
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n log n) - outer O(n) with inner O(log n)
// Expected Space Complexity: O(1) - no allocations

// Expected Time Complexity: O(n log n)
// Expected Space Complexity: O(1)
// Outer O(n) loop with inner O(log n) loop
func nLogN(n int) int {
	total := 0
	for i := 0; i < n; i++ {
		for j := 1; j < n; j *= 2 {
			total++
		}
	}
	return total
}

func main() {
	_ = nLogN(1000)
}
