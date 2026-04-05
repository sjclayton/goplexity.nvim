package main

import (
	"container/heap"
)

// Test: Heap Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n log n) - heapify + n pops
// Expected Space Complexity: O(n) - heap array
type IntHeap []int

func (h IntHeap) Len() int           { return len(h) }
func (h IntHeap) Less(i, j int) bool { return h[i] < h[j] }
func (h IntHeap) Swap(i, j int)      { h[i], h[j] = h[j], h[i] }
func (h *IntHeap) Push(x any) {
	*h = append(*h, x.(int))
}
func (h *IntHeap) Pop() any {
	old := *h
	n := len(old)
	x := old[n-1]
	*h = old[0 : n-1]
	return x
}

// Expected Time Complexity: O(n log n)
// Expected Space Complexity: O(n)
func heapSort(arr []int) []int {
	h := &IntHeap{}
	for _, v := range arr {
		heap.Push(h, v)
	}
	result := make([]int, 0, len(arr))
	for h.Len() > 0 {
		result = append(result, heap.Pop(h).(int))
	}
	return result
}

func main() {
	arr := []int{5, 3, 8, 4, 1}
	_ = heapSort(arr)
}
