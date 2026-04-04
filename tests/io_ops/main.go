package main

import (
	"io"
	"strings"
)

// Test: I/O Package Operations
// Expected Time Complexity: O(n) - reading and copying data
// Expected Space Complexity: O(n) - buffer allocations
func testIOOps() {
	src := strings.NewReader("hello world")

	// io.ReadFull - O(n)
	buf := make([]byte, 5)
	_, _ = io.ReadFull(src, buf)

	// io.Copy - O(n)
	var dst strings.Builder
	src2 := strings.NewReader("test data")
	_, _ = io.Copy(&dst, src2)
}

func main() {
	testIOOps()
}
