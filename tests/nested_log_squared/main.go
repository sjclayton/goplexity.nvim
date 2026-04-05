package main

// Test: Nested Logarithmic Loops - O(log² n)
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(log² n) - log n outer with log n inner
// Expected Space Complexity: O(1) - no allocations

// Expected Time Complexity: O(log² n)
// Expected Space Complexity: O(1)
func logSquared(n int) int {
	count := 0
	for i := 1; i < n; i *= 2 {
		for j := 1; j < n; j *= 2 {
			count++
		}
	}
	return count
}

func main() {
	_ = logSquared(1000)
}
