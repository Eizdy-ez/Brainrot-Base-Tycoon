-- ShopUI.luau — the shop panel: four upgrade tracks with live levels and
-- prices, and the two zone unlocks. (Rebirth used to live here; since
-- Round 9 it is the HUD's Rebirth button under Quest, behind its own
-- Yes/Tidak confirmation dialog.)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))
local UI = require(script.Parent:WaitForChild("UIBuilder"))

local ShopUI = {}
local ctx
local panel
local upgradeRows = {} -- [key] = { Level = label, Button = button }
local zoneRows = {}    -- [zi] = { Button = button, Status = label }

local function makeRow(parent, y, height)
	local row = UI.Frame(parent, UDim2.new(1, -24, 0, height), UDim2.new(0, 12, 0, y), Color3.fromRGB(50, 53, 70), 0)
	return row
end

function ShopUI.Open()
	panel.Visible = true
	ctx.Remotes.Action:FireServer("RequestState")
end

function ShopUI.Close()
	panel.Visible = false
end

function ShopUI.Toggle()
	if panel.Visible then
		ShopUI.Close()
	else
		ShopUI.Open()
	end
end

function ShopUI.Update(state)
	for key, row in pairs(upgradeRows) do
		local up = Config.Upgrades[key]
		local level
		if key == "Pads" then
			level = (state.Pads - up.Start) / up.Step
			row.Level.Text = "Pads: " .. state.Pads .. "/" .. up.Max
		else
			level = state[key .. "Lvl"]
			row.Level.Text = "Lv " .. level .. "/" .. up.Max
		end
		if level >= #up.Costs then
			row.Button.Text = "MAX ⭐"
			row.Button.BackgroundColor3 = Color3.fromRGB(90, 96, 120)
		else
			row.Button.Text = "$" .. Util.FormatInt(up.Costs[level + 1])
			row.Button.BackgroundColor3 = state.Cash >= up.Costs[level + 1] and Color3.fromRGB(64, 190, 90) or Color3.fromRGB(150, 90, 90)
		end
	end
	for zi, row in pairs(zoneRows) do
		local zone = Config.Zones[zi]
		if state.Zones[zi] then
			row.Button.Text = "OPEN ✅"
			row.Button.BackgroundColor3 = Color3.fromRGB(90, 96, 120)
		else
			row.Button.Text = "$" .. Util.FormatInt(zone.Price)
			row.Button.BackgroundColor3 = state.Cash >= zone.Price and Color3.fromRGB(64, 190, 90) or Color3.fromRGB(150, 90, 90)
		end
	end
end

function ShopUI.Start(c, gui)
	ctx = c
	panel = UI.Frame(gui, UDim2.new(0, 500, 0, 488), UDim2.new(0.5, -250, 0.5, -244), Color3.fromRGB(34, 36, 48), 0.03)
	panel.Visible = false
	UI.Label(panel, "🛒 TYCOON SHOP", UDim2.new(0, 300, 0, 40), UDim2.new(0, 16, 0, 8), { TextSize = 24, Color = Color3.fromRGB(255, 196, 66) })
	local close = UI.Button(panel, "✕", UDim2.new(0, 40, 0, 40), UDim2.new(1, -52, 0, 8), Color3.fromRGB(200, 70, 70))
	close.MouseButton1Click:Connect(function()
		ctx.Audio.PlaySfx("Click", 1)
		ShopUI.Close()
	end)

	local y = 56
	UI.Label(panel, "UPGRADES", UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 0, y), { TextSize = 16, Color = Color3.fromRGB(170, 210, 255) })
	y += 28
	local icons = { Pads = "🟦", Speed = "👟", Carry = "🎒", Luck = "🍀" }
	for _, key in ipairs({ "Pads", "Speed", "Carry", "Luck" }) do
		local up = Config.Upgrades[key]
		local row = makeRow(panel, y, 52)
		UI.Label(row, icons[key] .. " " .. up.Label, UDim2.new(0, 240, 0, 26), UDim2.new(0, 10, 0, 2), { TextSize = 16 })
		local level = UI.Label(row, "", UDim2.new(0, 240, 0, 20), UDim2.new(0, 10, 0, 28), { TextSize = 14, Color = Color3.fromRGB(190, 198, 214) })
		local button = UI.Button(row, "$?", UDim2.new(0, 130, 0, 38), UDim2.new(1, -142, 0, 7), Color3.fromRGB(64, 190, 90))
		button.MouseButton1Click:Connect(function()
			ctx.Remotes.Action:FireServer("BuyUpgrade", key)
		end)
		upgradeRows[key] = { Level = level, Button = button }
		y += 60
	end

	UI.Label(panel, "ZONES", UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 0, y), { TextSize = 16, Color = Color3.fromRGB(170, 210, 255) })
	y += 28
	for zi = 2, 3 do
		local zone = Config.Zones[zi]
		local row = makeRow(panel, y, 52)
		UI.Label(row, "🌈 " .. zone.Name, UDim2.new(0, 300, 0, 26), UDim2.new(0, 10, 0, 2), { TextSize = 16 })
		UI.Label(row, "Richer brainrots spawn here!", UDim2.new(0, 300, 0, 20), UDim2.new(0, 10, 0, 28), { TextSize = 14, Color = Color3.fromRGB(190, 198, 214) })
		local button = UI.Button(row, "$?", UDim2.new(0, 130, 0, 38), UDim2.new(1, -142, 0, 7), Color3.fromRGB(64, 190, 90))
		button.MouseButton1Click:Connect(function()
			ctx.Remotes.Action:FireServer("UnlockZone", zi)
		end)
		zoneRows[zi] = { Button = button }
		y += 60
	end
end

return ShopUI
