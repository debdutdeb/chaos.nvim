local vim = vim or {} -- shutting up lsp

---@return string
local function get_lines_within_visual_selection()
	local s_start = vim.fn.getpos("'<")
	local s_end = vim.fn.getpos("'>")
	local n_lines = math.abs(s_end[2] - s_start[2]) + 1
	local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
	lines[1] = string.sub(lines[1], s_start[3], -1)
	if n_lines == 1 then
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
	else
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
	end
	return lines
end

---@class LineRange
---@field range boolean
---@field line1 number
---@field line2 number

---@return string
---@param opts LineRange
local function get_lines(opts)
	if opts.range then -- visual selection
		-- indexing is zero based
		-- that is, first line is actually 0 and not 1
		-- so where we want to start actually is line_number - 1
		-- https://neovim.io/doc/user/api.html#nvim_buf_get_lines()
		return vim.api.nvim_buf_get_lines(0, opts.line1 - 1, opts.line2, false)
	end

	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

vim.api.nvim_create_user_command("Freeze", function(data)
	local job_id = vim.fn.jobstart({ "freeze", "-l", vim.bo.filetype, "-o", data.args, "-" }, {
		on_stderr = function()
			require("chaos.utils").notify_error("failed to save screenshot to " .. data.args)
		end,
		on_exit = function()
			vim.notify("successfully saved screenshot to " .. data.args)
		end,
	})
	vim.fn.chansend(job_id, get_lines({ range = data.range ~= 0, line1 = data.line1, line2 = data.line2 }))
	vim.fn.chanclose(job_id, "stdin")
end, { nargs = 1, range = true })
