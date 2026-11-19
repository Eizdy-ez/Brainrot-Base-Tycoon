-- FusionUI.luau — the fusion machine panel: groups your displayed brainrots,
-- and any group of 3 identical ones can fuse into a random brainrot of the
-- next rarity (mutation carries over).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UI = require(script.Parent:WaitForChild("UIBuilder"))

local FusionUI = {}
local ctx
local panel, rowsHolder, emptyLabel

function FusionUI.Open()
	panel.Visible = true
	ctx.Remotes.Action:FireServer("RequestState")
end

function FusionUI.Close()
	panel.Visible = false
end

function FusionUI.Toggle()
	if panel.Visible then
		FusionUI.Close()
	else
		FusionUI.Open()
	end
end

function FusionUI.Update(state)
	for _, child in ipairs(rowsHolder:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	-- group displayed brainrots by name + mutation
	local groups = {}
	local order = {}
	for _, entry in ipairs(state.Displayed) do
		local key = entry.Name .. "|" .. entry.Mutation
		if not groups[key] then
			groups[key] = { Name = entry.Name, Mutation = entry.Mutation, Rarity = entry.Rarity, Count = 0 }
			order[#order + 1] = groups[key]
		end
		groups[key].Count += 1
	end
	table.sort(order, function(a, b)
		if a.Rarity ~= b.Rarity then
			return a.Rarity > b.Rarity
		end
		return a.Count > b.Count
	end)
	emptyLabel.Visible = #order == 0
	local y = 0
	for _, group in ipairs(order) do
		local rarity = Config.Rarities[group.Rarity]
		local row = UI.Frame(rowsHolder, UDim2.new(1, -8, 0, 54), UDim2.new(0, 4, 0, y), Color3.fromRGB(50, 53, 70), 0)
		local canFuse = group.Count >= Config.FusionRequired and group.Rarity < 5
		UI.Label(row, group.Count .. "× " .. Config.DisplayName({ Name = group.Name }, group.Mutation), UDim2.new(0, 300, 0, 26), UDim2.new(0, 10, 0, 3),
			{ TextSize = 16, Color = rarity.Color })
		UI.Label(row, rarity.Name .. "  •  fuse " .. Config.FusionRequired .. " → 1 " .. (Config.Rarities[group.Rarity + 1] and Config.Rarities[group.Rarity + 1].Name or "—"),
			UDim2.new(0, 300, 0, 20), UDim2.new(0, 10, 0, 29), { TextSize = 13, Color = Color3.fromRGB(190, 198, 214) })
		local button = UI.Button(row, canFuse and "🧬 FUSE!" or (group.Rarity >= 5 and "MAX ⭐" or (group.Count .. "/" .. Config.FusionRequired)),
			UDim2.new(0, 118, 0, 38), UDim2.new(1, -128, 0, 8), canFuse and Color3.fromRGB(172, 84, 255) or Color3.fromRGB(90, 96, 120))
		if canFuse then
			button.MouseButton1Click:Connect(function()
				ctx.Remotes.Action:FireServer("Fuse", group.Name, group.Mutation)
			end)
		end
		y += 62
	end
	rowsHolder.CanvasSize = UDim2.new(0, 0, 0, y + 8)
end

function FusionUI.Start(c, gui)
	ctx = c
	panel = UI.Frame(gui, UDim2.new(0, 500, 0, 540), UDim2.new(0.5, -250, 0.5, -270), Color3.fromRGB(34, 36, 48), 0.03)
	panel.Visible = false
	UI.Label(panel, "🧬 FUSION MACHINE", UDim2.new(0, 340, 0, 40), UDim2.new(0, 16, 0, 8), { TextSize = 24, Color = Color3.fromRGB(215, 160, 255) })
	local close = UI.Button(panel, "✕", UDim2.new(0, 40, 0, 40), UDim2.new(1, -52, 0, 8), Color3.fromRGB(200, 70, 70))
	close.MouseButton1Click:Connect(function()
		ctx.Audio.PlaySfx("Click", 1)
		FusionUI.Close()
	end)
	UI.Label(panel, "Fuse 3 identical brainrots into ONE of the next rarity.\nThe mutation (Shiny/Golden) carries over!", UDim2.new(1, -32, 0, 44), UDim2.new(0, 16, 0, 52),
		{ TextSize = 15, Wrapped = true, Color = Color3.fromRGB(210, 200, 235) })
	rowsHolder = Instance.new("ScrollingFrame")
	rowsHolder.Name = "Rows"
	rowsHolder.Size = UDim2.new(1, -24, 1, -116)
	rowsHolder.Position = UDim2.new(0, 12, 0, 104)
	rowsHolder.BackgroundTransparency = 1
	rowsHolder.BorderSizePixel = 0
	rowsHolder.ScrollBarThickness = 6
	rowsHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
	rowsHolder.Parent = panel
	emptyLabel = UI.Label(rowsHolder, "No brainrots on your pads yet.\nCatch some in the fields first!", UDim2.new(1, -16, 0, 60), UDim2.new(0, 8, 0, 10),
		{ TextSize = 16, Wrapped = true, Color = Color3.fromRGB(190, 198, 214) })
end

return FusionUI
