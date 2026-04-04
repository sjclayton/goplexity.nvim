package main

// Test: Segment Tree
// Expected Time Complexity: O(log n) - per query/update
// Expected Space Complexity: O(n) - 4*n array size

type SegmentTree struct {
	tree []int
	n    int
}

func NewSegmentTree(arr []int) *SegmentTree {
	n := len(arr)
	st := &SegmentTree{
		tree: make([]int, 4*n),
		n:    n,
	}
	st.build(arr, 1, 0, n-1)
	return st
}

func (st *SegmentTree) build(arr []int, node, start, end int) {
	if start == end {
		st.tree[node] = arr[start]
		return
	}
	mid := (start + end) / 2
	st.build(arr, 2*node, start, mid)
	st.build(arr, 2*node+1, mid+1, end)
	st.tree[node] = st.tree[2*node] + st.tree[2*node+1]
}

func (st *SegmentTree) query(node, start, end, l, r int) int {
	if r < start || end < l {
		return 0
	}
	if l <= start && end <= r {
		return st.tree[node]
	}
	mid := (start + end) / 2
	return st.query(2*node, start, mid, l, r) +
		st.query(2*node+1, mid+1, end, l, r)
}

func main() {
	arr := []int{1, 3, 5, 7, 9, 11}
	st := NewSegmentTree(arr)
	_ = st.query(1, 0, 5, 1, 3)
}
