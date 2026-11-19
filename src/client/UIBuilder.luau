-- UIBuilder.luau — tiny factory helpers so every client module builds its
-- widgets the same way: rounded corners, soft strokes, Fredoka type.

local UI = {}

function UI.Corner(parent, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
	return c
end

function UI.Stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(20, 20, 28)
	s.Thickness = thickness or 2
	s.Transparency = 0.35
	s.Parent = parent
	return s
end

function UI.Frame(parent, size, position, color, transparency)
	local f = Instance.new("Frame")
	f.Size = size
	f.Position = position
	f.BackgroundColor3 = color or Color3.fromRGB(40, 42, 56)
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel = 0
	f.Parent = parent
	UI.Corner(f, 10)
	return f
end

function UI.Label(parent, text, size, position, options)
	options = options or {}
	local l = Instance.new("TextLabel")
	l.Size = size
	l.Position = position or UDim2.new(0, 0, 0, 0)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = options.Color or Color3.fromRGB(255, 255, 255)
	l.Font = options.Font or Enum.Font.FredokaOne
	l.TextSize = options.TextSize or 18
	l.TextXAlignment = options.Align or Enum.TextXAlignment.Left
	l.TextYAlignment = Enum.TextYAlignment.Center
	l.TextWrapped = options.Wrapped or false
	l.TextStrokeTransparency = options.Stroke and 0.5 or 1
	l.Parent = parent
	return l
end

function UI.Button(parent, text, size, position, color)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = position
	b.BackgroundColor3 = color or Color3.fromRGB(88, 101, 242)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.FredokaOne
	b.TextSize = 17
	b.AutoButtonColor = true
	b.Parent = parent
	UI.Corner(b, 10)
	UI.Stroke(b)
	return b
end

return UI
