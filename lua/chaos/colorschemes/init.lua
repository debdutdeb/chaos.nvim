local rok, action_state = pcall(require, "telescope.actions.state")
if not rok then
	error("telescope required for plugin thing to work")
	return
end

local error = require("chaos.utils").notify_error

local function save_colorscheme(colorscheme)
	if colorscheme == nil then
		error("no colorscheme passed")
		return
	end
	local file = io.open(vim.fn.expand("$HOME/.config/nvim/after/plugin/.colorscheme"), "w")
	if file == nil then
		error("failed to open colorscheme file")
		return
	end
	file:write(colorscheme)
	io.close(file)
end

local function get_colorscheme()
	local file = io.open(vim.fn.expand("$HOME/.config/nvim/after/plugin/.colorscheme"), "r")
	if file == nil then
		error("failed to open colorscheme file")
		return ""
	end
	local colorscheme = file:read("l")
	file:close()
	return colorscheme
end

local mod = {}
function mod.maybe_save_colorscheme(prompt_bufnr)
	local picker = action_state.get_current_picker(prompt_bufnr)
	local color = action_state.get_selected_entry().value
	if picker.prompt_title ~= "Change Colorscheme" then
		return
	end
	save_colorscheme(color)
	-- picker:close_windows() don't close window as select_default is chained
end

local transform_mod = require("telescope.actions.mt").transform_mod

local M = {
	maybe_save_colorscheme = transform_mod(mod).maybe_save_colorscheme,
}

function M.setup_colorscheme()
	local current_colorscheme = get_colorscheme()
	vim.api.nvim_exec2([[colorscheme ]] .. current_colorscheme, { output = false })
end

return M
