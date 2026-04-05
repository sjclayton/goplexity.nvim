package main

import "bytes"

// Test: Bytes Package Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - all operations iterate through byte slices
// Expected Space Complexity: O(n) - operations that create new slices

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
func testBytesOps() {
	b1 := []byte("hello")
	b2 := []byte("world")

	// bytes.Equal - O(n)
	_ = bytes.Equal(b1, b2)

	// bytes.Compare - O(n)
	_ = bytes.Compare(b1, b2)

	// bytes.Split - O(n)
	_ = bytes.Split([]byte("a,b,c"), []byte(","))

	// bytes.Join - O(n)
	_ = bytes.Join([][]byte{b1, b2}, []byte("-"))

	// bytes.Buffer - O(1) for creation
	var buf bytes.Buffer
	buf.WriteString("test")
	_ = buf.Bytes()
}

func main() {
	testBytesOps()
}
