package main

// Test: Triple Nested Loop - O(n³)
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n³) - three levels of nesting
// Expected Space Complexity: O(1) - no allocations

// Expected Time Complexity: O(n³)
// Expected Space Complexity: O(1)
func cubic(n int) int {
	total := 0
	for i := 0; i < n; i++ {
		for j := 0; j < n; j++ {
			for k := 0; k < n; k++ {
				total++
			}
		}
	}
	return total
}

func main() {
	_ = cubic(10)
}
