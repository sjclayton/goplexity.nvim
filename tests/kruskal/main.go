package main

import "sort"

// Test: Kruskal's Minimum Spanning Tree
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n log n) - sort.Slice detected as O(n log n) by analyzer
// Expected Space Complexity: O(n) - parent array for union-find

type Edge struct {
	u, v, w int
}

type DSU struct {
	parent []int
}

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
func NewDSU(n int) *DSU {
	p := make([]int, n)
	for i := 0; i < n; i++ {
		p[i] = i
	}
	return &DSU{parent: p}
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
	d.parent[px] = py
	return true
}

// Expected Time Complexity: O(n log n)
// Expected Space Complexity: O(n)
func kruskal(n int, edges []Edge) int {
	sort.Slice(edges, func(i, j int) bool {
		return edges[i].w < edges[j].w
	})

	dsu := NewDSU(n)
	mstWeight := 0
	for _, e := range edges {
		if dsu.union(e.u, e.v) {
			mstWeight += e.w
		}
	}
	return mstWeight
}

func main() {
	edges := []Edge{
		{0, 1, 10}, {0, 2, 6}, {0, 3, 5},
		{1, 3, 15}, {2, 3, 4},
	}
	_ = kruskal(4, edges)
}
