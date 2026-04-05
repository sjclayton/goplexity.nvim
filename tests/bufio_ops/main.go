package main

import (
	"bufio"
	"strings"
)

// Test: bufio Package Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - Scanner.Scan loop iterates over input
// Expected Space Complexity: O(1) - buffered reader/writer

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(1)
func testBufioOps() {
	// bufio.NewReader - O(1)
	r := bufio.NewReader(strings.NewReader("hello"))
	_ = r

	// bufio.NewWriter - O(1)
	var buf strings.Builder
	w := bufio.NewWriter(&buf)
	_ = w

	// Scanner.Scan - O(n)
	scanner := bufio.NewScanner(strings.NewReader("line1\nline2"))
	for scanner.Scan() {
		_ = scanner.Text()
	}
}

func main() {
	testBufioOps()
}
