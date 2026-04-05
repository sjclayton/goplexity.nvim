package main

import (
	"container/heap"
)

// Test: Dijkstra's Algorithm
// Expected Time Complexity: O(E log V) - priority queue operations
// Expected Space Complexity: O(V) - analyzer detects distance array, not PQ growth
type Edge struct {
	to int
	wt int
}
type PriorityQueue []struct {
	node int
	dist int
}

func (pq PriorityQueue) Len() int           { return len(pq) }
func (pq PriorityQueue) Less(i, j int) bool { return pq[i].dist < pq[j].dist }
func (pq PriorityQueue) Swap(i, j int)      { pq[i], pq[j] = pq[j], pq[i] }
func (pq *PriorityQueue) Push(x any) {
	*pq = append(*pq, x.(struct {
		node int
		dist int
	}))
}
func (pq *PriorityQueue) Pop() any {
	old := *pq
	n := len(old)
	item := old[n-1]
	*pq = old[0 : n-1]
	return item
}

func dijkstra(n int, edges [][]Edge, start int) []int {
	dist := make([]int, n)
	for i := range dist {
		dist[i] = 1e9
	}
	dist[start] = 0
	pq := &PriorityQueue{{start, 0}}
	heap.Init(pq)

	for pq.Len() > 0 {
		item := heap.Pop(pq).(struct {
			node int
			dist int
		})
		if item.dist > dist[item.node] {
			continue
		}
		for _, e := range edges[item.node] {
			if dist[e.to] > item.dist+e.wt {
				dist[e.to] = item.dist + e.wt
				heap.Push(pq, struct {
					node int
					dist int
				}{e.to, dist[e.to]})
			}
		}
	}
	return dist
}

func main() {
	n := 4
	edges := make([][]Edge, n)
	edges[0] = []Edge{{1, 1}, {2, 4}}
	edges[1] = []Edge{{2, 2}, {3, 6}}
	edges[2] = []Edge{{3, 3}}
	_ = dijkstra(n, edges, 0)
}
