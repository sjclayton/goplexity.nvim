package main

// Test: BFS - Graph Traversal
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(V+E) - visits all vertices and edges
// Expected Space Complexity: O(V) - queue + visited map

// Expected Time Complexity: O(V+E)
// Expected Space Complexity: O(V)
func bfs(graph map[int][]int, start int) []int {
	visited := make(map[int]bool)
	queue := []int{start}
	result := []int{}

	for len(queue) > 0 {
		node := queue[0]
		queue = queue[1:]
		if visited[node] {
			continue
		}
		visited[node] = true
		result = append(result, node)
		for _, neighbor := range graph[node] {
			if !visited[neighbor] {
				queue = append(queue, neighbor)
			}
		}
	}
	return result
}

func main() {
	graph := map[int][]int{
		0: {1, 2},
		1: {0, 3},
		2: {0, 3},
		3: {1, 2},
	}
	_ = bfs(graph, 0)
}
