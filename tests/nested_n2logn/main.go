package main

// Test: Nested O(n² log n) Pattern
// Expected Time Complexity: O(n² log n) - O(n²) outer with O(log n) inner
// Expected Space Complexity: O(1) - no allocations

func n2LogN(n int) int {
	total := 0
	for i := 0; i < n; i++ {
		for j := 0; j < n; j++ {
			for k := 1; k < n; k *= 2 {
				total++
			}
		}
	}
	return total
}

func main() {
	_ = n2LogN(10)
}
