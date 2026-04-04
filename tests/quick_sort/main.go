package main

// Test: Quick Sort
// Expected Time Complexity: O(n log n) average - partition + recursive calls
// Expected Space Complexity: O(log n) - recursion stack
func quickSort(arr []int) []int {
	if len(arr) <= 1 {
		return arr
	}
	pivot := arr[len(arr)/2]
	var left, middle, right []int
	for _, v := range arr {
		switch {
		case v < pivot:
			left = append(left, v)
		case v == pivot:
			middle = append(middle, v)
		case v > pivot:
			right = append(right, v)
		}
	}
	result := make([]int, 0, len(arr))
	result = append(result, quickSort(left)...)
	result = append(result, middle...)
	result = append(result, quickSort(right)...)
	return result
}

func main() {
	arr := []int{10, 7, 8, 9, 1, 5}
	_ = quickSort(arr)
}
