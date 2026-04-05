-- goplexity.nvim - Complexity Visualizer for Golang
-- Plugin entry point (requires Neovim 0.12+)

if vim.fn.has('nvim-0.12') == 0 then
  vim.notify(
    'goplexity.nvim requires Neovim 0.12+. Please upgrade Neovim.',
    vim.log.levels.WARN
  )
  return
end

if vim.g.loaded_goplexity == 1 then
  return
end
vim.g.loaded_goplexity = 1

vim.api.nvim_create_user_command('Goplexity', function(opts)
  require('goplexity').command(opts.fargs)
end, {
  nargs = '*',
  complete = function()
    return { 'constraints' }
  end,
  desc = 'Goplexity complexity visualizer commands',
})

-- Set up auto-refresh on save
require('goplexity').setup_autocmds()
