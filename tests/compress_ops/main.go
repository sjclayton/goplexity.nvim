package main

import (
	"bytes"
	"compress/gzip"
)

// Test: Compress/Gzip Operations
// Expected Time Complexity: O(n) - gzip.NewWriter, gzip.NewReader detected
// Expected Space Complexity: O(n) - compressed output allocation
func testCompressOps() {
	// gzip.NewWriter - O(n)
	var buf bytes.Buffer
	w := gzip.NewWriter(&buf)
	w.Write([]byte("test data"))
	w.Close()

	// gzip.NewReader - O(n)
	r, _ := gzip.NewReader(&buf)
	defer r.Close()
}

func main() {
	testCompressOps()
}
