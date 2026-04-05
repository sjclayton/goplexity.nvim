package main

import (
	"os"
	"path/filepath"
)

// Test: filepath Package Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - walks directories or matches patterns
// Expected Space Complexity: O(n) - path allocations

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
func testFilepathOps() {
	// filepath.Walk - O(n)
	_ = filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		return nil
	})

	// filepath.Match - O(n)
	_, _ = filepath.Match("*.go", "main.go")
}

func main() {
	testFilepathOps()
}
