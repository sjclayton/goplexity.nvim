package main

// Test: DFS - Graph Traversal
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(V+E) - visits all vertices and edges
// Expected Space Complexity: O(V) - visited map + recursion stack

// Expected Time Complexity: O(V+E)
// Expected Space Complexity: O(V)
func dfs(graph map[int][]int, node int, visited map[int]bool) {
	if visited[node] {
		return
	}
	visited[node] = true
	for _, neighbor := range graph[node] {
		dfs(graph, neighbor, visited)
	}
}

func main() {
	graph := map[int][]int{
		0: {1, 2},
		1: {0, 3},
		2: {0, 3},
		3: {1, 2},
	}
	visited := make(map[int]bool)
	dfs(graph, 0, visited)
}
