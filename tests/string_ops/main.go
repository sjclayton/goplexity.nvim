package main

import (
	"strings"
)

// Test: String Operations
// Expected Time Complexity: O(n) for all operations (iterate through string)
// Expected Space Complexity: O(n) for operations that create new strings
func testStringOperations() {
	s := "hello world"

	// strings.Contains - O(n)
	_ = strings.Contains(s, "world")

	// strings.Index - O(n)
	_ = strings.Index(s, "world")

	// strings.Count - O(n)
	_ = strings.Count(s, "l")

	// strings.Replace - O(n)
	_ = strings.Replace(s, "o", "0", -1)

	// strings.Split - O(n)
	_ = strings.Split(s, " ")

	// strings.Join - O(n)
	_ = strings.Join([]string{"a", "b", "c"}, "-")

	// strings.HasPrefix - O(n)
	_ = strings.HasPrefix(s, "hello")

	// strings.HasSuffix - O(n)
	_ = strings.HasSuffix(s, "world")

	// strings.ToLower - O(n)
	_ = strings.ToLower(s)

	// strings.ToUpper - O(n)
	_ = strings.ToUpper(s)

	// strings.Trim - O(n)
	_ = strings.Trim("  hello  ", " ")

	_ = s
}

func main() {
	testStringOperations()
}
