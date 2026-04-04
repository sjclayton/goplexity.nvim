package main

import (
	"regexp"
)

// Test: Regexp Operations
// Expected Time Complexity: O(n) - regex matching is linear in input size
// Expected Space Complexity: O(n) - compiled regex + matches
func testRegexpOps() {
	re, _ := regexp.Compile(`\d+`)
	_ = re.MatchString("abc123def")
	_ = re.FindString("abc123def")
	_ = re.FindAllString("abc123def456", -1)
	_ = re.ReplaceAllString("abc123", "NUM")
}

func main() {
	testRegexpOps()
}
