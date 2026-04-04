-- Headless test runner for goplexity.nvim
-- Run with: nvim --headless --clean -u tests/test_runner.lua

-- Add plugin lua directory to package path
local plugin_root = vim.fn.fnamemodify(debug.getinfo(1).source:match('@?(.*)/tests/[^/]*$'), ':p')
package.path = plugin_root .. 'lua/?.lua;' .. plugin_root .. 'lua/?/init.lua;' .. package.path

local M = {}

local analyzer = require('goplexity.analyzer')

-- Test results
local passed = 0
local failed = 0
local test_results = {}

-- Extract complexity value from a comment line
local function extract_complexity(line, prefix)
  local idx = line:find(prefix, 1, true)
  if not idx then
    return nil
  end
  local rest = line:sub(idx + #prefix):match('^%s*(.*)')
  if not rest then
    return nil
  end

  local start_idx = rest:find('O%(')
  if not start_idx then
    return nil
  end

  local depth = 0
  for i = start_idx, #rest do
    local c = rest:sub(i, i)
    if c == '(' then
      depth = depth + 1
    end
    if c == ')' then
      depth = depth - 1
      if depth == 0 then
        return rest:sub(start_idx, i)
      end
    end
  end
  return nil
end

-- Parse expected complexity from Go file comments
local function parse_expected(lines)
  local expected = {
    time = nil,
    space = nil,
    functions = {},
  }

  for _, line in ipairs(lines) do
    local time_val = extract_complexity(line, 'Expected Time Complexity:')
    local space_val = extract_complexity(line, 'Expected Space Complexity:')
    if time_val then
      expected.time = time_val
    end
    if space_val then
      expected.space = space_val
    end
  end

  local file_level_time = expected.time
  for i, line in ipairs(lines) do
    local func_name = line:match('^func%s+%([^)]+%)%s+([%w_]+)%s*%(') or line:match('^func%s+([%w_]+)%s*%(')

    if func_name and func_name ~= 'main' then
      local func_time = nil
      local func_space = nil
      for j = math.max(1, i - 5), i - 1 do
        local comment = lines[j]
        local ft = extract_complexity(comment, 'Expected Time Complexity:')
        local fs = extract_complexity(comment, 'Expected Space Complexity:')
        if ft and not comment:match('mix') and not comment:match('for sort') and not comment:match('for search') then
          func_time = ft
        end
        if fs and not comment:match('for sized') and not comment:match('for empty') then
          func_space = fs
        end
      end
      if func_time or func_space then
        table.insert(expected.functions, {
          name = func_name,
          time = func_time,
          space = func_space,
        })
      end
    end
  end

  return expected
end

-- Normalize complexity string for comparison
local function normalize_complexity(c)
  if not c then
    return nil
  end
  c = c:gsub('%s+', ' ')
  c = c:gsub('^%s+', '')
  c = c:gsub('%s+$', '')
  return c
end

-- Check if two complexity strings are equivalent
local function complexity_matches(actual, expected)
  if not expected then
    return true
  end
  if not actual then
    return false
  end

  local a = normalize_complexity(actual)
  local e = normalize_complexity(expected)

  if a == e then
    return true
  end
  if e:match('O%(n%)') and a == 'O(n)' then
    return true
  end
  if e:match('O%(1%)') and a == 'O(1)' then
    return true
  end

  return false
end

-- Check if actual space is not worse than expected
local function space_acceptable(actual, expected)
  if not expected then
    return true
  end
  if not actual then
    return false
  end

  local a = normalize_complexity(actual)
  local e = normalize_complexity(expected)

  if a == e then
    return true
  end
  if e:match('^O%(n%)') and a == 'O(1)' then
    return true
  end
  if e:match('O%(n') and a == 'O(n)' then
    return true
  end
  if e:match('O%(n%)') and e:match('O%(1%)') then
    return true
  end

  return false
end

-- Create a temporary buffer with file content
local function create_buffer(filepath)
  local lines = {}
  local f = io.open(filepath, 'r')
  if not f then
    return nil
  end
  for line in f:lines() do
    table.insert(lines, line)
  end
  f:close()

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'go')
  return bufnr, lines
end

