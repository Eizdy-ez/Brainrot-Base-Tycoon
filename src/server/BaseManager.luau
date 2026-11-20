-- BaseManager.luau — owns the eight base plots: assignment, rendering the
-- displayed brainrots from profile data, pad touch routing (collect —
-- the only pad left since Round 10 moved upgrades, the base lock and
-- rebirth onto the HUD's bottom buttons), the base lock itself, and
-- the locked-zone guard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))

local BaseManager = {}
BaseManager.List = {}     -- [slot] = base (from WorldBuilder)
BaseManager.ByPlayer = {} -- [player] = base

local ctx
local touchDebounce = {} -- [part][player] = time

local function debounced(partInst, player, seconds)
	local now = os.clock()
	touchDebounce[partInst] = touchDebounce[partInst] or {}
	local last = touchDebounce[partInst][player] or 0
	if now - last < seconds then
		return true
	end
	touchDebounce[partInst][player] = now
	return false
end

local function playerFromHit(hit)
	local character = hit and hit.Parent
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

function BaseManager.GetBase(player)
	return BaseManager.ByPlayer[player]
end

-- (Re)build the displayed brainrot models so they match profile.Displayed.
function BaseManager.RenderDisplayed(base)
	local profile = ctx.Data.Profiles[base.Owner]
	for i, pad in ipairs(base.Pads) do
		if pad.Model then
			pad.Model:Destroy()
			pad.Model = nil
		end
		-- pad top dim when the slot is not yet bought
		if profile and i <= profile.Pads then
			pad.Part.Material = Enum.Material.SmoothPlastic
			pad.Part.Transparency = 0
		else
			pad.Part.Material = Enum.Material.SmoothPlastic
			pad.Part.Transparency = 0.45
		end
	end
	if not profile then
		return
	end
	for i, entry in ipairs(profile.Displayed) do
		if i > #base.Pads then
			break
		end
		local def = Config.BrainrotByName[entry.Name]
		if def then
			local model = ctx.Factory.Build(def, entry.Mutation)
			model:SetAttribute("Kind", "Displayed")
			local anchor = base.Pads[i].Anchor
			-- feet rest on the pad: the factory's FootDrop below the
			-- body centre, with a hair of sink so they sit ON the pad
			local footDrop = model:GetAttribute("FootDrop") or (model.PrimaryPart.Size.Y / 2 + 0.35)
			model.PrimaryPart.CFrame = CFrame.new(anchor.X, anchor.Y + footDrop - 0.05, anchor.Z)
			model.Parent = game.Workspace
			base.Pads[i].Model = model
			-- stealing: another player touching it takes it (unless locked)
			model.PrimaryPart.Touched:Connect(function(hit)
				local thief = playerFromHit(hit)
				if thief and thief ~= base.Owner and base.Owner then
					ctx.Carry.TrySteal(thief, base, i)
				end
			end)
		end
	end
end

function BaseManager.Assign(player)
	for slot = 1, #BaseManager.List do
		local base = BaseManager.List[slot]
		if not base.Owner then
			base.Owner = player
			base.Pending = 0
			base.Locked = false
			BaseManager.UpdateGate(base)
			BaseManager.ByPlayer[player] = base
			base.SignLabel.Text = "🏠 " .. player.DisplayName:upper() .. "'S BASE"
			BaseManager.RenderDisplayed(base)
			return base
		end
	end
	return nil
end

function BaseManager.Release(player)
	local base = BaseManager.ByPlayer[player]
	if not base then
		return
	end
	for _, pad in ipairs(base.Pads) do
		if pad.Model then
			pad.Model:Destroy()
			pad.Model = nil
		end
	end
	base.Owner = nil
	base.Pending = 0
	base.Locked = false
	BaseManager.UpdateGate(base)
	base.SignLabel.Text = "EMPTY BASE"
	BaseManager.ByPlayer[player] = nil
end

function BaseManager.TeleportToBase(player)
	local base = BaseManager.ByPlayer[player]
	local character = player.Character
	if not (base and character) then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		local front = base.Center + Vector3.new(base.Center.X > 0 and -16 or 16, 4, 0)
		hrp.CFrame = CFrame.lookAt(front, Vector3.new(0, 4, base.Center.Z))
	end
end

local function wireBase(base)
	base.CollectPad.Touched:Connect(function(hit)
		local player = playerFromHit(hit)
		if player and player == base.Owner and not debounced(base.CollectPad, player, 0.8) then
			ctx.Economy.Collect(base)
		end
	end)
	-- (Lock, rebirth and upgrade pads are gone since Round 10:
	-- the HUD's bottom-row LOCK / REBIRTH / UPGRADE buttons drive
	-- the same server functions — ToggleLock below, the rebirth
	-- confirmation dialog, ShopManager.BuyUpgrade.)
end

