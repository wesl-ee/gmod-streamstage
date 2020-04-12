AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local medialib = include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/squad/sf_plates/sf_plate5x8.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()

	if phys:IsValid() then
		phys:Wake()
	end

	self:SetUseType(SIMPLE_USE)

	hook.Add("PlayerSay", "AdminStreamCmds", function(p, txt)
		-- These are admin commands!
		if not (p:IsAdmin() or p:IsSuperAdmin()) then
			return
		end

		-- /loadstream [URL]
		-- Loads and plays a stream to all spawned visualizers
		if (string.sub(string.lower(txt), 1, 11) == "/loadstream") then
			local url = string.sub(txt, 13)
			self:StartStream(url)
			ChatPrintAll(p:Nick().." is starting the music stream!")
			return ""
		end

		-- /stopstream
		-- Stops all visualizers
		if (string.sub(string.lower(txt), 1, 11) == "/stopstream") then
			self:StopStream()
			ChatPrintAll(p:Nick().." stopped the stream!")
			return ""
		end
	end )
end



function ENT:SetupDataTables()
	-- Precache client strings
	util.AddNetworkString("start-stream")
	util.AddNetworkString("stop-stream")

	-- Network variables
	self:NetworkVar("Bool", 0, "NowPlaying")
	self:NetworkVar("String", 0, "URL")
	self:SetNowPlaying(false)
end

function ENT:StartStream(url)
	-- Cvars
	local streamurl = cvars.String("stream_url", url)
	local vol = cvars.Number("stream_volume", 0.85)

	-- Broadcast start of stream
	net.Start("start-stream")
	net.WriteString(streamurl)
	net.WriteDouble(vol)
	net.Send(player.GetAll())

	-- Network vars
	self:SetURL(url)
	self:SetNowPlaying(true)
end

function ENT:StopStream()
	net.Start("stop-stream")
	net.Send(player.GetAll())
	self:SetNowPlaying(false)
end

-- Tell all players (from the server)
function ChatPrintAll(msg)
	for k, p in pairs(player.GetAll()) do
		p:ChatPrint(msg)
	end
end
