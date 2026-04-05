package main

type BIT struct {
	tree []int
}

// Test: Fenwick Tree (Binary Indexed Tree)
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func (b *BIT) update(i int, delta int) {
	// Expected Time Complexity: O(log n)
	for i < len(b.tree) {
		b.tree[i] += delta
		i += i & -i
	}
}

// Expected Time Complexity: O(log n)
// Expected Space Complexity: O(1)
func (b *BIT) query(i int) int {
	sum := 0
	// Expected Time Complexity: O(log n)
	for i > 0 {
		sum += b.tree[i]
		i -= i & -i
	}
	return sum
}

func main() {
	b := BIT{tree: make([]int, 10)}
	b.update(1, 1)
	b.query(1)
}
