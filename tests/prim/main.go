package main

// Test: Prim's Minimum Spanning Tree
// Expected Time Complexity: O(V²) - adjacency matrix with min weight selection
// Expected Space Complexity: O(V) - key and visited arrays

func prim(n int, graph [][]int) int {
	key := make([]int, n)
	visited := make([]bool, n)
	for i := 0; i < n; i++ {
		key[i] = 1000000000
	}
	key[0] = 0
	mstWeight := 0

	for count := 0; count < n; count++ {
		// Find minimum weight vertex not in MST
		u := -1
		minWeight := 1000000000
		for v := 0; v < n; v++ {
			if !visited[v] && key[v] < minWeight {
				minWeight = key[v]
				u = v
			}
		}
		if u == -1 {
			break
		}
		visited[u] = true
		mstWeight += minWeight

		// Update adjacent vertices
		for v := 0; v < n; v++ {
			if graph[u][v] > 0 && !visited[v] && graph[u][v] < key[v] {
				key[v] = graph[u][v]
			}
		}
	}
	return mstWeight
}

func main() {
	graph := [][]int{
		{0, 2, 0, 6, 0},
		{2, 0, 3, 8, 5},
		{0, 3, 0, 0, 7},
		{6, 8, 0, 0, 9},
		{0, 5, 7, 9, 0},
	}
	_ = prim(5, graph)
}
