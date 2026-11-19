-- Util.luau — small helpers shared by server and client.

local Util = {}

-- 1234567 -> "1.23M", 45000 -> "45K", 900 -> "900"
function Util.FormatCash(n)
	n = math.floor(n)
	if n >= 1e9 then
		return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6 then
		return string.format("%.2fM", n / 1e6)
	elseif n >= 1e4 then
		return string.format("%.1fK", n / 1e3)
	elseif n >= 1e3 then
		return string.format("%.2fK", n / 1e3)
	end
	return tostring(n)
end

function Util.FormatInt(n)
	n = math.floor(n)
	local s = tostring(n)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if out:sub(1, 1) == "," then
		out = out:sub(2)
	end
	return out
end

-- Weighted pick: weights is an array of numbers, returns an index.
function Util.WeightedIndex(weights)
	local total = 0
	for _, w in ipairs(weights) do
		total += w
	end
	local roll = math.random() * total
	local acc = 0
	for i, w in ipairs(weights) do
		acc += w
		if roll <= acc then
			return i
		end
	end
	return #weights
end

function Util.Clamp(n, lo, hi)
	return math.max(lo, math.min(hi, n))
end

function Util.Lerp(a, b, t)
	return a + (b - a) * t
end

-- Deep-ish copy for plain data tables (profiles are plain data).
function Util.CopyTable(t)
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in pairs(t) do
		out[k] = Util.CopyTable(v)
	end
	return out
end

return Util
