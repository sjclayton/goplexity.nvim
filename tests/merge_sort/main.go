package main

// Test: Merge Sort
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n log n) - divide (log n) + merge (n)
// Expected Space Complexity: O(n) - additional array for merging
func mergeSort(arr []int) []int {
	if len(arr) <= 1 {
		return arr
	}
	mid := len(arr) / 2
	left := mergeSort(arr[:mid])
	right := mergeSort(arr[mid:])
	return merge(left, right)
}

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
func merge(left, right []int) []int {
	result := make([]int, 0, len(left)+len(right))
	i, j := 0, 0
	for i < len(left) && j < len(right) {
		if left[i] <= right[j] {
			result = append(result, left[i])
			i++
		} else {
			result = append(result, right[j])
			j++
		}
	}
	result = append(result, left[i:]...)
	result = append(result, right[j:]...)
	return result
}

func main() {
	arr := []int{12, 11, 13, 5, 6, 7}
	_ = mergeSort(arr)
}
