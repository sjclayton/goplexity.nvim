package main

// Test: Constant Loop Bounds
// Expected Time Complexity: O(1) - all loops have literal constant bounds
// Expected Space Complexity: O(1) - no allocations

func constantLoop() int {
	sum := 0
	for i := 0; i < 10; i++ {
		sum += i
	}
	return sum
}

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
