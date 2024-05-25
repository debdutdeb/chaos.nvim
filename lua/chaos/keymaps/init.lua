local M = {}

---@class Callback
---@field callback string | function
---@field fallback string | function

local function bind(op, outer_opts)
	outer_opts = outer_opts or { noremap = true, silent = true }

	---@param foo string|function
	local run = function(foo)
		if type(foo) == "string" then
			return vim.api.nvim_command_output(foo)
		else
			return foo()
		end
	end

	---@param lhs string
	---@param rhs string | function
	---@param opts table | nil
	return function(lhs, rhs, opts)
		local func = rhs
		if type(rhs) == "table" then
			func = function()
				local ok, result = pcall(run, rhs.callback)
				if not ok then
					vim.notify("falling back since primary failed " .. result)
					run(rhs.fallback)
				end
			end
		end

		opts = vim.tbl_extend("force", outer_opts, opts or {})
		vim.keymap.set(op, lhs, func or function() end, opts)
	end
end

M.nmap = bind("n", { noremap = false })
M.nnoremap = bind("n")
M.vnoremap = bind("v")
M.xnoremap = bind("x")
M.inoremap = bind("i")

local function bind_send_keys(mode)
	return function(key)
		vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, false)
	end
end

M.nsend_keys = bind_send_keys("n")
M.vsend_keys = bind_send_keys("v")
M.xsend_keys = bind_send_keys("x")
M.isend_keys = bind_send_keys("i")
M.tsend_keys = bind_send_keys("t")

return M
