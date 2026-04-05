package main

// Test: Floyd-Warshall Algorithm
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n³) - triple nested loops over vertices
// Expected Space Complexity: O(n²) - distance matrix

// Expected Time Complexity: O(n³)
// Expected Space Complexity: O(n²)
func floydWarshall(n int, graph [][]int) [][]int {
	dist := make([][]int, n)
	for i := 0; i < n; i++ {
		dist[i] = make([]int, n)
		for j := 0; j < n; j++ {
			dist[i][j] = graph[i][j]
		}
	}

	for k := 0; k < n; k++ {
		for i := 0; i < n; i++ {
			for j := 0; j < n; j++ {
				if dist[i][k]+dist[k][j] < dist[i][j] {
					dist[i][j] = dist[i][k] + dist[k][j]
				}
			}
		}
	}
	return dist
}

func main() {
	inf := 1000000000
	graph := [][]int{
		{0, 3, inf, 7},
		{8, 0, 2, inf},
		{5, inf, 0, 1},
		{2, inf, inf, 0},
	}
	_ = floydWarshall(4, graph)
}
