local vim = vim or {} -- shutting up lsp

if vim.uv.os_uname().sysname ~= "Linux" then
	vim.notify("Freeze commands are currently supported in Linux")
	return
end

if not vim.fn.executable("freeze") then
	vim.notify("freeze command not found")
	return
end

if not vim.fn.executable("xclip") then
	vim.notify("xclip not found")
	return
end

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

---@return string[]
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

local uv = vim.uv

---@param lines string[]
function freeze(lines)
	local fd = uv.pipe({ nonblock = true }, { nonblock = true }) -- freeze write to and xclip to read from

	local write_to = uv.new_pipe()
	write_to:open(fd.write)

	local read_from = uv.new_pipe()
	read_from:open(fd.read)

	uv.spawn('xclip', {
		-- TODO: target atoms? i don't think I get what it means. Format looks like to be mime type.
		-- https://sourceforge.net/p/xclip/patches/4/
		args = { "-quiet", "-selection", "clipboard", "-t", "image/png" },
		stdio = { read_from, nil, nil },
	}, function(code, _signal)
		if code ~= 0 then
			print("failed to copy to clipboard")
			return
		end
		print('written to clipboard')
	end)

	local write_file_name = "/proc/" .. uv.getpid() .. "/fd/" .. fd.write

	local job_id = vim.fn.jobstart(
		{ "/home/debdut/git/freeze/freeze", "-l", vim.bo.filetype, "-o", write_file_name, "-f", "png", "-" }, {
			on_stderr = function()
				require("chaos.utils").notify_error("failed to save screenshot to pipe")
			end,
			on_exit = function()
				vim.notify("successfully saved screenshot to pipe")
				read_from:read_stop()
				read_from:close()
				write_to:close()
			end,
		})
	vim.fn.chansend(job_id, lines)
	vim.fn.chanclose(job_id, "stdin")
end

vim.api.nvim_create_user_command("Freeze", function(data)
	freeze(get_lines({ range = data.range ~= 0, line1 = data.line1, line2 = data.line2 }))
end, { nargs = 0, range = true })

vim.api.nvim_create_user_command("FreezeToFile", function(data)
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
