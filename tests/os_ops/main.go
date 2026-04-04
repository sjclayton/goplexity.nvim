package main

import (
	"os"
)

// Test: OS Package Operations
// Expected Time Complexity: O(n) for read/write, O(1) for open/stat
// Expected Space Complexity: O(n) for read/write
func testFileOps() {
	// os.Open - O(1)
	f, _ := os.Open("test.txt")
	defer f.Close()

	// os.Create - O(1)
	f2, _ := os.Create("test.txt")
	defer f2.Close()

	// os.Stat - O(1)
	_, _ = os.Stat("test.txt")

	// os.Lstat - O(1)
	_, _ = os.Lstat("test.txt")

	// os.ReadFile - O(n)
	_, _ = os.ReadFile("test.txt")

	// os.WriteFile - O(n)
	_ = os.WriteFile("test.txt", []byte("test"), 0644)

	// os.Read - O(n)
	buf := make([]byte, 100)
	_, _ = f.Read(buf)

	// os.Write - O(n)
	_, _ = f2.Write([]byte("data"))

	// os.ReadDir - O(n)
	_, _ = os.ReadDir(".")
}

func main() {
	testFileOps()
}