-- Run a single test case
local function run_test(name, filepath)
  local bufnr, lines = create_buffer(filepath)
  if not bufnr then
    table.insert(test_results, {
      name = name,
      status = 'FAIL',
      message = 'Could not read file: ' .. filepath,
    })
    failed = failed + 1
    return
  end

  local expected = parse_expected(lines)
  local results = analyzer.analyze(bufnr)

  local issues = {}

  if expected.time then
    if not complexity_matches(results.overall_time, expected.time) then
      table.insert(issues, string.format('Time: expected %s, got %s', expected.time, results.overall_time))
    end
  end

  if expected.space then
    if not space_acceptable(results.space, expected.space) then
      table.insert(issues, string.format('Space: expected %s, got %s', expected.space, results.space))
    end
  end

  local helper_funcs = { Len = true, Less = true, Swap = true, Push = true, Pop = true }
  for _, exp_func in ipairs(expected.functions) do
    if not helper_funcs[exp_func.name] then
      local found = false
      for _, act_func in ipairs(results.functions) do
        if act_func.name == exp_func.name then
          found = true
          if exp_func.time and not complexity_matches(act_func.time_complexity, exp_func.time) then
            table.insert(
              issues,
              string.format(
                'Function %s time: expected %s, got %s',
                exp_func.name,
                exp_func.time,
                act_func.time_complexity
              )
            )
          end
          break
        end
      end
      if not found then
        table.insert(issues, string.format('Function %s: not detected in analysis', exp_func.name))
      end
    end
  end

  local status, message
  if #issues == 0 then
    status = 'PASS'
    message = string.format(
      'Time: %s | Space: %s | Loops: %d | Functions: %d',
      results.overall_time,
      results.space,
      #results.loops,
      #results.functions
    )
    passed = passed + 1
  else
    status = 'FAIL'
    message = table.concat(issues, '; ')
    failed = failed + 1
  end

  table.insert(test_results, {
    name = name,
    status = status,
    message = message,
  })

  vim.api.nvim_buf_delete(bufnr, { force = true })
end

