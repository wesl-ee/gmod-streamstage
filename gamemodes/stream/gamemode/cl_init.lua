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
	local basswindow = 2
	local bassavg = 0
	self.FFT = { }
	station:FFT(self.FFT, self.FFTType)
	for i, sample in pairs(self.FFT) do
		local smoothsample = self.SmoothFFT[i]

		-- Rolling average
		self.SmoothFFT[i] = sample/window +
			(window-1)*smoothsample/window

		if i < 10 then
			bassavg = bassavg + sample
		end
	end
	local bassavg = bassavg / 10

	-- Rolling average on top of a rolling average... oh my!
	-- ... just so we don't overdo the effects
	if !self.FFTBassAvg then self.FFTBassAvg = bassavg
	else
		self.FFTBassAvg = bassavg/basswindow +
			(basswindow-1)*self.FFTBassAvg/basswindow
	end

	local mypos = LocalPlayer():GetPos()
	local emitpos = GAMEMODE.Emitter:GetPos()

	-- Sound Attenuation
	local dist = mypos:DistToSqr(emitpos)
	local attenvol = GAMEMODE:AttenuatedVolume(dist) / 100
	station:SetVolume(attenvol)

	-- We use this percentage elsewhere (FOV calculation etc.)
	self.AttenPercent = attenvol

	-- Dynamically pan stereo depending on your bias to the sound source
	-- This would be cool if SetPan() used values other than -1, 0, or 1
	-- So this is unused until then... (maybe forever!)
	-- local vec = (mypos - emitpos);

	-- local eyeangles = LocalPlayer():EyeAngles()

	-- local relangle = eyeangles.y - vec:Angle().y + 180
	-- if relangle < 0 then relangle = relangle + 360 end

	-- local polarity = math.sin(math.rad(relangle))

	-- This would be cool if SetPan() took values other than -1, 0, 1
	-- station:SetPan(0)

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
		self:StartAudio(GAMEMODE.SoundURL)
	end
end

function GM:StartAudio(url)
	sound.PlayURL(url, "", function(s)
		self:StationLoaded(s)
	end )
end

function GM:StopAudio()
	local a = GAMEMODE.AudioChannel
	hook.Remove("AudioTick", "CheckMedia")
	a:Stop()

	GAMEMODE.AudioChannel = nil
end

function GM:StopShow()
	GAMEMODE.NowPlaying = false

	hook.Remove("HUDPaint", "HUDCurrentlyPlaying")

	-- Stop audio
	if GAMEMODE.AudioChannel then
		self:StopAudio()
	end
end

function GM:RestartAudio()
	-- Out with the old...
	if GAMEMODE.AudioChannel then
		self:StopAudio()
	end

	-- ... in with the new
	if GAMEMODE.SoundURL then
		self:StartAudio(GAMEMODE.SoundURL)
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

function GM:RenderScreenspaceEffects()
	if self.NowPlaying and self.AttenPercent && self.Volume > 20 then
		local scale = self.AttenPercent * (self.Volume / 100)
		if scale then
			DrawMotionBlur(0.4, scale*10, 0.015)
		end
		if self.FFTBassAvg then
			DrawBloom(0.4, scale*self.FFTBassAvg*50, 10, 10, 1, 5, 1, 1, 1)
		end
	end
end
