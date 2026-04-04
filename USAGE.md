# Usage Guide

## Commands

### Toggle Complexity Hints

```vim
:Goplexity              " Toggle hints (analyze + show/hide)
```

Running `:Goplexity` with no arguments toggles complexity hints on and off. Each time hints are shown, the current buffer is re-analyzed so results are always fresh. Returns `true` if hints are now visible, `false` if hidden.

### Problem Constraints

```vim
:Goplexity constraints <n> [time_ms] [memory_mb]
```

Set problem constraints for TLE/MLE warnings.

**Example:**

```vim
" n=10^5, 2000ms time limit, 256MB memory
:Goplexity constraints 100000 2000 256
```

## Configuration

### Basic Setup

```lua
require('goplexity').setup({
  virtual_text_icon = '🧠',
  virtual_text_hl_group = 'Comment',
  enabled = true,
})
```

### Full Configuration

```lua
require('goplexity').setup({
  -- Visual settings
  virtual_text_icon = '🧠',          -- Icon shown in hints
  virtual_text_hl_group = 'Comment', -- Highlight group
  enabled = true,                     -- Enable by default

  -- Problem constraints
  constraints = {
    n = nil,              -- Problem size
    time_limit_ms = nil,  -- Time limit
    memory_limit_mb = nil, -- Memory limit
  },

  -- Warning thresholds
  thresholds = {
    time_warning = 1e8,   -- Operations per second
    space_warning = 256,  -- MB
  },
})
```

### Custom Keybindings

```lua
vim.keymap.set('n', '<leader>tc', ':Goplexity<CR>', { desc = 'Toggle complexity hints' })
```

## Lua API

Other plugins can toggle Goplexity and check its status via the return value:

```lua
local goplexity = require('goplexity')

-- Toggle hints (returns true if shown, false if hidden)
-- Re-runs analysis each time hints are shown
local visible = goplexity.toggle()
```

## Complexity Patterns

### Time Complexity

| Pattern                           | Complexity     |
| --------------------------------- | -------------- |
| `for i := 0; i < n; i++`          | O(n)           |
| `for _, v := range slice`         | O(n)           |
| `for condition { }`               | O(n)           |
| `for { }`                         | O(n)           |
| `for i := 0; i < 10; i++`         | O(1)           |
| `for i := 0; i < n; i *= 2`       | O(log n)       |
| `for i := 0; i < n; i /= 2`       | O(log n)       |
| `for i := 0; i < n; i <<= 1`      | O(log n)       |
| `for i := 0; i < n; i >>= 1`      | O(log n)       |
| `for i := 0; i < n; i += i`       | O(log n)       |
| `for i := 0; i*i < n; i++`        | O(√n)          |
| Nested: `for { for { } }`         | O(n²)          |
| Nested: `for { for { for { } } }` | O(n³)          |
| `sort.Slice(...)`                 | O(n log n)     |
| `sort.Search(...)`                | O(log n)       |
| `append(...)`                     | O(1) amortized |
| `copy(...)`                       | O(n)           |

### Space Complexity

| Pattern             | Complexity |
| ------------------- | ---------- |
| `make([]int, n)`    | O(n)       |
| `make([]int, 1000)` | O(1)       |
| `make([][]int, n)`  | O(n²)      |
| `make(map[K]V)`     | O(n)       |
| `make(chan T)`      | O(1)       |
| `make(chan T, n)`   | O(n)       |

## Examples

### Basic Analysis

```go
package main

import "sort"

func solve(n int) {
    arr := make([]int, n)

    for i := 0; i < n; i++ {
        arr[i] = i
    }

    sort.Slice(arr, func(i, j int) bool {
        return arr[i] < arr[j]
    })

    for i := 0; i < n; i++ {
        for j := i + 1; j < n; j++ {
            println(arr[i] + arr[j])
        }
    }
}
```

After running `:Goplexity`, you'll see virtual text annotations like:

```go
package main                    // 🧠 Time: O(n²) | Space: O(n)

func solve(n int) {             // 🧠 Time: O(n²) | Space: O(n)
    arr := make([]int, n)

    for i := 0; i < n; i++ {    // 🧠 T:O(n) S:O(1)
        arr[i] = i
    }

    sort.Slice(arr, func(i, j int) bool {  // 🧠 T:O(n log n)
        return arr[i] < arr[j]
    })

    for i := 0; i < n; i++ {    // 🧠 T:O(n²) S:O(1)
        for j := i + 1; j < n; j++ {  // 🧠 T:O(n) S:O(1)
            println(arr[i] + arr[j])
        }
    }
}
```

### Binary Search Pattern

```go
for i := 1; i < n; i *= 2 { // 🧠 T:O(log n) S:O(1)
    println(i)
}
```

### Square Root Loop

```go
for i := 0; i*i < n; i++ { // 🧠 T:O(√n) S:O(1)
    println(i)
}
```

## Tips

1. **Constraints**: Set problem limits with `:Goplexity constraints` for TLE/MLE warnings
