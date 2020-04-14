include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

util.AddNetworkString("ShowControllerVGUI")

function ENT:OnRemove()
	GAMEMODE:BroadcastStop()
end

function ENT:Use(a)
	net.Start("ShowControllerVGUI")
	net.WriteEntity(self)
	net.Send(a)
end
