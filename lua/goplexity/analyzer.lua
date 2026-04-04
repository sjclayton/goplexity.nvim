-- Complexity Analyzer - Rule-based static analysis for Go

local M = {}

local CONSTANTS = {
  DEFAULT_COMPLEXITY = 'O(1)',
  DEFAULT_RANK = 100,
}

-- Pattern matchers for control structures
local CONTROL_PATTERNS = {
   FOR_TRADITIONAL = '^for%s+[%w_]', -- Go traditional: for i := 0; ... or for i = 0; ...
   RANGE_FOR = '^for%s+[%w_].*:?=%s*[^=].*range', -- for i, v := range slice
   FOR_COND = '^for%s+[^;{]', -- Go while-style: for condition { or for condition
}

-- Complexity hierarchy (from lowest to highest)
local COMPLEXITY_HIERARCHY = {
  ['O(1)'] = 1,
  ['O(α(n))'] = 2, -- Union-Find amortized
  ['O(log n)'] = 3,
  ['O(log² n)'] = 4,
  ['O(√n)'] = 5,
  ['O(L)'] = 6, -- Trie operations
  ['O(n)'] = 7,
  ['O(n log n)'] = 8,
  ['O(n log log n)'] = 9, -- Sieve
  ['O(n√n)'] = 10,
  ['O(n²)'] = 11,
  ['O(n² log n)'] = 12,
  ['O(n³)'] = 13,
  ['O(V+E)'] = 14, -- Graph traversal
  ['O(V×E)'] = 15, -- Bellman-Ford
  ['O(E log V)'] = 16, -- Dijkstra
  ['O(2^n)'] = 17,
  ['O(n!)'] = 18,
}

-- Compare two complexity strings and return the dominant (higher) one
local function get_dominant_complexity(complexity1, complexity2)
  local rank1 = COMPLEXITY_HIERARCHY[complexity1] or CONSTANTS.DEFAULT_RANK
  local rank2 = COMPLEXITY_HIERARCHY[complexity2] or CONSTANTS.DEFAULT_RANK

  return rank1 >= rank2 and complexity1 or complexity2
end

-- Multiplication lookup table for common complexity combinations
local COMPLEXITY_MULTIPLICATION = {
  ['n|n'] = 'O(n²)',
  ['n|log n'] = 'O(n log n)',
  ['log n|n'] = 'O(n log n)',
  ['n|n log n'] = 'O(n² log n)',
  ['n log n|n'] = 'O(n² log n)',
  ['n²|n'] = 'O(n³)',
  ['n|n²'] = 'O(n³)',
  ['log n|log n'] = 'O(log² n)',
  ['√n|n'] = 'O(n√n)',
  ['n|√n'] = 'O(n√n)',
  ['n log log n|n'] = 'O(n² log log n)',
  ['n|n log log n'] = 'O(n² log log n)',
  ['2^n|n'] = 'O(n × 2^n)',
  ['n|2^n'] = 'O(n × 2^n)',
  ['n!|n'] = 'O(n × n!)',
  ['n|n!'] = 'O(n × n!)',
}

-- Extract inner complexity from O(...) notation
local function extract_inner_complexity(complexity)
  return complexity:match('O%((.+)%)')
end

-- Multiply two complexity strings (for nested operations)
local function multiply_complexity(complexity1, complexity2)
  -- O(1) is identity for multiplication
  if complexity1 == CONSTANTS.DEFAULT_COMPLEXITY then
    return complexity2
  end
  if complexity2 == CONSTANTS.DEFAULT_COMPLEXITY then
    return complexity1
  end

  local inner1 = extract_inner_complexity(complexity1)
  local inner2 = extract_inner_complexity(complexity2)

  if not inner1 or not inner2 then
    return 'O(n²)'
  end

  -- Check multiplication lookup table
  local key = inner1 .. '|' .. inner2
  if COMPLEXITY_MULTIPLICATION[key] then
    return COMPLEXITY_MULTIPLICATION[key]
  end

  -- Default: show as multiplication
  return 'O(' .. inner1 .. ' × ' .. inner2 .. ')'
end

-- Check if line contains square root pattern
local function is_sqrt_pattern(line)
  return line:match('[%w_]+%s*%*%s*[%w_]+%s*[<>]=?%s*[%w_]+') or line:match('sqrt%s*%(')
end

-- Detect binary search pattern by analyzing function content
local function detect_binary_search(lines, start_line)
  local func_content = {}
  local brace_count = 0
  for i = start_line, #lines do
    local line = lines[i]
    table.insert(func_content, line)
    for c in line:gmatch('.') do
      if c == '{' then
        brace_count = brace_count + 1
      end
      if c == '}' then
        brace_count = brace_count - 1
      end
    end
    if brace_count == 0 and #func_content > 1 then
      break
    end
  end

  local content = table.concat(func_content, ' ')

  -- Binary search patterns (simplified and more lenient):
  -- 1. Has left and right variables
  -- 2. Has mid calculation (typically: mid := left + (right-left)/2)
  -- 3. Has left <= right or left < right condition
  -- 4. Updates left or right based on mid

  local has_left_right = content:match('left') and content:match('right')
  local has_mid = content:match('mid') and (content:match(':=') or content:match('='))
  local has_condition = content:match('left%s*<=') or content:match('left%s*<')
  local has_mid_update = content:match('left%s*=%s*mid') or content:match('right%s*=%s*mid')

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
    for c in line:gmatch('.') do
      if c == '{' then
        brace_count = brace_count + 1
      end
      if c == '}' then
        brace_count = brace_count - 1
      end
    end
    if brace_count == 0 and #func_content > 1 then
      break
    end
  end

  local content = table.concat(func_content, ' ')

  -- Check for slice operation pattern (Go slice: arr[:mid] or arr[mid:])
  -- Or partition pattern with append
  local has_slice_operation = content:match(':%s*%]') or content:match('%[:%s*%w+%s*%]')
  local has_recursive_call = content:match(func_name .. '%s*%(')
  local has_partition_pattern = content:match('left.*right') and content:match('append')
  local has_mid_split = content:match('mid') and content:match(':%s*%]')

  -- Merge sort: name contains "merge" and has slice operations with recursive calls
  local is_merge_sort = (func_name:match('merge') or func_name:match('Merge'))
    and (has_slice_operation or has_partition_pattern)

  -- Quick sort: name contains "quick" and has partition pattern with recursive calls
  local is_quick_sort = (func_name:match('quick') or func_name:match('Quick'))
    and (has_slice_operation or has_partition_pattern)
    and has_recursive_call

  -- Generic divide-and-conquer: requires name suggesting D&C + recursive calls + split pattern
  local has_dc_name = func_name:match('sort') or func_name:match('merge')
    or func_name:match('split') or func_name:match('divide')
  if is_merge_sort then
    return 'O(n log n)', 'O(n)' -- time, space
  elseif is_quick_sort then
    return 'O(n log n)', 'O(log n)' -- time, space (average)
  elseif has_dc_name and has_recursive_call and has_mid_split then
    -- Generic divide-and-conquer detected
    return 'O(n log n)', 'O(n)' -- Assume O(n log n) for divide-and-conquer
  end

  return nil, nil -- Not detected
end

-- Check if a line contains a logarithmic increment pattern
local function is_log_increment(line)
  return
    line:match('[%w_]+%s*%*=%s*2') -- i *= 2
    or line:match('[%w_]+%s*/=%s*2') -- i /= 2
    or line:match('[%w_]+%s*<<=') -- i <<= 1
    or line:match('[%w_]+%s*>>=') -- i >>= 1
    or line:match('[%w_]+%s*=%s*[%w_]+%s*%*%s*2') -- i = i * 2
    or line:match('[%w_]+%s*=%s*[%w_]+%s*/%s*2') -- i = i / 2
end

-- Check if a line contains a self-doubling increment
local function is_self_double(line)
  local var = line:match('([%w_]+)%s*%+=%s*[%w_]+')
  return var and line:match(var .. '%s*%+=%s*' .. var)
end

-- Scan loop body for log increment patterns in the first few lines
local function scan_body_for_log_increment(lines, start_line)
  local brace_count = 0
  local scanned = 0
  for i = start_line, math.min(start_line + 10, #lines) do
    local line = lines[i]
    for c in line:gmatch('.') do
      if c == '{' then brace_count = brace_count + 1 end
      if c == '}' then brace_count = brace_count - 1 end
    end
    if is_log_increment(line) or is_self_double(line) then
      return true
    end
    scanned = scanned + 1
    if brace_count <= 0 and scanned > 0 then
      break
    end
  end
  return false
end

-- Analyze Go for loop complexity from its structure
local function analyze_go_for_loop(line, lines, current_line)
  -- Go range-based for loop: for i, v := range slice
  if line:match(CONTROL_PATTERNS.RANGE_FOR) then
    return 'O(n)' -- Default for range over slices/maps/channels
  end

  -- Go traditional for loop: for i := 0; i < n; i++
  -- Extract increment to detect logarithmic patterns
  local init, cond, increment = line:match('for%s+(.-);%s*(.-);%s*(.-)%s*%{?%s*$')

  if increment then
    -- Check if the condition uses ONLY a literal number > 1 (constant iterations)
    -- e.g., "i < 10" but NOT "i < n-1", "i < len(arr)", or "i > 0"
    -- The number must be >= 2 (single digit 2-9 or multi-digit)
    if cond and (cond:match('^%s*[%w_]+%s*[<>]=?%s*[2-9]%s*$') or cond:match('^%s*[%w_]+%s*[<>]=?%s*%d%d+%s*$')) then
      return 'O(1)' -- Constant number of iterations
    end
    -- Check for square root pattern in condition: i*i <= n
    if cond and cond:match('[%w_]+%s*%*%s*[%w_]+%s*[<>]=?') then
      return 'O(√n)'
    end
    -- Check for logarithmic patterns
    if
      increment:match('[%w_]+%s*%*=%s*2') -- i *= 2
      or increment:match('[%w_]+%s*/=%s*2') -- i /= 2
      or increment:match('[%w_]+%s*<<=') -- i <<= 1
      or increment:match('[%w_]+%s*>>=') -- i >>= 1
      or increment:match('[%w_]+%s*=%s*[%w_]+%s*%*%s*2') -- i = i * 2
      or increment:match('[%w_]+%s*=%s*[%w_]+%s*/%s*2')
    then -- i = i / 2
      return 'O(log n)'
    end
    -- Check for i += i patterns (also logarithmic)
    local var = increment:match('([%w_]+)%s*%+=')
    if var and increment:match(var .. '%s*%+=%s*' .. var) then
      return 'O(log n)'
    end
    -- Check for i++ or ++i patterns (linear)
    if increment:match('%+%s*%+') or increment:match('%-%s*-') then
      return 'O(n)'
    end
    return 'O(n)' -- Default for traditional for loops
  end

  -- Go condition-based for loop: for condition {
  if line:match(CONTROL_PATTERNS.FOR_COND) then
    -- Check if it's actually an infinite loop: for {
    if line:match('^for%s*{$') then
      return 'O(n)' -- Default assumption for infinite loops
    end
    -- Check for square root pattern in condition: i*i <= n
    if line:match('[%w_]+%s*%*%s*[%w_]+%s*[<>]=?') then
      return 'O(√n)'
    end
    -- Check for binary search pattern
    if detect_binary_search(lines, current_line) then
      return 'O(log n)'
    end
    -- Check body for log increment patterns (e.g., for i := 1; i < n; { i *= 2 })
    if scan_body_for_log_increment(lines, current_line + 1) then
      return 'O(log n)'
    end
    -- While-style loop without recognizable pattern
    return 'O(n)'
  end

  return 'O(n)'
end

-- Detect standard library function complexities (Go only)
local function analyze_function_call(line)
  -- Go standard library functions
  -- Sorting and searching
  if line:match('sort%.Slice%s*%(') or line:match('sort%.SliceStable%s*%(') then
    return { time = 'O(n log n)' }
  end

  if line:match('sort%.Search%s*%(') then
    return { time = 'O(log n)' }
  end

  if line:match('sort%.Ints%s*%(') or line:match('sort%.Strings%s*%(') then
    return { time = 'O(n log n)' }
  end

  -- Container operations
  if line:match('append%s*%(') then
    return { time = 'O(1)' }
  end

  if line:match('copy%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('delete%s*%(') then
    return { time = 'O(1)' }
  end

  if line:match('len%s*%(') or line:match('cap%s*%(') then
    return { time = 'O(1)' }
  end

  -- String operations
  if line:match('strings%.Split%s*%(') or line:match('strings%.Join%s*%(') then
    return { time = 'O(n)' }
  end

  if
    line:match('strings%.Contains%s*%(')
    or line:match('strings%.HasPrefix%s*%(')
    or line:match('strings%.HasSuffix%s*%(')
    or line:match('strings%.Index%s*%(')
  then
    return { time = 'O(n)' }
  end

  if
    line:match('strings%.ToLower%s*%(')
    or line:match('strings%.ToUpper%s*%(')
    or line:match('strings%.Trim%s*%(')
    or line:match('strings%.Replace%s*%(')
  then
    return { time = 'O(n)' }
  end

  if line:match('strings%.Count%s*%(') then
    return { time = 'O(n)' }
  end

  -- Bytes operations
  if line:match('bytes%.Equal%s*%(') or line:match('bytes%.Compare%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('bytes%.Split%s*%(') or line:match('bytes%.Join%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('bytes%.NewBuffer%s*%(') then
    return { time = 'O(1)' }
  end

  if line:match('bytes%.NewBufferString%s*%(') then
    return { time = 'O(n)' }
  end

  -- strconv operations
  if line:match('strconv%.Atoi%s*%(') or line:match('strconv%.Itoa%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('strconv%.ParseInt%s*%(') or line:match('strconv%.FormatInt%s*%(') then
    return { time = 'O(n)' }
  end

  -- regexp operations
  if line:match('regexp%.Compile%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('regexp%.Match%s*%(') or line:match('Regexp%.Match%s*%(') or line:match('Regexp%.Find%s*%(') or line:match('Regexp%.FindAll%s*%(') then
    return { time = 'O(n)' }
  end

  -- I/O operations
  if line:match('bufio%.NewReader') or line:match('bufio%.NewWriter') then
    return { time = 'O(1)' }
  end

  if line:match('%.Scan%s*%(') and line:match('bufio') then
    return { time = 'O(n)' }
  end

  if line:match('io%.ReadFull%s*%(') or line:match('io%.Copy%s*%(') then
    return { time = 'O(n)' }
  end

  -- JSON operations
  if line:match('json%.Unmarshal%s*%(') or line:match('json%.Marshal%s*%(') then
    return { time = 'O(n)' }
  end

  -- Hashing and crypto
  if line:match('sha256%.Sum256%s*%(') or line:match('md5%.Sum%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('sha256%.New%s*%(') or line:match('sha512%.New%s*%(') or line:match('md5%.New%s*%(') then
    return { time = 'O(1)' }
  end

  if line:match('Hash%.Write%s*%(') or line:match('h%.Write%s*%(') or line:match('h%.Sum%s*%(') then
    return { time = 'O(n)' }
  end

  -- time operations
  if line:match('time%.Now%s*%(') or line:match('time%.Sleep%s*%(') then
    return { time = 'O(1)' }
  end

  if line:match('time%.Since%s*%(') or line:match('time%.Until%s*%(') then
    return { time = 'O(1)' }
  end

  -- sync primitives
  if line:match('%.Lock%s*%(') or line:match('%.Unlock%s*%(') then
    return { time = 'O(1)' }
  end

  if line:match('sync%.Once%.Do%s*%(') then
    return { time = 'O(1)' }
  end

  if line:match('%.WaitGroup%.Wait%s*%(') or line:match('wg%.Wait%s*%(') then
    return { time = 'O(n)' }
  end

  -- context operations
  if line:match('context%.Background%s*%(') or line:match('context%.TODO%s*%(') then
    return { time = 'O(1)' }
  end

  if
    line:match('context%.WithTimeout%s*%(')
    or line:match('context%.WithCancel%s*%(')
    or line:match('context%.WithDeadline%s*%(')
  then
    return { time = 'O(1)' }
  end

  -- select statement - channel operations
  if line:match('^%s*select%s*{') then
    return { time = 'O(1)' }
  end

  -- goroutine - creates concurrent execution
  if line:match('^%s*go%s+') then
    return { time = 'O(n)' }
  end

  -- defer - O(1) for registration
  if line:match('^%s*defer%s+') then
    return { time = 'O(1)' }
  end

  -- Bit operations
  if
    line:match('bits%.OnesCount%s*%(')
    or line:match('bits%.LeadingZeros%s*%(')
    or line:match('bits%.TrailingZeros%s*%(')
    or line:match('bits%.RotateLeft%s*%(')
  then
    return { time = 'O(1)' }
  end

  -- math package operations
  if
    line:match('math%.Abs%s*%(')
    or line:match('math%.Max%s*%(')
    or line:match('math%.Min%s*%(')
    or line:match('math%.Ceil%s*%(')
    or line:match('math%.Floor%s*%(')
    or line:match('math%.Round%s*%(')
  then
    return { time = 'O(1)' }
  end

  if
    line:match('math%.Pow%s*%(')
    or line:match('math%.Sqrt%s*%(')
    or line:match('math%.Log%s*%(')
    or line:match('math%.Exp%s*%(')
  then
    return { time = 'O(1)' }
  end

  if
    line:match('math%.Sin%s*%(')
    or line:match('math%.Cos%s*%(')
    or line:match('math%.Tan%s*%(')
    or line:match('math%.Atan2%s*%(')
  then
    return { time = 'O(1)' }
  end

  -- math/big operations
  if line:match('big%.NewInt%s*%(') or line:match('big%.NewFloat%s*%(') then
    return { time = 'O(1)' }
  end

  if line:match('big%.Int%.Add%s*%(') or line:match('big%.Int%.Mul%s*%(') or line:match('big%.Int%.Div%s*%(') or line:match('big%.Int%.Sub%s*%(') or line:match('%.Add%s*%(') and line:match('big%.Int') or line:match('%.Mul%s*%(') and line:match('big%.Int') or line:match('%.Div%s*%(') and line:match('big%.Int') or line:match('%.Sub%s*%(') and line:match('big%.Int') then
    return { time = 'O(n)' }
  end

  -- sort.SearchInts, sort.SearchStrings
  if
    line:match('sort%.SearchInts%s*%(')
    or line:match('sort%.SearchStrings%s*%(')
    or line:match('sort%.SearchFloat64s%s*%(')
  then
    return { time = 'O(log n)' }
  end

  -- container/heap operations
  if line:match('heap%.Init%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('heap%.Push%s*%(') or line:match('heap%.Pop%s*%(') or line:match('heap%.Fix%s*%(') or line:match('heap%.Remove%s*%(') then
    return { time = 'O(log n)' }
  end

  -- container/list operations
  if line:match('list%.New%s*%(') then
    return { time = 'O(1)' }
  end

  if line:match('%.PushBack%s*%(') or line:match('%.PushFront%s*%(') or line:match('%.Remove%s*%(') then
    return { time = 'O(1)' }
  end

  -- container/ring operations
  if line:match('ring%.New%s*%(') then
    return { time = 'O(n)' }
  end

  -- slices package
  if line:match('slices%.Sort%s*%(') or line:match('slices%.SortFunc%s*%(') or line:match('slices%.SortStableFunc%s*%(') then
    return { time = 'O(n log n)' }
  end

  if line:match('slices%.BinarySearch%s*%(') or line:match('slices%.BinarySearchFunc%s*%(') then
    return { time = 'O(log n)' }
  end

  if
    line:match('slices%.Equal%s*%(')
    or line:match('slices%.Contains%s*%(')
    or line:match('slices%.Clone%s*%(')
    or line:match('slices%.ContainsFunc%s*%(')
    or line:match('slices%.IndexFunc%s*%(')
  then
    return { time = 'O(n)' }
  end

  if line:match('slices%.Delete%s*%(') or line:match('slices%.Insert%s*%(') then
    return { time = 'O(n)' }
  end

  -- maps package
  if line:match('maps%.Keys%s*%(') or line:match('maps%.Values%s*%(') or line:match('maps%.Equal%s*%(') or line:match('maps%.Clone%s*%(') or line:match('maps%.Copy%s*%(') then
    return { time = 'O(n)' }
  end

  -- fmt package - printing operations
  if line:match('fmt%.Print%s*%(') or line:match('fmt%.Printf%s*%(') or line:match('fmt%.Println%s*%(') or line:match('fmt%.Sprint%s*%(') or line:match('fmt%.Errorf%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('fmt%.Sprintf%s*%(') or line:match('fmt%.Fprintf%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('fmt%.Scan%s*%(') or line:match('fmt%.Fscan%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('fmt%.Sscan%s*%(') then
    return { time = 'O(n)' }
  end

  -- os package - file operations
  if line:match('os%.Open%s*%(') or line:match('os%.Create%s*%(') then
    return { time = 'O(1)' }
  end

  if line:match('os%.ReadFile%s*%(') or line:match('os%.WriteFile%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('os%.Read%s*%(') or line:match('os%.Write%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('os%.Stat%s*%(') or line:match('os%.Lstat%s*%(') then
    return { time = 'O(1)' }
  end

  if line:match('os%.ReadDir%s*%(') then
    return { time = 'O(n)' }
  end

  -- path/filepath package
  if line:match('filepath%.Walk%s*%(') or line:match('filepath%.WalkDir%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('filepath%.Match%s*%(') then
    return { time = 'O(n)' }
  end

  -- sort package - additional functions
  if line:match('sort%.IsSorted%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('sort%.Reverse%s*%(') then
    return { time = 'O(1)' }
  end

  -- encoding packages
  if line:match('binary%.Read%s*%(') or line:match('binary%.Write%s*%(') then
    return { time = 'O(n)' }
  end

  if line:match('base64%.NewDecoder%s*%(') or line:match('base64%.NewEncoder%s*%(') then
    return { time = 'O(n)' }
  end

  -- hash package
  if line:match('hash%.New%s*%(') then
    return { time = 'O(1)' }
  end

  -- compress packages (gzip, zlib, etc.)
  if line:match('gzip%.NewWriter%s*%(') or line:match('gzip%.NewReader%s*%(') then
    return { time = 'O(n)' }
  end

  return nil
end

-- Detect algorithms by analyzing function content (structural and name-based patterns)
local function detect_algorithm_by_content(lines, start_line, func_name)
  local func_content = {}
  local brace_count = 0
  for i = start_line, #lines do
    local line = lines[i]
    func_content[#func_content + 1] = line
    for c in line:gmatch('.') do
      if c == '{' then
        brace_count = brace_count + 1
      end
      if c == '}' then
        brace_count = brace_count - 1
      end
    end
    if brace_count == 0 and #func_content > 1 then
      break
    end
  end

  local content = table.concat(func_content, ' ')

  -- Graph: DFS/BFS - adjacency list + visited set + recursive/queue traversal
  local has_adjacency = content:match('adj') or content:match('neighbors') or content:match('graph')
  local has_visited = content:match('visited') or content:match('seen') or content:match('visit%s*%[')
  local has_recursive_call = func_name and content:match(func_name .. '%s*%(')
  local has_queue_ops = content:match('queue') or content:match('push%s*%(') or content:match('pop%s*%(')

  -- Prim: visited set + min-weight/key selection (no queue or heap)
  -- Must check BEFORE generic graph traversal to avoid false positive
  local has_min_weight = (content:match('min') or content:match('Min')) and (content:match('weight') or content:match('cost') or content:match('key'))
  if has_adjacency and has_visited and has_min_weight and not has_queue_ops and not content:match('heap') then
    return 'O(V²)', 'O(V)'
  end

  if has_adjacency and has_visited then
    if has_recursive_call or content:match('dfs') or content:match('DFS') then
      return 'O(V+E)', 'O(V)'
    elseif has_queue_ops or content:match('bfs') or content:match('BFS') then
      return 'O(V+E)', 'O(V)'
    else
      return 'O(V+E)', 'O(V)'
    end
  end

  -- Dijkstra: distance array + heap/priority queue + relaxation
  local has_dist = content:match('dist')
  local has_pq = content:match('heap') or content:match('priority') or content:match('container/heap')
  local has_relaxation = content:match('dist%[') and content:match('%+') and content:match('<')
  local has_sentinel = content:match('1e9') or content:match('math%.Inf') or content:match('MAX_INT')
  if has_dist and has_pq and has_sentinel then
    return 'O(E log V)', 'O(V)'
  end

  -- Bellman-Ford: n-1 iterations over edges + relaxation with sentinel value
  local has_edges = content:match('edges') or content:match('Edge')
  local has_n_minus_1 = content:match('n %- 1') or content:match('n%-1')
  if has_dist and has_edges and has_sentinel and has_n_minus_1 then
    return 'O(V×E)', 'O(V)'
  end

  -- Floyd-Warshall: triple nested loops + dist[i][j] pattern
  local has_triple_loop = content:match('for .- = .* for .- = .* for .- =')
  local has_dist_matrix = content:match('dist%[.*%]%[.*%]')
  if has_triple_loop or (has_dist_matrix and content:match('min')) then
    return 'O(n³)', 'O(n²)'
  end

  -- Topological sort: in-degree counting + queue
  local has_indegree = content:match('indegree') or content:match('in_degree') or content:match('degree')
  local has_zero_indegree = content:match('degree%s*==%s*0') or content:match('degree%s*==%s*0')
  if has_adjacency and has_indegree and has_queue_ops then
    return 'O(V+E)', 'O(V)'
  end

  -- Kruskal: edge sorting + union-find
  local has_edge_sort = (content:match('sort') or content:match('Sort')) and content:match('edges')
  local has_union_find = content:match('parent') and content:match('find') and content:match('union')
  if has_edge_sort and has_union_find then
    return 'O(E log E)', 'O(V)'
  end

  -- Binary search: left/right/mid pattern
  local has_left_right = content:match('left') and content:match('right')
  local has_mid = content:match('mid')
  local has_bs_condition = content:match('left%s*<=') or content:match('left%s*<')
  local has_mid_update = content:match('left%s*=%s*mid') or content:match('right%s*=%s*mid')
  if has_left_right and has_mid and has_bs_condition and has_mid_update then
    return 'O(log n)', 'O(1)'
  end

  -- Merge sort: mid split + recursive calls + merge
  local has_mid_split = content:match('mid') and content:match(':%s*%]')
  local has_merge = content:match('merge') or content:match('Merge')
  if (has_mid_split or has_merge) and has_recursive_call then
    return 'O(n log n)', 'O(n)'
  end

  -- Quick sort: pivot + partition + recursive calls
  local has_pivot = content:match('pivot')
  local has_partition = content:match('partition') or (content:match('left.*right') and content:match('swap'))
  if (has_pivot or has_partition) and has_recursive_call then
    return 'O(n log n)', 'O(log n)'
  end

  -- Sieve of Eratosthenes: boolean array + marking multiples
  local has_bool_array = content:match('isPrime') or content:match('prime') or content:match('composite')
  local has_sieve_loop = content:match('i%s*%*%s*i') or content:match('i%s*%*%s*2')
  if has_bool_array and has_sieve_loop then
    return 'O(n log log n)', 'O(n)'
  end

  -- GCD: modulo with b == 0 base case
  if content:match('%%') and content:match('[%w_]%s*==%s*0') then
    return 'O(log n)', 'O(1)'
  end

  -- Union-Find/DSU: parent array + find with path compression
  if has_union_find then
    return 'O(α(n))', 'O(n)'
  end

  -- Trie: children map/array + character traversal
  local has_trie_children = content:match('children') and (content:match('map') or content:match('%[26%]') or content:match('%[256%]') or content:match('rune') or content:match('byte'))
  local has_char_traversal = content:match('%-%s*%\'a\'') or content:match('%-%s*%\'0\'') or content:match('for .- := range') or content:match('for .-, .- := range')
  if has_trie_children and has_char_traversal then
    return 'O(L)', 'O(L * Σ)'
  end

  -- Segment tree: array size 4*n + 2*node children
  local has_seg_tree_size = content:match('4%s*%*%s*n')
  local has_node_children = content:match('2%s*%*%s*node') or content:match('node%s*%*%s*2')
  if has_seg_tree_size or has_node_children then
    return 'O(log n)', 'O(n)'
  end

  -- KMP: prefix/lps array computation
  local has_lps = content:match('lps') or content:match('prefix') or content:match('pi%s*%[')
  local has_kmp_match = content:match('j%s*>%s*0') and content:match('j%s*=%s*')
  if has_lps and has_kmp_match then
    return 'O(n)', 'O(m)'
  end

  return nil, nil
end

-- Analyze space complexity from declarations (Go only)
local function analyze_space(lines)
  local space_items = {}

  local skip_until = 0

  for i, line in ipairs(lines) do
    if i < skip_until then
      goto continue
    end

    -- Skip function signatures (including multi-line) - parameters are references
    if line:match('^func%s+') then
      local j = i
      while j <= #lines and not lines[j]:match('{') do
        j = j + 1
      end
      skip_until = j + 1
      goto continue
    end

    -- Skip slice/map literals with small inline data: []int{1, 2, 3}
    if line:match('%[%s*%]%s*{') and not line:match('make%s*%[%s*') then
      goto continue
    end

    -- Detect actual space-allocating declarations
    if
      line:match('make%s*%[%s*') -- make([]T, ...)
      or line:match('make%s*%(map') -- make(map[T]U, ...)
      or line:match('make%s*%(chan') -- make(chan T, ...)
    then
      local go_size = line:match('make%s*%[%s*[^,]+%s*,%s*(%w+)%s*%]')
        or line:match('make%s*%(chan%s+[^,]+%s*,%s*(%w+)%s*%)')

      if go_size and go_size:match('^%d+$') then
        table.insert(space_items, { line = i, complexity = 'O(1)' })
      elseif go_size then
        table.insert(space_items, { line = i, complexity = 'O(n)' })
      elseif line:match('make%s*%[%s*') then
        local make_size = line:match('make%s*%[%s*[^,]+%s*,%s*([^%)]+)')
        if make_size and make_size:match('^%d+$') then
          table.insert(space_items, { line = i, complexity = 'O(1)' })
        else
          table.insert(space_items, { line = i, complexity = 'O(n)' })
        end
      elseif line:match('make%s*%(chan') then
        local chan_size = line:match('make%s*%(chan%s+[^,]+%s*,%s*([^%)]+)')
        if chan_size and chan_size:match('^%d+$') then
          table.insert(space_items, { line = i, complexity = 'O(1)' })
        elseif chan_size then
          table.insert(space_items, { line = i, complexity = 'O(n)' })
        else
          table.insert(space_items, { line = i, complexity = 'O(1)' })
        end
      elseif line:match('make%s*%(map') then
        table.insert(space_items, { line = i, complexity = 'O(n)' })
      end
    end

    -- Detect new() allocations: new(int), new(Type)
    if line:match('new%s*%(') then
      table.insert(space_items, { line = i, complexity = 'O(1)' })
    end

    -- 2D slices (only make() calls, not literals)
    if line:match('make%s*%(%[%]%[%]') then
      table.insert(space_items, { line = i, complexity = 'O(n²)' })
    end

    -- slice of maps (only make() calls)
    if line:match('make%s*%(%[%]%[%].*map') then
      table.insert(space_items, { line = i, complexity = 'O(n²)' })
    end

    ::continue::
  end

  local max_space = 'O(1)'
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
    loops = {}, -- { line, complexity, nesting_level }
    function_calls = {}, -- { line, complexity }
    space = 'O(1)', -- Overall space complexity
    space_items = {}, -- Individual space allocations
    overall_time = 'O(1)', -- Overall time complexity
    functions = {}, -- Per-function complexity summaries
  }

  -- Track nesting level and current context
  local nesting_stack = {}
  local brace_depth = 0

  -- Track current function
  local current_function = nil
  local function_stack = {}

  results.space, results.space_items = analyze_space(lines)

  for i, line in ipairs(lines) do
    local trimmed = line:match('^%s*(.-)%s*$')

    -- Track opening braces for scope depth
    local open_braces = 0
    local close_braces = 0
    for c in line:gmatch('.') do
      if c == '{' then
        open_braces = open_braces + 1
      end
      if c == '}' then
        close_braces = close_braces + 1
      end
    end

    -- Detect function definitions (Go only)
    -- Supports: func name(), func (receiver) name(), func (r *Type) name(), method expressions
    local func_match = trimmed:match('^func%s+.*%(')

    if
      func_match
      and not trimmed:match('^if%s*%(')
      and not trimmed:match('^while%s*%(')
      and not trimmed:match('^for%s*%(')
      and not trimmed:match('^switch%s*%(')
    then
      -- Extract function name from various Go function declarations
      -- Standard: func functionName(
      -- Method: func (receiver) functionName(
      -- Pointer receiver: func (r *Type) functionName(
      local func_name = trimmed:match('^func%s+%([^)]+%)%s+([%w_]+)%s*%(') -- method with receiver
        or trimmed:match('^func%s+([%w_]+)%s*%(') -- regular function
        or trimmed:match('^func%s+([%w_]+)%s+$') -- forward declaration

      if func_name and func_name ~= 'if' and func_name ~= 'while' and func_name ~= 'for' and func_name ~= 'switch' then
        -- Check if this is a divide-and-conquer algorithm
        local dc_time, dc_space = detect_divide_conquer(lines, i, func_name)

        -- Check for content-based algorithm patterns
        local algo_time, algo_space = detect_algorithm_by_content(lines, i, func_name)

        current_function = {
          name = func_name,
          line = i,
          time_complexity = dc_time or algo_time or 'O(1)',
          space_complexity = dc_space or algo_space or 'O(1)',
          start_depth = brace_depth + open_braces,
          is_divide_conquer = dc_time ~= nil,
          is_algorithm = algo_time ~= nil,
        }
        table.insert(function_stack, current_function)

        -- Update overall time complexity if divide-and-conquer or algorithm detected
        if dc_time then
          results.overall_time = get_dominant_complexity(results.overall_time, dc_time)
          results.space = get_dominant_complexity(results.space, dc_space)
        elseif algo_time then
          results.overall_time = get_dominant_complexity(results.overall_time, algo_time)
          if algo_space then
            results.space = get_dominant_complexity(results.space, algo_space)
          end
        end
      end
    end

    -- Skip line comments and empty lines
    if not trimmed:match('^//') and not trimmed:match('^%s*$') then
      -- Detect loops (Go-specific)
      local loop_type = nil
      local base_complexity = 'O(1)'

      -- Go traditional for loop: for i := 0; i < n; i++
      if trimmed:match(CONTROL_PATTERNS.FOR_TRADITIONAL) then
        loop_type = 'go_for'
        base_complexity = analyze_go_for_loop(trimmed, lines, i)
        -- Go range-based for loop: for i, v := range slice
      elseif trimmed:match(CONTROL_PATTERNS.RANGE_FOR) then
        loop_type = 'range_for'
        base_complexity = analyze_go_for_loop(trimmed, lines, i)
        -- Go infinite loop: for {
      elseif trimmed:match('^for%s*{$') then
        loop_type = 'infinite_for'
        base_complexity = 'O(n)'
        -- Go while-style for loop: for condition {
      elseif trimmed:match(CONTROL_PATTERNS.FOR_COND) then
        loop_type = 'for_cond'
        base_complexity = analyze_go_for_loop(trimmed, lines, i)
      end

      if loop_type then
        -- Calculate effective complexity with nesting
        local effective = base_complexity
        for _, entry in ipairs(nesting_stack) do
          effective = multiply_complexity(entry.complexity, effective)
        end

        table.insert(results.loops, {
          line = i,
          complexity = effective,
          base_complexity = base_complexity,
          nesting_level = #nesting_stack,
        })

        -- Push to stack with depth tracking
        table.insert(nesting_stack, {
          complexity = base_complexity,
          depth = brace_depth + open_braces,
        })

        if effective ~= 'O(1)' and not (current_function and (current_function.is_divide_conquer or current_function.is_algorithm)) then
          results.overall_time = get_dominant_complexity(results.overall_time, effective)
          if current_function and not current_function.is_divide_conquer and not current_function.is_algorithm then
            current_function.time_complexity = get_dominant_complexity(current_function.time_complexity, effective)
          end
        end
      end

      -- Detect function calls
      local func_analysis = analyze_function_call(trimmed)
      if func_analysis then
        -- Calculate effective complexity considering current nesting
        local call_base_complexity = func_analysis.time
        local effective_call_complexity = call_base_complexity

        -- If we're inside loops, multiply the function call complexity
        for _, entry in ipairs(nesting_stack) do
          effective_call_complexity = multiply_complexity(entry.complexity, effective_call_complexity)
        end

        table.insert(results.function_calls, {
          line = i,
          complexity = effective_call_complexity,
          base_complexity = call_base_complexity,
          nesting_level = #nesting_stack,
        })

        if effective_call_complexity ~= 'O(1)' then
          results.overall_time = get_dominant_complexity(results.overall_time, effective_call_complexity)
          if current_function then
            current_function.time_complexity =
              get_dominant_complexity(current_function.time_complexity, effective_call_complexity)
          end
        end
      end
    end

    brace_depth = brace_depth + open_braces - close_braces

    while #nesting_stack > 0 and nesting_stack[#nesting_stack].depth > brace_depth do
      table.remove(nesting_stack)
    end

    if current_function and brace_depth < current_function.start_depth then
      table.insert(results.functions, {
        name = current_function.name,
        line = current_function.line,
        time_complexity = current_function.time_complexity,
        space_complexity = current_function.space_complexity,
      })
      table.remove(function_stack)
      current_function = function_stack[#function_stack]
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
