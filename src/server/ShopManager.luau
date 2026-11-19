-- ShopManager.luau — everything that costs cash: the four upgrade tracks,
-- zone unlocks at the gates, the fusion machine, and rebirth (with its aura).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local ShopManager = {}
local ctx

local function sound(player, name, pitch)
	ctx.Remotes.Event:FireClient(player, "PlaySound", name, pitch or 1)
end

local function notify(player, text, kind)
	ctx.Remotes.Event:FireClient(player, "Notify", text, kind)
end

function ShopManager.ApplySpeed(player)
	local profile = ctx.Data.Profiles[player]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if profile and humanoid then
		if not (ctx.DashUntil and (ctx.DashUntil[player] or 0) > os.clock()) then
			humanoid.WalkSpeed = Config.Upgrades.Speed.BaseSpeed + Config.Upgrades.Speed.PerLevel * profile.SpeedLvl
		end
	end
end

function ShopManager.ApplyAura(player)
	local profile = ctx.Data.Profiles[player]
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not (profile and hrp) then
		return
	end
	local existing = hrp:FindFirstChild("RebirthAura")
	if profile.Rebirths <= 0 then
		if existing then
			existing:Destroy()
		end
		return
	end
	if not existing then
		existing = Instance.new("ParticleEmitter")
		existing.Name = "RebirthAura"
		existing.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		existing.Size = NumberSequence.new(0.55)
		existing.Lifetime = NumberRange.new(0.8, 1.6)
		existing.Speed = NumberRange.new(1, 2.5)
		existing.SpreadAngle = Vector2.new(180, 180)
		existing.LightEmission = 0.8
		existing.Parent = hrp
	end
	existing.Color = ColorSequence.new(Color3.fromRGB(255, 120, 200), Color3.fromRGB(255, 200, 60))
	existing.Rate = 8 + profile.Rebirths * 5
end

function ShopManager.BuyUpgrade(player, key)
	local profile = ctx.Data.Profiles[player]
	local base = ctx.Bases.ByPlayer[player]
	if not profile then
		return
	end
	local up = Config.Upgrades[key]
	if not up then
		return
	end
	local level, cost
	if key == "Pads" then
		level = (profile.Pads - up.Start) / up.Step
	else
		level = profile[key .. "Lvl"]
	end
	if level >= #up.Costs then
		notify(player, "⭐ " .. up.Label .. " is already MAX!", "Error")
		sound(player, "Error", 1)
		return
	end
	cost = up.Costs[level + 1]
	if not ctx.Data.SpendCash(player, cost) then
		notify(player, "💸 Not enough cash! You need $" .. Util.FormatInt(cost) .. " for " .. up.Label, "Error")
		sound(player, "Error", 1)
		return
	end
	if key == "Pads" then
		profile.Pads += up.Step
		if base then
			ctx.Bases.RenderDisplayed(base)
		end
	else
		profile[key .. "Lvl"] += 1
	end
	profile.Stats.Bought += 1
	if key == "Speed" then
		ShopManager.ApplySpeed(player)
	end
	if base then
		ctx.Bases.UpdateShopLabels(base)
	end
	if profile.TutorialStep == 3 then
		profile.TutorialStep = 4
		profile.TutorialDone = true
	end
	notify(player, "🛒 Bought: " .. up.Label .. "!", "Success")
	sound(player, "Buy", 1)
	ctx.Quests.Refresh(player)
	ctx.Data.PushState(player, ctx)
end

function ShopManager.UnlockZone(player, zi)
	local profile = ctx.Data.Profiles[player]
	if not profile then
		return
	end
	local zone = Config.Zones[zi]
	if profile.Zones[zi] then
		notify(player, "✅ " .. zone.Name .. " is already unlocked!", "Info")
		return
	end
	if zi > 2 and not profile.Zones[zi - 1] then
		notify(player, "🔒 Unlock " .. Config.Zones[zi - 1].Name .. " first!", "Error")
		sound(player, "Error", 1)
		return
	end
	if not ctx.Data.SpendCash(player, zone.Price) then
		notify(player, "💸 Not enough cash! " .. zone.Name .. " costs $" .. Util.FormatInt(zone.Price), "Error")
		sound(player, "Error", 1)
		return
	end
	profile.Zones[zi] = true
	notify(player, "🌈 " .. zone.Name .. " UNLOCKED! Richer brainrots await!", "Success")
	sound(player, "Celebrate", 1)
	ctx.Quests.Refresh(player)
	ctx.Data.PushState(player, ctx)
