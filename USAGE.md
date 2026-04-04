# Usage Guide

## Commands

### Complexity Analysis

```vim
:Goplexity complexity
```

Analyzes the current buffer and displays inline complexity hints as virtual text.

### Visibility Control

```vim
:Goplexity hide       " Remove all hints
:Goplexity toggle     " Toggle visibility
```

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
vim.keymap.set('n', '<leader>tc', ':Goplexity complexity<CR>', { desc = 'Analyze complexity' })
vim.keymap.set('n', '<leader>tt', ':Goplexity toggle<CR>', { desc = 'Toggle hints' })
```

## Complexity Patterns

### Time Complexity

| Pattern                     | Complexity     |
| --------------------------- | -------------- |
| `for i := 0; i < n; i++`    | O(n)           |
| `for i := 0; i < n; i *= 2` | O(log n)       |
| `for i := 0; i < n; i /= 2` | O(log n)       |
| `for i := 0; i*i < n; i++`  | O(√n)          |
| Nested: `for { for { } }`   | O(n²)          |
| `sort.Slice(...)`           | O(n log n)     |
| `sort.Search(...)`          | O(log n)       |
| `append(...)`               | O(1) amortized |
| `copy(...)`                 | O(n)           |

### Space Complexity

| Pattern             | Complexity |
| ------------------- | ---------- |
| `make([]int, n)`    | O(n)       |
| `make([]int, 1000)` | O(1)       |
| `make([][]int, n)`  | O(n²)      |
| `make(map[K]V)`     | O(n)       |
| `make(chan T)`      | O(1)       |

## Examples

### Basic Analysis

```go
package main

func solve(n int) {
    arr := make([]int, n)  // Space: O(n)

    for i := 0; i < n; i++ {  // 🧠 O(n)
        arr[i] = i
    }

    sort.Slice(arr, func(i, j int) bool {  // 🧠 O(n log n)
        return arr[i] < arr[j]
    })

    for i := 0; i < n; i++ {  // 🧠 O(n²)
        for j := i + 1; j < n; j++ {
            println(arr[i] + arr[j])
        }
    }
}
```

After running `:Goplexity complexity`, you'll see:

- `🧠 Time: O(n²) | Space: O(n)` at the top of the file
- Individual complexity hints beside each loop: `🧠 T:O(n)`
- Per-function complexity summaries at each function definition

### Binary Search Pattern

```go
for i := 1; i < n; i *= 2 { // 🧠 O(log n)
    println(i)
}
```

### Square Root Loop

```go
for i := 0; i*i < n; i++ { // 🧠 O(√n)
    println(i)
}
```

## Tips

1. **Constraints**: Set problem limits with `:Goplexity constraints` for warnings
2. **Toggle**: Use `:Goplexity toggle` to hide hints while focusing on logic
