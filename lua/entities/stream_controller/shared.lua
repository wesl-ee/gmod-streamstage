ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Stream Controller (Mixtrack Pro)"
ENT.Category = "Stream Controller"
ENT.Spawnable = true

function MasterController()
	return ents.FindByClass("stream_controller")[1]
end

function AllSpeakers()
	return ents.FindByClass("stream_visualizer")
end

function ENT:Initialize()
	-- Constants for networking
	self.NETINTLEN = 8
	self.NETCODE = {
		VGUI_NO_OUTPUTS = 1,
		VGUI_NOT_PLAYING = 2,
		VGUI_NOW_PLAYING = 3
	}

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