end

function ShopManager.Fuse(player, name, mutation)
	local profile = ctx.Data.Profiles[player]
	local base = ctx.Bases.ByPlayer[player]
	if not profile or not base then
		return
	end
	local def = Config.BrainrotByName[name]
	if not def then
		return
	end
	if def.Rarity >= 5 then
		notify(player, "⭐ Mythic brainrots can't fuse any further!", "Error")
		sound(player, "Error", 1)
		return
	end
	-- collect the indices of matching displayed brainrots
	local indices = {}
	for i, entry in ipairs(profile.Displayed) do
		if entry.Name == name and entry.Mutation == mutation then
			indices[#indices + 1] = i
		end
	end
	if #indices < Config.FusionRequired then
		notify(player, "🧬 You need " .. Config.FusionRequired .. "x " .. Config.DisplayName(def, mutation) .. " to fuse!", "Error")
		sound(player, "Error", 1)
		return
	end
	-- remove three (from the back so indices stay valid)
	for n = 1, Config.FusionRequired do
		table.remove(profile.Displayed, indices[#indices])
		table.remove(indices)
	end
	local candidates = {}
	for _, candidate in ipairs(Config.Brainrots) do
		if candidate.Rarity == def.Rarity + 1 then
			candidates[#candidates + 1] = candidate
		end
	end
	local result = candidates[math.random(#candidates)]
	profile.Displayed[#profile.Displayed + 1] = { Name = result.Name, Mutation = mutation }
	profile.Stats.Fused += 1
	ctx.Bases.RenderDisplayed(base)
	notify(player, "🧬 FUSION! Your brainrots became a " .. Config.DisplayName(result, mutation) .. "!", "Success")
	sound(player, "Fusion", 1)
	sound(player, "Magic", 1.2)
	ctx.Quests.Refresh(player)
	ctx.Data.PushState(player, ctx)
end

function ShopManager.Rebirth(player)
	local profile = ctx.Data.Profiles[player]
	local base = ctx.Bases.ByPlayer[player]
	if not profile then
		return
	end
	local requirement = Config.RebirthRequirement(profile.Rebirths)
	if profile.TotalEarned < requirement then
		notify(player, "🌟 Rebirth needs $" .. Util.FormatInt(requirement) .. " lifetime earned (you: $" .. Util.FormatInt(profile.TotalEarned) .. ")", "Error")
		sound(player, "Error", 1)
		return
	end
	profile.Rebirths += 1
	profile.Cash = Config.StartCash
	profile.Pads = Config.Upgrades.Pads.Start
	profile.SpeedLvl = 0
	profile.CarryLvl = 0
	profile.LuckLvl = 0
	profile.Zones = { true, false, false }
	profile.Displayed = {}
	if base then
		base.Pending = 0
		ctx.Bases.RenderDisplayed(base)
		ctx.Bases.UpdateShopLabels(base)
	end
	ShopManager.ApplySpeed(player)
	ShopManager.ApplyAura(player)
	ctx.Data.SyncLeaderstats(player)
	notify(player, "🌟 REBIRTH #" .. profile.Rebirths .. "! Income is now x" .. string.format("%.1f", Config.IncomeMultiplier(profile.Rebirths)) .. " forever!", "Success")
	sound(player, "Fanfare", 1)
	sound(player, "Celebrate", 1)
	ctx.Remotes.Event:FireClient(player, "Banner", "🌟 REBIRTH #" .. profile.Rebirths .. "!", "Permanent income x" .. string.format("%.1f", Config.IncomeMultiplier(profile.Rebirths)), Color3.fromRGB(255, 120, 200), 4)
	ctx.Quests.Refresh(player)
	ctx.Data.PushState(player, ctx)
	ctx.Data.SaveProfile(player)
end

function ShopManager.Start(c)
	ctx = c
	for zi = 2, 3 do
		local gate = ctx.World.Gates[zi]
		if gate then
			gate.Prompt.Triggered:Connect(function(player)
				ShopManager.UnlockZone(player, zi)
			end)
		end
	end
end

return ShopManager
