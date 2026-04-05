package main

// Test: Binary Search
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(log n) - halves search space each iteration
// Expected Space Complexity: O(1) - only local variables

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func binarySearch(arr []int, target int) int {
	left, right := 0, len(arr)-1
	for left <= right {
		mid := left + (right-left)/2
		if arr[mid] == target {
			return mid
		} else if arr[mid] < target {
			left = mid + 1
		} else {
			right = mid - 1
		}
	}
	return -1
}

func main() {
	arr := []int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
	_ = binarySearch(arr, 7)
}
