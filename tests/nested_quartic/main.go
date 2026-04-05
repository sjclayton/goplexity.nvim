package main

// Test: Four Levels of Nested Loops - O(n⁴)
// Expected Time Complexity: O(n⁴) - four levels of nesting
// Expected Space Complexity: O(1) - no allocations

func quartic(n int) int {
	total := 0
	for i := 0; i < n; i++ {
		for j := 0; j < n; j++ {
			for k := 0; k < n; k++ {
				for l := 0; l < n; l++ {
					total++
				}
			}
		}
	}
	return total
}

func main() {
	_ = quartic(10)
}
