package main

import "sort"

// Test: Advanced Sort Package Operations
// Expected Time Complexity: O(n log n) for sort operations, O(n) for checks
// Expected Space Complexity: O(1) - no new allocations

func testAdvancedSort() {
	data := []int{5, 2, 8, 1, 9, 3}

	// sort.Slice - O(n log n)
	sort.Slice(data, func(i, j int) bool { return data[i] < data[j] })

	// sort.SliceStable - O(n log n)
	sort.SliceStable(data, func(i, j int) bool { return data[i] < data[j] })

	// sort.Strings - O(n log n)
	strs := []string{"banana", "apple", "cherry"}
	sort.Strings(strs)

	// sort.SearchInts - O(log n)
	_ = sort.SearchInts(data, 5)

	// sort.SearchFloat64s - O(log n)
	floats := []float64{1.1, 2.2, 3.3}
	_ = sort.SearchFloat64s(floats, 2.2)

	// sort.IsSorted - O(n)
	_ = sort.IsSorted(sort.IntSlice(data))

	// sort.Reverse - O(1)
	_ = sort.Reverse(sort.IntSlice(data))
}

func main() {
	testAdvancedSort()
}
