include("shared.lua")
include("cl_thirdperson.lua")

hook.Add("HUDShouldDraw", "HideHUD", function(name)
	if GAMEMODE.HideHUD[name] then return false end
end )

function GM:AudioTick(station)
	-- Guard against bad access
	if !IsValid(station) then return end

	if station:GetState() == GMOD_CHANNEL_BUFFERING then
		print("Bufffffffffffferrrrrrrring...")
		return
	end

	-- Compute the FFT
	local window = self.FFTAveragingWindow || 3
	self.FFT = { }
	station:FFT(self.FFT, self.FFTType)
	for i, sample in pairs(self.FFT) do
		local smoothsample = self.SmoothFFT[i]

		-- Rolling average
		self.SmoothFFT[i] = sample/window +
			(window-1)*smoothsample/(window)
	end

	-- Sound Attenuation
	local dist = LocalPlayer():GetPos():DistToSqr(
		GAMEMODE.Emitter:GetPos())
	local attenvol = GAMEMODE:AttenuatedVolume(dist)
	station:SetVolume(attenvol/100)
end

function GM:StationLoaded(station)
	if !IsValid(station) then
		LocalPlayer():ChatPrint("Invalid Stream URL!")
	end

	GAMEMODE.AudioChannel = station
	station:SetVolume(GAMEMODE.Volume/100)

	station:SetPos(GAMEMODE.Emitter:GetPos())

	local slowdown = 0
	hook.Add("Tick", "AudioTick", function()
		GAMEMODE:AudioTick(station)
	end )

	hook.Add("HUDPaint", "HUDCurrentlyPlaying", function()
		local padding = 20
		local maxw = 350
		local lineheight = 10

		local artist
		local title
		local tags = station:GetTagsOGG() || station:GetTagsID3()
		if tags then for _, v in pairs(tags) do
			local sep = v:find("=")
			local key = v:sub(0, sep-1):lower()
			local value = v:sub(sep+1)

			if key == "artist" then artist = value end
			if key == "title" then title = value end
		end end

		surface.SetFont("CloseCaption_Normal")
		surface.SetTextColor(255, 255, 0)

		if artist then
			surface.SetTextPos(ScrW() - maxw - padding,
				ScrH() - padding - 20 - (20+lineheight)*2)
			surface.DrawText("Artist: "..artist)
		end

		if title then
			surface.SetTextPos(ScrW() - maxw - padding,
				ScrH() - padding - 20 - (20+lineheight))
			surface.DrawText("Title: "..title)
		end
	end )
end

function GM:StartShow()
	-- Do not start if we're already started
	if GAMEMODE.NowPlaying then return end

	GAMEMODE.NowPlaying = true

	-- Process audio for client
	if GAMEMODE.SoundURL then
		sound.PlayURL(GAMEMODE.SoundURL, "", function(s)
			GAMEMODE:StationLoaded(s)
		end )
	end

	-- Show HTML derma panel
	if GAMEMODE.VideoURL and GAMEMODE.VideoURL ~= "" then
		GAMEMODE.VideoPanel = vgui.Create("DFrame")
		local v = GAMEMODE.VideoPanel
		v:SetPos(ScrW() - 426 - 10, 10)
		v:SetSize(426, 260)
		v:SetTitle("LIVE FEED")
		v.btnMinim:SetVisible(false)
		v.btnMaxim:SetVisible(false)
		v:ShowCloseButton(false)

		local html = vgui.Create("HTML", v)
		html:SetSize(426, 240)
		html:SetPos(0, 20)
		html:OpenURL(GAMEMODE.VideoURL)
	end
end

function GM:StopShow()
	GAMEMODE.NowPlaying = false

	hook.Remove("HUDPaint", "HUDCurrentlyPlaying")

	-- Stop audio
	if GAMEMODE.AudioChannel then
		local a = GAMEMODE.AudioChannel
		hook.Remove("AudioTick", "CheckMedia")
		a:Stop()

		GAMEMODE.AudioChannel = nil
	end

	-- Stop video
	if GAMEMODE.VideoPanel then
		local v = GAMEMODE.VideoPanel
		v:Close()

		GAMEMODE.VideoPanel = nil
	end
end

hook.Add("OnPlayerChat", "WeirdCmds", function(p, txt)
	if p:Team() ~= GAMEMODE.TeamCreator then return end
	local cmd = string.lower(txt)
	if string.sub(cmd, 1, 1) ~= "/" then return end
	cmd = string.sub(cmd, 2)

	if cmd == "partystarted" then
		if !GAMEMODE.NameThing then
			LocalPlayer():ChatPrint("Hey, let's get this party started!")
			GAMEMODE.NameThing = true
		else
			GAMEMODE.NameThing = false
		end

		return true
	end
end )
