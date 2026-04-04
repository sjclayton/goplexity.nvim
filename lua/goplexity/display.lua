-- Display module - Handle extmarks and virtual text rendering

local M = {}

-- Constants
local DISPLAY_CONSTANTS = {
  HEADER_SCAN_LIMIT = 100,
  PRIORITY_OVERALL = 1000,
  PRIORITY_FUNCTION = 900,
  PRIORITY_OPERATION = 100,
}

local HIGHLIGHT_GROUPS = {
  OVERALL = 'DiagnosticInfo',
  FUNCTION = 'DiagnosticHint',
}

-- Namespace for extmarks
M.namespace = vim.api.nvim_create_namespace('goplexity')

M.visible = false

-- Clear all extmarks in buffer
function M.clear(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
end

-- Create extmark with given text and styling
local function create_extmark(bufnr, namespace, line, text, hl_group, priority)
  vim.api.nvim_buf_set_extmark(bufnr, namespace, line, 0, {
    virt_text = { { text, hl_group } },
    virt_text_pos = 'eol',
    hl_mode = 'combine',
    priority = priority or DISPLAY_CONSTANTS.PRIORITY_OPERATION,
  })
end

-- Display loop complexity (show both time and space)
local function display_loop(bufnr, loop_info, config)
  local time_complexity = loop_info.complexity or loop_info.base_complexity or 'O(1)'
  local space_complexity = 'O(1)' -- Loops typically don't allocate new space
  local text = string.format('%s T:%s S:%s', config.virtual_text_icon, time_complexity, space_complexity)
  create_extmark(bufnr, M.namespace, loop_info.line - 1, text, config.virtual_text_hl_group)
end

-- Display function call time complexity
local function display_function_call(bufnr, call_info, config)
  local time_complexity = call_info.complexity or call_info.base_complexity or 'O(1)'
  local text = string.format('%s T:%s', config.virtual_text_icon, time_complexity)
  create_extmark(bufnr, M.namespace, call_info.line - 1, text, config.virtual_text_hl_group)
end

-- Display per-function complexity summary
local function display_function_summary(bufnr, func_info, config)
  local text = string.format(
    '%s Time: %s | Space: %s',
    config.virtual_text_icon,
    func_info.time_complexity,
    func_info.space_complexity
  )
  create_extmark(
    bufnr,
    M.namespace,
    func_info.line - 1,
    text,
    HIGHLIGHT_GROUPS.FUNCTION,
    DISPLAY_CONSTANTS.PRIORITY_FUNCTION
  )
end

-- Check if line is a comment or empty
local function is_comment_or_empty(trimmed)
  return trimmed == '' or trimmed:match('^//') or trimmed:match('^/%*')
end

-- Check if line is a header-like pattern (package, import, func, type, etc.)
local function is_header_pattern(trimmed)
  local patterns = {
    '^package%s+',
    '^import%s+',
    '^func%s+main%s*%(',
    '^func%s+[A-Z]%w*%s*%(', -- exported function
    '^type%s+%w+%s+struct',
    '^type%s+%w+%s+interface',
  }

  for _, pattern in ipairs(patterns) do
    if trimmed:match(pattern) then
      return true
    end
  end
  return false
end

-- Find the best line to display overall complexity
local function find_display_line(lines)
  local target_line = 0

  for i, line in ipairs(lines) do
    local trimmed = line:match('^%s*(.-)%s*$')

    if not is_comment_or_empty(trimmed) then
      -- Check for header patterns (package, import, func, type)
      if is_header_pattern(trimmed) then
        target_line = i - 1
        break
      end

      -- Fallback: first non-empty, non-comment line
      if target_line == 0 then
        target_line = i - 1
      end
    end
  end

  return target_line
end

-- Display overall complexity near top of file
local function display_overall(bufnr, time_complexity, space_complexity, config)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, DISPLAY_CONSTANTS.HEADER_SCAN_LIMIT, false)
  local target_line = find_display_line(lines)

  local overall_text =
    string.format('%s Time: %s | Space: %s', config.virtual_text_icon, time_complexity, space_complexity)

  create_extmark(
    bufnr,
    M.namespace,
    target_line,
    overall_text,
    HIGHLIGHT_GROUPS.OVERALL,
    DISPLAY_CONSTANTS.PRIORITY_OVERALL
  )
end

-- Display all analysis results
function M.display(bufnr, analysis_results)
  local config = require('goplexity.config').config
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  if not M.visible then
    return
  end

  M.clear(bufnr)

  display_overall(bufnr, analysis_results.overall_time, analysis_results.space, config)

  for _, func_info in ipairs(analysis_results.functions or {}) do
    display_function_summary(bufnr, func_info, config)
  end

  for _, loop_info in ipairs(analysis_results.loops) do
    display_loop(bufnr, loop_info, config)
  end

  for _, call_info in ipairs(analysis_results.function_calls) do
    display_function_call(bufnr, call_info, config)
  end
end

-- Toggle visibility (returns true if shown, false if hidden)
function M.toggle(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  M.visible = not M.visible

  if not M.visible then
    M.clear(bufnr)
  end

  return M.visible
end

-- Clear marks (exposed for external use)
function M.hide(bufnr)
  M.visible = false
  M.clear(bufnr or vim.api.nvim_get_current_buf())
end

return M
