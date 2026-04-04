package main

// Test: Two Sum
// Expected Time Complexity: O(n) - single loop with map lookup
// Expected Space Complexity: O(n) - hash map storage
func twoSum(nums []int, target int) []int {
	numMap := make(map[int]int)
	for i, num := range nums {
		if j, found := numMap[target-num]; found {
			return []int{j, i}
		}
		numMap[num] = i
	}
	return []int{-1, -1}
}

func main() {
	nums := []int{2, 7, 11, 15}
	target := 9
	_ = twoSum(nums, target)
}
