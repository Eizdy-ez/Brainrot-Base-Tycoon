-- LeaderboardManager — the plaza Cash Kings board: top tycoons by lifetime earnings, refreshed every ten seconds.
-- Key responsibility: ranks the tycoons by lifetime earnings on the plaza Cash Kings board.
-- LeaderboardManager.luau — keeps the big plaza board honest: the top
-- tycoons by lifetime earnings, refreshed every ten seconds.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Util = require(Shared:WaitForChild("Util"))

local LeaderboardManager = {}

function LeaderboardManager.Start(ctx)
	task.spawn(function()
		while true do
			task.wait(10)
			local label = ctx.World.LeaderboardLabel
			if label then
				local rows = {}
				for _, player in ipairs(Players:GetPlayers()) do
					local profile = ctx.Data.Profiles[player]
					if profile then
						rows[#rows + 1] = { Name = player.DisplayName, Earned = profile.TotalEarned, Rebirths = profile.Rebirths }
					end
				end
				table.sort(rows, function(a, b)
					return a.Earned > b.Earned
				end)
				if #rows == 0 then
					label.Text = "Be the first tycoon on the board!"
				else
					local lines = {}
					for i = 1, math.min(8, #rows) do
						local r = rows[i]
						lines[#lines + 1] = i .. ". " .. r.Name .. " — $" .. Util.FormatCash(r.Earned) .. (r.Rebirths > 0 and (" (🌟" .. r.Rebirths .. ")") or "")
					end
					label.Text = table.concat(lines, "\n")
				end
			end
		end
	end)
end

return LeaderboardManager
