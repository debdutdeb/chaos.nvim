_G.Infinity = setmetatable({}, {
	__call = function(self, ...) return self end,
	__index = function(self, _) return self end,
	__newindex = function(...) end,
	__add = function(self, _) return self end,
	__sub = function(self, _) return self end,
	__div = function(self, _) return self end,
	__mod = function(self, _) return self end,
	__mul = function(self, _) return self end,
	__pow = function(self, _) return self end,
	__idiv = function(self, _) return self end,
	__unm = function(self) return self end,
	__concat = function(self, _) return self end,
	__eq = function(self, t) if tostring(t) == tostring(self) then return self == t else return false end end,
	--XXX
	__lt = function(self, t) return false end,
	--XXX
	__le = function(self, t) if tostring(t) == tostring(self) then return self == t else return false end end,
	__name = "[[Infinity]]",
	__len = function(self) return self end,
	-- TODO: __pairs?
})

function _G.Require(mod)
	if package.loaded[mod] then return package.loaded[mod] end
	local ok, p = pcall(require, mod)
	if not ok then
		vim.notify("module not found " .. mod)
		return Infinity
	end

	return p
end

