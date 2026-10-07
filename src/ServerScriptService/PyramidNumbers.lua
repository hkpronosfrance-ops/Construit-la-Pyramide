local M = {}

function M.Finite(value, fallback, minValue, maxValue)
	local n = tonumber(value)
	if not n or n ~= n or n == math.huge or n == -math.huge then
		return fallback
	end
	if minValue ~= nil then
		n = math.max(minValue, n)
	end
	if maxValue ~= nil then
		n = math.min(maxValue, n)
	end
	return n
end

function M.Integer(value, fallback, minValue, maxValue)
	local n = M.Finite(value, fallback, minValue, maxValue)
	if n == nil then
		return nil
	end
	return math.floor(n)
end

return M
