package main

import (
	"maps"
	"slices"
)

// Test: Slices Package Operations
// Expected Time Complexity: O(n log n) for sort, O(n) for others
// Expected Space Complexity: O(n) - new slices
func testSlicesOps() {
	s1 := []int{3, 1, 2}
	slices.Sort(slices.Clone(s1))
	_ = slices.Contains(s1, 1)
	_ = slices.Equal(s1, s1)
	s2 := slices.Delete(s1, 0, 1)
	_ = slices.Insert(s2, 0, 99)
	_ = maps.Keys(map[string]int{"a": 1})
}

func main() {
	testSlicesOps()
}
