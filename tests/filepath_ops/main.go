package main

import (
	"os"
	"path/filepath"
)

// Test: Filepath operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)

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

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(1)
func testFilepath(p string) {
	// Expected Time Complexity: O(n)
	filepath.Abs(p)

	// Expected Time Complexity: O(n)
	filepath.Base(p)

	// Expected Time Complexity: O(n)
	filepath.Clean(p)

	// Expected Time Complexity: O(n)
	filepath.Ext(p)

	// Expected Time Complexity: O(n)
	filepath.Join(p, "subdir")
}

func main() {
	testFilepathOps()
	testFilepath("/home/user/file.txt")
}
