-- Complexity Analyzer - Rule-based static analysis for Go

local M = {}

local CONSTANTS = {
  DEFAULT_COMPLEXITY = 'O(1)',
  DEFAULT_RANK = 100,
}

-- Complexity hierarchy (from lowest to highest)
-- Exported so ts_analyzer.lua can share the same table without duplication.
M.COMPLEXITY_HIERARCHY = {
  ['O(1)'] = 1,
  ['O(α(n))'] = 2, -- Union-Find amortized
  ['O(log n)'] = 3,
  ['O(log² n)'] = 4,
  ['O(log³ n)'] = 4.5,
  ['O(log⁴ n)'] = 4.75,
  ['O(√n)'] = 5,
  ['O(√n log n)'] = 5.5,
  ['O(L)'] = 6, -- Trie operations
  ['O(nL)'] = 6.5,
  ['O(n)'] = 7,
  ['O(n log log n)'] = 7.5, -- Sieve
  ['O(n log n)'] = 8,
  ['O(n√n)'] = 9,
  ['O(n²)'] = 10,
  ['O(n² log n)'] = 11,
  ['O(n³)'] = 12,
  ['O(n⁴)'] = 13,
  ['O(n⁵)'] = 14,
  ['O(V+E)'] = 15, -- Graph traversal
  ['O(V×E)'] = 16, -- Bellman-Ford
  ['O(E log V)'] = 17, -- Dijkstra
  ['O(2^n)'] = 18,
  ['O(n!)'] = 19,
}

-- Compare two complexity strings and return the dominant (higher) one.
-- Exported for use by ts_analyzer.
function M.get_dominant_complexity(complexity1, complexity2)
  local rank1 = M.COMPLEXITY_HIERARCHY[complexity1] or CONSTANTS.DEFAULT_RANK
  local rank2 = M.COMPLEXITY_HIERARCHY[complexity2] or CONSTANTS.DEFAULT_RANK

  return rank1 >= rank2 and complexity1 or complexity2
end

-- Multiplication lookup table for common complexity combinations
local COMPLEXITY_MULTIPLICATION = {
  ['n|n'] = 'O(n²)',
  ['n|log n'] = 'O(n log n)',
  ['log n|n'] = 'O(n log n)',
  ['n²|log n'] = 'O(n² log n)',
  ['log n|n²'] = 'O(n² log n)',
  ['n|n log n'] = 'O(n² log n)',
  ['n log n|n'] = 'O(n² log n)',
  ['n²|n'] = 'O(n³)',
  ['n|n²'] = 'O(n³)',
  ['log n|log n'] = 'O(log² n)',
  ['√n|n'] = 'O(n√n)',
  ['n|√n'] = 'O(n√n)',
  ['n log log n|n'] = 'O(n² log log n)',
  ['n|n log log n'] = 'O(n² log log n)',
  ['2^n|n'] = 'O(n×2^n)',
  ['n|2^n'] = 'O(n×2^n)',
  ['n!|n'] = 'O(n×n!)',
  ['n|n!'] = 'O(n×n!)',
  ['n²|n²'] = 'O(n⁴)',
  ['n³|n'] = 'O(n⁴)',
  ['n|n³'] = 'O(n⁴)',
  ['n³|n²'] = 'O(n⁵)',
  ['n²|n³'] = 'O(n⁵)',
  ['√n|√n'] = 'O(n)',
  ['log n|√n'] = 'O(√n log n)',
  ['√n|log n'] = 'O(√n log n)',
  ['log n|log² n'] = 'O(log³ n)',
  ['log² n|log n'] = 'O(log³ n)',
  ['log² n|log² n'] = 'O(log⁴ n)',
  ['α(n)|n'] = 'O(n)',
  ['n|α(n)'] = 'O(n)',
  ['α(n)|log n'] = 'O(log n)',
  ['log n|α(n)'] = 'O(log n)',
  ['L|n'] = 'O(nL)',
  ['n|L'] = 'O(nL)',
  ['L|log n'] = 'O(L log n)',
  ['log n|L'] = 'O(L log n)',
  ['log³ n|log n'] = 'O(log⁴ n)',
  ['log n|log³ n'] = 'O(log⁴ n)',
}

-- Extract inner complexity from O(...) notation
local function extract_inner_complexity(complexity)
  return complexity:match('O%((.+)%)')
end

-- Simplify inner complexity string to canonical form for comparison
local function simplify_inner(inner)
  if not inner then
    return nil
  end
  -- Remove spaces
  inner = inner:gsub('%s+', '')
  -- Handle multiplication notation
  if inner:match('×') then
    local parts = {}
    for part in inner:gmatch('([^×]+)') do
      table.insert(parts, part)
    end
    -- Count variable factors
    local n_count = 0
    local log_count = 0
    local sqrt_count = 0
    local const = 1
    for _, p in ipairs(parts) do
      if p == 'n' then
        n_count = n_count + 1
      elseif p == 'n²' then
        n_count = n_count + 2
      elseif p == 'n³' then
        n_count = n_count + 3
      elseif p == 'n⁴' then
        n_count = n_count + 4
      elseif p == 'log n' then
        log_count = log_count + 1
      elseif p == 'log² n' then
        log_count = log_count + 2
      elseif p == 'log³ n' then
        log_count = log_count + 3
      elseif p == '√n' then
        sqrt_count = sqrt_count + 1
      elseif p:match('^%d+$') then
        const = const * tonumber(p)
      end
    end
    -- Build simplified form
    local result = ''
    if n_count > 0 then
      result = result .. 'n'
      if n_count == 2 then
        result = result .. '²'
      elseif n_count == 3 then
        result = result .. '³'
      elseif n_count == 4 then
        result = result .. '⁴'
      elseif n_count == 5 then
        result = result .. '⁵'
      elseif n_count > 5 then
        result = result .. '^' .. n_count
      end
    end
    if sqrt_count > 0 then
      if result ~= '' then
        result = result .. '×'
      end
      result = result .. '√n'
    end
    if log_count > 0 then
      if result ~= '' then
        result = result .. '×'
      end
      result = result .. 'log n'
      if log_count == 2 then
        result = result:gsub('log n', 'log² n')
      elseif log_count == 3 then
        result = result:gsub('log n', 'log³ n')
      elseif log_count == 4 then
        result = result:gsub('log n', 'log⁴ n')
      elseif log_count > 4 then
        result = result:gsub('log n', 'log^' .. log_count .. ' n')
      end
    end
    if const > 1 then
      if result ~= '' then
        result = const .. '×' .. result
      else
        result = tostring(const)
      end
    end
    if result == '' then
      result = '1'
    end
    return result
  end
  return inner
end

-- Multiply two complexity strings (for nested operations).
-- Exported for use by ts_analyzer.
function M.multiply_complexity(complexity1, complexity2)
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

  -- Default: simplify and return canonical form
  local simplified = simplify_inner(inner1 .. '×' .. inner2)
  if simplified then
    return 'O(' .. simplified .. ')'
  end
  return 'O(n²)'
end

return M
