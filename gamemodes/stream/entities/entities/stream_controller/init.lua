include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

util.AddNetworkString("ShowControllerVGUI")

function ENT:OnRemove()
	GAMEMODE:BroadcastStop()
end

function ENT:Use(a)
	-- Only DJs should be able to use the mixer!
	if a:Team() ~= GAMEMODE.TeamDJCrew then return end

	net.Start("ShowControllerVGUI")
	net.WriteEntity(self)
	net.Send(a)
end
