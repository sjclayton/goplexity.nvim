package main

import (
	"crypto/sha256"
)

// Test: Hash operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - hashing
// Expected Space Complexity: O(1) - fixed size

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(1)
func testHashOps() {
	h := sha256.New()
	h.Write([]byte("test"))
	_ = h.Sum(nil)
	_ = h.BlockSize()
	_ = h.Size()
}

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(1)
func testHashSum() {
	data := []byte("hello world")
	sum := sha256.Sum256(data)
	_ = sum
}

func main() {
	testHashOps()
	testHashSum()
}
