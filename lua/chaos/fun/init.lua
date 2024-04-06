local function get_visual_selection_lines()
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

vim.api.nvim_create_user_command("Freeze", function(data)
	local job_id = vim.fn.jobstart({ "freeze", "-l", vim.bo.filetype, "-o", data.args, "-" }, {
		on_stderr = function()
			require("chaos.utils").notify_error("failed to save screenshot to " .. data.args)
		end,
		on_exit = function()
			vim.notify("successfully saved screenshot to " .. data.args)
		end,
	})
	vim.fn.chansend(job_id, get_visual_selection_lines())
	vim.fn.chanclose(job_id, "stdin")
end, { nargs = 1 })
