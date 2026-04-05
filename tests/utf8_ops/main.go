package main

import "unicode/utf8"

// Test: UTF-8 encoding operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n)
// Expected Space Complexity: O(1)
func testUTF8(s string) {
	// Expected Time Complexity: O(n)
	utf8.RuneCountInString(s)
	
	// Expected Time Complexity: O(n)
	utf8.ValidString(s)
	
	// Expected Time Complexity: O(n)
	for i := 0; i < len(s); {
		_, size := utf8.DecodeRuneInString(s[i:])
		i += size
	}
}

func main() {
	testUTF8("hello")
}
