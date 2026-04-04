package main

// Test: Bubble Sort
// Expected Time Complexity: O(n²) - nested loops
// Expected Space Complexity: O(1) - sorts in-place
func bubbleSort(arr []int) []int {
	n := len(arr)
	for i := 0; i < n-1; i++ {
		for j := 0; j < n-i-1; j++ {
			if arr[j] > arr[j+1] {
				arr[j], arr[j+1] = arr[j+1], arr[j]
			}
		}
	}
	return arr
}

// Test: Selection Sort
// Expected Time Complexity: O(n²) - nested loops
// Expected Space Complexity: O(1) - sorts in-place
func selectionSort(arr []int) []int {
	n := len(arr)
	for i := 0; i < n-1; i++ {
		minIdx := i
		for j := i + 1; j < n; j++ {
			if arr[j] < arr[minIdx] {
				minIdx = j
			}
		}
		arr[i], arr[minIdx] = arr[minIdx], arr[i]
	}
	return arr
}

func main() {
	arr := []int{64, 34, 25, 12, 22, 11, 90}
	_ = bubbleSort(arr)
	_ = selectionSort(arr)
}
