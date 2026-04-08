-- Main module - Command interface and orchestration

local M = {}

local ts_analyzer = require('goplexity.ts_analyzer')
local display = require('goplexity.display')
local config = require('goplexity.config')

-- Store last analysis results per buffer
M.last_analysis = {}

-- Setup
function M.setup(user_config)
  config.setup(user_config)
end

-- Run complexity analysis via the tree-sitter backend and display results.
-- show_summary: if true, displays the summary notification (default: true)
local function run_analysis(bufnr, show_summary)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  show_summary = show_summary ~= false

  local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufnr })
  if filetype ~= 'go' then
    vim.notify('Goplexity: Only Go files are supported', vim.log.levels.WARN)
    return nil
  end

  local ok, results = pcall(ts_analyzer.analyze, bufnr)
  if not ok then
    -- results holds the error string when pcall fails
    vim.notify('Goplexity: ' .. tostring(results), vim.log.levels.ERROR)
    return nil
  end

  M.last_analysis[bufnr] = results
  display.display(bufnr, results)

  local summary = string.format('Time: %s | Space: %s | %d loops', results.overall_time, results.space, #results.loops)

  if show_summary then
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

-- Auto-refresh on save when hints are visible.
-- Auto-analyze on Go file open when enabled = true.
function M.setup_autocmds()
  local group = vim.api.nvim_create_augroup('GoplexityAutoRefresh', { clear = true })

  local timers = {}

  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*.go',
    callback = function()
      if display.visible then
        local bufnr = vim.api.nvim_get_current_buf()
        if M.last_analysis[bufnr] then
          run_analysis(bufnr)
        end
      end
    end,
    desc = 'Re-run goplexity analysis on save when hints are visible',
  })

  vim.api.nvim_create_autocmd({ 'BufDelete', 'BufWipeout' }, {
    group = group,
    pattern = '*.go',
    callback = function(args)
      M.last_analysis[args.buf] = nil
      display.clear(args.buf)
      if timers[args.buf] then
        timers[args.buf]:stop()
        timers[args.buf] = nil
      end
    end,
    desc = 'Cleanup goplexity data when buffer is closed',
  })

  vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
    group = group,
    pattern = '*.go',
    callback = function(args)
      if not display.visible then
        return
      end
      if timers[args.buf] then
        timers[args.buf]:stop()
        timers[args.buf] = nil
      end
      timers[args.buf] = vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(args.buf) then
          run_analysis(args.buf, false)
        end
        timers[args.buf] = nil
      end, 500)
    end,
    desc = 'Debounced live-refresh of goplexity analysis',
  })

  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'go',
    callback = function()
      if config.config.enabled then
        local bufnr = vim.api.nvim_get_current_buf()
        display.visible = true
        run_analysis(bufnr)
      end
    end,
    desc = 'Auto-analyze Go files on open when enabled = true',
  })
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
