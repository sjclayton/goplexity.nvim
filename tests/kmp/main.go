package main

// Test: KMP String Matching
// Expected Time Complexity: O(n) - analyzer detects linear scan (n=text length)
// Expected Space Complexity: O(m) - LPS array for pattern

func computeLPS(pattern string) []int {
	m := len(pattern)
	lps := make([]int, m)
	length := 0
	i := 1
	for i < m {
		if pattern[i] == pattern[length] {
			length++
			lps[i] = length
			i++
		} else {
			if length > 0 {
				length = lps[length-1]
			} else {
				lps[i] = 0
				i++
			}
		}
	}
	return lps
}

func kmpSearch(text, pattern string) []int {
	n, m := len(text), len(pattern)
	if m == 0 {
		return nil
	}
	lps := computeLPS(pattern)
	var matches []int
	i, j := 0, 0
	for i < n {
		if text[i] == pattern[j] {
			i++
			j++
		}
		if j == m {
			matches = append(matches, i-j)
			j = lps[j-1]
		} else if i < n && text[i] != pattern[j] {
			if j > 0 {
				j = lps[j-1]
			} else {
				i++
			}
		}
	}
	return matches
}

func main() {
	text := "ABABDABACDABABCABAB"
	pattern := "ABABCABAB"
	_ = kmpSearch(text, pattern)
}
