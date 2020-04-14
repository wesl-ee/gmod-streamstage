AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/squad/sf_plates/sf_plate5x8.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()

	if phys:IsValid() then
		phys:Wake()
	end

	-- Respect SpawnFlags
	if self:HasSpawnFlags(SF_PHYSPROP_MOTIONDISABLED) then
		phys:EnableMotion(false)
	end
end

