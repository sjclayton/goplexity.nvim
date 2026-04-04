package main

// Test: DFS - Graph Traversal
// Expected Time Complexity: O(V+E) - visits all vertices and edges
// Expected Space Complexity: O(V) - visited map + recursion stack
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
