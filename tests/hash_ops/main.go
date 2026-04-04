package main

import (
	"crypto/sha256"
)

// Test: Hash operations
// Expected Time Complexity: O(n) - hashing
// Expected Space Complexity: O(1) - fixed size
func testHashOps() {
	h := sha256.New()
	h.Write([]byte("test"))
	_ = h.Sum(nil)
	_ = h.BlockSize()
	_ = h.Size()
}

func testHashSum() {
	data := []byte("hello world")
	sum := sha256.Sum256(data)
	_ = sum
}

func main() {
	testHashOps()
	testHashSum()
}
