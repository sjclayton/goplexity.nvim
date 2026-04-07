package main

import "sync"

// Test: Sync Package Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - WaitGroup.Wait and Map operations
// Expected Space Complexity: O(n) - Map storage

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
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

	// sync.Map - Load O(1), Store O(1), Delete O(1)
	var mp sync.Map
	mp.Store("key", "value")
	_, _ = mp.Load("key")
	mp.Delete("key")

	// sync.Map.Range - O(n)
	mp.Store("a", 1)
	mp.Store("b", 2)
	mp.Range(func(key, value any) bool {
		_ = key
		_ = value
		return true
	})

	// sync.Pool - O(1) Get/Put
	pool := sync.Pool{}
	_ = pool.Get()
	pool.Put("item")
}

func main() {
	testSyncOps()
}
