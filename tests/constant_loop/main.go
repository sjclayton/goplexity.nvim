package main

// Test: Constant Loop Bounds
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(1) - all loops have literal constant bounds
// Expected Space Complexity: O(1) - no allocations

// Expected Time Complexity: O(1)
// Expected Space Complexity: O(1)
func constantLoop() int {
	sum := 0
	for i := 0; i < 10; i++ {
		sum += i
	}
	return sum
}

// Expected Time Complexity: O(1)
// Expected Space Complexity: O(1)
func anotherConstantLoop() int {
	sum := 0
	for i := 0; i < 5; i++ {
		for j := 0; j < 3; j++ {
			sum += i * j
		}
	}
	return sum
}

func main() {
	_ = constantLoop()
	_ = anotherConstantLoop()
}
