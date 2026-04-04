package main

import (
	"math"
)

// Test: Math Operations
// Expected Time Complexity: O(1) - constant time math operations
// Expected Space Complexity: O(1) - local variables only
func testMathOps() {
	_ = math.Abs(-5)
	_ = math.Max(3.0, 5.0)
	_ = math.Min(3.0, 5.0)
	_ = math.Ceil(3.4)
	_ = math.Floor(3.7)
	_ = math.Round(3.5)
	_ = math.Pow(2.0, 10.0)
	_ = math.Sqrt(16.0)
	_ = math.Log(2.718)
	_ = math.Exp(1.0)
	_ = math.Sin(math.Pi / 2)
	_ = math.Cos(0)
	_ = math.Tan(math.Pi / 4)
	_ = math.Atan2(1.0, 1.0)
}

func main() {
	testMathOps()
}
