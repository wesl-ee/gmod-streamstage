GM.Name = "Stream Stage"
GM.Author = "Pretty-boy Yumi"
GM.Email = "yumi@prettyboytellem.com"
GM.Website = "https://prettyboytellem.com/"

DeriveGamemode("base")

function GM:PlayerSpawn(pl)
	pl:SetMaxSpeed(self.MaxSpeed)
	pl:SetWalkSpeed(self.WalkSpeed)
	pl:SetRunSpeed(self.RunSpeed)
	pl:SetJumpPower(self.JumpPower)

	hook.Run("PlayerSetModel", pl)
end

function GM:Initialize()
	if SERVER then
		util.AddNetworkString("streamstage-start")
		util.AddNetworkString("streamstage-stop")
		util.AddNetworkString("streamstage-parameters")

		net.Receive("streamstage-start", function() GAMEMODE:BroadcastStart() end)
		net.Receive("streamstage-stop", function() GAMEMODE:BroadcastStop() end)

	else
		-- GM-specific client functions
		net.Receive("streamstage-start", function() GAMEMODE:StartShow() end)
		net.Receive("streamstage-stop", function() GAMEMODE:StopShow() end)

		self.HideHUD = { ["CHudHealth"] = true,
			["CHudCrosshair"] = true }
	end

	-- Relative constants
	self.TeamAudience = 1
	self.TeamDJCrew = 2
	self.TeamAdmin = 3
	self.TeamCreator = 4

	-- Movement speed parameters
	self.MaxSpeed = 300
	self.WalkSpeed = 100
	self.RunSpeed = 175
	self.JumpPower = 150

	self.NetUIntSize = 32
	self.FFTType = FFT_16384
	self.FFTAveragingWindow = 3
	self.SmoothFFT = { }
	for i = 1, 128 do
		self.SmoothFFT[i] = 0
	end

	-- Audience, DJs, admins are separate "teams"
	team.SetUp(self.TeamAudience, "Audience", Color(255, 255, 255))
	team.SetUp(self.TeamDJCrew, "DJ", Color(255, 165, 255), false)
	team.SetUp(self.TeamAdmin, "Admin", Color(255, 0, 0), false)
	team.SetUp(self.TeamCreator, "Creator", Color(255, 100, 0), false)

	-- ConVars
	if CLIENT then
		CreateConVar("stream_forcefirstperson", "false", FCVAR_USERINFO,
			"Force First Person")
	end

	if SERVER then
		CreateConVar("stream_url", "http://stream.djr3.org:8000/Club-Howler-Set.ogg", FCVAR_NONE,
			"Music Stream URL")
		CreateConVar("stream_autoplay", 0, FCVAR_NONE,
			 "Autoplay Music Stream?")

		GAMEMODE.SoundURL = GetConVar("stream_url"):GetString()
		GAMEMODE.Volume = 50
		GAMEMODE.Attenuation = 60
		GAMEMODE.NowPlaying = GetConVar("stream_autoplay"):GetBool()
	end

end

function GM:AttenuatedVolume(sqdist)
	-- Distance parameters
	local MinDistance = 25
	local MaxDistance = (GAMEMODE.Attenuation + 1) * MinDistance

	-- Maximum relative volume w.r.t. gamemode parameters
	local relvol = GAMEMODE.Volume

	-- Linear region
	local maxsqr = MaxDistance ^ 2
	local minsqr = MinDistance ^ 2

	-- No attenuation outside linear region
	if sqdist < minsqr then return relvol end
	if sqdist > maxsqr then return 0 end

	-- Calculate the linear attenuation curve
	local linearatten = sqdist * 1 / (minsqr - maxsqr) + maxsqr / (maxsqr - minsqr)

	-- Adjust the curve to behave parabolically
	local parabolicatten = linearatten * (maxsqr - sqdist) / (maxsqr + sqdist)

	-- Scale to the parameterized volume
	return parabolicatten * relvol
end


net.Receive("streamstage-parameters", function(len, p)
	-- Trash goes in the trash bin
	-- if !IsValid(p) then return end

	-- Server only accepts messages from priviliged users...
	if SERVER and IsValid(p) and !GAMEMODE:CheckYourPriv(p) then return end
	-- ...and clients only accept messages from the server
	if CLIENT and IsValid(p) then return end

	-- Read parameters from the RPC
	local attenuation = net.ReadUInt(GAMEMODE.NetUIntSize)
	local emitter = net.ReadUInt(GAMEMODE.NetUIntSize)
	local soundurl = net.ReadString()
	local volume = net.ReadInt(GAMEMODE.NetUIntSize)
	local shouldPlayNow = net.ReadBool()

	-- Should we update our existing sources?
	local newSound = GAMEMODE.NowPlaying &&
		GAMEMODE.SoundURL &&
		soundurl ~= GAMEMODE.SoundURL

	-- Update worldwide parameters
	GAMEMODE.Attenuation = attenuation
	GAMEMODE.Emitter = Entity(emitter)
	GAMEMODE.SoundURL = soundurl
	GAMEMODE.Volume = volume

	if SERVER then
		GAMEMODE:BroadcastParameters()
	end

	if CLIENT && newSound then
		GAMEMODE:RestartAudio()
	end

	if SERVER && shouldPlayNow then
		GAMEMODE:BroadcastStart()
	elseif !SERVER && shouldPlayNow then
		GAMEMODE:StartShow()
	end
end )

function GM:ShowTeam(p)
	if not vrmod then return end

	RunConsoleCommand("vrmod")
end

function GM:ShowSpare1(p)
	RunConsoleCommand("outfitter")
end

-- Add some buttons to VRMod quickmenu which help us use the controller from the headset
if CLIENT and vrmod then
	-- if !GAMEMODE:CheckYourPriv(p) then return end

	vrmod.AddInGameMenuItem("Play ▶", 3, 2, function()
		net.Start("streamstage-start")
		net.SendToServer()
	end )
	vrmod.AddInGameMenuItem("Stop ⏹", 3, 3, function()
		net.Start("streamstage-stop")
		net.SendToServer()
	end )
end

-- Only priviliged users can touch that dial!
function GM:CheckYourPriv(p)
	return p:Team() == GAMEMODE.TeamAdmin or
		p:Team() == GAMEMODE.TeamDJCrew or
		p:Team() == GAMEMODE.TeamCreator
end
