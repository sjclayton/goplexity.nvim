package main

// Test: GCD - Greatest Common Divisor
// Expected Time Complexity: O(log n) - Euclidean algorithm
// Expected Space Complexity: O(1) - iterative analysis shows no allocations
func gcd(a, b int) int {
	if b == 0 {
		return a
	}
	return gcd(b, a%b)
}

func lcm(a, b int) int {
	return a * b / gcd(a, b)
}

func main() {
	_ = gcd(48, 18)
	_ = lcm(4, 5)
}
