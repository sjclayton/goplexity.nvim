package main

// Test: 0/1 Knapsack
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n×m)
// Expected Space Complexity: O(n×m)
func knapsack(W int, weights []int, values []int, n int) int {
	// Expected Space Complexity: O(n×m)
	dp := make([][]int, n+1)
	for i := range dp {
		dp[i] = make([]int, W+1)
	}

	// Expected Time Complexity: O(n×m)
	for i := 1; i <= n; i++ {
		for w := 1; w <= W; w++ {
			if weights[i-1] <= w {
				v1 := values[i-1] + dp[i-1][w-weights[i-1]]
				v2 := dp[i-1][w]
				if v1 > v2 {
					dp[i][w] = v1
				} else {
					dp[i][w] = v2
				}
			} else {
				dp[i][w] = dp[i-1][w]
			}
		}
	}
	return dp[n][W]
}

func main() {
	knapsack(50, []int{10, 20, 30}, []int{60, 100, 120}, 3)
}
