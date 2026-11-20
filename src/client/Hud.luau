-- Hud — always-on HUD: the money bar, carry pips, the side menu and the bottom Upgrade/Lock/Rebirth row.
-- Hud.luau — always-on interface: the money bar (cash, income/s, pending),
-- carry pips, the side menu buttons (Shop / Quest / Sound), the bottom
-- action row (Upgrade / Lock / Rebirth — buttons since Round 10, the
-- base pads for them are gone), the rebirth confirmation dialog,
-- toast notifications, and the big centre banner used by events
-- and rebirths.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))
local UI = require(script.Parent:WaitForChild("UIBuilder"))

local Hud = {}
local ctx
local cashLabel, incomeLabel, pendingLabel, carryLabel
local lockButton
local toastHolder, bannerFrame, bannerTitle, bannerSub
local rebirthBackdrop, rebirthDialog
local deltaLabel
local lastCash = nil
local deltaToken = 0

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

-- Cash delta floater: every time the cash total actually moves, a
-- "+$X" (green, income collected) or "-$X" (red, a purchase) drifts
-- up from under the money bar and fades — gains and spends are felt,
-- not just silently re-totalled.
local function showDelta(delta)
	deltaToken += 1
	local myToken = deltaToken
	deltaLabel.Text = (delta > 0 and "+$" or "-$") .. Util.FormatInt(math.abs(delta))
	deltaLabel.TextColor3 = delta > 0 and Color3.fromRGB(110, 255, 140) or Color3.fromRGB(255, 100, 100)
	deltaLabel.Position = UDim2.new(0.5, -284, 0, 72)
	deltaLabel.TextTransparency = 0
	deltaLabel.TextStrokeTransparency = 0.35
	deltaLabel.Visible = true
	local tween = TweenService:Create(deltaLabel, TweenInfo.new(1.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, -284, 0, 46), TextTransparency = 1, TextStrokeTransparency = 1 })
	tween:Play()
	tween.Completed:Connect(function()
		if deltaToken == myToken then
			deltaLabel.Visible = false
		end
	end)
end

function Hud.Update(state)
	cashLabel.Text = "💰 $" .. Util.FormatInt(state.Cash)
	incomeLabel.Text = "⚡ $" .. Util.FormatCash(state.IncomePerSec) .. "/s"
	pendingLabel.Text = "🏠 $" .. Util.FormatInt(state.Pending) .. " waiting"
	carryLabel.Text = "🎒 " .. state.CarryCount .. "/" .. state.CarryCapacity
	-- the LOCK button mirrors the base lock live: locked (with the
	-- seconds left), recharging (seconds left), or ready
	if lockButton then
		if state.BaseLocked then
			lockButton.Text = "🔒 " .. (state.LockLeft or 0) .. "s"
			lockButton.BackgroundColor3 = Color3.fromRGB(70, 110, 180)
		elseif (state.LockCooldownLeft or 0) > 0 then
			lockButton.Text = "🔓 " .. state.LockCooldownLeft .. "s"
			lockButton.BackgroundColor3 = Color3.fromRGB(90, 96, 120)
		else
			lockButton.Text = "🔓 LOCK"
			lockButton.BackgroundColor3 = Color3.fromRGB(90, 160, 255)
		end
	end
	if lastCash ~= nil and state.Cash ~= lastCash then
		showDelta(state.Cash - lastCash)
	end
	lastCash = state.Cash
end