-- The gate door mirrors the lock: while the base is locked the door is
-- solid and clearly shut for everyone else; otherwise it ghosts open and
-- anyone may walk in (stealing rules unchanged). The owner always passes
-- their own door — Effects clears its collision on the owner's client.
function BaseManager.UpdateGate(base)
	local door = base.GateDoor
	if not door then
		return
	end
	if base.Locked then
		door.CanCollide = true
		door.Transparency = 0.3
	else
		door.CanCollide = false
		door.Transparency = 0.85
	end
end

function BaseManager.ToggleLock(base)
	local now = os.clock()
	local player = base.Owner
	if not player then
		return
	end
	if base.Locked then
		ctx.Remotes.Event:FireClient(player, "Notify", "🔒 Base locked for " .. math.ceil(base.LockUntil - now) .. " more seconds", "Info")
		return
	end
	if now < base.LockReadyAt then
		ctx.Remotes.Event:FireClient(player, "Notify", "Lock recharging… " .. math.ceil(base.LockReadyAt - now) .. "s", "Error")
		ctx.Remotes.Event:FireClient(player, "PlaySound", "Error", 1)
		return
	end
	base.Locked = true
	base.LockUntil = now + Config.BaseLockTime
	base.LockReadyAt = now + Config.BaseLockCooldown
	BaseManager.UpdateGate(base)
	-- push a snapshot so the owner's client re-clears its own door pass
	ctx.Data.PushState(player, ctx)
	ctx.Remotes.Event:FireClient(player, "Notify", "🔒 Your base is locked for " .. Config.BaseLockTime .. "s — brainrots are safe!", "Success")
	ctx.Remotes.Event:FireClient(player, "PlaySound", "Buy", 1.1)
end

function BaseManager.Start(c)
	ctx = c
	BaseManager.List = ctx.World.Bases
	for _, base in ipairs(BaseManager.List) do
		wireBase(base)
		BaseManager.UpdateGate(base)
	end

	-- displayed brainrots slowly spin in place (vertical bob kept to a
	-- breath — 0.05 studs — so nothing reads as bouncing)
	task.spawn(function()
		while true do
			task.wait(0.12)
			local t = os.clock()
			for _, base in ipairs(BaseManager.List) do
				for i, pad in ipairs(base.Pads) do
					if pad.Model and pad.Model.PrimaryPart then
						local a = pad.Anchor
						local footDrop = pad.Model:GetAttribute("FootDrop") or (pad.Model.PrimaryPart.Size.Y / 2 + 0.35)
						pad.Model.PrimaryPart.CFrame = CFrame.new(a.X, a.Y + footDrop - 0.05 + math.sin(t * 1.6 + i * 1.3) * 0.05, a.Z)
							* CFrame.Angles(0, t * 0.7 + i, 0)
						ctx.Factory.Pose(pad.Model, "Idle", t)
					end
				end
			end
		end
	end)

	-- lock expiry + the HUD LOCK button's live countdown: while a
	-- base is locked (or its lock is still recharging) the owner
	-- gets a fresh snapshot every second so the button can tick
	-- (the state carries BaseLocked / LockLeft / LockCooldownLeft)
	task.spawn(function()
		while true do
			task.wait(1)
			local now = os.clock()
			for _, base in ipairs(BaseManager.List) do
				if base.Locked and now >= base.LockUntil then
					base.Locked = false
					BaseManager.UpdateGate(base)
					if base.Owner then
						ctx.Remotes.Event:FireClient(base.Owner, "Notify", "🔓 Your base lock expired!", "Error")
						ctx.Data.PushState(base.Owner, ctx)
					end
				elseif base.Owner and (base.Locked or now < base.LockReadyAt) then
					ctx.Data.PushState(base.Owner, ctx)
				end
			end
		end
	end)

	-- locked-zone guard: bounce players out of zones they have not unlocked
	local guardNotifyAt = {}
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in ipairs(Players:GetPlayers()) do
				local profile = ctx.Data.Profiles[player]
				local character = player.Character
				local hrp = character and character:FindFirstChild("HumanoidRootPart")
				if profile and hrp then
					for zi = 2, 3 do
						local zone = Config.Zones[zi]
						if not profile.Zones[zi] then
							local dx = math.abs(hrp.Position.X - zone.Center.X)
							local dz = math.abs(hrp.Position.Z - zone.Center.Z)
							if dx < zone.Size.X / 2 + 6 and dz < zone.Size.Y / 2 + 6 then
								local gate = ctx.World.Gates[zi]
								hrp.CFrame = CFrame.new(0, 3, gate.Z + 12)
								if (guardNotifyAt[player] or 0) < os.clock() - 5 then
									guardNotifyAt[player] = os.clock()
									ctx.Remotes.Event:FireClient(player, "Notify", "🔒 " .. zone.Name .. " is locked — unlock it at the gate for $" .. Util.FormatInt(zone.Price), "Error")
									ctx.Remotes.Event:FireClient(player, "PlaySound", "Error", 1)
								end
							end
						end
					end
				end
			end
		end
	end)
end

return BaseManager
