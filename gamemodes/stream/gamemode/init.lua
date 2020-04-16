AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_thirdperson.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

hook.Add("PlayerInitialSpawn", "FullLoadSetup", function(ply)
	hook.Add("SetupMove", ply, function(self, ply, _, cmd)
		if self == ply and not cmd:IsForced() then
			hook.Run("PlayerFullLoad", self)
			hook.Remove("SetupMove", self)
		end
	end )
end )

hook.Add("PlayerFullLoad", "FullLoad", function(p)
	-- Which entity is playing the sound?
	-- Please send ENT ID of the "controlling" controller

	hook.Run("PlayerSetModel", p)
end )

function GM:BroadcastStart()
	self.NowPlaying = true

	for _, v in pairs(player.GetAll()) do
		net.Start("streamstage-start")
		net.Send(v)
	end
end

function GM:BroadcastStop()
	self.NowPlaying = false

	for _, v in pairs(player.GetAll()) do
		net.Start("streamstage-stop")
		net.Send(v)
	end
end

function GM:BroadcastParameters()
	for _, v in pairs(player.GetAll()) do
		net.Start("streamstage-parameters")
		net.WriteUInt(GAMEMODE.Attenuation, GAMEMODE.NetUIntSize)
		net.WriteUInt(GAMEMODE.Emitter:EntIndex(), GAMEMODE.NetUIntSize)
		net.WriteString(GAMEMODE.SoundURL)
		net.WriteString(GAMEMODE.VideoURL)
		net.WriteInt(GAMEMODE.Volume, GAMEMODE.NetUIntSize)
		net.WriteBool(GAMEMODE.NowPlaying)
		net.Send(v)
	end
end

function GM:PlayerSetModel(p)
	-- https://www.youtube.com/watch?v=1_hnTNlYCbw
	p:SetModel("models/player/phoenix.mdl")
end
