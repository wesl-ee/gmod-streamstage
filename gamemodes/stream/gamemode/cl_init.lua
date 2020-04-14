include( "shared.lua" )

function ConstantAudio(station)
	if !station then
		print("Probably dead!")
		return
	end

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
	hook.Add("Tick", "CheckMedia", function()
		slowdown = slowdown + 1
		if slowdown <= 20 then return end

		ConstantAudio(station)
		slowdown = 0
	end )
end

function GM:StartShow()
	GAMEMODE.NowPlaying = true

	if GAMEMODE.SoundURL then
		sound.PlayURL(GAMEMODE.SoundURL, "", function(s)
			GAMEMODE:StationLoaded(s)
		end )
	end
	if GAMEMODE.VideoURL then
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

	if GAMEMODE.AudioChannel then
		local a = GAMEMODE.AudioChannel
		hook.Remove("Tick", "CheckMedia")
		a:Stop()

		GAMEMODE.AudioChannel = nil
	end

	if GAMEMODE.VideoPanel then
		local v = GAMEMODE.VideoPanel
		v:Close()

		GAMEMODE.VideoPanel = nil
	end
end

