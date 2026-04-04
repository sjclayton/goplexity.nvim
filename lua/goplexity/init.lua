-- Main module - Command interface and orchestration

local M = {}

M.version = '2.0.0'

local analyzer = require('goplexity.analyzer')
local display = require('goplexity.display')
local config = require('goplexity.config')

-- Store last analysis results per buffer
M.last_analysis = {}

-- Setup
function M.setup(user_config)
  config.setup(user_config)
end

-- Run complexity analysis and display results
local function run_analysis(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  if filetype ~= 'go' then
    vim.notify('Goplexity: Only Go files are supported', vim.log.levels.WARN)
    return nil
  end

  local results = analyzer.analyze(bufnr)
  M.last_analysis[bufnr] = results
  display.display(bufnr, results)

  local summary = string.format('Time: %s | Space: %s | %d loops', results.overall_time, results.space, #results.loops)

  local constraints = config.get_constraints()
  local has_constraints = constraints.n or constraints.memory_limit_mb
  if has_constraints then
    local warnings = config.should_warn(results.overall_time, results.space)
    if #warnings > 0 then
      for _, warning in ipairs(warnings) do
        vim.notify(warning, vim.log.levels.WARN)
      end
    else
      vim.notify('Goplexity: ' .. summary, vim.log.levels.INFO)
    end
  else
    vim.notify('Goplexity: ' .. summary, vim.log.levels.INFO)
  end

  return results
end

-- Set problem constraints
local function set_constraints(args)
  if #args < 1 then
    vim.notify('Goplexity: Usage: :Goplexity constraints <n> [time_ms] [memory_mb]', vim.log.levels.ERROR)
    return
  end

  local n = tonumber(args[1])
  local time_ms = args[2] and tonumber(args[2])
  local memory_mb = args[3] and tonumber(args[3])

  if not n then
    vim.notify('Goplexity: Invalid constraint value', vim.log.levels.ERROR)
    return
  end

  config.set_constraints(n, time_ms, memory_mb)

  local msg = string.format('Goplexity: Constraints set - n=%s', n)
  if time_ms then
    msg = msg .. string.format(', time=%dms', time_ms)
  end
  if memory_mb then
    msg = msg .. string.format(', memory=%dMB', memory_mb)
  end

  vim.notify(msg, vim.log.levels.INFO)
end

-- Toggle complexity visibility (returns true if shown, false if hidden)
function M.toggle(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local visible = display.toggle(bufnr)

  if visible then
    run_analysis(bufnr)
  end

  return visible
end

-- Main command handler
function M.command(args)
  if #args == 0 then
    M.toggle()
    return
  end

  local cmd = args[1]:lower()

  if cmd == 'constraints' then
    local constraint_args = {}
    for i = 2, #args do
      table.insert(constraint_args, args[i])
    end
    set_constraints(constraint_args)
  else
    vim.notify('Goplexity: Unknown command: ' .. cmd, vim.log.levels.ERROR)
  end
end

return M
