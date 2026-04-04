package main

// Test: Trie (Prefix Tree)
// Expected Time Complexity: O(n) - Insert/Search iterate over string characters
// Expected Space Complexity: O(n) - children map allocations

type TrieNode struct {
	children map[rune]*TrieNode
	isEnd    bool
}

func NewTrieNode() *TrieNode {
	return &TrieNode{children: make(map[rune]*TrieNode)}
}

func (t *TrieNode) Insert(word string) {
	node := t
	for _, ch := range word {
		if node.children[ch] == nil {
			node.children[ch] = NewTrieNode()
		}
		node = node.children[ch]
	}
	node.isEnd = true
}

func (t *TrieNode) Search(word string) bool {
	node := t
	for _, ch := range word {
		if node.children[ch] == nil {
			return false
		}
		node = node.children[ch]
	}
	return node.isEnd
}

func main() {
	trie := NewTrieNode()
	trie.Insert("hello")
	trie.Insert("world")
	_ = trie.Search("hello")
}
