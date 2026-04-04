package main

// Test: Map Operations
// Expected Time Complexity: O(n) - map iteration dominates
// Expected Space Complexity: O(n) for map storage
func testMapOperations() {
	// Create map
	counts := make(map[string]int)

	// Insert - O(1) amortized
	counts["apple"]++
	counts["banana"] += 2

	// Lookup - O(1) amortized
	_ = counts["apple"]

	// Delete - O(1) amortized
	delete(counts, "banana")

	// Iterate - O(n)
	for k, v := range counts {
		_ = k
		_ = v
	}

	_ = counts
}

func main() {
	testMapOperations()
}
