include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

util.AddNetworkString("ShowControllerVGUI")

function ENT:OnRemove()
	GAMEMODE:BroadcastStop()
end

function ENT:Use(a)
	-- What did he mean by this?
	if !a:IsPlayer() then return end

	-- We have a cooler menu in the VRMod quick menu
	if vrmod and vrmod.IsPlayerInVR(a) then return end

	-- Only priviliged users should use the mixer!
	if !GAMEMODE:CheckYourPriv(a) then return end

	net.Start("ShowControllerVGUI")
	net.WriteEntity(self)
	net.Send(a)
end
