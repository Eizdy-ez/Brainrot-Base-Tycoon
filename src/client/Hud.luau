-- Hud.luau — always-on interface: the money bar (cash, income/s, pending),
-- carry pips, the menu buttons (Shop / Quest / Sound), toast
-- notifications, and the big centre banner used by events and rebirths.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))
local UI = require(script.Parent:WaitForChild("UIBuilder"))

local Hud = {}
local ctx
local cashLabel, incomeLabel, pendingLabel, rebirthLabel, carryLabel
local toastHolder, bannerFrame, bannerTitle, bannerSub

local KIND_COLORS = {
	Success = Color3.fromRGB(64, 220, 110),
	Error = Color3.fromRGB(255, 96, 96),
	Info = Color3.fromRGB(96, 178, 255),
}

function Hud.Toast(text, kind)
	local toast = UI.Frame(toastHolder, UDim2.new(1, 0, 0, 44), UDim2.new(0, 0, 0, 0), Color3.fromRGB(34, 36, 48), 0.08)
	UI.Stroke(toast, KIND_COLORS[kind] or KIND_COLORS.Info, 2)
	UI.Label(toast, text, UDim2.new(1, -16, 1, 0), UDim2.new(0, 8, 0, 0), { TextSize = 15, Wrapped = true })
	toast.Position = UDim2.new(-1.1, 0, 0, 0)
	TweenService:Create(toast, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0, 0, 0, 0) }):Play()
	task.delay(4.2, function()
		if toast.Parent then
			local out = TweenService:Create(toast, TweenInfo.new(0.3), { Position = UDim2.new(-1.1, 0, 0, 0) })
			out:Play()
			out.Completed:Connect(function()
				toast:Destroy()
			end)
		end
	end)
end

local bannerToken = 0
function Hud.Banner(title, sub, color, duration)
	bannerToken += 1
	local myToken = bannerToken
	bannerTitle.Text = title
	bannerSub.Text = sub or ""
	bannerFrame.BackgroundColor3 = color or Color3.fromRGB(46, 44, 66)
	bannerFrame.Visible = true
	bannerFrame.Position = UDim2.new(0.5, 0, -0.2, 0)
	TweenService:Create(bannerFrame, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0.09, 0) }):Play()
	task.delay(duration or 4, function()
		if bannerToken == myToken and bannerFrame.Parent then
			local out = TweenService:Create(bannerFrame, TweenInfo.new(0.35), { Position = UDim2.new(0.5, 0, -0.2, 0) })
			out:Play()
			out.Completed:Connect(function()
				if bannerToken == myToken then
					bannerFrame.Visible = false
				end
			end)
		end
	end)
end

function Hud.Update(state)
	cashLabel.Text = "💰 $" .. Util.FormatInt(state.Cash)
	incomeLabel.Text = "⚡ $" .. Util.FormatCash(state.IncomePerSec) .. "/s"
	pendingLabel.Text = "🏦 $" .. Util.FormatInt(state.Pending) .. " waiting"
	rebirthLabel.Text = state.Rebirths > 0 and ("🌟 x" .. string.format("%.1f", state.IncomeMultiplier)) or ""
	carryLabel.Text = "🎒 " .. state.CarryCount .. "/" .. state.CarryCapacity
end

