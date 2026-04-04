package main

// Test: Method with pointer receiver
// Expected: Function name should be detected
func (s *Stack) Push(val int) {
	s.items = append(s.items, val)
}

// Test: Method with value receiver
func (s Stack) Len() int {
	return len(s.items)
}

// Test: Regular function
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
