package main

// Test: Union-Find (Disjoint Set Union)
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - NewDSU has O(n) loop, union is O(α(n))
// Expected Space Complexity: O(n) - parent and rank arrays

type DSU struct {
	parent []int
	rank   []int
}

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
func NewDSU(n int) *DSU {
	parent := make([]int, n)
	rank := make([]int, n)
	for i := 0; i < n; i++ {
		parent[i] = i
	}
	return &DSU{parent: parent, rank: rank}
}

// Expected Time Complexity: O(α(n))
// Expected Space Complexity: O(1)
func (d *DSU) find(x int) int {
	if d.parent[x] != x {
		d.parent[x] = d.find(d.parent[x])
	}
	return d.parent[x]
}

// Expected Time Complexity: O(α(n))
// Expected Space Complexity: O(1)
func (d *DSU) union(x, y int) bool {
	px, py := d.find(x), d.find(y)
	if px == py {
		return false
	}
	if d.rank[px] < d.rank[py] {
		px, py = py, px
	}
	d.parent[py] = px
	if d.rank[px] == d.rank[py] {
		d.rank[px]++
	}
	return true
}

func main() {
	dsu := NewDSU(5)
	dsu.union(0, 1)
	dsu.union(2, 3)
	_ = dsu.find(0)
}
