package main

// Test: Data Structure Declarations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(1) - just allocations
// Expected Space Complexity: O(1) - all allocations use literal sizes

// Expected Time Complexity: O(1)
// Expected Space Complexity: O(1)
func testDataStructures() {
	// Slices
	var emptySlice []int               // O(1) space - nil/header only
	sizedSlice := make([]int, 10)      // O(n) space - allocates n elements
	sliceWithCap := make([]int, 5, 20) // O(n) space - allocates at least n elements

	// Maps
	var emptyMap map[string]int         // O(1) space - nil map
	sizedMap := make(map[string]int, 5) // O(n) space - pre-allocated for n elements

	// Channels
	unbufChan := make(chan int)   // O(1) space - unbuffered
	bufChan := make(chan int, 10) // O(n) space - buffered with n capacity

	// Use variables to avoid unused errors
	_ = emptySlice
	_ = sizedSlice
	_ = sliceWithCap
	_ = emptyMap
	_ = sizedMap
	_ = unbufChan
	_ = bufChan
}

func main() {
	testDataStructures()
}
