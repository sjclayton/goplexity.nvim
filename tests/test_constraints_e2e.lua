-- Careful verification of :Goplexity constraints command
-- Traces: command → set_constraints → get_constraints → should_warn → run_analysis

local plugin_root = vim.fn.fnamemodify(debug.getinfo(1).source:match('@?(.*)/tests/[^/]*$'), ':p')
package.path = plugin_root .. 'lua/?.lua;' .. plugin_root .. 'lua/?/init.lua;' .. package.path

local goplexity = require('goplexity')
local config = require('goplexity.config')
local analyzer = require('goplexity.analyzer')

local M = {}
local passed = 0
local failed = 0

local function green(s) return '\27[32m' .. s .. '\27[0m' end
local function red(s) return '\27[31m' .. s .. '\27[0m' end
local function bold(s) return '\27[1m' .. s .. '\27[0m' end

local function assert_eq(name, actual, expected)
  if actual == expected then
    passed = passed + 1
    print(string.format('  %s %-55s %s', green('PASS'), name, tostring(actual)))
  else
    failed = failed + 1
    print(string.format('  %s %-55s expected %s, got %s', red('FAIL'), name, tostring(expected), tostring(actual)))
  end
end

local function reset()
  config.config = vim.deepcopy(config.defaults)
  config.user_constraints = {}
end

local function make_go_buf(code)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, code)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'go')
  vim.api.nvim_set_current_buf(buf)
  return buf
end

-- Verify the full command flow: :Goplexity constraints N TIME MEM
-- 1. Parses args correctly
-- 2. Stores in config.user_constraints
-- 3. get_constraints() merges with defaults
-- 4. should_warn() uses merged constraints
-- 5. run_analysis() calls should_warn() after analysis

