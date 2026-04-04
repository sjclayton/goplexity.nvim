-- goplexity.nvim - Complexity Visualizer for Golang
-- Plugin entry point

if vim.g.loaded_goplexity == 1 then
	return
end
vim.g.loaded_goplexity = 1

vim.api.nvim_create_user_command("Goplexity", function(opts)
	require("goplexity").command(opts.fargs)
end, {
	nargs = "*",
	complete = function()
		return { "constraints" }
	end,
	desc = "Goplexity complexity visualizer commands",
})
