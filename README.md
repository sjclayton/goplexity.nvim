# goplexity.nvim

Complexity analyzer for Golang

## Features

- **Inline complexity hints** - Displays time complexity on every loop and function call
- **Overall complexity summary** - Shows `Time: O(n log n) | Space: O(n)` at the top of your file
- **Comprehensive pattern detection** - 100+ Go patterns including stdlib, algorithms, and data structures
- **Nested operation support** - Correctly handles sort inside loops, multiple nested structures
- **Per-function analysis** - Shows complexity for each function with time and space
- **Zero dependencies** - Fully offline, no external tools required

## Supported Patterns

### Time Complexity Detection

- **Loops**: traditional `for i:=0; i<n; i++`, range-based `for _, v := range`, condition-based `for condition`
- **Sorting**: `sort.Slice`, `sort.Search`, `sort.Ints`, heap operations
- **Containers**: slices, maps, channels, `container/list`
- **Strings**: `strings.Split`, `strings.Join`, `strings.Contains`, `strings.Index`, and 20+ more
- **Bytes**: `bytes.*` operations
- **Math**: `math.*`, `bits.*`, `math/big`
- **I/O**: `fmt.*`, `os.*`, `bufio`, `ioutil`, `io`
- **Encoding**: `json`, `encoding/binary`
- **Hashing**: `crypto/*`, `hash` package
- **Concurrency**: `sync.*`, `context.*`, goroutines with `go`
- **Algorithms**: DFS, BFS, Dijkstra, Merge Sort, Quick Sort, Sieve, GCD, and more

### Space Complexity Detection

- Slices: `make([]int, n)`, `[]int`, `make([]int, 0, n)`
- Maps: `make(map[K]V)`, `map[K]V`
- Channels: `make(chan T)`, `make(chan T, buffer)`
- 2D structures: `[][]int`, `[]map[K]V`
- Correctly identifies O(1) for functions without allocations

## Installation

```lua
-- lazy.nvim
{
  'sjclayton/goplexity.nvim',
  config = function()
    require('goplexity').setup()
  end,
  cmd = 'Goplexity',
  ft = { 'go' },
}
```

## Quick Start

```vim
:Goplexity complexity   " Analyze code complexity
:Goplexity toggle       " Show/hide hints
:Goplexity hide         " Hide complexity hints
:Goplexity constraints 100000 2000 256  " Set problem constraints (n, time_ms, memory_mb)
```

## Configuration

```lua
require('goplexity').setup({
  virtual_text_icon = '🧠',
  virtual_text_hl_group = 'Comment',
  enabled = true,
  constraints = {
    n = nil,
    time_limit_ms = nil,
    memory_limit_mb = nil,
  },
  thresholds = {
    time_warning = 1e8,
    space_warning = 256,
  },
})
```

## Keybindings

```lua
vim.keymap.set('n', '<leader>tc', ':Goplexity complexity<CR>', { desc = 'Analyze complexity' })
vim.keymap.set('n', '<leader>tt', ':Goplexity toggle<CR>', { desc = 'Toggle hints' })
```

## Requirements

- Neovim 0.8+

## License

MIT
