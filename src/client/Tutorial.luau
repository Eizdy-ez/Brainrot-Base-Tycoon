-- Tutorial.luau — walks a new tycoon through their first loop: a hint bar
-- plus a bouncing 3D arrow over the next thing to touch (field, own pad,
-- collect pad, upgrade pad). Driven by the server's TutorialStep.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UI = require(script.Parent:WaitForChild("UIBuilder"))

local Tutorial = {}
local ctx
local hintFrame, hintLabel, arrow, arrowLabel
local targetPos = nil

local STEP_TEXT = {
	[0] = "👉 Go to the fields and TOUCH a brainrot to catch it!",
	[1] = "🏠 Carry it home! Step on a glowing pad at YOUR base to place it.",
	[2] = "💰 Your brainrot earns cash — step on the GREEN pad to collect!",
	[3] = "🛒 Buy an upgrade: step on a GOLD pad at your base, or open the SHOP!",
}

local function findBasePart(state, partName)
	local worldRoot = Workspace:FindFirstChild("BrainrotWorld")
	local baseModel = worldRoot and state.BaseSlot > 0 and worldRoot:FindFirstChild("Base" .. state.BaseSlot)
	return baseModel and baseModel:FindFirstChild(partName)
end

function Tutorial.Update(state)
	if state.TutorialDone or state.TutorialStep >= 4 then
		hintFrame.Visible = false
		arrow.Visible = false
		targetPos = nil
		return
	end
	local step = state.TutorialStep
	hintFrame.Visible = true
	hintLabel.Text = STEP_TEXT[step] or ""
	if step == 0 then
		targetPos = Vector3.new(0, 9, -64)
	else
		local partName = ({ [1] = "PadTop1", [2] = "CollectPad", [3] = "Upgrade_Pads" })[step]
		local part = partName and findBasePart(state, partName)
		if part then
			targetPos = part.Position + Vector3.new(0, 6.5, 0)
		else
			targetPos = nil
		end
	end
	arrow.Visible = targetPos ~= nil
end

function Tutorial.Start(c, gui)
	ctx = c
	hintFrame = UI.Frame(gui, UDim2.new(0, 560, 0, 46), UDim2.new(0.5, -280, 1, -108), Color3.fromRGB(255, 170, 40), 0.05)
	hintFrame.Visible = false
	hintLabel = UI.Label(hintFrame, "", UDim2.new(1, -20, 1, 0), UDim2.new(0, 10, 0, 0), { TextSize = 17, Align = Enum.TextXAlignment.Center, Color = Color3.fromRGB(40, 32, 10) })

	arrow = Instance.new("Part")
	arrow.Name = "TutorialArrow"
	arrow.Shape = Enum.PartType.Ball
	arrow.Size = Vector3.new(1.7, 1.7, 1.7)
	arrow.Color = Color3.fromRGB(255, 170, 40)
	arrow.Material = Enum.Material.Neon
	arrow.Anchored = true
	arrow.CanCollide = false
	arrow.CanQuery = false
	arrow.CanTouch = false
	arrow.Visible = false
	arrow.Parent = Workspace
	local guiBillboard = Instance.new("BillboardGui")
	guiBillboard.Size = UDim2.fromOffset(60, 60)
	guiBillboard.StudsOffset = Vector3.new(0, 2.2, 0)
	guiBillboard.AlwaysOnTop = true
	arrowLabel = Instance.new("TextLabel")
	arrowLabel.Size = UDim2.fromScale(1, 1)
	arrowLabel.BackgroundTransparency = 1
	arrowLabel.Text = "▼"
	arrowLabel.TextColor3 = Color3.fromRGB(255, 190, 60)
	arrowLabel.TextStrokeTransparency = 0.3
	arrowLabel.Font = Enum.Font.FredokaOne
	arrowLabel.TextSize = 44
	arrowLabel.Parent = guiBillboard
	guiBillboard.Parent = arrow

	RunService.Heartbeat:Connect(function()
		if arrow.Visible and targetPos then
			local bob = math.sin(os.clock() * 3) * 0.7
			arrow.CFrame = CFrame.new(targetPos + Vector3.new(0, bob, 0))
		end
	end)
end

return Tutorial
