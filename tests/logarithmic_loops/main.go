package main

// Test: Logarithmic Loop Patterns
// Expected Time Complexity: O(n) - mix of log and linear patterns (body-based updates not detected)
// Expected Space Complexity: O(1) - no allocations

// i *= 2 pattern - O(log n)
func logMultiply(n int) int {
	count := 0
	for i := 1; i < n; i *= 2 {
		count++
	}
	return count
}

// i /= 2 pattern
func logDivide(n int) int {
	count := 0
	for i := n; i > 0; i /= 2 {
		count++
	}
	return count
}

// i <<= 1 pattern (left shift = multiply by 2)
func logLeftShift(n int) int {
	count := 0
	for i := 1; i < n; i <<= 1 {
		count++
	}
	return count
}

// i >>= 1 pattern (right shift = divide by 2)
func logRightShift(n int) int {
	count := 0
	for i := n; i > 0; i >>= 1 {
		count++
	}
	return count
}

// i = i * 2 pattern
func logAssignMultiply(n int) int {
	count := 0
	for i := 1; i < n; {
		count++
		i = i * 2
	}
	return count
}

// i = i / 2 pattern
func logAssignDivide(n int) int {
	count := 0
	for i := n; i > 0; {
		count++
		i = i / 2
	}
	return count
}

// i += i pattern (self-doubling)
func logSelfAdd(n int) int {
	count := 0
	for i := 1; i < n; {
		count++
		i += i
	}
	return count
}

// i &= (i-1) pattern (Brian Kernighan's - counts set bits)
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