function M.run()
  print(bold('goplexity.nvim - :Goplexity constraints Verification'))
  print(string.rep('-', 80))

  -- Step 1: Verify command handler parses and stores args
  print('\n--- Step 1: Command parsing ---')
  reset()
  goplexity.command({'constraints', '100000', '2000', '256'})
  local c = config.get_constraints()
  assert_eq('n parsed as number', type(c.n), 'number')
  assert_eq('n value', c.n, 100000)
  assert_eq('time_limit_ms value', c.time_limit_ms, 2000)
  assert_eq('memory_limit_mb value', c.memory_limit_mb, 256)

  -- Verify user_constraints directly
  assert_eq('user_constraints.n', config.user_constraints.n, 100000)
  assert_eq('user_constraints.time_limit_ms', config.user_constraints.time_limit_ms, 2000)
  assert_eq('user_constraints.memory_limit_mb', config.user_constraints.memory_limit_mb, 256)

  -- Step 2: Verify partial args
  print('\n--- Step 2: Partial args ---')
  reset()
  goplexity.command({'constraints', '50000'})
  c = config.get_constraints()
  assert_eq('n only', c.n, 50000)
  assert_eq('time default nil', c.time_limit_ms, nil)
  assert_eq('memory default nil', c.memory_limit_mb, nil)

  -- Step 3: Verify invalid args produce nil, not crash
  print('\n--- Step 3: Invalid input handling ---')
  reset()
  local ok = pcall(function() goplexity.command({'constraints', 'notanumber'}) end)
  assert_eq('invalid arg does not crash', ok, true)
  c = config.get_constraints()
  assert_eq('invalid n is nil', c.n, nil)

  -- Step 4: Verify no-args shows usage
  print('\n--- Step 4: No args after constraints ---')
  reset()
  ok = pcall(function() goplexity.command({'constraints'}) end)
  assert_eq('no args does not crash', ok, true)

  -- Step 5: Verify unknown command
  print('\n--- Step 5: Unknown command ---')
  reset()
  ok = pcall(function() goplexity.command({'foobar'}) end)
  assert_eq('unknown command does not crash', ok, true)

  -- Step 6: Verify should_warn logic with real complexity values
  print('\n--- Step 6: should_warn with real complexity values ---')

  -- O(1) should never warn regardless of n
  reset()
  config.set_constraints(1000000, 1) -- extreme n, tiny time
  local warnings = config.should_warn('O(1)', nil)
  assert_eq('O(1) never warns', #warnings, 0)

  -- O(log n): base=100, no n-scaling in complexity_to_ops, so ops=100 always
  -- max_ops at 1ms = (1/1000)*1e8 = 1e5. 100 < 1e5 → no warn
  reset()
  config.set_constraints(1000000, 1)
  warnings = config.should_warn('O(log n)', nil)
  assert_eq('O(log n) base ops too low to warn', #warnings, 0)

  -- O(n) at n=100, 1000ms: base=1e6, scaled=1e6*100=1e8, max_ops=1e8 → no warn
  reset()
  config.set_constraints(100, 1000)
  warnings = config.should_warn('O(n)', nil)
  assert_eq('O(n) at n=100 with 1000ms no warn', #warnings, 0)

  -- O(n) at n=101, 1000ms: scaled=1.01e8, max=1e8 → warns
  reset()
  config.set_constraints(101, 1000)
  warnings = config.should_warn('O(n)', nil)
  assert_eq('O(n) at n=101 with 1000ms warns', #warnings, 1)

  -- O(n²) at n=10, 1000ms: base=1e9, scaled=1e9*10*10=1e11, max=1e8 → warns
  reset()
  config.set_constraints(10, 1000)
  warnings = config.should_warn('O(n²)', nil)
  assert_eq('O(n²) at n=10 with 1000ms warns', #warnings, 1)

  -- O(V+E) at n=101, 1000ms: scaled=1e6*101=1.01e8, max=1e8 → warns
  reset()
  config.set_constraints(101, 1000)
  warnings = config.should_warn('O(V+E)', nil)
  assert_eq('O(V+E) at n=101 with 1000ms warns', #warnings, 1)

  -- O(E log V) at n=6, 1000ms: scaled=2e7*6=1.2e8, max=1e8 → warns
  reset()
  config.set_constraints(6, 1000)
  warnings = config.should_warn('O(E log V)', nil)
  assert_eq('O(E log V) at n=6 with 1000ms warns', #warnings, 1)

  -- O(V×E): base=1e9, scaled=1e9*n, max_ops=1e8 at 1000ms
  -- n=1: scaled=1e9 > 1e8 → warns
  reset()
  config.set_constraints(1, 1000)
  warnings = config.should_warn('O(V×E)', nil)
  assert_eq('O(V×E) at n=1 with 1000ms warns', #warnings, 1)

  -- Step 7: Verify warning message format
  print('\n--- Step 7: Warning message content ---')
  reset()
  config.set_constraints(100000, 1000)
  warnings = config.should_warn('O(n²)', nil)
  assert_eq('warning count', #warnings, 1)
  if #warnings > 0 then
    assert_eq('message contains complexity', warnings[1]:match('O%(n²%)') ~= nil, true)
    assert_eq('message contains ops estimate', warnings[1]:match('~%d') ~= nil, true)
    assert_eq('message contains time limit', warnings[1]:match('1000ms') ~= nil, true)
    assert_eq('message starts with warning emoji', warnings[1]:match('⚠') ~= nil, true)
  end

  -- Step 8: Verify memory warnings
  print('\n--- Step 8: Memory warnings ---')

  -- O(n²) space at n=10000 with 256MB limit
  -- O(n²) base=1e9, scaled=1e9*1e4*1e4=1e17, mb=1e11 → far exceeds 256
  reset()
  config.set_constraints(10000, 1000, 256)
  warnings = config.should_warn('O(1)', 'O(n²)')
  assert_eq('O(n²) space at n=10000 with 256MB warns', #warnings, 1)
  if #warnings > 0 then
    assert_eq('memory warning contains Space', warnings[1]:match('Space:') ~= nil, true)
    assert_eq('memory warning contains complexity', warnings[1]:match('O%(n²%)') ~= nil, true)
    assert_eq('memory warning contains MB', warnings[1]:match('MB') ~= nil, true)
    assert_eq('memory warning contains limit', warnings[1]:match('256MB') ~= nil, true)
  end

  -- O(n) space at n=100 with 256MB limit
  -- O(n) base=1e6, scaled=1e6*100=1e8, mb=100 → under 256
  reset()
  config.set_constraints(100, 1000, 256)
  warnings = config.should_warn('O(n)', 'O(n)')
  -- Should have time warning (O(n) at n=100 is borderline) but no space warning
  local space_warnings = 0
  for _, w in ipairs(warnings) do
    if w:match('Space:') then space_warnings = space_warnings + 1 end
  end
  assert_eq('O(n) space at n=100 with 256MB no space warning', space_warnings, 0)

  -- O(n) space at n=1000000 with 256MB limit
  -- O(n) base=1e6, scaled=1e6*1e6=1e12, mb=1e6 → exceeds 256
  reset()
  config.set_constraints(1000000, 1000000, 256)
  warnings = config.should_warn('O(n)', 'O(n)')
  space_warnings = 0
  for _, w in ipairs(warnings) do
    if w:match('Space:') then space_warnings = space_warnings + 1 end
  end
  assert_eq('O(n) space at n=1e6 with 256MB warns', space_warnings, 1)

  -- Both time and space warnings together
  reset()
  config.set_constraints(100000, 1000, 1)
  warnings = config.should_warn('O(n²)', 'O(n²)')
  assert_eq('both time and space warnings', #warnings, 2)

  -- Memory limit only (no n, no time) — should not warn (n is required for scaling)
  reset()
  config.user_constraints = { memory_limit_mb = 256 }
  warnings = config.should_warn('O(n²)', 'O(n²)')
  assert_eq('memory only without n = no warnings', #warnings, 0)

  -- Step 9: Verify no time warnings when time_limit_ms not set
  print('\n--- Step 9: No time warnings without time_limit_ms ---')
  reset()
  config.set_constraints(100000) -- n only, no time
  warnings = config.should_warn('O(n²)', nil)
  assert_eq('no time_limit_ms = no time warnings', #warnings, 0)

  -- Step 10: Verify no warnings without n
  print('\n--- Step 10: No warnings without n ---')
  reset()
  config.user_constraints = { time_limit_ms = 1000 }
  warnings = config.should_warn('O(n²)', nil)
  assert_eq('no n = no warnings', #warnings, 0)

  -- Step 11: Verify setup() constraints work
  print('\n--- Step 11: setup() with constraints ---')
  reset()
  goplexity.setup({constraints = {n = 50000, time_limit_ms = 500, memory_limit_mb = 128}})
  c = config.get_constraints()
  assert_eq('setup n', c.n, 50000)
  assert_eq('setup time', c.time_limit_ms, 500)
  assert_eq('setup memory', c.memory_limit_mb, 128)

  -- Step 12: Verify command overrides setup
  print('\n--- Step 12: Command overrides setup ---')
  reset()
  goplexity.setup({constraints = {n = 50000, time_limit_ms = 500, memory_limit_mb = 128}})
  goplexity.command({'constraints', '100000', '2000', '256'})
  c = config.get_constraints()
  assert_eq('command overrides setup n', c.n, 100000)
  assert_eq('command overrides setup time', c.time_limit_ms, 2000)
  assert_eq('command overrides setup memory', c.memory_limit_mb, 256)

  -- Step 13: Verify full integration: command → analysis → warnings
  print('\n--- Step 13: Full integration (command + analysis) ---')
  reset()
  goplexity.command({'constraints', '100', '1000', '1'})

  local buf = make_go_buf({
    'package main',
    'func slow(n int) int {',
    '  t := 0',
    '  for i := 0; i < n; i++ {',
    '    for j := 0; j < n; j++ { t++ }',
    '  }',
    '  return t',
    '}',
  })
  local results = analyzer.analyze(buf)
  assert_eq('analysis detects O(n²)', results.overall_time, 'O(n²)')

  -- Verify constraints are still active after analysis
  c = config.get_constraints()
  assert_eq('constraints still set after analysis', c.n, 100)
  assert_eq('time still set after analysis', c.time_limit_ms, 1000)
  assert_eq('memory still set after analysis', c.memory_limit_mb, 1)

  -- Verify should_warn matches what run_analysis would use
  warnings = config.should_warn(results.overall_time, results.space)
  assert_eq('should_warn triggers for O(n²) at n=100', #warnings, 1)

  vim.api.nvim_buf_delete(buf, { force = true })

  -- Step 14: Memory constraint integration with analysis
  print('\n--- Step 14: Memory constraint integration ---')
  reset()
  goplexity.command({'constraints', '10000', '1000000', '256'})

  local buf3 = make_go_buf({
    'package main',
    'func bigSpace(n int) [][]int {',
    '  m := make([][]int, n)',
    '  for i := 0; i < n; i++ { m[i] = make([]int, n) }',
    '  return m',
    '}',
  })
  local results3 = analyzer.analyze(buf3)
  assert_eq('analysis detects O(n²) space', results3.space, 'O(n²)')

  -- With n=10000, O(n²) space should far exceed 256MB
  warnings = config.should_warn(results3.overall_time, results3.space)
  local has_space_warning = false
  for _, w in ipairs(warnings) do
    if w:match('Space:') then has_space_warning = true end
  end
  assert_eq('O(n²) space at n=10000 with 256MB warns', has_space_warning, true)

  vim.api.nvim_buf_delete(buf3, { force = true })

  -- Step 15: Verify :Goplexity (no args) toggles correctly
  print('\n--- Step 15: :Goplexity toggle behavior ---')
  reset()
  local buf2 = make_go_buf({
    'package main',
    'func f(n int) int {',
    '  for i := 0; i < n; i++ {}',
    '  return n',
    '}',
  })
  -- First call: visible=false → true, runs analysis
  local visible = goplexity.toggle(buf2)
  assert_eq('first toggle shows hints', visible, true)
  assert_eq('analysis stored', goplexity.last_analysis[buf2] ~= nil, true)

  -- Second call: visible=true → false, no analysis
  visible = goplexity.toggle(buf2)
  assert_eq('second toggle hides hints', visible, false)

  -- Third call: visible=false → true, re-runs analysis
  visible = goplexity.toggle(buf2)
  assert_eq('third toggle shows hints again', visible, true)

  vim.api.nvim_buf_delete(buf2, { force = true })

  -- Step 16: Randomized stress testing
  print('\n--- Step 16: Randomized stress testing ---')
  math.randomseed(os.time())

  local complexities = {'O(1)', 'O(log n)', 'O(n)', 'O(n log n)', 'O(n²)', 'O(n³)', 'O(V+E)', 'O(E log V)', 'O(V×E)'}

  -- Generate 50 random constraint + complexity combinations and verify no crashes
  local random_passes = 0
  for i = 1, 50 do
    reset()
    local rn = math.random(1, 1000000)
    local rtime = math.random(1, 100000)
    local rmem = math.random(1, 4096)
    config.set_constraints(rn, rtime, rmem)

    local rtc = complexities[math.random(#complexities)]
    local rsc = complexities[math.random(#complexities)]

    local ok, result = pcall(function()
      return config.should_warn(rtc, rsc)
    end)
    if ok and type(result) == 'table' then
      random_passes = random_passes + 1
    else
      assert_eq('random test ' .. i .. ' (n=' .. rn .. ' t=' .. rtime .. ' m=' .. rmem .. ' tc=' .. rtc .. ' sc=' .. rsc .. ')', ok and type(result) == 'table', true)
    end
  end
  assert_eq('50 random constraint combos no crash', random_passes, 50)

  -- Verify specific random edge cases with known outcomes
  -- O(1) space at any n should never exceed any reasonable memory limit
  reset()
  config.set_constraints(1000000, 1, 1) -- extreme n, tiny time, tiny memory
  warnings = config.should_warn('O(1)', 'O(1)')
  assert_eq('O(1) time+space never warns even at extremes', #warnings, 0)

  -- O(n³) at n=1000000 should definitely warn on both time and space with tiny limits
  reset()
  config.set_constraints(1000000, 1, 1)
  warnings = config.should_warn('O(n³)', 'O(n³)')
  assert_eq('O(n³) at n=1e6 with 1ms/1MB warns on both', #warnings, 2)

  -- O(V×E) at n=1 with 1ms/1MB should warn (base ops 1e9 > 1e5 max_ops, and 1e9/1e6=1000MB > 1MB)
  reset()
  config.set_constraints(1, 1, 1)
  warnings = config.should_warn('O(V×E)', 'O(V×E)')
  assert_eq('O(V×E) at n=1 with 1ms/1MB warns on both', #warnings, 2)

  -- O(n log n) at n=1000 with 10000ms/1024MB: base=2e7, scaled=2e11, max_ops=1e9 → warns
  -- space: mb=2e5 → 200000 > 1024 → warns
  reset()
  config.set_constraints(1000, 10000, 1024)
  warnings = config.should_warn('O(n log n)', 'O(n log n)')
  assert_eq('O(n log n) at n=1000 with 10s/1GB warns on both', #warnings, 2)

  -- O(n²) at n=500 with 100ms/10MB: time warns, space=2.5e8 MB > 10 → warns
  reset()
  config.set_constraints(500, 100, 10)
  warnings = config.should_warn('O(n²)', 'O(n²)')
  local time_w = 0
  local space_w = 0
  for _, w in ipairs(warnings) do
    if w:match('Time:') then time_w = time_w + 1 end
    if w:match('Space:') then space_w = space_w + 1 end
  end
  assert_eq('O(n²) at n=500 100ms/10MB time warns', time_w, 1)
  assert_eq('O(n²) at n=500 100ms/10MB space warns', space_w, 1)

  -- Summary
  print('\n' .. string.rep('-', 80))
  local total = passed + failed
  print(string.format('Total: %d | %s | %s',
    total,
    green(string.format('Passed: %d', passed)),
    failed > 0 and red(string.format('Failed: %d', failed)) or ''
  ))

  if failed > 0 then
    vim.cmd('cq')
  else
    vim.cmd('q')
  end
end

M.run()

return M