function Hud.Start(c, gui)
	ctx = c
	-- money bar
	local bar = UI.Frame(gui, UDim2.new(0, 560, 0, 52), UDim2.new(0.5, -280, 0, 10), Color3.fromRGB(34, 36, 48), 0.08)
	cashLabel = UI.Label(bar, "💰 $0", UDim2.new(0, 170, 1, 0), UDim2.new(0, 12, 0, 0), { TextSize = 21, Color = Color3.fromRGB(140, 255, 160) })
	incomeLabel = UI.Label(bar, "⚡ $0/s", UDim2.new(0, 130, 1, 0), UDim2.new(0, 182, 0, 0), { TextSize = 17, Color = Color3.fromRGB(255, 224, 120) })
	pendingLabel = UI.Label(bar, "🏦 $0 waiting", UDim2.new(0, 160, 1, 0), UDim2.new(0, 316, 0, 0), { TextSize = 15, Color = Color3.fromRGB(170, 210, 255) })
	rebirthLabel = UI.Label(bar, "", UDim2.new(0, 70, 1, 0), UDim2.new(0, 480, 0, 0), { TextSize = 17, Color = Color3.fromRGB(255, 150, 210) })

	-- menu buttons (right side)
	local buttons = Instance.new("Frame")
	buttons.Name = "MenuButtons"
	buttons.Size = UDim2.new(0, 118, 0, 142)
	buttons.Position = UDim2.new(1, -128, 0, 74)
	buttons.BackgroundTransparency = 1
	buttons.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.Parent = buttons
	local shopBtn = UI.Button(buttons, "🛒 SHOP", UDim2.new(1, 0, 0, 42), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 150, 60))
	local questBtn = UI.Button(buttons, "📜 QUEST", UDim2.new(1, 0, 0, 42), UDim2.new(0, 0, 0, 0), Color3.fromRGB(64, 160, 255))
	local soundBtn = UI.Button(buttons, "🔊 SOUND", UDim2.new(1, 0, 0, 42), UDim2.new(0, 0, 0, 0), Color3.fromRGB(90, 96, 120))
	shopBtn.MouseButton1Click:Connect(function()
		ctx.Audio.PlaySfx("Click", 1)
		ctx.ShopUI.Toggle()
	end)
	questBtn.MouseButton1Click:Connect(function()
		ctx.Audio.PlaySfx("Click", 1)
		ctx.QuestUI.Toggle()
	end)
	soundBtn.MouseButton1Click:Connect(function()
		local muted = ctx.Audio.ToggleMute()
		soundBtn.Text = muted and "🔇 MUTED" or "🔊 SOUND"
		if not muted then
			ctx.Audio.PlaySfx("Click", 1)
		end
	end)

	-- dash button (bottom right; keyboard players use Shift)
	local dashBtn = UI.Button(gui, "🏃 DASH", UDim2.new(0, 118, 0, 46), UDim2.new(1, -128, 1, -58), Color3.fromRGB(64, 190, 90))
	dashBtn.MouseButton1Click:Connect(function()
		if ctx.RequestDash then
			ctx.RequestDash()
		end
	end)

	-- carry pips (bottom centre)
	local carryFrame = UI.Frame(gui, UDim2.new(0, 130, 0, 40), UDim2.new(0.5, -65, 1, -52), Color3.fromRGB(34, 36, 48), 0.08)
	carryLabel = UI.Label(carryFrame, "🎒 0/1", UDim2.new(1, 0, 1, 0), UDim2.new(0, 0, 0, 0), { TextSize = 19, Align = Enum.TextXAlignment.Center })

	-- toasts (bottom left)
	toastHolder = Instance.new("Frame")
	toastHolder.Name = "Toasts"
	toastHolder.Size = UDim2.new(0, 360, 0, 300)
	toastHolder.Position = UDim2.new(0, 12, 1, -312)
	toastHolder.BackgroundTransparency = 1
	toastHolder.Parent = gui
	local toastLayout = Instance.new("UIListLayout")
	toastLayout.Padding = UDim.new(0, 6)
	toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	toastLayout.Parent = toastHolder

	-- banner (top centre)
	bannerFrame = UI.Frame(gui, UDim2.new(0, 620, 0, 96), UDim2.new(0.5, 0, -0.2, 0), Color3.fromRGB(46, 44, 66), 0.05)
	bannerFrame.AnchorPoint = Vector2.new(0.5, 0)
	bannerFrame.Visible = false
	bannerTitle = UI.Label(bannerFrame, "", UDim2.new(1, -20, 0, 54), UDim2.new(0, 10, 0, 4), { TextSize = 30, Align = Enum.TextXAlignment.Center, Stroke = true })
	bannerSub = UI.Label(bannerFrame, "", UDim2.new(1, -20, 0, 32), UDim2.new(0, 10, 0, 58), { TextSize = 17, Align = Enum.TextXAlignment.Center })
end

return Hud
