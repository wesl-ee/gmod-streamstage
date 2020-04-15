ENT.Type = "anim"
ENT.Base = "base_entity"
ENT.PrintName = "Stream Controller (Mixtrack Pro)"
ENT.Category = "Stream Kit"
ENT.Spawnable = true

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/props/stream_controller.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)

		local phys = self:GetPhysicsObject()

		if phys:IsValid() then
			phys:Wake()
		end

		-- Respect SpawnFlags
		if self:HasSpawnFlags(SF_PHYSPROP_MOTIONDISABLED) then
			phys:EnableMotion(false)
		end

		self:SetUseType(SIMPLE_USE)
	end
end

