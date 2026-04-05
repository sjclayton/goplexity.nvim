package main

import (
	"fmt"
	"os"
	"strings"
)

// Test: fmt Package Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - string formatting and I/O
// Expected Space Complexity: O(n) - string allocations

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
func testFmtOps() {
	s := "hello"

	// fmt.Sprint - O(n)
	_ = fmt.Sprint(s)

	// fmt.Sprintf - O(n)
	_ = fmt.Sprintf("%s world", s)

	// fmt.Print - O(n)
	fmt.Print(s)

	// fmt.Println - O(n)
	fmt.Println(s)

	// fmt.Fprintf - O(n)
	fmt.Fprintf(os.Stdout, "%s", s)

	// fmt.Errorf - O(n)
	_ = fmt.Errorf("error: %s", s)

	// fmt.Scan - O(n)
	r := strings.NewReader(s)
	var sc string
	_, _ = fmt.Fscan(r, &sc)

	// fmt.Sscan - O(n)
	_, _ = fmt.Sscan(s, &sc)

	_ = s
}

func main() {
	testFmtOps()
}
