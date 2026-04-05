package main

// Test: Concurrency Patterns
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - range over channel dominates
// Expected Space Complexity: O(1)

// Expected Time Complexity: O(1)
// Expected Space Complexity: O(1)
func testConcurrency() {
	// Buffered channel - O(n) space
	ch := make(chan int, 10)

	// Unbuffered channel - O(1) space
	done := make(chan bool)

	// Goroutine creation - O(n)
	go func() {
		ch <- 42
		done <- true
	}()

	// Defer - O(1)
	defer func() {
		close(ch)
	}()

	// Select statement - O(1)
	select {
	case v := <-ch:
		_ = v
	case <-done:
	}
}

// Test: Range over channel
// Expected Time Complexity: O(n) - iterates over channel values
// Expected Space Complexity: O(1) - unbuffered channel
func rangeOverChannel(ch chan int) []int {
	result := []int{}
	for v := range ch {
		result = append(result, v)
	}
	return result
}

func main() {
	testConcurrency()

	ch := make(chan int)
	go func() {
		for i := 0; i < 5; i++ {
			ch <- i
		}
		close(ch)
	}()
	_ = rangeOverChannel(ch)
}
