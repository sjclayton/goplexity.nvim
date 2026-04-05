package main

// Test: Longest Common Subsequence (LCS)
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n×m)
// Expected Space Complexity: O(n×m)
func lcs(s1, s2 string) int {
	n := len(s1)
	m := len(s2)
	
	// Create DP table
	// Expected Space Complexity: O(n×m)
	dp := make([][]int, n+1)
	for i := range dp {
		dp[i] = make([]int, m+1)
	}
	
	// Expected Time Complexity: O(n×m)
	for i := 1; i <= n; i++ {
		for j := 1; j <= m; j++ {
			if s1[i-1] == s2[j-1] {
				dp[i][j] = dp[i-1][j-1] + 1
			} else {
				if dp[i-1][j] > dp[i][j-1] {
					dp[i][j] = dp[i-1][j]
				} else {
					dp[i][j] = dp[i][j-1]
				}
			}
		}
	}
	return dp[n][m]
}

func main() {
	lcs("abc", "def")
}
