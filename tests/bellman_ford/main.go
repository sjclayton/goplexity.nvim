package main

// Test: Bellman-Ford Algorithm
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(V×E) - n-1 iterations over all edges
// Expected Space Complexity: O(V) - distance array

// Expected Time Complexity: O(V×E)
// Expected Space Complexity: O(V)
func bellmanFord(n int, edges [][3]int, start int) []int {
	dist := make([]int, n)
	for i := 0; i < n; i++ {
		dist[i] = 1e9
	}
	dist[start] = 0

	for i := 0; i < n-1; i++ {
		for _, e := range edges {
			u, v, w := e[0], e[1], e[2]
			if dist[u]+w < dist[v] {
				dist[v] = dist[u] + w
			}
		}
	}
	return dist
}

func main() {
	edges := [][3]int{
		{0, 1, 4}, {0, 2, 1}, {1, 2, 2}, {2, 3, 3},
	}
	_ = bellmanFord(4, edges, 0)
}
