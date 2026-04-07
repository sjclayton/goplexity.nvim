package main

import (
	"maps"
	"slices"
)

// Test: Slices Package Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n log n) for sort, O(log n) for binary search, O(n) for others
// Expected Space Complexity: O(n) - new slices

// Expected Time Complexity: O(n log n)
// Expected Space Complexity: O(n)
func testSlicesOps() {
	s1 := []int{3, 1, 2}
	s1Copy := slices.Clone(s1)

	// slices.Sort - O(n log n)
	slices.Sort(s1Copy)

	// slices.SortFunc - O(n log n)
	slices.SortFunc(s1, func(a, b int) int { return a - b })

	// slices.SortStableFunc - O(n log n)
	slices.SortStableFunc(s1, func(a, b int) int { return a - b })

	// slices.Contains - O(n)
	_ = slices.Contains(s1, 1)

	// slices.ContainsFunc - O(n)
	_ = slices.ContainsFunc(s1, func(x int) bool { return x > 0 })

	// slices.Equal - O(n)
	_ = slices.Equal(s1, s1)

	// slices.Delete - O(n)
	s2 := slices.Delete(s1, 0, 1)

	// slices.Insert - O(n)
	_ = slices.Insert(s2, 0, 99)

	// slices.BinarySearch - O(log n)
	_, _ = slices.BinarySearch(s1, 2)

	// slices.BinarySearchFunc - O(log n)
	_, _ = slices.BinarySearchFunc(s1, 2, func(a, b int) int { return a - b })

	// slices.IndexFunc - O(n)
	_ = slices.IndexFunc(s1, func(x int) bool { return x == 2 })

	// maps.Keys - O(n)
	_ = maps.Keys(map[string]int{"a": 1})

	// maps.Values - O(n)
	_ = maps.Values(map[string]int{"a": 1})

	// maps.Equal - O(n)
	_ = maps.Equal(map[string]int{"a": 1}, map[string]int{"a": 1})

	// maps.Clone - O(n)
	_ = maps.Clone(map[string]int{"a": 1})

	// maps.Copy - O(n)
	m := make(map[string]int)
	maps.Copy(m, map[string]int{"a": 1})
	_ = m
}

func main() {
	testSlicesOps()
}
