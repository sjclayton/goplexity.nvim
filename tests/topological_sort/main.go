package main

// Test: Topological Sort (Kahn's Algorithm)
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(V+E) - visits all vertices and edges once
// Expected Space Complexity: O(V) - in-degree array + queue

// Expected Time Complexity: O(V+E)
// Expected Space Complexity: O(V)
func topologicalSort(n int, adj map[int][]int) []int {
	indegree := make(map[int]int)
	for i := 0; i < n; i++ {
		indegree[i] = 0
	}
	for u := range adj {
		for _, v := range adj[u] {
			indegree[v]++
		}
	}

	queue := []int{}
	for i := 0; i < n; i++ {
		if indegree[i] == 0 {
			queue = append(queue, i)
		}
	}

	result := []int{}
	for len(queue) > 0 {
		node := queue[0]
		queue = queue[1:]
		result = append(result, node)
		for _, neighbor := range adj[node] {
			indegree[neighbor]--
			if indegree[neighbor] == 0 {
				queue = append(queue, neighbor)
			}
		}
	}
	return result
}

func main() {
	adj := map[int][]int{
		0: {1, 2},
		1: {3},
		2: {3},
		3: {},
	}
	_ = topologicalSort(4, adj)
}