function Hud.Start(c, gui)
	ctx = c
	-- money bar (Round 9, styled after the user's reference shot):
	-- ONE dark rounded bar with three segments side by side —
	-- money-bag cash in bold green, lightning income/s in bold
	-- yellow, house pending in light blue. Every balance display
	-- in the game reads from this bar; values come straight from
	-- the server state snapshot (Cash / IncomePerSec / Pending).
	local bar = UI.Frame(gui, UDim2.new(0, 600, 0, 54), UDim2.new(0.5, -300, 0, 10), Color3.fromRGB(24, 26, 36), 0.05)
	cashLabel = UI.Label(bar, "💰 $50", UDim2.new(0, 196, 1, 0), UDim2.new(0, 16, 0, 0), { TextSize = 26, Color = Color3.fromRGB(110, 255, 140) })
	incomeLabel = UI.Label(bar, "⚡ $0/s", UDim2.new(0, 168, 1, 0), UDim2.new(0, 224, 0, 0), { TextSize = 20, Color = Color3.fromRGB(255, 200, 60), Align = Enum.TextXAlignment.Center })
	pendingLabel = UI.Label(bar, "🏠 $0 waiting", UDim2.new(0, 180, 1, 0), UDim2.new(0, 404, 0, 0), { TextSize = 18, Color = Color3.fromRGB(170, 215, 255), Align = Enum.TextXAlignment.Right })

	-- cash delta floater (sits just under the money bar's left edge)
	deltaLabel = UI.Label(gui, "", UDim2.new(0, 260, 0, 32), UDim2.new(0.5, -284, 0, 72), { TextSize = 23, Stroke = true })
	deltaLabel.BackgroundTransparency = 1
	deltaLabel.Visible = false

	-- menu buttons (right side): Shop, Quest, Sound. (REBIRTH used
	-- to sit under Quest; since Round 10 it lives in the bottom
	-- action row with UPGRADE and LOCK, per the user's spec.)
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

	-- bottom action row (Round 10, user spec): UPGRADE, LOCK and
	-- REBIRTH as real buttons along the BOTTOM of the screen, NOT
	-- in the side menu — the step-on upgrade buttons, lock pad and
	-- rebirth pad at the base are gone. The mechanisms behind them
	-- are unchanged: UPGRADE opens the shop panel (the same four
	-- tracks, Config prices and server-side BuyUpgrade validation
	-- the pads used), LOCK fires the server's ToggleLock (45 s
	-- lock / 90 s cooldown from Config; Hud.Update shows the live
	-- locked / recharging state on the button), REBIRTH opens the
	-- same confirmation dialog as the old side button and pad.
	local actionRow = Instance.new("Frame")
	actionRow.Name = "ActionRow"
	actionRow.Size = UDim2.new(0, 534, 0, 48)
	actionRow.Position = UDim2.new(0.5, -267, 1, -104)
	actionRow.BackgroundTransparency = 1
	actionRow.Parent = gui
	local rowLayout = Instance.new("UIListLayout")
	rowLayout.FillDirection = Enum.FillDirection.Horizontal
	rowLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	rowLayout.Padding = UDim.new(0, 12)
	rowLayout.Parent = actionRow
	local upgradeBtn = UI.Button(actionRow, "⬆️ UPGRADE", UDim2.new(0, 170, 0, 48), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 170, 40))
	upgradeBtn.TextSize = 19
	lockButton = UI.Button(actionRow, "🔓 LOCK", UDim2.new(0, 170, 0, 48), UDim2.new(0, 0, 0, 0), Color3.fromRGB(90, 160, 255))
	lockButton.TextSize = 19
	local rebirthBtn = UI.Button(actionRow, "🌟 REBIRTH", UDim2.new(0, 170, 0, 48), UDim2.new(0, 0, 0, 0), Color3.fromRGB(255, 120, 160))
	rebirthBtn.TextSize = 19
	upgradeBtn.MouseButton1Click:Connect(function()
		ctx.Audio.PlaySfx("Click", 1)
		ctx.ShopUI.Toggle()
	end)
	lockButton.MouseButton1Click:Connect(function()
		ctx.Audio.PlaySfx("Click", 1)
		ctx.Remotes.Action:FireServer("ToggleLock")
	end)
	rebirthBtn.MouseButton1Click:Connect(function()
		ctx.Audio.PlaySfx("Click", 1)
		Hud.ShowRebirthConfirm()
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

	-- rebirth confirmation dialog (Round 9, user spec; English
	-- wording since Round 10): a dimmed backdrop and a centred
	-- panel asking "Do you want to rebirth? All progress will be
	-- lost" with a "Yes" and a "No" button. Yes fires the server
	-- reset; No (or anything else) simply closes the dialog.
	rebirthBackdrop = Instance.new("Frame")
	rebirthBackdrop.Name = "RebirthBackdrop"
	rebirthBackdrop.Size = UDim2.new(1, 0, 1, 0)
	rebirthBackdrop.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
	rebirthBackdrop.BackgroundTransparency = 0.45
	rebirthBackdrop.BorderSizePixel = 0
	rebirthBackdrop.ZIndex = 8
	rebirthBackdrop.Visible = false
	rebirthBackdrop.Parent = gui
	rebirthDialog = UI.Frame(gui, UDim2.new(0, 470, 0, 226), UDim2.new(0.5, -235, 0.5, -113), Color3.fromRGB(34, 36, 48), 0)
	rebirthDialog.Name = "RebirthDialog"
	rebirthDialog.ZIndex = 9
	rebirthDialog.Visible = false
	UI.Stroke(rebirthDialog, Color3.fromRGB(255, 120, 160), 2)
	local dialogText = UI.Label(rebirthDialog, "Do you want to rebirth? All progress will be lost", UDim2.new(1, -44, 0, 92), UDim2.new(0, 22, 0, 20),
		{ TextSize = 22, Wrapped = true, Align = Enum.TextXAlignment.Center, Stroke = true })
	dialogText.ZIndex = 10
	local yesBtn = UI.Button(rebirthDialog, "Yes", UDim2.new(0, 150, 0, 48), UDim2.new(0.5, -160, 1, -68), Color3.fromRGB(255, 95, 105))
	yesBtn.TextSize = 20
	yesBtn.ZIndex = 10
	local noBtn = UI.Button(rebirthDialog, "No", UDim2.new(0, 150, 0, 48), UDim2.new(0.5, 10, 1, -68), Color3.fromRGB(90, 96, 120))
	noBtn.TextSize = 20
	noBtn.ZIndex = 10
	yesBtn.MouseButton1Click:Connect(function()
		ctx.Audio.PlaySfx("Click", 1)
		Hud.HideRebirthConfirm()
		ctx.ShopUI.Close()
		ctx.Remotes.Action:FireServer("Rebirth")
	end)
	noBtn.MouseButton1Click:Connect(function()
		ctx.Audio.PlaySfx("Click", 1)
		Hud.HideRebirthConfirm()
	end)
end

function Hud.ShowRebirthConfirm()
	rebirthBackdrop.Visible = true
	rebirthDialog.Visible = true
end

function Hud.HideRebirthConfirm()
	rebirthBackdrop.Visible = false
	rebirthDialog.Visible = false
end

return Hud
