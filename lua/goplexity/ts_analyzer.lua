-- Tree-sitter backend for goplexity.nvim
-- Requires Neovim 0.12+ with the Go tree-sitter parser installed.
--
-- results = {
--   loops          = { { line, complexity, base_complexity, nesting_level }, ... }
--   function_calls = { { line, complexity, base_complexity, nesting_level }, ... }
--   space          = 'O(1)'   -- overall space (dominant across functions)
--   space_items    = { { line, complexity }, ... }
--   overall_time   = 'O(1)'
--   functions      = { { name, line, time_complexity, space_complexity }, ... }
-- }

local M = {}

-- Share hierarchy / helpers from analyzer.lua (single source of truth).
local analyzer = require('goplexity.analyzer')
local get_dominant = analyzer.get_dominant_complexity
local multiply = analyzer.multiply_complexity

-- ---------------------------------------------------------------------------
-- Load the tree-sitter query from the bundled .scm file.
-- Using the source file's own path avoids runtimepath ambiguity.
-- ---------------------------------------------------------------------------
local _PLUGIN_ROOT = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:match('@?(.+)$'), ':h:h:h')

local _QUERY = nil -- cached after first parse
local function get_query()
  if _QUERY then
    return _QUERY
  end
  local scm_path = _PLUGIN_ROOT .. '/queries/go/complexity.scm'
  local f = io.open(scm_path, 'r')
  if not f then
    error('goplexity: cannot open query file at ' .. scm_path)
  end
  local src = f:read('*all')
  f:close()
  _QUERY = vim.treesitter.query.parse('go', src)
  return _QUERY
end

