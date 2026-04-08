-- Configuration and constraint management

local M = {}

-- Complexity to operations mapping (matches analyzer hierarchy order)
local COMPLEXITY_OPS = {
  ['O(1)'] = 1,
  ['O(α(n))'] = 1,
  ['O(log n)'] = 100,
  ['O(log² n)'] = 100,
  ['O(log³ n)'] = 100,
  ['O(log⁴ n)'] = 100,
  ['O(√n)'] = 10000,
  ['O(√n log n)'] = 1000,
  ['O(L)'] = 100,
  ['O(nL)'] = 100,
  ['O(n)'] = 1000000,
  ['O(n log log n)'] = 5000000,
  ['O(n log n)'] = 20000000,
  ['O(n√n)'] = 100000000,
  ['O(n²)'] = 1000000000,
  ['O(n² log n)'] = 20000000000,
  ['O(n² log log n)'] = 10000000000,
  ['O(n³)'] = 100000000000,
  ['O(n⁴)'] = 10000000000000,
  ['O(n⁵)'] = 1000000000000000,
  ['O(V+E)'] = 1000000,
  ['O(V×E)'] = 1000000000,
  ['O(n×m)'] = 1000000000, -- 2D DP (LCS, Knapsack)
  ['O(E log V)'] = 20000000,
  ['O(2^n)'] = 1000000000000000,
  ['O(n×2^n)'] = 10000000000000000,
  ['O(n×n!)'] = 100000000000000000,
  ['O(n!)'] = 1000000000000000000,
}

-- Default configuration
M.defaults = {
  -- Visual settings
  virtual_text_icon = '🧠',
  virtual_text_hl_group = 'Comment',
  enabled = true,

  -- Problem constraints (can be overridden per problem)
  constraints = {
    n = nil,
    time_limit_ms = nil,
    memory_limit_mb = nil,
  },

  -- Complexity thresholds for warnings
  thresholds = {
    time_warning = 1e8,
    space_warning = 256,
  },
}

-- Current configuration (merged with user settings)
M.config = vim.deepcopy(M.defaults)

-- User-defined constraints for current session/file
M.user_constraints = {}

function M.setup(user_config)
  M.config = vim.tbl_deep_extend('force', M.config, user_config or {})
end

-- Set problem constraints
function M.set_constraints(n, time_ms, memory_mb)
  M.user_constraints = {
    n = tonumber(n),
    time_limit_ms = tonumber(time_ms),
    memory_limit_mb = tonumber(memory_mb),
  }
end

-- Get current constraints (user-defined or defaults)
function M.get_constraints()
  return vim.tbl_deep_extend('force', M.config.constraints, M.user_constraints)
end

-- Calculate the raw scaled units for a given complexity and n.
-- Returns the base_ops * n-scaling factor.
local function get_scaled_units(complexity_str, n)
  if not complexity_str or not n then
    return nil
  end

  local base_ops = COMPLEXITY_OPS[complexity_str]
  if not base_ops then
    return nil
  end

  local units = base_ops
  -- Scale by n for complexity factors
  if complexity_str:match('n⁵') then
    units = units * n * n * n * n * n
  elseif complexity_str:match('n⁴') then
    units = units * n * n * n * n
  elseif complexity_str:match('n³') then
    units = units * n * n * n
  elseif complexity_str:match('n²') then
    units = units * n * n
  elseif complexity_str:match('n log log n') then
    units = units * n * (math.log(math.log(n) / math.log(2)) / math.log(2))
  elseif complexity_str:match('n√n') then
    units = units * n * math.sqrt(n)
  elseif complexity_str:match('√n log n') then
    units = units * math.sqrt(n) * (math.log(n) / math.log(2))
  elseif complexity_str:match('n log n') then
    units = units * n * (math.log(n) / math.log(2))
  elseif complexity_str:match('log⁴ n') then
    local log2n = math.log(n) / math.log(2)
    units = units * log2n * log2n * log2n * log2n
  elseif complexity_str:match('log³ n') then
    local log2n = math.log(n) / math.log(2)
    units = units * log2n * log2n * log2n
  elseif complexity_str:match('log² n') then
    local log2n = math.log(n) / math.log(2)
    units = units * log2n * log2n
  elseif complexity_str:match('√n') then
    units = units * math.sqrt(n)
  elseif complexity_str:match('O%(n%)') and not complexity_str:match('O%(n²%)') then
    units = units * n
  elseif
    complexity_str:match('O%(V%+E%)')
    or complexity_str:match('O%(V×E%)')
    or complexity_str:match('O%(E log V%)')
  then
    units = units * n
  elseif complexity_str:match('O%(2%^n%)') or complexity_str:match('O%(n×2') then
    units = units * n * (2 ^ n)
  elseif complexity_str:match('O%(n×n!%)') then
    -- Approximate n! for scaling purposes
    local factorial = 1
    for i = 2, math.min(n, 20) do
      factorial = factorial * i
    end
    units = units * n * factorial
  end

  return units
end

-- Convert complexity string to estimated operations
local function complexity_to_ops(complexity_str, n)
  return get_scaled_units(complexity_str, n)
end

-- Convert space complexity string to estimated MB usage.
-- We use a baseline of 8 bytes per complexity unit (typical for Go int/int64/headers).
local function complexity_to_mb(complexity_str, n)
  local scaled_units = get_scaled_units(complexity_str, n)
  if not scaled_units then
    return nil
  end

  -- We treat 1e6 scaled units as 1 "base unit" of O(n) space (e.g. 8 bytes).
  -- This makes n=1,000,000 for O(n) ≈ 7.6 MB.
  -- units / 1e6 * 8 = bytes.
  -- bytes / 1,048,576 = MB.
  return (scaled_units / 1e6 * 8) / 1048576
end

-- Check if analysis should show warnings based on constraints
function M.should_warn(time_complexity, space_complexity)
  local constraints = M.get_constraints()
  local warnings = {}

  if constraints.n and constraints.time_limit_ms and time_complexity then
    local ops = complexity_to_ops(time_complexity, constraints.n)
    if ops then
      local max_ops = (constraints.time_limit_ms / 1000) * M.config.thresholds.time_warning
      if ops > max_ops then
        table.insert(
          warnings,
          string.format(
            '⚠️  Time: %s (~%.2e ops) may exceed limit (%dms)',
            time_complexity,
            ops,
            constraints.time_limit_ms
          )
        )
      end
    end
  end

  if constraints.n and constraints.memory_limit_mb and space_complexity then
    local mb = complexity_to_mb(space_complexity, constraints.n)
    if mb and mb > constraints.memory_limit_mb then
      table.insert(
        warnings,
        string.format(
          '⚠️  Space: %s (~%.1f MB) may exceed limit (%dMB)',
          space_complexity,
          mb,
          constraints.memory_limit_mb
        )
      )
    end
  end

  return warnings
end

return M
