package main

import "math/big"

// Test: math/big Package Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - big int operations are linear in number of bits
// Expected Space Complexity: O(n) - big int storage

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
func testBigIntOps() {
	// big.NewInt - O(1)
	a := big.NewInt(123456789012345678)
	b := big.NewInt(987654321098765432)

	// Int.Add - O(n)
	c := new(big.Int).Add(a, b)

	// Int.Mul - O(n)
	d := new(big.Int).Mul(a, b)

	// Int.Div - O(n)
	e := new(big.Int).Div(d, a)

	// Int.Sub - O(n)
	f := new(big.Int).Sub(c, e)

	_ = f
}

func main() {
	testBigIntOps()
}