-- ---------------------------------------------------------------------------
-- Stdlib call-complexity lookup: pkg → { fn → complexity }.
-- Tree-sitter gives us the call site precisely (no false matches from
-- strings/comments); this table maps the semantic complexity.
-- ---------------------------------------------------------------------------
local STDLIB = {
  sort = {
    Slice = 'O(n log n)',
    SliceStable = 'O(n log n)',
    Ints = 'O(n log n)',
    Strings = 'O(n log n)',
    Float64s = 'O(n log n)',
    Search = 'O(log n)',
    SearchInts = 'O(log n)',
    SearchStrings = 'O(log n)',
    SearchFloat64s = 'O(log n)',
    IsSorted = 'O(n)',
    Reverse = 'O(1)',
  },
  slices = {
    Sort = 'O(n log n)',
    SortFunc = 'O(n log n)',
    SortStableFunc = 'O(n log n)',
    BinarySearch = 'O(log n)',
    BinarySearchFunc = 'O(log n)',
    Equal = 'O(n)',
    Contains = 'O(n)',
    Clone = 'O(n)',
    ContainsFunc = 'O(n)',
    IndexFunc = 'O(n)',
    Index = 'O(n)',
    Delete = 'O(n)',
    Insert = 'O(n)',
  },
  maps = { Keys = 'O(n)', Values = 'O(n)', Equal = 'O(n)', Clone = 'O(n)', Copy = 'O(n)' },
  strings = {
    Split = 'O(n)',
    Join = 'O(n)',
    Contains = 'O(n)',
    HasPrefix = 'O(n)',
    HasSuffix = 'O(n)',
    Index = 'O(n)',
    ToLower = 'O(n)',
    ToUpper = 'O(n)',
    Trim = 'O(n)',
    Replace = 'O(n)',
    Count = 'O(n)',
  },
  bytes = {
    Equal = 'O(n)',
    Compare = 'O(n)',
    Split = 'O(n)',
    Join = 'O(n)',
    NewBuffer = 'O(1)',
    NewBufferString = 'O(n)',
  },
  strconv = {
    Atoi = 'O(n)',
    Itoa = 'O(n)',
    ParseInt = 'O(n)',
    FormatInt = 'O(n)',
    ParseFloat = 'O(n)',
    FormatFloat = 'O(n)',
  },
  regexp = { Compile = 'O(n)', MustCompile = 'O(n)', Match = 'O(n)' },
  bufio = { NewReader = 'O(1)', NewWriter = 'O(1)', NewScanner = 'O(1)' },
  io = { ReadFull = 'O(n)', Copy = 'O(n)' },
  json = { Marshal = 'O(n)', Unmarshal = 'O(n)' },
  fmt = {
    Print = 'O(n)',
    Println = 'O(n)',
    Printf = 'O(n)',
    Sprint = 'O(n)',
    Sprintf = 'O(n)',
    Fprintf = 'O(n)',
    Errorf = 'O(n)',
    Scan = 'O(n)',
    Fscan = 'O(n)',
    Sscan = 'O(n)',
    Sscanf = 'O(n)',
  },
  os = {
    Open = 'O(1)',
    Create = 'O(1)',
    Stat = 'O(1)',
    Lstat = 'O(1)',
    ReadFile = 'O(n)',
    WriteFile = 'O(n)',
    Read = 'O(n)',
    Write = 'O(n)',
    ReadDir = 'O(n)',
  },
  filepath = {
    Walk = 'O(n)',
    WalkDir = 'O(n)',
    Match = 'O(n)',
    Abs = 'O(n)',
    Base = 'O(n)',
    Clean = 'O(n)',
    Ext = 'O(n)',
    Join = 'O(n)',
  },
  context = {
    Background = 'O(1)',
    TODO = 'O(1)',
    WithTimeout = 'O(1)',
    WithCancel = 'O(1)',
    WithDeadline = 'O(1)',
  },
  time = { Now = 'O(1)', Sleep = 'O(1)', Since = 'O(1)', Until = 'O(1)' },
  math = {
    Abs = 'O(1)',
    Max = 'O(1)',
    Min = 'O(1)',
    Ceil = 'O(1)',
    Floor = 'O(1)',
    Round = 'O(1)',
    Pow = 'O(1)',
    Sqrt = 'O(1)',
    Log = 'O(1)',
    Exp = 'O(1)',
    Sin = 'O(1)',
    Cos = 'O(1)',
    Tan = 'O(1)',
    Atan2 = 'O(1)',
  },
  bits = { OnesCount = 'O(1)', LeadingZeros = 'O(1)', TrailingZeros = 'O(1)', RotateLeft = 'O(1)' },
  big = { NewInt = 'O(1)', NewFloat = 'O(1)' },
  heap = { Init = 'O(n)', Push = 'O(log n)', Pop = 'O(log n)', Fix = 'O(log n)', Remove = 'O(log n)' },
  list = { New = 'O(1)', PushBack = 'O(1)', PushFront = 'O(1)', Remove = 'O(1)' },
  ring = { New = 'O(n)', Len = 'O(n)' },
  hash = { New = 'O(1)' },
  sha256 = { Sum256 = 'O(n)', New = 'O(1)' },
  sha512 = { New = 'O(1)' },
  md5 = { Sum = 'O(n)', New = 'O(1)' },
  base64 = { NewDecoder = 'O(n)', NewEncoder = 'O(n)' },
  gzip = { NewWriter = 'O(n)', NewReader = 'O(n)' },
  binary = { Read = 'O(n)', Write = 'O(n)' },
  utf8 = {
    DecodeRune = 'O(1)',
    DecodeRuneInString = 'O(1)',
    RuneCount = 'O(n)',
    RuneCountInString = 'O(n)',
    Valid = 'O(n)',
    ValidString = 'O(n)',
    ValidRune = 'O(1)',
  },
  reflect = { DeepEqual = 'O(n)', TypeOf = 'O(1)', ValueOf = 'O(1)' },
  rand = { Shuffle = 'O(n)', Perm = 'O(n)', Intn = 'O(1)', Float64 = 'O(1)' },
  sync = {
    Once = 'O(1)',
    WaitGroup = 'O(1)',
    Mutex = 'O(1)',
    RWMutex = 'O(1)',
    Pool = 'O(1)',
    Cond = 'O(1)',
    Map = 'O(1)', -- Map methods are in METHOD_COMPLEXITIES
  },
  url = { Parse = 'O(n)', QueryEscape = 'O(n)', QueryUnescape = 'O(n)' },
  csv = { NewReader = 'O(1)', NewWriter = 'O(1)' },
  zip = { NewReader = 'O(n)', OpenReader = 'O(n)' },
}

local METHOD_COMPLEXITIES = {
  Write = 'O(n)',
  Read = 'O(n)',
  ReadFull = 'O(n)',
  Sum = 'O(n)',
  Sum256 = 'O(n)',
  Wait = 'O(n)',
  Add = 'O(n)',
  Mul = 'O(n)',
  Div = 'O(n)',
  Sub = 'O(n)',
  -- sync.Map
  Range = 'O(n)',
  Load = 'O(1)',
  Store = 'O(1)',
  Delete = 'O(1)',
  -- container/ring
  Next = 'O(1)',
  Prev = 'O(1)',
  Move = 'O(n)',
  -- url.Values
  Encode = 'O(n)',
}

-- Unqualified builtins.
local BUILTINS = {
  append = 'O(1)',
  copy = 'O(n)',
  delete = 'O(1)',
  len = 'O(1)',
  cap = 'O(1)',
  recover = 'O(1)',
}

-- ---------------------------------------------------------------------------
-- Node utilities
-- ---------------------------------------------------------------------------

