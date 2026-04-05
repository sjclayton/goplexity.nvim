package main

// Test: GCD - Greatest Common Divisor
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(log n) - Euclidean algorithm
// Expected Space Complexity: O(1) - analyzer does not track recursive call stack

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func gcd(a, b int) int {
	if b == 0 {
		return a
	}
	return gcd(b, a%b)
}

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func lcm(a, b int) int {
	return a * b / gcd(a, b)
}

func main() {
	_ = gcd(48, 18)
	_ = lcm(4, 5)
}
