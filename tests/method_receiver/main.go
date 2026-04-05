package main

// Test: Method Receivers and Regular Functions
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - regular function contains loop
// Expected Space Complexity: O(1)
// Expected Time Complexity: O(1)
// Expected Space Complexity: O(1)
func (s *Stack) Push(val int) {
	s.items = append(s.items, val)
}

// Test: Method with value receiver
// Expected Time Complexity: O(1)
// Expected Space Complexity: O(1)
func (s Stack) Len() int {
	return len(s.items)
}

// Test: Regular function
// Expected Time Complexity: O(n)
// Expected Space Complexity: O(1)
func regularFunction(n int) int {
	sum := 0
	for i := 0; i < n; i++ {
		sum += i
	}
	return sum
}

// Test: Method on custom type
type Stack struct {
	items []int
}

func main() {
	s := &Stack{}
	s.Push(1)
	_ = s.Len()
	_ = regularFunction(10)
}
