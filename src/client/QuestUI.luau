-- QuestUI — the quest tracker card: current quest, live progress bar and its cash reward.
-- QuestUI.luau — the quest tracker card: current quest, live progress bar,
-- and its cash reward. Fed entirely by the server state snapshot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Util = require(Shared:WaitForChild("Util"))
local UI = require(script.Parent:WaitForChild("UIBuilder"))

local QuestUI = {}
local ctx
local card, titleLabel, textLabel, rewardLabel, fillFrame, progressLabel
local visible = true

function QuestUI.Toggle()
	visible = not visible
	card.Visible = visible
end

function QuestUI.Update(state)
	if not state.Quest then
		titleLabel.Text = "📜 QUESTS DONE!"
		textLabel.Text = "Every quest complete — you are a true Brainrot Tycoon. Keep growing that base!"
		rewardLabel.Text = ""
		fillFrame.Size = UDim2.new(1, 0, 1, 0)
		progressLabel.Text = "🏆"
		return
	end
	local q = state.Quest
	titleLabel.Text = "📜 QUEST " .. q.Index .. "/" .. q.Total
	textLabel.Text = q.Text
	rewardLabel.Text = "Reward: $" .. Util.FormatInt(q.Reward)
	local frac = math.clamp(q.Progress / math.max(1, q.Target), 0, 1)
	fillFrame.Size = UDim2.new(frac, 0, 1, 0)
	progressLabel.Text = Util.FormatInt(math.min(q.Progress, q.Target)) .. " / " .. Util.FormatInt(q.Target)
end

function QuestUI.Start(c, gui)
	ctx = c
	card = UI.Frame(gui, UDim2.new(0, 300, 0, 148), UDim2.new(0, 12, 0, 74), Color3.fromRGB(34, 36, 48), 0.08)
	titleLabel = UI.Label(card, "📜 QUEST", UDim2.new(1, -20, 0, 26), UDim2.new(0, 10, 0, 6), { TextSize = 17, Color = Color3.fromRGB(140, 200, 255) })
	textLabel = UI.Label(card, "…", UDim2.new(1, -20, 0, 52), UDim2.new(0, 10, 0, 32), { TextSize = 16, Wrapped = true })
	textLabel.TextYAlignment = Enum.TextYAlignment.Top
	rewardLabel = UI.Label(card, "", UDim2.new(1, -20, 0, 22), UDim2.new(0, 10, 0, 86), { TextSize = 15, Color = Color3.fromRGB(140, 255, 160) })
	local barBg = UI.Frame(card, UDim2.new(1, -20, 0, 18), UDim2.new(0, 10, 0, 116), Color3.fromRGB(22, 23, 32), 0)
	fillFrame = Instance.new("Frame")
	fillFrame.Name = "Fill"
	fillFrame.Size = UDim2.new(0, 0, 1, 0)
	fillFrame.BackgroundColor3 = Color3.fromRGB(64, 200, 255)
	fillFrame.BorderSizePixel = 0
	fillFrame.Parent = barBg
	UI.Corner(fillFrame, 10)
	progressLabel = UI.Label(barBg, "0 / 1", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), { TextSize = 13, Align = Enum.TextXAlignment.Center })
end

return QuestUI
