local lspconfig = require("lspconfig")
local lspconfig_configs = require("lspconfig.configs")
local lspconfig_util = require("lspconfig.util")
local plenary_filetype = require("plenary.filetype")

local function _start_and_autostart_from_now_on(config) -- this lets me gotoDefinition and still have lsp running on other modules
	-- vim.lsp.start(config)
	config.autostart = true
	lspconfig[config.name].setup(config) -- resetup
end

local function __maybe_start_lsp(lsp_servers_configured, args)
	-- TODO this probably can be simplified couple folds given lsp.start exists
	local autostart_patterns = {
		"neovim_autostart_lsp",
		"vim_autostart_lsp",
		"autostart_lsp",
		"lsp_autostart",
		"start_lsp",
		"lsp_start",
	}
	local ft = plenary_filetype.detect(args.file or args.match)
	for _, client in pairs(lspconfig_util.get_active_clients_list_by_ft(ft)) do
		if client ~= "null-ls" then
			return
		end
	end
	local get_configured_server = function()
		for _, client in pairs(lspconfig_util.get_other_matching_providers(ft)) do
			for _, server in pairs(lsp_servers_configured) do
				if server == client.name then
					return server
				end
			end
		end
	end
	local config = lspconfig_configs[get_configured_server()]
	if not config or config.autostart then
		return
	end
	-- try to find the trigger files in current and parents before lsp root
	if lspconfig_util.root_pattern(unpack(autostart_patterns))(args.match or args.file) ~= nil then
		-- return config.launch(args.buf)
		return _start_and_autostart_from_now_on(config)
	end
	coroutine.resume(coroutine.create(function()
		local root_dir
		local status, error = pcall(function()
			root_dir = config.get_root_dir(args.match)
		end)
		if vim.in_fast_event() then
			local routine = assert(coroutine.running())
			vim.schedule(function()
				coroutine.resume(routine)
			end)
			routine.yield()
		end
		if not status then
			return vim.notify_once(
				("[config] failed to start language server %s::error: %s"):format(language_server, error),
				vim.log.levels.WARN
			)
		end
		if not root_dir then
			return
		end

		if #vim.fs.find(autostart_patterns, { upward = false, limit = 1, type = "file", path = root_dir }) ~= 0 then
			-- config.launch(args.buf)
			_start_and_autostart_from_now_on(config)
		end
	end))
end

return {
	_create_autocmd = function(servers)
		vim.api.nvim_create_autocmd("BufReadPost", {
			callback = function(args)
				vim.defer_fn(function()
					__maybe_start_lsp(servers, args)
				end, 2000)
			end,
			-- https://github.com/neovim/nvim-lspconfig/blob/0011c435282f043a018e23393cae06ed926c3f4a/lua/lspconfig/configs.lua#L64
			group = vim.api.nvim_create_augroup("lspconfig", { clear = false }),
		})
	end,
}
