package main

// Test: Linear Search
// Expected Time Complexity: O(n) - single loop iterating through array
// Expected Space Complexity: O(1) - only local variables
func linearSearch(arr []int, target int) int {
	for i, v := range arr {
		if v == target {
			return i
		}
	}
	return -1
}

func main() {
	arr := []int{1, 2, 3, 4, 5}
	_ = linearSearch(arr, 3)
}
