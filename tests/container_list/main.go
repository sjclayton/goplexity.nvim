package main

import (
	"container/list"
)

// Test: Container List Operations
// Expected Time Complexity: O(1) - constant time push/remove
// Expected Space Complexity: O(1) - fixed 11 elements in list
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
