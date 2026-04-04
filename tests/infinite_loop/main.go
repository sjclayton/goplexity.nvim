package main

// Test: Infinite Loop Pattern
// Expected Time Complexity: O(n) - runs until break condition
// Expected Space Complexity: O(1) - no allocations

func infiniteStyle(n int) int {
	i := 0
	sum := 0
	for {
		if i >= n {
			break
		}
		sum += i
		i++
	}
	return sum
}

func main() {
	_ = infiniteStyle(100)
}
