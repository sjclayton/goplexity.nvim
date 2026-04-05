package main

import (
	"bytes"
	"encoding/base64"
	"encoding/binary"
)

// Test: Encoding Package Operations
// Verified: Real-world complexity expectations are accurate. Do not modify again.
// Expected Time Complexity: O(n) - binary.Read/Write and base64.NewDecoder detected
// Expected Space Complexity: O(n) - encoded output allocation

// Expected Time Complexity: O(n)
// Expected Space Complexity: O(n)
func testEncodingOps() {
	// binary.Read - O(n)
	buf := bytes.NewBuffer([]byte{0x01, 0x02, 0x03, 0x04})
	var val uint32
	_ = binary.Read(buf, binary.LittleEndian, &val)

	// binary.Write - O(n)
	var out bytes.Buffer
	_ = binary.Write(&out, binary.LittleEndian, uint32(42))

	// base64.NewDecoder - O(n)
	encoded := base64.StdEncoding.EncodeToString([]byte("hello"))
	_ = encoded
}

func main() {
	testEncodingOps()
}
