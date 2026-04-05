package main

import "reflect"

// Test: Reflect operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n)
// Expected Space Complexity: O(1)
func testReflect(v1, v2 interface{}) {
	// Expected Time Complexity: O(n)
	reflect.DeepEqual(v1, v2)
	
	// Expected Time Complexity: O(1)
	reflect.TypeOf(v1)
	
	// Expected Time Complexity: O(1)
	reflect.ValueOf(v2)
}

func main() {
	testReflect(1, 2)
}
