package main

import (
	"sort"
)

// Test: Go Built-in Sort Functions
// Expected Time Complexity: O(n log n) for sort, O(log n) for search, O(n) for check
// Expected Space Complexity: O(n) for sort (creates copy), O(1) for others
func testBuiltInSort() {
	data := []int{5, 2, 8, 1, 9, 3}

	// sort.Ints - O(n log n)
	sorted := make([]int, len(data))
	copy(sorted, data)
	sort.Ints(sorted)

	// sort.Search - O(log n)
	idx := sort.Search(len(sorted), func(i int) bool { return sorted[i] >= 5 })
	_ = idx

	// sort.IntsAreSorted - O(n)
	isSorted := sort.IntsAreSorted(sorted)
	_ = isSorted
}

func main() {
	testBuiltInSort()
}
