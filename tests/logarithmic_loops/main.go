package main

// Test: Logarithmic Loop Patterns
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func logMultiply(n int) int {
	count := 0
	for i := 1; i < n; i *= 2 {
		count++
	}
	return count
}

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func logDivide(n int) int {
	count := 0
	for i := n; i > 0; i /= 2 {
		count++
	}
	return count
}

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func logLeftShift(n int) int {
	count := 0
	for i := 1; i < n; i <<= 1 {
		count++
	}
	return count
}

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func logRightShift(n int) int {
	count := 0
	for i := n; i > 0; i >>= 1 {
		count++
	}
	return count
}

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func logAssignMultiply(n int) int {
	count := 0
	for i := 1; i < n; {
		count++
		i = i * 2
	}
	return count
}

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func logAssignDivide(n int) int {
	count := 0
	for i := n; i > 0; {
		count++
		i = i / 2
	}
	return count
}

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func logSelfAdd(n int) int {
	count := 0
	for i := 1; i < n; {
		count++
		i += i
	}
	return count
}

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
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
