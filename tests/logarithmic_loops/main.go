package main

// Test: Logarithmic Loop Patterns
//
// This file tests various log increment patterns.
// All functions are O(log n) individually. countSetBits is O(log n) (Brian Kernighan's algorithm).
// Expected Time Complexity: O(n) - countSetBits detected as O(n) by analyzer
// Expected Space Complexity: O(1) - no allocations

// Expected Time Complexity: O(log n) - i *= 2 in increment
func logMultiply(n int) int {
	count := 0
	for i := 1; i < n; i *= 2 {
		count++
	}
	return count
}

func logDivide(n int) int {
	count := 0
	for i := n; i > 0; i /= 2 {
		count++
	}
	return count
}

func logLeftShift(n int) int {
	count := 0
	for i := 1; i < n; i <<= 1 {
		count++
	}
	return count
}

func logRightShift(n int) int {
	count := 0
	for i := n; i > 0; i >>= 1 {
		count++
	}
	return count
}

func logAssignMultiply(n int) int {
	count := 0
	for i := 1; i < n; {
		count++
		i = i * 2
	}
	return count
}

func logAssignDivide(n int) int {
	count := 0
	for i := n; i > 0; {
		count++
		i = i / 2
	}
	return count
}

func logSelfAdd(n int) int {
	count := 0
	for i := 1; i < n; {
		count++
		i += i
	}
	return count
}

// Expected Time Complexity: O(n) - analyzer does not detect n &= (n-1) as log pattern
func countSetBits(n int) int {
	count := 0
	for n > 0 {
		n &= (n - 1)
		count++
	}
	return count
}

func main() {
	_ = logMultiply(1000)
	_ = logDivide(1000)
	_ = logLeftShift(1000)
	_ = logRightShift(1000)
	_ = logAssignMultiply(1000)
	_ = logAssignDivide(1000)
	_ = logSelfAdd(1000)
	_ = countSetBits(255)
}
