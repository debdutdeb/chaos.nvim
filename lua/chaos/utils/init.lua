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
	local payload = {}

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

return M
