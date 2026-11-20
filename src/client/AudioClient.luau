-- AudioClient — client audio module: the looping soundtrack and every sound effect.
-- Key responsibility: keeps the looping track matched to the current moment and fires every one-shot sound effect.
-- AudioClient.luau — the game's ears: a looping APM soundtrack that follows
-- the action (calm main theme, sparkly gold-rain theme)
-- plus every sound effect, all from the verified ids in Config.Audio.
-- The mute button lives in the HUD; state is kept here.

local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local AudioClient = {}
AudioClient.Muted = false

local sounds = {} -- [name] = Sound template in SoundService
local bgm = nil
local currentTrack = nil
local BGM_VOLUME = 0.32
local SFX_VOLUME = {
	Collect = 0.7, Buy = 0.7, Fanfare = 0.85, Celebrate = 0.7,
	Magic = 0.6, Bandit = 0.6, Pickup = 0.55,
	Place = 0.6, Dash = 0.55, Click = 0.45, Error = 0.5, Thud = 0.6,
}

local TRACKS = { Main = "BgmMain", Gold = "BgmZone" }

function AudioClient.PlayBgm(trackName)
	local configKey = TRACKS[trackName] or "BgmMain"
	if currentTrack == configKey or not bgm then
		return
	end
	currentTrack = configKey
	local fadeOut = TweenService:Create(bgm, TweenInfo.new(0.5), { Volume = 0 })
	fadeOut:Play()
	fadeOut.Completed:Connect(function()
		bgm.SoundId = Config.Audio[configKey]
		bgm:Play()
		if not AudioClient.Muted then
			TweenService:Create(bgm, TweenInfo.new(0.8), { Volume = BGM_VOLUME }):Play()
		end
	end)
end

function AudioClient.PlaySfx(name, pitch)
	if AudioClient.Muted then
		return
	end
	local template = sounds[name]
	if not template then
		return
	end
	local s = template:Clone()
	s.Name = "Sfx_" .. name
	s.PlaybackSpeed = pitch or 1
	if name == "Error" then
		s.PlaybackSpeed = 0.65 -- the beep becomes a proper error buzz
	end
	s.Volume = SFX_VOLUME[name] or 0.55
	s.Parent = SoundService
	s:Play()
	Debris:AddItem(s, (s.TimeLength > 0 and s.TimeLength / s.PlaybackSpeed or 2) + 0.3)
end

function AudioClient.ToggleMute()
	AudioClient.Muted = not AudioClient.Muted
	if bgm then
		bgm.Volume = AudioClient.Muted and 0 or BGM_VOLUME
	end
	return AudioClient.Muted
end

function AudioClient.Start(ctx)
	local folder = Instance.new("Folder")
	folder.Name = "BrainrotSounds"
	folder.Parent = SoundService
	for name, id in pairs(Config.Audio) do
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = id
		s.Volume = 0.5
		s.Parent = folder
		sounds[name] = s
	end
	bgm = Instance.new("Sound")
	bgm.Name = "Bgm"
	bgm.SoundId = Config.Audio.BgmMain
	bgm.Looped = true
	bgm.Volume = BGM_VOLUME
	bgm.Parent = SoundService
	currentTrack = "BgmMain"
	task.delay(0.5, function()
		bgm:Play()
	end)
	-- warm the cache so first plays are not silent (best effort)
	task.spawn(function()
		local ids = {}
		for _, id in pairs(Config.Audio) do
			ids[#ids + 1] = id
		end
		pcall(function()
			ContentProvider:PreloadAsync(ids)
		end)
	end)
end

return AudioClient
