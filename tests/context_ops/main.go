package main

import (
	"context"
	"time"
)

// Test: Context Package Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(1) - context creation is constant time
// Expected Space Complexity: O(1) - minimal allocations

// Expected Time Complexity: O(1)
// Expected Space Complexity: O(1)
func testContextOps() {
	// context.Background - O(1)
	ctx := context.Background()

	// context.TODO - O(1)
	_ = context.TODO()

	// context.WithTimeout - O(1)
	ctx2, cancel := context.WithTimeout(ctx, 0)
	defer cancel()

	// context.WithCancel - O(1)
	ctx3, cancel2 := context.WithCancel(ctx2)
	defer cancel2()

	// context.WithDeadline - O(1)
	deadline, _ := ctx3.Deadline()
	ctx4, cancel3 := context.WithDeadline(ctx3, deadline.Add(time.Second))
	defer cancel3()

	_ = ctx4
}

func main() {
	testContextOps()
}
