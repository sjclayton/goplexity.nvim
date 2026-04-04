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
- **Nested complexity multiplication**: correctly computes O(n²), O(n³), O(n log n), O(n² log n), O(log² n), O(n√n)
- **Sorting**: `sort.Slice`, `sort.SliceStable`, `sort.Ints`, `sort.Strings`, `sort.Search` O(log n), `sort.SearchInts`, `sort.SearchFloat64s`, `sort.IsSorted`, `sort.Reverse`, heap operations
- **Containers**: slices, maps, channels, `container/list` (PushBack, PushFront, Remove), `container/ring`
- **Strings**: `strings.Split`, `strings.Join`, `strings.Contains`, `strings.Index`, `strings.ToLower`, `strings.ToUpper`, `strings.Trim`, `strings.Replace`, `strings.Count`, `strings.HasPrefix`, `strings.HasSuffix`
- **Bytes**: `bytes.Equal`, `bytes.Compare`, `bytes.Split`, `bytes.Join`, `bytes.Buffer`
- **Math**: `math.Abs`, `math.Max`, `math.Min`, `math.Ceil`, `math.Floor`, `math.Round`, `math.Pow`, `math.Sqrt`, `math.Log`, `math.Exp`, `math.Sin`, `math.Cos`, `math.Tan`, `math.Atan2`, `math/bits` (OnesCount, LeadingZeros, TrailingZeros, RotateLeft), `math/big` (NewInt, NewFloat, Int.Add)
- **I/O**: `fmt.Print`, `fmt.Println`, `fmt.Sprint`, `fmt.Sprintf`, `fmt.Fprintf`, `fmt.Errorf`, `fmt.Scan`, `fmt.Fscan`, `fmt.Sscan`, `os.Open`, `os.Create`, `os.Stat`, `os.Lstat`, `os.ReadFile`, `os.WriteFile`, `os.Read`, `os.Write`, `os.ReadDir`, `bufio.NewReader`, `bufio.NewWriter`, `Scanner.Scan`, `io.ReadFull`, `io.Copy`
- **Encoding**: `json.Marshal`, `json.Unmarshal`, `binary.Read`, `binary.Write`, `base64.NewDecoder`, `base64.NewEncoder`
- **Hashing**: `sha256.Sum256`, `sha256.New`, `sha512.New`, `md5.Sum`, `md5.New`, `h.Write`, `h.Sum`, `hash.New`
- **Concurrency**: `go` goroutines, `defer`, `select { }`, buffered/unbuffered channels
- **Context**: `context.Background`, `context.TODO`, `context.WithTimeout`, `context.WithCancel`, `context.WithDeadline`
- **Sync**: `sync.Mutex` (Lock/Unlock), `sync.WaitGroup` (Add/Done/Wait), `sync.Once.Do`
- **Time**: `time.Now`, `time.Sleep`, `time.Since`, `time.Until`
- **Filepath**: `filepath.Walk`, `filepath.WalkDir`, `filepath.Match`
- **Strconv**: `strconv.Atoi`, `strconv.Itoa`, `strconv.ParseInt`, `strconv.FormatInt`
- **Regexp**: `regexp.Compile`, `regexp.Match`, `Regexp.Find`, `Regexp.FindAll`
- **Compress**: `gzip.NewWriter`, `gzip.NewReader`
- **Slices & Maps**: `slices.Sort` O(n log n), `slices.Contains` O(n), `slices.Equal` O(n), `slices.Clone` O(n), `slices.Delete` O(n), `slices.Insert` O(n), `maps.Keys` O(n), `maps.Values` O(n), `maps.Equal` O(n)
- **Builtins**: `append` O(1), `copy` O(n), `delete` O(1), `len`/`cap` O(1)
- **Algorithms**:
  - Graph: DFS O(V+E), BFS O(V+E), Dijkstra O(E log V), Bellman-Ford O(V×E), Floyd-Warshall O(n³), Topological Sort O(V+E), Kruskal's MST O(E log E), Prim's MST O(V²)
  - Sorting: Merge Sort O(n log n), Quick Sort O(n log n), Heap Sort O(n log n)
  - Data structures: Union-Find/DSU O(α(n)), Trie O(L), Segment Tree O(log n)
  - String matching: KMP O(n)
  - Number theory: Sieve of Eratosthenes O(n log log n), GCD O(log n)
  - Searching: Binary Search O(log n)

### Space Complexity Detection

- Slices: `make([]int, n)`, `make([]int, 0, n)`
- Maps: `make(map[K]V)`
- Channels: `make(chan T)`, `make(chan T, buffer)`
- 2D structures: `make([][]int, n)` → O(n²), `make([]map[K]V, n)` → O(n²)
- Correctly excludes function signature parameters (references, not allocations)
- Correctly excludes slice/map literals (`[]int{1, 2, 3}`)
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
:Goplexity toggle       " Toggle complexity hints
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

- Neovim 0.8+

## License

MIT
