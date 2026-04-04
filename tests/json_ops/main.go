package main

import "encoding/json"

// Test: JSON Marshal and Unmarshal
// Expected Time Complexity: O(n) - linear in data size
// Expected Space Complexity: O(n) - allocations for encoded/decoded data

type Person struct {
	Name string `json:"name"`
	Age  int    `json:"age"`
}

func testJSONOps() {
	// json.Marshal - O(n)
	p := Person{Name: "Alice", Age: 30}
	data, _ := json.Marshal(p)

	// json.Unmarshal - O(n)
	var p2 Person
	_ = json.Unmarshal(data, &p2)
}

func main() {
	testJSONOps()
}
