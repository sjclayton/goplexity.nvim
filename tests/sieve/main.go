package main

// Test: Sieve of Eratosthenes
// Expected Time Complexity: O(n log log n) - classic sieve
// Expected Space Complexity: O(n) - boolean array
func sieve(n int) []int {
	isPrime := make([]bool, n+1)
	for i := 2; i*i <= n; i++ {
		if !isPrime[i] {
			for j := i * i; j <= n; j += i {
				isPrime[j] = true
			}
		}
	}
	primes := []int{}
	for i := 2; i <= n; i++ {
		if !isPrime[i] {
			primes = append(primes, i)
		}
	}
	return primes
}

func main() {
	_ = sieve(100)
}
