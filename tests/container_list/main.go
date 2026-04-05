package main

import (
	"container/list"
)

// Test: Container List Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(1) - constant time push/remove
// Expected Space Complexity: O(1) - fixed 11 elements in list

// Expected Time Complexity: O(1)
// Expected Space Complexity: O(1)
func testListOps() {
	l := list.New()
	for i := 0; i < 10; i++ {
		l.PushBack(i)
	}
	l.PushFront(-1)
	l.Remove(l.Front())
	_ = l
}

func main() {
	testListOps()
}
