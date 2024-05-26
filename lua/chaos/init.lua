local M = {}

local git_handlers = require("chaos.git_handlers")
local utils = require("chaos.utils")

require("chaos.fun")

function M.setup_commands()
	vim.api.nvim_create_user_command("GitUrl", function(opts)
		local _filename = vim.fn.expand("%")
		local filename = string.sub(vim.system({ "git", "ls-files", "--full-name", _filename }):wait().stdout, 0, -2)

		if not git_handlers.is_git_worktree() then
			utils.notify_error("not a git repository")
			return
		end

		local origins = git_handlers.list_origins()

		if not origins then
			return
		end

		local remote_origin = ""

		if #origins > 1 then
			local prompt = "select an origin\n"
			for i, origin in ipairs(origins) do
				prompt = prompt .. i .. ". " .. origin .. "\n"
			end
			remote_origin = origins[tonumber(vim.fn.input(prompt), 10)]
		else
			remote_origin = origins[1]
		end

		local remote = git_handlers.get_remote_url_for_origin(remote_origin)
		if not remote then
			return
		end

		local repo_url = ""

		local ssh_at = string.find(remote, "@")
		if ssh_at ~= nil then
			local colon = string.find(remote, ":")
			local repo_host = string.sub(remote, ssh_at + 1, colon - 1)
			local repo = string.sub(remote, colon + 1, -5)
			repo_url = "https://" .. repo_host .. "/" .. repo
		else
			repo_url = string.sub(remote, 0, -5)
		end

		local hash = git_handlers.get_commit_hash_for_file(_filename)
		if not hash then
			return
		end

		local url = repo_url .. "/blob/" .. hash .. "/" .. filename

		if opts.range == 1 then
			url = url .. "#L" .. opts.count -- or any of opts.line1 or opts.line2
		elseif opts.range == 2 then
			url = url .. "#L" .. opts.line1 .. "-L" .. opts.line2
		end

		if opts.bang then
			vim.fn.setreg("+", url)
		else
			vim.notify(url)
		end
	end, { nargs = 0, range = true, bang = true, })
end

return M
