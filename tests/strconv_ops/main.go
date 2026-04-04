package main

import "strconv"

// Test: strconv Package Operations
// Expected Time Complexity: O(n) - proportional to number of digits
// Expected Space Complexity: O(1) - returns new strings

func testStrconvOps() {
	// strconv.Atoi - O(n)
	n, _ := strconv.Atoi("12345")
	_ = n

	// strconv.Itoa - O(n)
	_ = strconv.Itoa(12345)

	// strconv.ParseInt - O(n)
	p, _ := strconv.ParseInt("12345", 10, 64)
	_ = p

	// strconv.FormatInt - O(n)
	_ = strconv.FormatInt(12345, 10)
}

func main() {
	testStrconvOps()
}
