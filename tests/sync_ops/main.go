package main

import "sync"

// Test: Sync Package Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - WaitGroup.Wait detected as O(n) by analyzer
// Expected Space Complexity: O(1) - minimal allocations

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(1)
func testSyncOps() {
	// sync.Mutex - O(1)
	var m sync.Mutex
	m.Lock()
	m.Unlock()

	// sync.WaitGroup - O(1) creation, Wait is O(n)
	var wg sync.WaitGroup
	wg.Add(1)
	wg.Done()
	wg.Wait()

	// sync.Once.Do - O(1)
	var once sync.Once
	once.Do(func() {})
}

func main() {
	testSyncOps()
}
