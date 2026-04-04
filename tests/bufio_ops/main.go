package main

import (
	"bufio"
	"strings"
)

// Test: bufio Package Operations
// Expected Time Complexity: O(n) - Scanner.Scan loop iterates over input
// Expected Space Complexity: O(1) - buffered reader/writer

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
