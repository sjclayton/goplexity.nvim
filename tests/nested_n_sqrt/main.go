package main

// Test: Linear-Sqrt Nested Loop - O(n√n)
// Expected Time Complexity: O(n√n) - n outer with √n inner
// Expected Space Complexity: O(1) - no allocations

func nSqrtN(n int) int {
	count := 0
	for i := 0; i < n; i++ {
		for j := 1; j*j <= n; j++ {
			count++
		}
	}
	return count
}

func main() {
	_ = nSqrtN(10000)
}
