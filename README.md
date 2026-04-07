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

- **Loops**: traditional `for i:=0; i<n; i++`, range-based `for _, v := range`, condition-based `for condition`, infinite `for { }`, and constant-bound `for i := 0; i < 10; i++` → O(1)
- **Logarithmic loops**: `i *= 2`, `i /= 2`, `i <<= 1`, `i >>= 1`, `i += i` → O(log n)
- **Square root loops**: `i * i <= n` condition → O(√n)
- **Nested complexity multiplication**: correctly computes O(n²), O(n³), O(n log n), O(n² log n), O(n² log log n), O(log² n), O(n√n), O(n × 2^n), O(n × n!)
- **Sorting**: `sort.Slice, SliceStable, Ints, Strings, Search` -> O(log n), `sort.SearchInts, SearchFloat64s, IsSorted, IntsAreSorted` -> O(n), `sort.Reverse` -> O(1)
- **Containers**: `container/list.New, PushBack, PushFront, Remove` -> O(1), `container/ring.New, Len, Move` -> O(n), `container/heap.Init` -> O(n), `container/heap.Push, Pop` -> O(log n)
- **Strings**: `strings.Split, Join, Contains, Index, ToLower, ToUpper, Trim, Replace, Count, HasPrefix, HasSuffix` -> O(n), `strings.Builder, NewReader` -> O(n)
- **Bytes**: `bytes.Split, Join` -> O(n), `bytes.Equal, Compare` -> O(n), `bytes.NewBuffer` -> O(1), `bytes.Buffer.WriteString` -> O(n)
- **Math**: `math.Abs, Max, Min, Ceil, Floor, Round, Pow, Sqrt, Log, Exp, Sin, Cos, Tan, Atan2, Pi` -> O(1), `math/bits.OnesCount, LeadingZeros, TrailingZeros, RotateLeft` -> O(1), `math/big.NewInt` -> O(1), `big.Int.Add, Mul, Div, Sub` -> O(n)
- **I/O**: `fmt.Print, Println, Printf` -> O(n), `fmt.Sprint, Sprintf, Errorf` -> O(n), `fmt.Scan, Fscan, Sscan, Scanf` -> O(n), `os.Open, Create, Stat, Lstat, ReadFile, WriteFile, Read, Write, ReadDir` -> O(n), `bufio.NewReader, NewWriter, NewScanner` -> O(1), `io.ReadFull, Copy` -> O(n)
- **Encoding**: `json.Marshal, Unmarshal` -> O(n), `encoding/binary.Read, Write, LittleEndian` -> O(n), `base64.NewDecoder, NewEncoder` -> O(n)
- **Hashing**: `crypto/sha256.New, Sum256` -> O(n), `crypto/md5.Sum` -> O(n), `hash.New` -> O(n), `hash.Hash.BlockSize, Size` -> O(1)
- **Concurrency**: `go` goroutines, `defer`, `select { }`, buffered/unbuffered channels -> O(1)
- **Context**: `context.Background, TODO, WithTimeout, WithCancel, WithDeadline` -> O(1)
- **Filepath**: `filepath.Walk, Match, WalkDir` -> O(n), `filepath.Abs, Base, Clean, Ext, Join` -> O(n)
- **Reflect**: `reflect.DeepEqual` -> O(n), `reflect.TypeOf, ValueOf` -> O(1)
- **Random**: `rand.Shuffle, Perm` -> O(n)
- **Sync**: `sync.Map.Range` -> O(n), `sync.Map.Load, Store, Delete` -> O(1), `sync.Mutex.Lock, Unlock` -> O(1), `sync.Pool.Get, Put` -> O(1), `sync.WaitGroup.Add, Done, Wait` -> O(n), `sync.Once.Do` -> O(1)
- **Unicode/UTF8**: `utf8.DecodeRuneInString, RuneCountInString, ValidString` -> O(n)
- **Strconv**: `strconv.Atoi, Itoa, ParseInt, FormatInt` -> O(n)
- **Regexp**: `regexp.Compile, MustCompile` -> O(n), `regexp.MatchString, Find, FindAllString, ReplaceAllString` -> O(n)
- **Compress**: `gzip.NewWriter, NewReader` -> O(n)
- **Slices & Maps**: `slices.Sort, SortFunc, SortStableFunc` -> O(n log n), `slices.BinarySearch, BinarySearchFunc` -> O(log n), `slices.Contains, Equal, Clone, Delete, Insert, ContainsFunc, IndexFunc, Index` -> O(n), `maps.Keys, Values, Equal, Clone, Copy` -> O(n)
- **Builtins**: `append`, `delete`, `len`, `cap` -> O(1), `copy` -> O(n), `make` (allocations -> O(n), capacity-only -> O(1))
- **Time**: `time.Now, Sleep, Since, Until, Second, Hour` -> O(1)
- **Algorithms**:
  - Graph: DFS O(V+E), BFS O(V+E), Dijkstra O(E log V), Bellman-Ford O(V×E), Floyd-Warshall O(n³), Topological Sort O(V+E), Kruskal's MST O(E log E), Prim's MST O(V²)
  - Sorting: Merge Sort O(n log n), Quick Sort O(n log n), Heap Sort O(n log n)
  - Data structures: Union-Find/DSU O(α(n)), Trie O(L), Segment Tree O(log n)
  - String matching: KMP O(n)
  - Dynamic Programming: Kadane's O(n), Longest Common Subsequence (LCS) O(n×m), 0/1 Knapsack O(n×W)
  - Number theory: Sieve of Eratosthenes O(n log log n), GCD O(log n)
  - Data structures: Binary Indexed Tree (Fenwick) O(log n), Sparse Table O(n log n) preprocessing / O(1) query
  - Searching: Binary Search O(log n)

