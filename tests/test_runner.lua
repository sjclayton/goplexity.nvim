-- Tree-sitter backend test runner for goplexity.nvim
-- Run with: nvim --headless --clean -u tests/test_runner.lua
--
-- Exclusively tests the tree-sitter integration.
-- Skips gracefully if the Go tree-sitter parser is not installed.

local plugin_root = vim.fn.fnamemodify(debug.getinfo(1).source:match('@?(.*)/tests/[^/]*$'), ':p')
package.path = plugin_root .. 'lua/?.lua;' .. plugin_root .. 'lua/?/init.lua;' .. package.path

-- ---------------------------------------------------------------------------
-- Check parser availability before loading anything else.
-- ---------------------------------------------------------------------------
local parser_ok = pcall(vim.treesitter.language.inspect, 'go')
if not parser_ok then
  print('SKIP: Go tree-sitter parser not available (install with :TSInstall go)')
  vim.cmd('q')
  return
end

local ts_analyzer = require('goplexity.ts_analyzer')

local passed      = 0
local failed      = 0
local skipped     = 0
local test_results = {}

-- ---------------------------------------------------------------------------
-- Helpers shared with test_runner.lua
-- ---------------------------------------------------------------------------
local function extract_complexity(line, prefix)
  local idx = line:find(prefix, 1, true)
  if not idx then return nil end
  local rest = line:sub(idx + #prefix):match('^%s*(.*)')
  if not rest then return nil end
  local start_idx = rest:find('O%(')
  if not start_idx then return nil end
  local depth = 0
  for i = start_idx, #rest do
    local c = rest:sub(i, i)
    if c == '(' then depth = depth + 1 end
    if c == ')' then
      depth = depth - 1
      if depth == 0 then return rest:sub(start_idx, i) end
    end
  end
  return nil
end

local function parse_expected(lines)
  local expected = { time = nil, space = nil, functions = {} }
  for _, line in ipairs(lines) do
    local tv = extract_complexity(line, 'Expected Time Complexity:')
    local sv = extract_complexity(line, 'Expected Space Complexity:')
    if tv and not expected.time then expected.time  = tv end
    if sv and not expected.space then expected.space = sv end
  end
  local file_level_time = expected.time
  for i, line in ipairs(lines) do
    local func_name = line:match('^func%s+%([^)]+%)%s+([%w_]+)%s*%(')
                   or line:match('^func%s+([%w_]+)%s*%(')
    if func_name and func_name ~= 'main' then
      local func_time, func_space
      for j = math.max(1, i - 5), i - 1 do
        local comment = lines[j]
        local ft = extract_complexity(comment, 'Expected Time Complexity:')
        local fs = extract_complexity(comment, 'Expected Space Complexity:')
        if ft and not comment:match('mix') then func_time  = ft end
        if fs then func_space = fs end
      end
      -- Always track every function to ensure it has expectations and is detected
      table.insert(expected.functions, { name = func_name, time = func_time, space = func_space })
    end
  end
  return expected
end

local function normalize(c)
  if not c then return nil end
  return c:gsub('%s+', ' '):match('^%s*(.-)%s*$')
end

local function complexity_matches(actual, expected)
  if not expected then return true end
  if not actual   then return false end
  return normalize(actual) == normalize(expected)
end

local function space_acceptable(actual, expected)
  if not expected then return true end
  if not actual   then return false end
  local a, e = normalize(actual), normalize(expected)
  if a == e then return true end
  if e:match('^O%(n%)') and a == 'O(1)' then return true end
  if e:match('O%(n')    and a == 'O(n)' then return true end
  return false
end

-- ---------------------------------------------------------------------------
-- Test execution
-- ---------------------------------------------------------------------------
local function create_buffer(filepath)
  local lines = {}
  local f = io.open(filepath, 'r')
  if not f then return nil end
  for line in f:lines() do table.insert(lines, line) end
  f:close()

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value('filetype', 'go', { buf = bufnr })
  return bufnr, lines
end

local function run_test(name, filepath)
  local bufnr, lines = create_buffer(filepath)
  if not bufnr then
    table.insert(test_results, { name = name, status = 'FAIL',
      message = 'Could not read file: ' .. filepath })
    failed = failed + 1
    return
  end

  -- Tree-sitter needs the buffer to be parsed; language must be set.
  -- We parse lazily inside ts_analyzer.analyze via get_parser.
  local ok, results = pcall(ts_analyzer.analyze, bufnr)
  if not ok then
    table.insert(test_results, { name = name, status = 'FAIL',
      message = 'ts_analyzer error: ' .. tostring(results) })
    failed = failed + 1
    vim.api.nvim_buf_delete(bufnr, { force = true })
    return
  end

  local expected = parse_expected(lines)
  local issues   = {}

  if expected.time and not complexity_matches(results.overall_time, expected.time) then
    table.insert(issues, string.format('File Time: expected %s, got %s', expected.time, results.overall_time))
  end
  if expected.space and not space_acceptable(results.space, expected.space) then
    table.insert(issues, string.format('File Space: expected %s, got %s', expected.space, results.space))
  end

  local helper_funcs = { Len = true, Less = true, Swap = true, Push = true, Pop = true }
  for _, exp_func in ipairs(expected.functions) do
    if not helper_funcs[exp_func.name] then
      -- If expectation is missing, it's a failure (missing coverage)
      if not exp_func.time then
        table.insert(issues, string.format('Function %s: missing Expected Time Complexity', exp_func.name))
      end
      
      local found = false
      for _, act_func in ipairs(results.functions) do
        if act_func.name == exp_func.name then
          found = true
          if exp_func.time and not complexity_matches(act_func.time_complexity, exp_func.time) then
            table.insert(issues, string.format(
              'Function %s time: expected %s, got %s',
              exp_func.name, exp_func.time, act_func.time_complexity
            ))
          end
          if exp_func.space and not space_acceptable(act_func.space_complexity, exp_func.space) then
            table.insert(issues, string.format(
              'Function %s space: expected %s, got %s',
              exp_func.name, exp_func.space, act_func.space_complexity
            ))
          end
          break
        end
      end
      if not found then
        table.insert(issues, string.format('Function %s: not detected by analyzer', exp_func.name))
      end
    end
  end

  local status, message
  if #issues == 0 then
    status  = 'PASS'
    message = string.format(
      'Time: %s | Space: %s | Loops: %d | Functions: %d',
      results.overall_time, results.space, #results.loops, #results.functions
    )
    passed = passed + 1
  else
    status  = 'FAIL'
    message = table.concat(issues, '; ')
    failed  = failed + 1
  end

  table.insert(test_results, { name = name, status = status, message = message })
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

-- ---------------------------------------------------------------------------
-- Test list (identical fixtures to test_runner.lua)
-- ---------------------------------------------------------------------------
local function run()
  local test_dir = plugin_root .. 'tests/'
  local tests = {
    -- Core algorithms
    { name = 'bfs',               file = test_dir .. 'bfs/main.go' },
    { name = 'binary_search',     file = test_dir .. 'binary_search/main.go' },
    { name = 'bellman_ford',      file = test_dir .. 'bellman_ford/main.go' },
    { name = 'dfs',               file = test_dir .. 'dfs/main.go' },
    { name = 'dijkstra',          file = test_dir .. 'dijkstra/main.go' },
    { name = 'floyd_warshall',    file = test_dir .. 'floyd_warshall/main.go' },
    { name = 'gcd',               file = test_dir .. 'gcd/main.go' },
    { name = 'kmp',               file = test_dir .. 'kmp/main.go' },
    { name = 'kruskal',           file = test_dir .. 'kruskal/main.go' },
    { name = 'merge_sort',        file = test_dir .. 'merge_sort/main.go' },
    { name = 'prim',              file = test_dir .. 'prim/main.go' },
    { name = 'quick_sort',        file = test_dir .. 'quick_sort/main.go' },
    { name = 'segment_tree',      file = test_dir .. 'segment_tree/main.go' },
    { name = 'sieve',             file = test_dir .. 'sieve/main.go' },
    { name = 'topological_sort',  file = test_dir .. 'topological_sort/main.go' },
    { name = 'trie',              file = test_dir .. 'trie/main.go' },
    { name = 'union_find',        file = test_dir .. 'union_find/main.go' },
    -- Sorting
    { name = 'bubble_sort',       file = test_dir .. 'bubble_sort/main.go' },
    { name = 'insertion_sort',    file = test_dir .. 'insertion_sort/main.go' },
    { name = 'built_in_sort',     file = test_dir .. 'built_in_sort/main.go' },
    { name = 'sort_advanced',     file = test_dir .. 'sort_advanced/main.go' },
    -- Searching
    { name = 'linear_search',     file = test_dir .. 'linear_search/main.go' },
    { name = 'two_sum',           file = test_dir .. 'two_sum/main.go' },
    -- Loop patterns
    { name = 'logarithmic_loops', file = test_dir .. 'logarithmic_loops/main.go' },
    { name = 'sqrt_loop',         file = test_dir .. 'sqrt_loop/main.go' },
    { name = 'infinite_loop',     file = test_dir .. 'infinite_loop/main.go' },
    { name = 'constant_loop',     file = test_dir .. 'constant_loop/main.go' },
    -- Nested complexity
    { name = 'nested_log_loops',  file = test_dir .. 'nested_log_loops/main.go' },
    { name = 'nested_cubic',      file = test_dir .. 'nested_cubic/main.go' },
    { name = 'nested_n2logn',     file = test_dir .. 'nested_n2logn/main.go' },
    -- Stdlib: strings, bytes, strconv
    { name = 'string_ops',        file = test_dir .. 'string_ops/main.go' },
    { name = 'bytes_ops',         file = test_dir .. 'bytes_ops/main.go' },
    { name = 'strconv_ops',       file = test_dir .. 'strconv_ops/main.go' },
    -- Stdlib: math, bits, big
    { name = 'math_ops',          file = test_dir .. 'math_ops/main.go' },
    { name = 'bits_ops',          file = test_dir .. 'bits_ops/main.go' },
    { name = 'big_int_ops',       file = test_dir .. 'big_int_ops/main.go' },
    -- Stdlib: fmt, os, io, bufio, filepath
    { name = 'fmt_ops',           file = test_dir .. 'fmt_ops/main.go' },
    { name = 'os_ops',            file = test_dir .. 'os_ops/main.go' },
    { name = 'io_ops',            file = test_dir .. 'io_ops/main.go' },
    { name = 'bufio_ops',         file = test_dir .. 'bufio_ops/main.go' },
    { name = 'filepath_ops',      file = test_dir .. 'filepath_ops/main.go' },
    -- Stdlib: json, regexp, hash, compress, encoding
    { name = 'json_ops',          file = test_dir .. 'json_ops/main.go' },
    { name = 'regexp',            file = test_dir .. 'regexp/main.go' },
    { name = 'hash_ops',          file = test_dir .. 'hash_ops/main.go' },
    { name = 'compress_ops',      file = test_dir .. 'compress_ops/main.go' },
    { name = 'encoding_ops',      file = test_dir .. 'encoding_ops/main.go' },
    -- Stdlib: sync, context, time, concurrency
    { name = 'sync_ops',          file = test_dir .. 'sync_ops/main.go' },
    { name = 'context_ops',       file = test_dir .. 'context_ops/main.go' },
    { name = 'time_ops',          file = test_dir .. 'time_ops/main.go' },
    { name = 'concurrency',       file = test_dir .. 'concurrency/main.go' },
    -- Stdlib: containers, slices, maps
    { name = 'container_list',    file = test_dir .. 'container_list/main.go' },
    { name = 'heap_ops',          file = test_dir .. 'heap_ops/main.go' },
    { name = 'slices_ops',        file = test_dir .. 'slices_ops/main.go' },
    -- Data structures & space
    { name = 'data_structures',   file = test_dir .. 'data_structures/main.go' },
    { name = 'map_ops',           file = test_dir .. 'map_ops/main.go' },
    { name = 'space_2d',          file = test_dir .. 'space_2d/main.go' },
    { name = 'space_expressions', file = test_dir .. 'space_expressions/main.go' },
    { name = 'make_with_capacity',file = test_dir .. 'make_with_capacity/main.go' },
    { name = 'mixed_space_patterns',file = test_dir .. 'mixed_space_patterns/main.go' },
    -- More nested complexity
    { name = 'nested_quartic',    file = test_dir .. 'nested_quartic/main.go' },
    { name = 'nested_log_squared',file = test_dir .. 'nested_log_squared/main.go' },
    { name = 'nested_n_sqrt',     file = test_dir .. 'nested_n_sqrt/main.go' },
    -- Other
    { name = 'method_receiver',   file = test_dir .. 'method_receiver/main.go' },
    -- New Advanced Fixtures
    { name = 'ring_ops',          file = test_dir .. 'ring_ops/main.go' },
    { name = 'utf8_ops',          file = test_dir .. 'utf8_ops/main.go' },
    { name = 'reflect_ops',       file = test_dir .. 'reflect_ops/main.go' },
    { name = 'kadane',            file = test_dir .. 'kadane/main.go' },
    { name = 'fenwick_tree',      file = test_dir .. 'fenwick_tree/main.go' },
    { name = 'sparse_table',      file = test_dir .. 'sparse_table/main.go' },
    { name = 'lcs',               file = test_dir .. 'lcs/main.go' },
    { name = 'knapsack',          file = test_dir .. 'knapsack/main.go' },
    { name = 'filepath_ops',      file = test_dir .. 'filepath_ops/main.go' },
    { name = 'rand_ops',          file = test_dir .. 'rand_ops/main.go' },
  }

  local header = string.format(
    '%-25s %-6s %-16s %-14s %-7s %-11s',
    'Test', 'Status', 'Time', 'Space', 'Loops', 'Functions'
  )
  print('\n=== goplexity.nvim :: tree-sitter backend ===')
  print(header)
  print(string.rep('-', #header))

  for _, test in ipairs(tests) do
    run_test(test.name, test.file)
  end

  for _, result in ipairs(test_results) do
    local time_str, space_str, loops_str, funcs_str = '', '', '', ''
    if result.status == 'PASS' then
      local parts = {}
      for part in result.message:gmatch('[^|]+') do
        table.insert(parts, part:match('^%s*(.-)%s*$'))
      end
      time_str  = (parts[1] or ''):match('Time:%s*(.*)') or ''
      space_str = (parts[2] or ''):match('Space:%s*(.*)') or ''
      loops_str = (parts[3] or ''):match('Loops:%s*(.*)') or ''
      funcs_str = (parts[4] or ''):match('Functions:%s*(.*)') or ''
    else
      time_str = result.message
    end
    print(string.format(
      '%-25s %-6s %-16s %-14s %-7s %-11s',
      result.name, result.status, time_str, space_str, loops_str, funcs_str
    ))
  end

  print(string.rep('-', #header))
  local total = passed + failed + skipped
  print(string.format('Total: %d  Passed: %d  Failed: %d  Skipped: %d', total, passed, failed, skipped))

  if failed > 0 then
    vim.cmd('cq')
  else
    vim.cmd('q')
  end
end

run()
