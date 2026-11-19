-- Effects.luau — client juice: camera shake when the wave hits you, the
-- floating "+$" burst over the collect pad, dash FOV kick, and locally
-- hiding the gate barriers of zones you personally unlocked.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Util = require(Shared:WaitForChild("Util"))

local Effects = {}
local shakePower = 0
local fovBusy = false

function Effects.Shake(intensity)
	shakePower = math.max(shakePower, intensity or 0.5)
end

function Effects.DashFov()
	local camera = Workspace.CurrentCamera
	if not camera or fovBusy then
		return
	end
	fovBusy = true
	local up = TweenService:Create(camera, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = 82 })
	up:Play()
	up.Completed:Connect(function()
		local down = TweenService:Create(camera, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = 70 })
		down:Play()
		down.Completed:Connect(function()
			fovBusy = false
		end)
	end)
end

function Effects.CollectBurst(amount, worldPos)
	local anchor = Instance.new("Part")
	anchor.Name = "CollectFx"
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(worldPos + Vector3.new(0, 3.5, 0))
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Parent = Workspace
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, 60)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "+$" .. Util.FormatInt(amount)
	label.TextColor3 = Color3.fromRGB(140, 255, 160)
	label.TextStrokeTransparency = 0.25
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 34
	label.Parent = gui
	gui.Parent = anchor
	task.spawn(function()
		local start = os.clock()
		while os.clock() - start < 1.25 do
			local t = (os.clock() - start) / 1.25
			anchor.CFrame = CFrame.new(worldPos + Vector3.new(0, 3.5 + t * 3.5, 0))
			label.TextTransparency = t
			label.TextStrokeTransparency = 0.25 + t * 0.75
			task.wait()
		end
		anchor:Destroy()
	end)
end

local ownBaseSlot = 0

-- Barriers and base doors are shared parts; adjusting them is per-client
-- only. Zone barriers you unlocked fade out, and your own base's gate
-- door never blocks you (it stays solid for everyone else while locked).
function Effects.GateCheck(state)
	ownBaseSlot = state.BaseSlot or 0
	local worldRoot = Workspace:FindFirstChild("BrainrotWorld")
	if not worldRoot then
		return
	end
	for zi = 2, 3 do
		local gate = worldRoot:FindFirstChild("Gate" .. zi)
		local barrier = gate and gate:FindFirstChild("Barrier")
		if barrier then
			barrier.Transparency = state.Zones[zi] and 1 or 0.45
		end
	end
	Effects.PassOwnDoor()
end

function Effects.PassOwnDoor()
	if ownBaseSlot <= 0 then
		return
	end
	local worldRoot = Workspace:FindFirstChild("BrainrotWorld")
	local baseModel = worldRoot and worldRoot:FindFirstChild("Base" .. ownBaseSlot)
	local door = baseModel and baseModel:FindFirstChild("GateDoor")
	if door then
		door.CanCollide = false
	end
end

function Effects.Start(ctx)
	-- the server re-solidifies a locked door for everyone; keep clearing
	-- it locally for the owner so a replication update can never trap
	-- them inside (or outside) their own base
	task.spawn(function()
		while true do
			task.wait(0.4)
			Effects.PassOwnDoor()
		end
	end)
	RunService.RenderStepped:Connect(function(dt)
		if shakePower > 0.003 then
			local camera = Workspace.CurrentCamera
			if camera then
				local p = shakePower
				camera.CFrame = camera.CFrame
					* CFrame.new((math.random() - 0.5) * p, (math.random() - 0.5) * p, 0)
					* CFrame.Angles((math.random() - 0.5) * p * 0.06, (math.random() - 0.5) * p * 0.06, (math.random() - 0.5) * p * 0.04)
			end
			shakePower *= math.exp(-5.5 * dt)
		end
	end)
end

return Effects
