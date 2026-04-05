package main

// Test: Kadane's Algorithm
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n)
// Expected Space Complexity: O(1)
func maxSubArray(nums []int) int {
	maxSoFar := nums[0]
	currentMax := nums[0]
	
	// Expected Time Complexity: O(n)
	for i := 1; i < len(nums); i++ {
		currentMax += nums[i]
		if currentMax < nums[i] {
			currentMax = nums[i]
		}
		if maxSoFar < currentMax {
			maxSoFar = currentMax
		}
	}
	return maxSoFar
}

func main() {
	maxSubArray([]int{-2, 1, -3, 4, -1, 2, 1, -5, 4})
}
