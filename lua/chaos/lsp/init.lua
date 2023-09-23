local M = {}

function M.setup_autocommands(servers, config_fn)
	if not vim.tbl_islist(servers) then
		require("chaos.utils").notify_error("server list must be an array")
		return
	end
	require("chaos.lsp.autocommands")._create_autocmd(servers, config_fn)
end

return M
