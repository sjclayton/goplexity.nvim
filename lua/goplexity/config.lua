-- Configuration and constraint management

local M = {}

-- Complexity to operations mapping (matches analyzer hierarchy order)
local COMPLEXITY_OPS = {
  ["O(1)"] = 1,
  ["O(α(n))"] = 10,
  ["O(log n)"] = 100,
  ["O(log² n)"] = 1000,
  ["O(√n)"] = 10000,
  ["O(L)"] = 100,
  ["O(n)"] = 1000000,
  ["O(n log n)"] = 20000000,
  ["O(n log log n)"] = 5000000,
  ["O(n√n)"] = 100000000,
  ["O(n²)"] = 1000000000,
  ["O(n² log n)"] = 20000000000,
  ["O(n³)"] = 100000000000,
  ["O(V+E)"] = 1000000,
  ["O(V×E)"] = 1000000000,
  ["O(E log V)"] = 20000000,
  ["O(2^n)"] = 1000000000000000,
  ["O(n!)"] = 10000000000000000,
}

-- Default configuration
M.defaults = {
  -- Visual settings
  virtual_text_icon = "🧠",
  virtual_text_hl_group = "Comment",
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
  M.config = vim.tbl_deep_extend("force", M.config, user_config or {})
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
  return vim.tbl_deep_extend("force", M.config.constraints, M.user_constraints)
end

-- Convert complexity string to estimated operations
local function complexity_to_ops(complexity_str, n)
  if not complexity_str or not n then return nil end

  local ops = COMPLEXITY_OPS[complexity_str]
  if not ops then return nil end

  -- Scale by n for complexity factors
  if complexity_str:match("n²") then
    ops = ops * n * n
  elseif complexity_str:match("n³") then
    ops = ops * n * n * n
  elseif complexity_str:match("n log n") or complexity_str:match("n log") then
    ops = ops * n * 10
  elseif complexity_str:match("O%(n%)") and not complexity_str:match("O%(n²%)") then
    ops = ops * n
  elseif complexity_str:match("O%(V%+E%)") or complexity_str:match("O%(E log V%)") then
    ops = ops * n
  end

  return ops
end

-- Convert space complexity string to estimated MB usage
local function complexity_to_mb(complexity_str, n)
  if not complexity_str or not n then return nil end

  local ops = COMPLEXITY_OPS[complexity_str]
  if not ops then return nil end

  -- Scale by n for space factors (same scaling as time)
  if complexity_str:match("n²") then
    ops = ops * n * n
  elseif complexity_str:match("n³") then
    ops = ops * n * n * n
  elseif complexity_str:match("n log n") or complexity_str:match("n log") then
    ops = ops * n * 10
  elseif complexity_str:match("O%(n%)") and not complexity_str:match("O%(n²%)") then
    ops = ops * n
  elseif complexity_str:match("O%(V%+E%)") or complexity_str:match("O%(E log V%)") then
    ops = ops * n
  end

  -- Convert ops to rough MB estimate (1 op ≈ 1 byte, so divide by 1e6 for MB)
  return ops / 1e6
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
        table.insert(warnings, string.format("⚠️  Time: %s (~%.2e ops) may exceed limit (%dms)", time_complexity, ops, constraints.time_limit_ms))
      end
    end
  end

  if constraints.n and constraints.memory_limit_mb and space_complexity then
    local mb = complexity_to_mb(space_complexity, constraints.n)
    if mb and mb > constraints.memory_limit_mb then
      table.insert(warnings, string.format("⚠️  Space: %s (~%.1f MB) may exceed limit (%dMB)", space_complexity, mb, constraints.memory_limit_mb))
    end
  end

  return warnings
end

return M
