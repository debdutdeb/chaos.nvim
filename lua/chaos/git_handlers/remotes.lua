local utils = require("chaos.utils")

local M = {}

function M.is_git_worktree()
	return utils.run_system_command_blocking({ "git", "rev-parse", "--is-inside-work-tree" }).code == 0
end

function M.list_origins()
	local result = utils.run_system_command_blocking({ "git", "remote", "show" })
	if result.code ~= 0 then
		utils.error("failed to list repository origins")
		return
	end

	return result.job:result()
end

function M.get_remote_url_for_origin(origin)
	local result = utils.run_system_command_blocking({ "git", "remote", "get-url", origin })
	if result.code ~= 0 then
		utils.error("failed to get remote url for origin " .. origin)
		return
	end

	return result.job:result()[1]
end

function M.get_commit_hash_for_file(file)
	local result = utils.run_system_command_blocking({ "git", "log", "-n", "1", "--pretty=format:%H", "--", file })
	if result.code ~= 0 then
		utils.error("failed to get commit hash for file " .. file)
		return
	end

	return result.job:result()[1]
end

return M