--- Get the first child of a node by field name.
--- Neovim 0.11+ replaced child_by_field_name() with field() → TSNode[].
--- @param node TSNode
--- @param name string
--- @return TSNode|nil
local function field1(node, name)
  if not node then
    return nil
  end
  local results = node:field(name)
  return results and results[1] or nil
end

--- Return the source text of a TSNode.
--- @param node  TSNode
--- @param lines string[]  buffer lines (1-indexed)
--- @return string
local function node_text(node, lines)
  if not node then
    return ''
  end
  local sr, sc, er, ec = node:range()
  if sr == er then
    local line = lines[sr + 1]
    return line and line:sub(sc + 1, ec) or ''
  end
  local parts = { (lines[sr + 1] or ''):sub(sc + 1) }
  for i = sr + 2, er do
    parts[#parts + 1] = lines[i] or ''
  end
  parts[#parts + 1] = (lines[er + 1] or ''):sub(1, ec)
  return table.concat(parts, '\n')
end

--- Return the 1-indexed start line of a TSNode.
--- @param node TSNode
--- @return integer
local function node_line(node)
  local row = node:range()
  return row + 1
end

--- Return the innermost function_declaration or method_declaration ancestor.
--- @param  node TSNode
--- @return TSNode|nil
local function enclosing_func_node(node)
  local p = node:parent()
  while p do
    local t = p:type()
    if t == 'function_declaration' or t == 'method_declaration' then
      return p
    end
    p = p:parent()
  end
  return nil
end

--- Walk ancestors collecting base complexity of each enclosing for_statement.
--- Returns in outer→inner order (ready for left-fold multiply).
--- @param  node           TSNode
--- @param  loop_base_map  table<any, string>
--- @return string[]
local function enclosing_loop_complexities(node, loop_base_map)
  local result = {}
  local p = node:parent()
  while p do
    if p:type() == 'for_statement' then
      table.insert(result, 1, loop_base_map[p:id()] or 'O(n)')
    end
    p = p:parent()
  end
  return result
end

--- Multiply a list of complexity strings (left-associative).
--- @param  list string[]
--- @return string
local function multiply_all(list)
  local acc = 'O(1)'
  for _, c in ipairs(list) do
    acc = multiply(acc, c)
  end
  return acc
end

-- ---------------------------------------------------------------------------
-- For-loop classification (done in Lua, not in the query)
-- ---------------------------------------------------------------------------

--- Classify a for_statement node into 'traditional'|'range'|'while'|'infinite'
--- and return the key sub-clause node (for_clause/range_clause/cond expression) or nil.
--- @param  for_node TSNode
--- @return string, TSNode|nil
local function classify_for(for_node)
  -- Walk named children; the first non-block one identifies the loop kind.
  for i = 0, for_node:named_child_count() - 1 do
    local ch = for_node:named_child(i)
    local t = ch:type()
    if t == 'for_clause' then
      return 'traditional', ch
    elseif t == 'range_clause' then
      return 'range', ch
    elseif t == 'block' then
      return 'infinite', nil -- `for {}`
    else
      return 'while', ch -- `for cond {}`
    end
  end
end

--- Determine if a node (update clause or body) contains a logarithmic update to a target variable.
--- @param  node     TSNode|nil
--- @param  lines    string[]
--- @param  var_name string|nil
--- @return boolean
local function update_is_log(node, lines, var_name)
  if not node then
    return false
  end
  local raw = node_text(node, lines)

  -- If var_name is provided, ensure the update targets it.
  -- Otherwise (while loops), we look for any log pattern.
  local p_suffix = ''
  if var_name then
    p_suffix = '^%s*' .. vim.pesc(var_name) .. '%s*'
  end

  if raw:match(p_suffix .. '%*=') or raw:match(p_suffix .. '/=') then
    return true
  end
  if raw:match(p_suffix .. '<<=') or raw:match(p_suffix .. '>>=') then
    return true
  end
  if var_name then
    local esc_var = vim.pesc(var_name)
    if raw:match(esc_var .. '%s*=%s*' .. esc_var .. '%s*[%*%/]') then
      return true
    end
    if raw:match(esc_var .. '%s*&=%s*%(.*-.*1%)') then
      return true
    end
    if raw:match(esc_var .. '%s*%+=%s*' .. esc_var) then
      return true
    end
    if raw:match(esc_var .. '%s*=%s*' .. esc_var .. '%s*%+%s*' .. esc_var) then
      return true
    end
  else
    -- Generic patterns for while loops
    if raw:match('&=%s*%(.*-.*1%)') then
      return true
    end
    local lhs = raw:match('^%s*([%w_]+)%s*%+=') or raw:match('^%s*([%w_]+)%s*=')
    if lhs then
      local pattern = lhs .. '%s*[%+*]%s*' .. lhs
      if raw:match(pattern) or raw:match('%+=%s*' .. lhs) then
        return true
      end
    end
  end
  return false
end

--- Return true if the condition node encodes a sqrt loop: i*i <= n.
--- Walks the subtree looking for a binary_expression with operator `*`.
--- @param  cond_node TSNode
--- @param  lines     string[]
--- @return boolean
local function cond_is_sqrt(cond_node, lines)
  if not cond_node then
    return false
  end
  local function walk(n)
    if n:type() == 'binary_expression' then
      -- Operator is anonymous child at index 1 in tree-sitter ordering.
      local op = n:child(1)
      if op and node_text(op, lines) == '*' then
        return true
      end
    end
    for i = 0, n:child_count() - 1 do
      if walk(n:child(i)) then
        return true
      end
    end
    return false
  end
  return walk(cond_node)
end

--- Return true if the condition value is a small compile-time constant (>= 2).
--- @param  cond_node TSNode|nil
--- @param  lines     string[]
--- @return boolean
local function cond_is_constant_bound(cond_node, lines)
  if not cond_node then
    return false
  end
  local raw = node_text(cond_node, lines)
  return raw:match('[<>]=?%s*[2-9]%s*$') ~= nil or raw:match('[<>]=?%s*%d%d+%s*$') ~= nil
end

--- Determine the base time complexity of a for_statement node.
--- @param  for_node TSNode
--- @param  lines    string[]
--- @return string
local function base_complexity_of_for(for_node, lines)
  local kind, clause = classify_for(for_node)

  if kind == 'infinite' then
    return 'O(n)'
  end
  if kind == 'range' then
    return 'O(n)'
  end

  if kind == 'traditional' then
    -- Use field() API (Neovim 0.11+) – returns TSNode[]
    local cond = field1(clause, 'condition')
    local update = field1(clause, 'update')

    local var_name = nil
    if cond then
      var_name = node_text(cond, lines):match('([%w_]+)%s*[<>!]=?')
    end

    if cond_is_constant_bound(cond, lines) then
      return 'O(1)'
    end
    if cond_is_sqrt(cond, lines) then
      return 'O(√n)'
    end
    if update_is_log(update, lines, var_name) then
      return 'O(log n)'
    end

    -- If update is missing from clause, check body (while-style)
    local body = field1(for_node, 'body')
    if body and update_is_log(body, lines, var_name) then
      return 'O(log n)'
    end

    return 'O(n)'
  end

  if kind == 'while' then
    -- clause is the condition expression
    local var_name = node_text(clause, lines):match('([%w_]+)%s*[<>!]=?')
    if cond_is_sqrt(clause, lines) then
      return 'O(√n)'
    end
    if update_is_log(for_node, lines, var_name) then
      return 'O(log n)'
    end
    return 'O(n)'
  end

  return 'O(n)'
end

-- ---------------------------------------------------------------------------
-- Space: analyse make() and new() argument lists
-- ---------------------------------------------------------------------------

--- Determine the space complexity of a make() call_expression node.
--- @param  call_node TSNode  the call_expression node
--- @param  lines     string[]
--- @param  mode      'time'|'space'
--- @return string
local function complexity_of_make(call_node, lines, mode)
  local args_node = field1(call_node, 'arguments')
  if not args_node then
    return 'O(n)'
  end

  -- Named children of argument_list are the actual arguments (no commas/parens).
  local args = {}
  for i = 0, args_node:named_child_count() - 1 do
    args[#args + 1] = args_node:named_child(i)
  end
  if #args == 0 then
    return 'O(n)'
  end

  local type_raw = node_text(args[1], lines)

  -- 2D slice: make([][]T, n)
  if type_raw:match('%[%]%[%]') then
    return 'O(n²)'
  end

  -- Channel: unbuffered or buffered with no size → O(1)
  if type_raw:match('^chan') then
    if #args == 1 then
      return 'O(1)'
    end
    local size_raw = node_text(args[#args], lines):match('^%s*(.-)%s*$')
    if size_raw and size_raw:match('^%d+$') then
      return 'O(1)'
    end
    return mode == 'space' and 'O(n)' or 'O(1)' -- Channel allocation is O(1) time
  end

  -- make(map[T]U) with no size is O(1)
  if #args == 1 and type_raw:match('map') then
    return 'O(1)'
  end

  if #args == 1 then
    return 'O(n)'
  end

  -- Size/cap analysis:
  local len_arg = args[2]
  local cap_arg = args[3]
  local len_raw = len_arg and node_text(len_arg, lines):match('^%s*(.-)%s*$') or nil
  local cap_raw = cap_arg and node_text(cap_arg, lines):match('^%s*(.-)%s*$') or nil

  if mode == 'time' then
    -- Zero-length slices are O(1) time (allocation only, no clearing)
    if len_raw == '0' then
      return 'O(1)'
    end
    -- Constant lengths are O(1)
    if len_raw and len_raw:match('^%d+$') then
      return 'O(1)'
    end
    return 'O(n)'
  else
    -- Space: any non-constant length or capacity is O(n)
    local dominant = 'O(1)'
    if len_raw and not len_raw:match('^%d+$') then
      dominant = 'O(n)'
    end
    if cap_raw and not cap_raw:match('^%d+$') then
      dominant = 'O(n)'
    end
    -- If cap is missing but len is variable, it's still O(n)
    if not cap_raw and len_raw and not len_raw:match('^%d+$') then
      dominant = 'O(n)'
    end
    return dominant
  end
end

-- ---------------------------------------------------------------------------
-- Algorithm detection (structural analysis of a function body node)
-- ---------------------------------------------------------------------------

--- Collect a set of all identifier texts inside a node (recursively).
--- @param  body  TSNode
--- @param  lines string[]
--- @return table<string, boolean>
local function collect_ids(body, lines)
  local ids = {}
  local function walk(n)
    local t = n:type()
    if t == 'identifier' or t == 'field_identifier' then
      ids[node_text(n, lines)] = true
    end
    for i = 0, n:child_count() - 1 do
      walk(n:child(i))
    end
  end
  walk(body)
  return ids
end

--- Return true if body contains a direct call to func_name (recursive call).
--- @param  body      TSNode
--- @param  func_name string
--- @param  lines     string[]
--- @return boolean
local function body_has_recursive_call(body, func_name, lines)
  local function walk(n)
    if n:type() == 'call_expression' then
      local fn = field1(n, 'function')
      if fn and fn:type() == 'identifier' and node_text(fn, lines) == func_name then
        return true
      end
    end
    for i = 0, n:child_count() - 1 do
      if walk(n:child(i)) then
        return true
      end
    end
    return false
  end
  return walk(body)
end

--- Return the maximum nesting depth of for_statement nodes inside a node.
--- @param  node TSNode
--- @return integer
local function max_for_depth(node)
  local function walk(n, depth)
    local next_d = depth + (n:type() == 'for_statement' and 1 or 0)
    local best = next_d
    for i = 0, n:child_count() - 1 do
      local d = walk(n:child(i), next_d)
      if d > best then
        best = d
      end
    end
    return best
  end
  return walk(node, 0)
end

--- Detect a known algorithm from a function body node.
--- Returns (time_complexity, space_complexity) or (nil, nil).
--- @param  body      TSNode
--- @param  func_name string
--- @param  lines     string[]
--- @return string|nil, string|nil
local function detect_algorithm(body, func_name, lines)
  local ids = collect_ids(body, lines)
  local raw = node_text(body, lines)
  local recurse = body_has_recursive_call(body, func_name, lines)
  local for_depth = max_for_depth(body)

  -- Helper: true if any of the given identifiers was found in the function body.
  local has = function(...)
    for _, name in ipairs({ ... }) do
      if ids[name] then
        return true
      end
    end
    return false
  end

  -- Advanced Algorithms Detection

  -- Kadane's Algorithm: O(n) max subarray sum
  -- Pattern: local sum += x; if sum < 0 { sum = 0 }; if sum > max { max = sum }
  local has_kadane = (raw:match('%+=%s*') and raw:match('<%s*0') and (raw:match('max') or raw:match('Max')))
  if has_kadane and for_depth == 1 then
    return 'O(n)', 'O(1)'
  end

  -- Binary Indexed Tree (BIT / Fenwick): O(log n) update/query
  -- Pattern: i += i & -i or i -= i & -i
  local has_bit_op = raw:match('%+=%s*[%w_]+%s*&%s*%-') or raw:match('%-=%s*[%w_]+%s*&%s*%-')
  if has_bit_op then
    return 'O(log n)', 'O(1)'
  end

  -- Sparse Table: O(n log n) preprocessing
  -- Pattern: 2D array dp[i][j] + binary jump 1 << (j-1)
  local has_bin_jump = raw:match('1%s*<<')
  local has_2d_dp = raw:match('%[.*%]%[.*%]')
  if has_bin_jump and has_2d_dp and for_depth >= 2 then
    if func_name:match('[Bb]uild') or func_name:match('[Pp]recompute') or func_name:match('[Ii]nit') then
      return 'O(n log n)', 'O(n log n)'
    end
    -- Query is O(1)
    if func_name:match('[Qq]uery') or func_name:match('[Gg]et') then
      return 'O(1)', 'O(1)'
    end
  end

  -- LCS / Knapsack: O(n*m) or O(n*W) DP
  -- Pattern: 2D array dp[i][j] + nested loops + max/min update
  if has_2d_dp and for_depth >= 2 and (raw:match('max%(') or raw:match('min%(') or raw:match('dp%[.*%]%[.*%]%s*=')) then
    -- Detect if it's likely knapsack or LCS
    if has('dp', 'table', 'memo') then
      return 'O(n×m)', 'O(n×m)'
    end
  end

  -- Graph-related identifiers (from AST, no string/comment false positives)
  local has_adj = has('adj', 'neighbors', 'graph')
  local has_vis = has('visited', 'seen')
  local has_queue = has('queue')
  local has_heap = has('heap')
  local has_edges = has('edges', 'Edge')
  local has_parent = has('parent', 'node.parent')
  local has_find = has('find')
  local has_union = has('union')
  local has_indeg = has('indegree', 'in_degree', 'degree')
  local has_dist = has('dist')
  local has_lps = has('lps', 'prefix', 'pi')
  local has_prime = has('isPrime', 'prime', 'composite')
  local has_pivot = has('pivot')
  local has_kids = has('children') -- Trie
  local has_sqrt = raw:match('math%.Sqrt')

  -- These remaining checks use raw body text but only for structural/numeric patterns
  -- (sentinel values, array subscript patterns) that have no useful AST form.
  local has_sentinel = raw:match('1e9') or raw:match('math%.Inf') or raw:match('math%.MaxInt') or raw:match('MAX_INT')
  local has_mid_update = raw:match('left%s*=%s*mid') or raw:match('right%s*=%s*mid')
  local has_mid_slice = has('mid') and (raw:match(':%]') or raw:match('%[:'))
  local has_partition = raw:match('partition') or (has('left') and has('right') and raw:match('swap'))
  local has_sieve_loop = raw:match('i%s*%*%s*i') or raw:match('i%s*%*%s*2')
  local has_min_weight = (raw:match('min') or raw:match('Min'))
    and (raw:match('weight') or raw:match('cost') or raw:match('key'))
  local has_n_minus_1 = raw:match('n%s*%-%s*1') or raw:match('n%-1')
  local has_kmp_logic = raw:match('j%s*>%s*0') and raw:match('j%s*=%s*')
  local has_dist_matrix = raw:match('dist%[.*%]%[.*%]')

  -- Floyd-Warshall: triple nested loops + dist matrix (or 3 loops with dist)
  if (for_depth >= 3 and has_dist) or (has_dist_matrix and raw:match('min')) then
    return 'O(n³)', 'O(n²)'
  end

  -- Prim: adjacency + visited + min-weight, NO queue or heap → O(V²)
  if has_adj and has_vis and has_min_weight and not has_queue and not has_heap then
    return 'O(V²)', 'O(V)'
  end

  -- Bellman-Ford: dist + edges + sentinel + n-1 iterations
  if has_dist and has_edges and has_sentinel and has_n_minus_1 then
    return 'O(V×E)', 'O(V)'
  end

  -- Dijkstra: dist + heap + sentinel
  if has_dist and has_heap and has_sentinel then
    return 'O(E log V)', 'O(V)'
  end

  -- Kruskal: edge-sort + union-find
  if has_edges and has_parent and has_find and has_union then
    return 'O(E log E)', 'O(V)'
  end

  -- Topological sort: adjacency + in-degree + queue
  if has_adj and has_indeg and has_queue then
    return 'O(V+E)', 'O(V)'
  end

  -- DFS / BFS: adjacency + visited set
  if has_adj and has_vis then
    return 'O(V+E)', 'O(V)'
  end

  -- Merge sort: mid split into slices + recursive call
  if has_mid_slice and recurse then
    return 'O(n log n)', 'O(n)'
  end

  -- Quick sort: pivot or partition + recursive call
  if (has_pivot or has_partition) and recurse then
    local qs_space = 'O(log n)'
    if raw:match('append') or raw:match('make') then
      qs_space = 'O(n)'
    end
    return 'O(n log n)', qs_space
  end

  -- Binary search: left + right + mid + mid-pointer update (no recursion needed)
  if has('left') and has('right') and has('mid') and has_mid_update then
    return 'O(log n)', 'O(1)'
  end

  -- Sieve of Eratosthenes: prime-marking boolean array + i*i pattern
  if has_prime and has_sieve_loop then
    return 'O(n log log n)', 'O(n)'
  end

  -- GCD: modulo with == 0 base case (recursive or iterative)
  if raw:match('%%') and raw:match('[%w_]%s*==%s*0') then
    return 'O(log n)', 'O(1)'
  end

  -- Union-Find / DSU
  -- Detection: has parent array access + naming or recursive path compression or simple union
  local has_dsu_pattern = raw:match('[%w_%.]*parent%[.-%]%s*!=')
    or raw:match('[%w_%.]*parent%[.-%]%s*=%s*.-find')
    or raw:match('[%w_%.]*parent%[.-%]%s*=%s*.-parent%[')
    or raw:match('[%w_%.]*parent%[.-%]%s*=%s*[%w_]+%s*$')
  if (has_parent and has_find and has_union) or (has_parent and has_dsu_pattern) then
    return 'O(α(n))', 'O(1)'
  end

  -- Trie: children field + character offset traversal
  local has_char_traversal = raw:match("%-'a'") or raw:match("%-'0'")
  if has_kids and has_char_traversal then
    return 'O(L)', 'O(L * Σ)'
  end

  -- Segment tree: 4*n sizing or 2*node pattern + naming convention
  local has_seg_size = raw:match('4%s*%*%s*n')
  local has_seg_node = raw:match('2%s*%*%s*node') or raw:match('node%s*%*%s*2')
  local has_seg_name = func_name:match('[Ss]egment')
    or func_name:match('build')
    or func_name:match('query')
    or func_name:match('update')
  if (has_seg_size and has_seg_node) or (has_seg_name and (has_seg_size or has_seg_node)) then
    if func_name:match('[Bb]uild') or func_name:match('[Nn]ew') then
      return 'O(n)', 'O(n)'
    end
    return 'O(log n)', 'O(n)'
  end

  -- Sqrt loop variant: for i := 1; i <= limit; i++ where limit = sqrt(n)
  if has_sqrt and for_depth >= 1 and (raw:match('limit') or raw:match('sq')) then
    return 'O(√n)', 'O(1)'
  end

  -- KMP: lps/prefix array + j > 0 mismatch back-step
  if has_lps and has_kmp_logic then
    return 'O(n)', 'O(m)'
  end

  return nil, nil
end

-- ---------------------------------------------------------------------------
-- Main entry point
-- ---------------------------------------------------------------------------

--- Analyse the given buffer with tree-sitter.
--- Errors loudly if the Go parser is unavailable (caller wraps in pcall).
--- @param  bufnr integer
--- @return table  results
function M.analyze(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local parser = vim.treesitter.get_parser(bufnr, 'go')
  if not parser then
    error('goplexity: Go tree-sitter parser not found — install it with :TSInstall go')
  end

  local tree = parser:parse()[1]
  local root = tree:root()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local query = get_query()

  local results = {
    loops = {},
    function_calls = {},
    space = 'O(1)',
    space_items = {},
    overall_time = 'O(1)',
    functions = {},
  }

  -- -------------------------------------------------------------------------
  -- Pass 1: Discovery. Collect loops and function declarations.
  -- -------------------------------------------------------------------------
  local loop_base = {} -- TSNode ID → string
  local func_map = {} -- body TSNode ID → table

  for id, node in query:iter_captures(root, bufnr) do
    local capture_name = query.captures[id]

    if capture_name == 'goplexity.loop' then
      loop_base[node:id()] = base_complexity_of_for(node, lines)
    elseif capture_name == 'goplexity.func.decl' then
      local name_node = field1(node, 'name')
      local body_node = field1(node, 'body')
      if name_node and body_node then
        local func_name = node_text(name_node, lines)
        local algo_t, algo_s = detect_algorithm(body_node, func_name, lines)
        func_map[body_node:id()] = {
          name = func_name,
          line = node_line(node),
          time_complexity = algo_t or 'O(1)',
          space_complexity = algo_s or 'O(1)',
          is_algorithm = algo_t ~= nil,
        }
        -- Dominant complexity for detected algorithms
        if algo_t then
          results.overall_time = get_dominant(results.overall_time, algo_t)
          if algo_s then
            results.space = get_dominant(results.space, algo_s)
          end
        end
      end
    end
  end

  -- Helper: find the func_map entry that owns a given node
  local function owning_func(node)
    local enc = enclosing_func_node(node)
    if not enc then
      return nil
    end
    local body = field1(enc, 'body')
    return body and func_map[body:id()]
  end

  -- -------------------------------------------------------------------------
  -- Pass 2: Resolution. Compute nested complexities and resolve all calls.
  -- -------------------------------------------------------------------------
  for id, node in query:iter_captures(root, bufnr) do
    local capture_name = query.captures[id]

    if capture_name == 'goplexity.loop' then
      local base = loop_base[node:id()] or 'O(n)'
      local ancestors = enclosing_loop_complexities(node, loop_base)
      local effective = multiply(multiply_all(ancestors), base)

      results.loops[#results.loops + 1] = {
        line = node_line(node),
        complexity = effective,
        base_complexity = base,
        nesting_level = #ancestors,
      }

      local fe = owning_func(node)
      if effective ~= 'O(1)' then
        if not fe or not fe.is_algorithm then
          results.overall_time = get_dominant(results.overall_time, effective)
        end
        if fe and not fe.is_algorithm then
          fe.time_complexity = get_dominant(fe.time_complexity, effective)
        end
      end
    elseif capture_name == 'goplexity.call.qualified' or capture_name == 'goplexity.call.builtin_expr' then
      local base_c = nil
      local fn_child = field1(node, 'function')
      local name = nil

      if fn_child then
        if fn_child:type() == 'selector_expression' then
          local pkg_node = field1(fn_child, 'operand')
          local fn_node = field1(fn_child, 'field')
          if fn_node then
            local pkg = pkg_node and node_text(pkg_node, lines) or ''
            local fn = node_text(fn_node, lines)
            name = fn
            base_c = (STDLIB[pkg] or {})[fn]
            if not base_c and METHOD_COMPLEXITIES[fn] then
              if (fn == 'Add' or fn == 'Sub' or fn == 'Mul' or fn == 'Div') and not pkg:match('big%.Int') then
                base_c = nil
              else
                base_c = METHOD_COMPLEXITIES[fn]
              end
            end
          end
        elseif fn_child:type() == 'identifier' then
          name = node_text(fn_child, lines)
          base_c = BUILTINS[name]
          if name == 'make' then
            base_c = complexity_of_make(node, lines, 'time')
            local sc = complexity_of_make(node, lines, 'space')
            results.space_items[#results.space_items + 1] = { line = node_line(node), complexity = sc }
            local fe = owning_func(node)
            if not fe or not fe.is_algorithm then
              results.space = get_dominant(results.space, sc)
            end
            if fe and not fe.is_algorithm then
              fe.space_complexity = get_dominant(fe.space_complexity, sc)
            end
          elseif name == 'new' then
            results.space_items[#results.space_items + 1] = { line = node_line(node), complexity = 'O(1)' }
          end
        end
      end

      -- If not a builtin/stdlib, check if it's an internal function
      if not base_c and name and not BUILTINS[name] and name ~= 'make' and name ~= 'new' then
        for _, fe in pairs(func_map) do
          if fe.name == name then
            if fe.time_complexity ~= 'O(1)' then
              base_c = fe.time_complexity
            end
            break
          end
        end
      end

      if base_c then
        local ancs = enclosing_loop_complexities(node, loop_base)
        local eff = multiply(multiply_all(ancs), base_c)
        if eff ~= 'O(1)' then
          results.function_calls[#results.function_calls + 1] = {
            line = node_line(node),
            complexity = eff,
            base_complexity = base_c,
            nesting_level = #ancs,
          }
          local fe = owning_func(node)
          if not fe or not fe.is_algorithm then
            results.overall_time = get_dominant(results.overall_time, eff)
          end
          if fe and not fe.is_algorithm then
            fe.time_complexity = get_dominant(fe.time_complexity, eff)
          end
        end
      end
    elseif capture_name == 'goplexity.go_stmt' then
      local base_c = 'O(1)'
      local ancs = enclosing_loop_complexities(node, loop_base)
      local eff = multiply(multiply_all(ancs), base_c)

      results.function_calls[#results.function_calls + 1] = {
        line = node_line(node),
        complexity = eff,
        base_complexity = base_c,
        nesting_level = #ancs,
      }

      local fe = owning_func(node)
      if not fe or not fe.is_algorithm then
        results.overall_time = get_dominant(results.overall_time, eff)
      end
      if fe and not fe.is_algorithm then
        fe.time_complexity = get_dominant(fe.time_complexity, eff)
      end
    end
  end

  -- -------------------------------------------------------------------------
  -- Finalise: collect function entries; sort all output tables by line.
  -- -------------------------------------------------------------------------
  for _, fe in pairs(func_map) do
    results.functions[#results.functions + 1] = {
      name = fe.name,
      line = fe.line,
      time_complexity = fe.time_complexity,
      space_complexity = fe.space_complexity,
    }
  end

  local by_line = function(a, b)
    return a.line < b.line
  end
  table.sort(results.functions, by_line)
  table.sort(results.loops, by_line)
  table.sort(results.function_calls, by_line)
  table.sort(results.space_items, by_line)

  return results
end

return M
