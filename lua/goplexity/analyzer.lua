-- Complexity Analyzer - Rule-based static analysis for Go

local M = {}

-- Constants
local CONSTANTS = {
  DEFAULT_COMPLEXITY = "O(1)",
  DEFAULT_RANK = 100,
}

-- Pattern matchers for control structures
local CONTROL_PATTERNS = {
  IF = "^if%s*%(",
  WHILE = "^while%s*%(",  -- Go doesn't have while, but we keep for compatibility
  FOR = "^for%s*%(",      -- C-style: for (init; cond; inc) - rare in Go but possible
  FOR_TRADITIONAL = "^for%s+[%w_]",  -- Go traditional: for i := 0; ... or for i = 0; ...
  RANGE_FOR = "^for%s+[%w_].*:?=%s*[^=].*range",  -- for i, v := range slice
  FOR_COND = "^for%s+[^;{]",  -- Go while-style: for condition { or for condition
  DO = "^do%s*",
  SWITCH = "^switch%s*%(",
}

-- Complexity class for easier manipulation
local Complexity = {}
Complexity.__index = Complexity

function Complexity.new(time, space, description)
  return setmetatable({
    time = time or CONSTANTS.DEFAULT_COMPLEXITY,
    space = space or CONSTANTS.DEFAULT_COMPLEXITY,
    description = description or "",
  }, Complexity)
end

-- Complexity hierarchy (from lowest to highest)
local COMPLEXITY_HIERARCHY = {
  ["O(1)"] = 1,
  ["O(α(n))"] = 2,        -- Union-Find amortized
  ["O(log n)"] = 3,
  ["O(log² n)"] = 4,
  ["O(√n)"] = 5,
  ["O(L)"] = 6,           -- Trie operations
  ["O(n)"] = 7,
  ["O(n log n)"] = 8,
  ["O(n log log n)"] = 9, -- Sieve
  ["O(n√n)"] = 10,
  ["O(n²)"] = 11,
  ["O(n² log n)"] = 12,
  ["O(n³)"] = 13,
  ["O(V+E)"] = 14,        -- Graph traversal
  ["O(V×E)"] = 15,        -- Bellman-Ford
  ["O(E log V)"] = 16,    -- Dijkstra
  ["O(2^n)"] = 17,
  ["O(n!)"] = 18,
}

-- Compare two complexity strings and return the dominant (higher) one
local function get_dominant_complexity(complexity1, complexity2)
  local rank1 = COMPLEXITY_HIERARCHY[complexity1] or CONSTANTS.DEFAULT_RANK
  local rank2 = COMPLEXITY_HIERARCHY[complexity2] or CONSTANTS.DEFAULT_RANK
  
  return rank1 >= rank2 and complexity1 or complexity2
end

-- Multiplication lookup table for common complexity combinations
local COMPLEXITY_MULTIPLICATION = {
  ["n|n"] = "O(n²)",
  ["n|log n"] = "O(n log n)",
  ["log n|n"] = "O(n log n)",
  ["n|n log n"] = "O(n² log n)",
  ["n log n|n"] = "O(n² log n)",
  ["n²|n"] = "O(n³)",
  ["n|n²"] = "O(n³)",
  ["log n|log n"] = "O(log² n)",
  ["√n|n"] = "O(n√n)",
  ["n|√n"] = "O(n√n)",
}

-- Extract inner complexity from O(...) notation
local function extract_inner_complexity(complexity)
  return complexity:match("O%((.+)%)")
end

-- Multiply two complexity strings (for nested operations)
local function multiply_complexity(complexity1, complexity2)
  -- O(1) is identity for multiplication
  if complexity1 == CONSTANTS.DEFAULT_COMPLEXITY then return complexity2 end
  if complexity2 == CONSTANTS.DEFAULT_COMPLEXITY then return complexity1 end
  
  local inner1 = extract_inner_complexity(complexity1)
  local inner2 = extract_inner_complexity(complexity2)
  
  if not inner1 or not inner2 then return "O(n²)" end
  
  -- Check multiplication lookup table
  local key = inner1 .. "|" .. inner2
  if COMPLEXITY_MULTIPLICATION[key] then
    return COMPLEXITY_MULTIPLICATION[key]
  end
  
  -- Default: show as multiplication
  return "O(" .. inner1 .. " × " .. inner2 .. ")"
end

-- Check if line contains logarithmic increment pattern
local function is_logarithmic_pattern(line)
  local log_patterns = {
    "[%w_]+%s*%*=%s*2",              -- i *= 2
    "[%w_]+%s*/=%s*2",               -- i /= 2  
    "[%w_]+%s*<<=%s*%d+",            -- i <<= 1
    "[%w_]+%s*>>=%s*%d+",            -- i >>= 1
    "[%w_]+%s*=%s*[%w_]+%s*%*%s*2", -- i = i * 2
    "[%w_]+%s*=%s*[%w_]+%s*/%s*2",  -- i = i / 2
    "[%w_]+%s*&=%s*%(.-%-.-%)%",     -- i &= (i-1)
    "[%w_]+%s*=%s*[%w_]+%s*&%s*%(.-%-.-%)%" -- i = i & (i-1)
  }
  
  for _, pattern in ipairs(log_patterns) do
    if line:match(pattern) then return true end
  end
  return false
end

-- Check if line contains square root pattern
local function is_sqrt_pattern(line)
  return line:match("[%w_]+%s*%*%s*[%w_]+%s*[<>]=?%s*[%w_]+") or
         line:match("sqrt%s*%(")
end

-- Detect complexity pattern from loop increment/condition
local function analyze_loop_increment(increment_line)
  if is_logarithmic_pattern(increment_line) then
    return "O(log n)"
  end
  
  if is_sqrt_pattern(increment_line) then
    return "O(√n)"
  end
  
  -- Check for i += i patterns (also log)
  if increment_line:match("[%w_]+%s*%+=%s*[%w_]+") then
    local var = increment_line:match("([%w_]+)%s*%+=")
    if var and increment_line:match(var .. "%s*%+=%s*" .. var) then
      return "O(log n)"
    end
  end
  
  return "O(n)"  -- Default: linear
end

-- Analyze for loop complexity from its structure
local function analyze_for_loop(line)
  -- Range-based for loop: for(auto x : container)
  if line:match("for%s*%(.-%s*:%s*.-%)")  then
    return "O(n)"
  end
  
  -- Traditional for loop: for (init; condition; increment)
  local _, _, increment = line:match("for%s*%((.-)%;(.-)%;(.-)%)")
  
  if increment then
    return analyze_loop_increment(increment)
  end
  
  return "O(n)"  -- Default assumption
end

-- Detect binary search pattern by analyzing function content
local function detect_binary_search(lines, start_line)
  local func_content = {}
  for i = start_line, #lines do
    local line = lines[i]
    table.insert(func_content, line)
    -- Stop at closing brace (but not nested braces)
    -- Count braces to handle nesting properly
    local opens = (line:gsub("{", ""):gsub("}", ""))
    -- Simple approach: stop at first line that is just a closing brace with optional whitespace
    if line:match("^%s*}%s*$") and #func_content > 1 then
      break
    end
  end
  
  local content = table.concat(func_content, " ")
  
  -- Binary search patterns (simplified and more lenient):
  -- 1. Has left and right variables
  -- 2. Has mid calculation (typically: mid := left + (right-left)/2)
  -- 3. Has left <= right or left < right condition
  -- 4. Updates left or right based on mid
  
  local has_left_right = content:match("left") and content:match("right")
  local has_mid = content:match("mid") and (content:match(":=") or content:match("="))
  local has_condition = content:match("left%s*<=") or content:match("left%s*<")
  local has_mid_update = content:match("left%s*=%s*mid") or content:match("right%s*=%s*mid")
  
  if has_left_right and has_mid and has_condition and has_mid_update then
    return true
  end
  
  return false
end

-- Detect common divide-and-conquer algorithms by analyzing function content
local function detect_divide_conquer(lines, start_line, func_name)
  local func_content = {}
  local brace_count = 0
  for i = start_line, #lines do
    local line = lines[i]
    func_content[#func_content + 1] = line
    for c in line:gmatch(".") do
      if c == "{" then brace_count = brace_count + 1 end
      if c == "}" then brace_count = brace_count - 1 end
    end
    if brace_count == 0 and #func_content > 1 then
      break
    end
  end
  
  local content = table.concat(func_content, " ")
  
  -- Check for slice operation pattern (Go slice: arr[:mid] or arr[mid:])
  -- Or partition pattern with append
  local has_slice_operation = content:match(":%s*%]") or content:match("%[:%s*%w+%s*%]")
  local has_recursive_call = content:match(func_name .. "%s*%(")
  local has_partition_pattern = content:match("left.*right") and content:match("append")
  
  -- Merge sort: name contains "merge" and has slice operations with recursive calls
  local is_merge_sort = (func_name:match("merge") or func_name:match("Merge")) and 
                        (has_slice_operation or has_partition_pattern)
  
  -- Quick sort: name contains "quick" and has partition pattern with recursive calls
  local is_quick_sort = (func_name:match("quick") or func_name:match("Quick")) and 
                        (has_slice_operation or has_partition_pattern) and has_recursive_call
  
  -- Generic divide-and-conquer: recursive call with slice operations or partition pattern
  if is_merge_sort then
    return "O(n log n)", "O(n)"  -- time, space
  elseif is_quick_sort then
    return "O(n log n)", "O(log n)"  -- time, space (average)
  elseif has_recursive_call and (has_slice_operation or has_partition_pattern) then
    -- Generic divide-and-conquer detected
    return "O(n log n)", "O(n)"  -- Assume O(n log n) for divide-and-conquer
  end
  
  return nil, nil  -- Not detected
end

-- Analyze while loop complexity from its condition
local function analyze_while_loop(line, lines, current_line)
  -- Detect multiplication/division patterns in condition
  if line:match("while%s*%(.*[*/].*%)") then
    return "O(log n)"
  end
  
  -- Check for binary search pattern
  local is_binary_search = detect_binary_search(lines, current_line)
  if is_binary_search then
    return "O(log n)"
  end
  
  return "O(n)"  -- Default assumption
end

-- Analyze Go for loop complexity from its structure
local function analyze_go_for_loop(line, lines, current_line)
  -- Go range-based for loop: for i, v := range slice
  if line:match(CONTROL_PATTERNS.RANGE_FOR) then
    return "O(n)"  -- Default for range over slices/maps/channels
  end
  
  -- Go traditional for loop: for i := 0; i < n; i++
  -- Extract increment to detect logarithmic patterns
  local _, _, increment = line:match("for%s+.-;.-;%s*(.-)%s*%{?%s*$")
  
  if increment then
    -- Check for logarithmic patterns
    if increment:match("[%w_]+%s*%*=%s*2") or           -- i *= 2
       increment:match("[%w_]+%s*/=%s*2") or            -- i /= 2
       increment:match("[%w_]+%s*<<=") or               -- i <<= 1
       increment:match("[%w_]+%s*>>=") or               -- i >>= 1
       increment:match("[%w_]+%s*=%s*[%w_]+%s*%*%s*2") or  -- i = i * 2
       increment:match("[%w_]+%s*=%s*[%w_]+%s*/%s*2") then  -- i = i / 2
      return "O(log n)"
    end
    -- Check for i += i patterns (also logarithmic)
    local var = increment:match("([%w_]+)%s*%+=")
    if var and increment:match(var .. "%s*%+=%s*" .. var) then
      return "O(log n)"
    end
    -- Check for i++ or ++i patterns (linear)
    if increment:match("%+%s*%+") or increment:match("%-%s*-") then
      return "O(n)"
    end
    return "O(n)"  -- Default for traditional for loops
  end
  
  -- Go condition-based for loop: for condition { 
  if line:match(CONTROL_PATTERNS.FOR_COND) then
    -- Check if it's actually an infinite loop: for {
    if line:match("^for%s*{$") then
      return "O(n)"  -- Default assumption for infinite loops
    end
    -- Check for binary search pattern
    if detect_binary_search(lines, current_line) then
      return "O(log n)"
    end
    -- Could be a while-like loop, analyze condition for patterns
    -- For now, default to O(n)
    return "O(n)"
  end
  
  return "O(n)"  -- Default assumption
end

-- Detect standard library function complexities (Go only)
local function analyze_function_call(line)
  -- Go standard library functions
  -- Sorting and searching
  if line:match("sort%.Slice%s*%(") or line:match("sort%.SliceStable%s*%(") then
    return { time = "O(n log n)", is_call = true }
  end
  
  if line:match("sort%.Search%s*%(") or line:match("sort%.Ints%s*%(") or 
     line:match("sort%.Strings%s*%(") then
    return { time = "O(n log n)", is_call = true }
  end
  
  -- Container operations
  if line:match("append%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("copy%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("delete%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("len%s*%(") or line:match("cap%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  -- String operations
  if line:match("strings%.Split%s*%(") or line:match("strings%.Join%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("strings%.Contains%s*%(") or line:match("strings%.HasPrefix%s*%(") or
     line:match("strings%.HasSuffix%s*%(") or line:match("strings%.Index%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("strings%.ToLower%s*%(") or line:match("strings%.ToUpper%s*%(") or
     line:match("strings%.Trim%s*%(") or line:match("strings%.Replace%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("strings%.Count%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- Bytes operations
  if line:match("bytes%.Equal%s*%(") or line:match("bytes%.Compare%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("bytes%.Split%s*%(") or line:match("bytes%.Join%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("bytes%.Buffer%s*") then
    return { time = "O(1)", is_call = true }
  end
  
  -- strconv operations
  if line:match("strconv%.Atoi%s*%(") or line:match("strconv%.Itoa%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("strconv%.ParseInt%s*%(") or line:match("strconv%.FormatInt%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- regexp operations
  if line:match("regexp%.Compile%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("regexp%.Match%s*%(") or line:match("Regexp%.Find%s*%(") or
     line:match("Regexp%.FindAll%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- I/O operations
  if line:match("bufio%.NewReader") or line:match("bufio%.NewWriter") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("Scanner%.Scan%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("ioutil%.ReadFile%s*%(") or line:match("ioutil%.WriteFile%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("io%.ReadFull%s*%(") or line:match("io%.Copy%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- JSON operations
  if line:match("json%.Unmarshal%s*%(") or line:match("json%.Marshal%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- Hashing and crypto
  if line:match("crypto/sha256%.Sum256%s*%(") or line:match("crypto/md5%.Sum%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- time operations
  if line:match("time%.Now%s*%(") or line:match("time%.Sleep%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("time%.Since%s*%(") or line:match("time%.Until%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  -- sync primitives
  if line:match("sync%.NewMutex%s*%(") or line:match("sync%.NewWaitGroup%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("sync%.Once%.Do%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("sync%.WaitGroup%.Wait%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- context operations
  if line:match("context%.Background%s*%(") or line:match("context%.TODO%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("context%.WithTimeout%s*%(") or line:match("context%.WithCancel%s*%(") or
     line:match("context%.WithDeadline%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  -- select statement - channel operations
  if line:match("^%s*select%s*{") then
    return { time = "O(1)", is_call = true }
  end
  
  -- goroutine - creates concurrent execution
  if line:match("^%s*go%s+") then
    return { time = "O(n)", is_call = true }
  end
  
  -- defer - O(1) for registration
  if line:match("^%s*defer%s+") then
    return { time = "O(1)", is_call = true }
  end
  
  -- Bit operations
  if line:match("bits%. OnesCount%s*%(") or line:match("bits%. LeadingZeros%s*%(") or
     line:match("bits%. TrailingZeros%s*%(") or line:match("bits%. RotateLeft%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  -- math package operations
  if line:match("math%.Abs%s*%(") or line:match("math%.Max%s*%(") or
     line:match("math%.Min%s*%(") or line:match("math%.Ceil%s*%(") or
     line:match("math%.Floor%s*%(") or line:match("math%.Round%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("math%.Pow%s*%(") or line:match("math%.Sqrt%s*%(") or
     line:match("math%.Log%s*%(") or line:match("math%.Exp%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("math%.Sin%s*%(") or line:match("math%.Cos%s*%(") or
     line:match("math%.Tan%s*%(") or line:match("math%.Atan2%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  -- math/big operations
  if line:match("big%.NewInt%s*%(") or line:match("big%.NewFloat%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("Int%.Add%s*%(") or line:match("Int%.Mul%s*%(") or
     line:match("Int%.Div%s*%(") or line:match("Int%.Sub%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- sort.SearchInts, sort.SearchStrings
  if line:match("sort%.SearchInts%s*%(") or line:match("sort%.SearchStrings%s*%(") or
     line:match("sort%.SearchFloat%s*%(") then
    return { time = "O(log n)", is_call = true }
  end
  
  -- container/heap operations
  if line:match("heap%.Init%s*%(") or line:match("heap%.Push%s*%(") or
     line:match("heap%.Pop%s*%(") then
    return { time = "O(log n)", is_call = true }
  end
  
  -- container/list operations
  if line:match("list%.New%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("List%.PushBack%s*%(") or line:match("List%.PushFront%s*%(") or
     line:match("List%.Remove%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  -- container/ring operations
  if line:match("ring%.New%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- slices package
  if line:match("slices%.Sort%s*%(") or line:match("slices%.Equal%s*%(") or
     line:match("slices%.Contains%s*%(") or line:match("slices%.Clone%s*%(") then
    return { time = "O(n log n)", is_call = true }
  end
  
  if line:match("slices%.Delete%s*%(") or line:match("slices%.Insert%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- maps package
  if line:match("maps%.Keys%s*%(") or line:match("maps%.Values%s*%(") or
     line:match("maps%.Equal%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- fmt package - printing operations
  if line:match("fmt%.Print%s*%(") or line:match("fmt%.Sprint%s*%(") or
     line:match("fmt%.Errorf%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("fmt%.Sprintf%s*%(") or line:match("fmt%.Fprintf%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("fmt%.Scan%s*%(") or line:match("fmt%.Fscan%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("fmt%.Sscan%s*%(") or line:match("fmt%.Fscan%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- os package - file operations
  if line:match("os%.Open%s*%(") or line:match("os%.Create%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("os%.ReadFile%s*%(") or line:match("os%.WriteFile%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("os%.Read%s*%(") or line:match("os%.Write%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("os%.Stat%s*%(") or line:match("os%.Lstat%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  if line:match("os%.ReadDir%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- path/filepath package
  if line:match("filepath%.Walk%s*%(") or line:match("filepath%.WalkDir%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("filepath%.Match%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- sort package - additional functions
  if line:match("sort%.IsSorted%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("sort%.Reverse%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  -- encoding packages
  if line:match("encoding%/binary%.Read%s*%(") or line:match("encoding%/binary%.Write%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("encoding%/base64%.NewDecoder%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- hash package
  if line:match("hash%.Hash%s*%(") or line:match("hash%.HashFunc%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  if line:match("hash%.New%s*%(") then
    return { time = "O(1)", is_call = true }
  end
  
  -- compress packages (gzip, zlib, etc.)
  if line:match("compress%.Gzip%.NewWriter%s*%(") or line:match("compress%.Gzip%.NewReader%s*%(") then
    return { time = "O(n)", is_call = true }
  end
  
  -- sort.SearchInts, sort.SearchStrings
  if line:match("sort%.SearchInts%s*%(") or line:match("sort%.SearchStrings%s*%(") or
     line:match("sort%.SearchFloat%s*%(") then
     return { time = "O(log n)", is_call = true }
  end
  
  -- Custom algorithm function detection (supports methods with receivers)
  local func_name = line:match("^func%s+%([^)]+%)%s+([%w_]+)%s*%(") or
                   line:match("^func%s+([%w_]+)%s*%(")
  if func_name then
    -- Graph algorithms
    if func_name:match("^dfs") or func_name:match("^bfs") then
      return { time = "O(V+E)", is_call = true }
    end
    
    if func_name:match("dijkstra") then
      return { time = "O(E log V)", is_call = true }
    end
    
    if func_name:match("floyd") or func_name:match("warshall") then
      return { time = "O(n³)", is_call = true }
    end
    
    if func_name:match("bellman") then
      return { time = "O(V×E)", is_call = true }
    end
    
    if func_name:match("topo") or func_name:match("topological") then
      return { time = "O(V+E)", is_call = true }
    end
    
    if func_name:match("kruskal") then
      return { time = "O(E log E)", is_call = true }
    end
    
    if func_name:match("prim") then
      return { time = "O(E log V)", is_call = true }
    end
    
    -- Searching algorithms
    if func_name:match("binary") and not func_name:match("search") then
      return { time = "O(log n)", is_call = true }
    end
    
    -- Sorting algorithms  
    if func_name:match("merge") and func_name:match("sort") then
      return { time = "O(n log n)", is_call = true }
    end
    
    if func_name:match("quick") and func_name:match("sort") then
      return { time = "O(n log n)", is_call = true }
    end
    
    if func_name:match("heap") and func_name:match("sort") then
      return { time = "O(n log n)", is_call = true }
    end
    
    -- String algorithms
    if func_name:match("kmp") or func_name:match("z_?algo") then
      return { time = "O(n)", is_call = true }
    end
    
    if func_name:match("manacher") then
      return { time = "O(n)", is_call = true }
    end
    
    -- Number theory
    if func_name:match("sieve") then
      return { time = "O(n log log n)", is_call = true }
    end
    
    if func_name:match("gcd") or func_name:match("lcm") then
      return { time = "O(log n)", is_call = true }
    end
    
    if func_name:match("prime") and func_name:match("factor") then
      return { time = "O(√n)", is_call = true }
    end
    
    if func_name:match("fast") and func_name:match("pow") then
      return { time = "O(log n)", is_call = true }
    end
    
    -- Data structures
    if func_name:match("segment") and func_name:match("tree") then
      return { time = "O(log n)", is_call = true }
    end
    
    if func_name:match("fenwick") or func_name:match("bit") then
      return { time = "O(log n)", is_call = true }
    end
    
    if func_name:match("disjoint") or func_name:match("union") or func_name:match("dsu") then
      return { time = "O(α(n))", is_call = true }
    end
    
    if func_name:match("trie") then
      return { time = "O(L)", is_call = true }
    end
    
    if func_name:match("lca") or func_name:match("lowest") and func_name:match("common") then
      return { time = "O(log n)", is_call = true }
    end
    
    if func_name:match("rmq") or func_name:match("sparse") then
      return { time = "O(n log n)", is_call = true }
    end
  end
  
  return nil
end

-- Analyze space complexity from declarations (Go only)
local function analyze_space(lines)
  local space_items = {}
  
  for i, line in ipairs(lines) do
    -- Skip function signatures - they don't allocate (parameters are references)
    if line:match("^func%s+") and line:match("%(") then
      -- skip function signatures
    else
      -- Go slice declarations: []T, make([]T, n)
      if line:match("[%[]%s*[%]]") or  -- []T slice
         line:match("make%s*[%[]%s*[%]]") or  -- make([]T, ...)
         line:match("map%s*[%[]") or  -- map[T]U or make(map[T]U)
         line:match("make%s*%([^)]*map") or  -- make(map[T]U, ...) with parentheses
         line:match("chan%s+") or  -- chan T
         line:match("make%s*%*chan") or  -- make(chan T, ...)
         line:match("buffered%s+chan") then
        
        local size = line:match("%[%s*(%w+)%s*%]") or line:match("%((%w+)%)")
        
        local go_size = line:match("make%s*%[%s*[^,]+%s*,%s*(%w+)%s*%]") or
                       line:match("make%s*map%[%s*[^,]+%s*,%s*[^%]]*%s*,%s*(%w+)%s*%)") or
                       line:match("make%s*%*chan%s*%[,%s*(%w+)%s*%)")
        
        if size and size:match("^%d+$") then
          table.insert(space_items, { line = i, complexity = "O(1)" })
        elseif go_size and go_size:match("^%d+$") then
          table.insert(space_items, { line = i, complexity = "O(1)" })
        elseif size or go_size then
          table.insert(space_items, { line = i, complexity = "O(n)" })
        else
          if line:match("%[%s*%]") then
            table.insert(space_items, { line = i, complexity = "O(n)" })
          elseif line:match("map%s*%[") then
            table.insert(space_items, { line = i, complexity = "O(n)" })
          elseif line:match("chan%s+") then
            table.insert(space_items, { line = i, complexity = "O(1)" })
          elseif line:match("make%s*%*chan") then
            table.insert(space_items, { line = i, complexity = "O(n)" })
          elseif line:match("var%s+%w+%s+map") then
            table.insert(space_items, { line = i, complexity = "O(1)" })
          else
            table.insert(space_items, { line = i, complexity = "O(n)" })
          end
        end
      end
    end
    
    -- 2D slices
    if line:match("[%[]%s*[%]]%s*[%[]%s*[%]]") then
      table.insert(space_items, { line = i, complexity = "O(n²)" })
    end
    
    -- slice of maps
    if line:match("[%[]%s*[%]]%s*map%s*%[") then
      table.insert(space_items, { line = i, complexity = "O(n²)" })
    end
  end
  
  local max_space = "O(1)"
  for _, item in ipairs(space_items) do
    max_space = get_dominant_complexity(max_space, item.complexity)
  end
  
  return max_space, space_items
end

-- Main analysis function
function M.analyze(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  
  local results = {
    loops = {},          -- { line, complexity, nesting_level }
    function_calls = {}, -- { line, complexity }
    space = "O(1)",      -- Overall space complexity
    space_items = {},    -- Individual space allocations
    overall_time = "O(1)", -- Overall time complexity
    functions = {},      -- Per-function complexity summaries
  }
  
  -- Track nesting level and current context
  local nesting_stack = {}
  local brace_depth = 0
  
  -- Track current function
  local current_function = nil
  local function_stack = {}
  
  -- Analyze space first
  results.space, results.space_items = analyze_space(lines)
  
  -- Analyze time complexity
  for i, line in ipairs(lines) do
    local trimmed = line:match("^%s*(.-)%s*$")
    
    -- Track opening braces for scope depth
    local open_braces = 0
    local close_braces = 0
    for c in line:gmatch(".") do
      if c == "{" then open_braces = open_braces + 1 end
      if c == "}" then close_braces = close_braces + 1 end
    end
    
    -- Detect function definitions (Go only)
    -- Supports: func name(), func (receiver) name(), func (r *Type) name(), method expressions
    local func_match = trimmed:match("^func%s+.*%(")
    
    if func_match and not trimmed:match("^if%s*%(") and not trimmed:match("^while%s*%(") and 
       not trimmed:match("^for%s*%(") and not trimmed:match("^switch%s*%(") then
      -- Extract function name from various Go function declarations
      -- Standard: func functionName(
      -- Method: func (receiver) functionName(
      -- Pointer receiver: func (r *Type) functionName(
      local func_name = trimmed:match("^func%s+%([^)]+%)%s+([%w_]+)%s*%(") or  -- method with receiver
                        trimmed:match("^func%s+([%w_]+)%s*%(") or  -- regular function
                        trimmed:match("^func%s+([%w_]+)%s+$")  -- forward declaration
      
      if func_name and func_name ~= "if" and func_name ~= "while" and 
         func_name ~= "for" and func_name ~= "switch" then
        -- Check if this is a divide-and-conquer algorithm
        local dc_time, dc_space = detect_divide_conquer(lines, i, func_name)
        
        -- Start tracking new function
        current_function = {
          name = func_name,
          line = i,
          time_complexity = dc_time or "O(1)",
          space_complexity = dc_space or "O(1)",
          start_depth = brace_depth + open_braces,
          is_divide_conquer = dc_time ~= nil,
        }
        table.insert(function_stack, current_function)
        
        -- Update overall time complexity if divide-and-conquer
        if dc_time then
          results.overall_time = get_dominant_complexity(results.overall_time, dc_time)
          results.space = get_dominant_complexity(results.space, dc_space)
        end
      end
    end
    
     -- Skip comments and empty lines
    if not trimmed:match("^//") and not trimmed:match("^%s*$") then
       
       -- Detect loops (Go-specific)
       local loop_type = nil
       local base_complexity = "O(1)"
        
        -- Go traditional for loop: for i := 0; i < n; i++
        if trimmed:match(CONTROL_PATTERNS.FOR_TRADITIONAL) then
          loop_type = "go_for"
          base_complexity = analyze_go_for_loop(trimmed, lines, i)
        -- Go range-based for loop: for i, v := range slice
        elseif trimmed:match(CONTROL_PATTERNS.RANGE_FOR) then
          loop_type = "range_for"
          base_complexity = analyze_go_for_loop(trimmed, lines, i)
        -- Go while-style for loop: for condition {
        elseif trimmed:match(CONTROL_PATTERNS.FOR_COND) then
          loop_type = "for_cond"
          base_complexity = analyze_go_for_loop(trimmed, lines, i)
        end
      
      if loop_type then
        -- Calculate effective complexity with nesting
        local effective = base_complexity
        for _, parent_complexity in ipairs(nesting_stack) do
          effective = multiply_complexity(parent_complexity, effective)
        end
        
        table.insert(results.loops, {
          line = i,
          complexity = effective,
          base_complexity = base_complexity,
          nesting_level = #nesting_stack,
        })
        
        -- Push to stack
        table.insert(nesting_stack, base_complexity)
         
        -- Update overall time complexity - compare and take dominant
        -- Skip for divide-and-conquer functions as they have their own complexity
        if effective ~= "O(1)" and not (current_function and current_function.is_divide_conquer) then
          results.overall_time = get_dominant_complexity(results.overall_time, effective)
          -- Update current function complexity
          if current_function and not current_function.is_divide_conquer then
            current_function.time_complexity = get_dominant_complexity(
              current_function.time_complexity, effective)
          end
        end
      end
      
      -- Detect closing braces to pop nesting
      if trimmed:match("^}") and #nesting_stack > 0 then
        table.remove(nesting_stack)
      end
      
      -- Detect function calls
      local func_analysis = analyze_function_call(trimmed)
      if func_analysis then
        -- Calculate effective complexity considering current nesting
        local call_base_complexity = func_analysis.time
        local effective_call_complexity = call_base_complexity
        
        -- If we're inside loops, multiply the function call complexity
        for _, parent_complexity in ipairs(nesting_stack) do
          effective_call_complexity = multiply_complexity(parent_complexity, effective_call_complexity)
        end
        
        table.insert(results.function_calls, {
          line = i,
          complexity = effective_call_complexity,
          base_complexity = call_base_complexity,
          nesting_level = #nesting_stack,
        })
        
        -- Update overall time complexity with effective function call complexity
        if effective_call_complexity ~= "O(1)" then
          results.overall_time = get_dominant_complexity(results.overall_time, effective_call_complexity)
          -- Update current function complexity
          if current_function then
            current_function.time_complexity = get_dominant_complexity(
              current_function.time_complexity, effective_call_complexity)
          end
        end
      end
    end
    
    -- Update brace depth
    brace_depth = brace_depth + open_braces - close_braces
    
    -- Check if we're exiting a function
    if current_function and brace_depth < current_function.start_depth then
      -- Function ended, save it to results
      table.insert(results.functions, {
        name = current_function.name,
        line = current_function.line,
        time_complexity = current_function.time_complexity,
        space_complexity = current_function.space_complexity,
      })
      table.remove(function_stack)
      current_function = function_stack[#function_stack]
      -- Clear nesting stack when exiting a function
      nesting_stack = {}
    end
  end
  
  -- Add any remaining functions
  for _, func in ipairs(function_stack) do
    table.insert(results.functions, {
      name = func.name,
      line = func.line,
      time_complexity = func.time_complexity,
      space_complexity = func.space_complexity,
    })
  end
  
  return results
end

return M