### Space Complexity Detection

- Slices: `make([]int, n)`, `make([]int, 0, n)` -> O(n)
- Maps: `make(map[K]V)` -> O(n)
- Channels: `make(chan T)`, `make(chan T, buffer)` -> O(n) for buffered, O(1) for unbuffered
- Allocations: `new(Type)` → O(1)
- 2D structures: `make([][]int, n)` → O(n²), `make([]map[K]V, n)` → O(n²)
- Correctly excludes function signature parameters (references, not allocations)
- Correctly excludes small slice/map literals (`[]int{1, 2, 3}`)
- Correctly identifies O(1) for functions without allocations

## Installation

```lua
-- lazy.nvim
{
  'sjclayton/goplexity.nvim',
  ft = { 'go' },
}
```

## Quick Start

```vim
:Goplexity              " Toggle complexity hints (analyze + show/hide)
:Goplexity constraints 100000 2000 256  " Set problem constraints (n, time_ms, memory_mb)
```

Running `:Goplexity` toggles hints on and off. Each time hints are shown, the
buffer is re-analyzed so results are always fresh.

### Output Example

```go
package main                    // 🧠 Time: O(n²) | Space: O(n)

import "sort"

func solve(n int) {             // 🧠 Time: O(n²) | Space: O(n)
    arr := make([]int, n)           // 🧠 T:O(n)
    for i := 0; i < n; i++ {        // 🧠 T:O(n) S:O(1)
        arr[i] = i
    }

    sort.Slice(arr, func(i, j int) bool {  // 🧠 T:O(n log n)
        return arr[i] < arr[j]
    })

    for i := 0; i < n; i++ {        // 🧠 T:O(n) S:O(1)
        for j := i + 1; j < n; j++ { // 🧠 T:O(n²) S:O(1)
            println(arr[i] + arr[j])
        }
    }
}
```

### Constraint Warnings

When `n`, `time_limit_ms`, and/or `memory_limit_mb` are set via `:Goplexity
constraints` or `setup()`, the plugin warns if the detected complexity may
exceed your limits:

```
⚠️  Time: O(n²) (~1.00e+11 ops) may exceed limit (1000ms)
⚠️  Space: O(n²) (~250000000.0 MB) may exceed limit (256MB)
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

## Requirements

- Neovim 0.12+
- Treesitter (Main branch / Neovim built-in)
- Go treesitter parser installed (`:TSInstall go`)

## Running Tests

The plugin includes two test suites run headlessly via Neovim:

```bash
# Main suite: 73 tests covering all audited algorithm/syntax patterns
nvim --headless --clean --cmd "set rtp+=~/.local/share/nvim/site" -u tests/test_runner.lua 2>&1

# Integration suite: 80 tests covering (constraint warnings,
# memory limits, randomized testing, general functionality)
nvim --headless --clean --cmd "set rtp+=~/.local/share/nvim/site" -u tests/test_constraints_e2e.lua 2>&1
```

Each test fixture in `tests/*/main.go` is a real Go file with expected complexity
declared in comments. The test runner analyzes each file and verifies the output
matches expectations.

## Contributing

Anyone who wishes to help improve this plugin is welcome to open an issue and/or submit a pull request.