-- Run all tests
function M.run()
  local test_dir = plugin_root .. 'tests/'
  local tests = {
    -- Core algorithms
    { name = 'bfs', file = test_dir .. 'bfs/main.go' },
    { name = 'binary_search', file = test_dir .. 'binary_search/main.go' },
    { name = 'bellman_ford', file = test_dir .. 'bellman_ford/main.go' },
    { name = 'dfs', file = test_dir .. 'dfs/main.go' },
    { name = 'dijkstra', file = test_dir .. 'dijkstra/main.go' },
    { name = 'floyd_warshall', file = test_dir .. 'floyd_warshall/main.go' },
    { name = 'gcd', file = test_dir .. 'gcd/main.go' },
    { name = 'kmp', file = test_dir .. 'kmp/main.go' },
    { name = 'kruskal', file = test_dir .. 'kruskal/main.go' },
    { name = 'merge_sort', file = test_dir .. 'merge_sort/main.go' },
    { name = 'prim', file = test_dir .. 'prim/main.go' },
    { name = 'quick_sort', file = test_dir .. 'quick_sort/main.go' },
    { name = 'segment_tree', file = test_dir .. 'segment_tree/main.go' },
    { name = 'sieve', file = test_dir .. 'sieve/main.go' },
    { name = 'topological_sort', file = test_dir .. 'topological_sort/main.go' },
    { name = 'trie', file = test_dir .. 'trie/main.go' },
    { name = 'union_find', file = test_dir .. 'union_find/main.go' },
    -- Sorting
    { name = 'bubble_sort', file = test_dir .. 'bubble_sort/main.go' },
    { name = 'insertion_sort', file = test_dir .. 'insertion_sort/main.go' },
    { name = 'built_in_sort', file = test_dir .. 'built_in_sort/main.go' },
    { name = 'sort_advanced', file = test_dir .. 'sort_advanced/main.go' },
    -- Searching
    { name = 'linear_search', file = test_dir .. 'linear_search/main.go' },
    { name = 'two_sum', file = test_dir .. 'two_sum/main.go' },
    -- Loop patterns
    { name = 'logarithmic_loops', file = test_dir .. 'logarithmic_loops/main.go' },
    { name = 'sqrt_loop', file = test_dir .. 'sqrt_loop/main.go' },
    { name = 'infinite_loop', file = test_dir .. 'infinite_loop/main.go' },
    { name = 'constant_loop', file = test_dir .. 'constant_loop/main.go' },
    -- Nested complexity multiplication
    { name = 'nested_log_loops', file = test_dir .. 'nested_log_loops/main.go' },
    { name = 'nested_cubic', file = test_dir .. 'nested_cubic/main.go' },
    { name = 'nested_n2logn', file = test_dir .. 'nested_n2logn/main.go' },
    -- Stdlib: strings, bytes, strconv
    { name = 'string_ops', file = test_dir .. 'string_ops/main.go' },
    { name = 'bytes_ops', file = test_dir .. 'bytes_ops/main.go' },
    { name = 'strconv_ops', file = test_dir .. 'strconv_ops/main.go' },
    -- Stdlib: math, bits, big
    { name = 'math_ops', file = test_dir .. 'math_ops/main.go' },
    { name = 'bits_ops', file = test_dir .. 'bits_ops/main.go' },
    { name = 'big_int_ops', file = test_dir .. 'big_int_ops/main.go' },
    -- Stdlib: fmt, os, io, bufio, filepath
    { name = 'fmt_ops', file = test_dir .. 'fmt_ops/main.go' },
    { name = 'os_ops', file = test_dir .. 'os_ops/main.go' },
    { name = 'io_ops', file = test_dir .. 'io_ops/main.go' },
    { name = 'bufio_ops', file = test_dir .. 'bufio_ops/main.go' },
    { name = 'filepath_ops', file = test_dir .. 'filepath_ops/main.go' },
    -- Stdlib: json, regexp, hash, compress, encoding
    { name = 'json_ops', file = test_dir .. 'json_ops/main.go' },
    { name = 'regexp', file = test_dir .. 'regexp/main.go' },
    { name = 'hash_ops', file = test_dir .. 'hash_ops/main.go' },
    { name = 'compress_ops', file = test_dir .. 'compress_ops/main.go' },
    { name = 'encoding_ops', file = test_dir .. 'encoding_ops/main.go' },
    -- Stdlib: sync, context, time, concurrency
    { name = 'sync_ops', file = test_dir .. 'sync_ops/main.go' },
    { name = 'context_ops', file = test_dir .. 'context_ops/main.go' },
    { name = 'time_ops', file = test_dir .. 'time_ops/main.go' },
    { name = 'concurrency', file = test_dir .. 'concurrency/main.go' },
    -- Stdlib: containers, slices, maps
    { name = 'container_list', file = test_dir .. 'container_list/main.go' },
    { name = 'heap_ops', file = test_dir .. 'heap_ops/main.go' },
    { name = 'slices_ops', file = test_dir .. 'slices_ops/main.go' },
    -- Data structures & space
    { name = 'data_structures', file = test_dir .. 'data_structures/main.go' },
    { name = 'map_ops', file = test_dir .. 'map_ops/main.go' },
    { name = 'space_2d', file = test_dir .. 'space_2d/main.go' },
    -- Other
    { name = 'method_receiver', file = test_dir .. 'method_receiver/main.go' },
  }

  -- Print header
  local header =
    string.format('%-25s %-6s %-16s %-14s %-7s %-11s', 'Test', 'Status', 'Time', 'Space', 'Loops', 'Functions')
  print(header)
  print(string.rep('-', #header))

  for _, test in ipairs(tests) do
    run_test(test.name, test.file)
  end

  -- Print results table
  for _, result in ipairs(test_results) do
    local status_str = result.status
    local time_str = ''
    local space_str = ''
    local loops_str = ''
    local funcs_str = ''

    if result.status == 'PASS' then
      local parts = {}
      for part in result.message:gmatch('[^|]+') do
        table.insert(parts, part:match('^%s*(.-)%s*$'))
      end
      time_str = parts[1]:match('Time:%s*(.*)') or ''
      space_str = parts[2]:match('Space:%s*(.*)') or ''
      loops_str = parts[3]:match('Loops:%s*(.*)') or ''
      funcs_str = parts[4]:match('Functions:%s*(.*)') or ''
    else
      time_str = '—'
      space_str = '—'
      loops_str = '—'
      funcs_str = '—'
    end

    print(
      string.format(
        '%-25s %-6s %-16s %-14s %-7s %-11s',
        result.name,
        status_str,
        time_str,
        space_str,
        loops_str,
        funcs_str
      )
    )
  end

  print(string.rep('-', #header))
  local total = passed + failed
  local summary = string.format('Total: %d  Passed: %d  Failed: %d', total, passed, failed)
  print(summary)

  if failed > 0 then
    vim.cmd('cq')
  else
    vim.cmd('q')
  end
end

-- Auto-run when loaded as init file
M.run()

return M
