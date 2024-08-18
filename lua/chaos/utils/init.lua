local ok, Job = pcall(require, "plenary.job")
if not ok then
	vim.notify("plenary is required for this plugin to work", vim.log.levels.WARN)
	return
end

local M = {}

local function tbl_slice(tbl, first, last)
	local sliced = {}
	for i = first or 1, last or #tbl do
		sliced[#sliced + 1] = tbl[i]
	end
	return sliced
end

function M.run_system_command_blocking(cmd)
	local payload = { code = -1 }

	Job:new({
		command = cmd[1],
		args = tbl_slice(cmd, 2),
		on_exit = function(job, return_code)
			payload = {
				job = job,
				code = return_code,
			}
		end,
	}):sync()

	return payload
end

function M.notify_error(msg)
	vim.notify(msg, vim.log.levels.ERROR)
end

---@param handler function
function M.get_file_relative_path_with_telescope(handler)
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local config = require("telescope.config").values

	local Path = require("plenary.path")

	---@param file string
	local get_relative_path = function(file)
		local current_file = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
		local current_file_dir = Path:new(current_file):is_dir() and current_file
			or current_file:gsub(Path.path.sep .. "[^" .. Path.path.sep .. "]+$", "")

		--[[
		-- If selected file is in the same directory as current file
		--]]
		local selected_file_path = Path:new(Path:new(file):absolute())

		local selected_file_relative_to_cwd = selected_file_path:make_relative(current_file_dir)
		if not Path:new(selected_file_relative_to_cwd):is_absolute() then
			return "./" .. tostring(selected_file_relative_to_cwd):gsub(Path.path.sep .. "%." .. Path.path.sep, "")
		end

		--[[
		-- If selected file isn't in the same directory as currently open file
		--]]
		local cwd_with_sep = vim.fn.getcwd() .. Path.path.sep

		-- both are 100% relative to vim_cwd
		local current_dir_relative_to_vim_cwd = Path:new(current_file_dir):make_relative(cwd_with_sep)

		local selected_file_relative_to_vim_cwd = Path:new(file):make_relative(cwd_with_sep)

		local relative_dir = selected_file_relative_to_vim_cwd
		for _ in string.gmatch(current_dir_relative_to_vim_cwd, string.format("([^%s]+)", Path.path.sep)) do -- for each part, up one dir
			relative_dir = Path:new("..") / Path:new(relative_dir)
		end

		return tostring(relative_dir):gsub(Path.path.sep .. "%." .. Path.path.sep, "")
	end

	pickers
		.new({}, {
			prompt_title = "Get relative path of",
			finder = finders.new_oneshot_job(
				{
					vim.iter({ "yes", "true", "1" }):any(function(value)
						return os.getenv("NEOVIM_CHAOS_USE_FIND") == value
					end) and "find" or "fd",
				},
				{}
			),
			previewer = config.file_previewer({}),
			sorter = config.generic_sorter({}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					handler(get_relative_path(action_state.get_selected_entry()[1]))
				end)
				return true
			end,
			layout_config = {
				width = 0.9,
			},
		})
		:find()
end

return M
