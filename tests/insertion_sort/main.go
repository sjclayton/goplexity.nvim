package main

// Test: Insertion Sort
// Expected Time Complexity: O(n²) - nested loops (outer + inner while)
// Expected Space Complexity: O(1) - sorts in-place
func insertionSort(arr []int) []int {
	for i := 1; i < len(arr); i++ {
		key := arr[i]
		j := i - 1
		for j >= 0 && arr[j] > key {
			arr[j+1] = arr[j]
			j--
		}
		arr[j+1] = key
	}
	return arr
}

func main() {
	arr := []int{12, 11, 13, 5, 6}
	_ = insertionSort(arr)
}
