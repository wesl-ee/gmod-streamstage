include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

util.AddNetworkString("ShowControllerVGUI")
util.AddNetworkString("StartMusicStream")

net.Receive("StartMusicStream", function(a)
	url = net.ReadString()
	master = MasterController()
	if url != "" then
		print("Start the music!")
		print(url)
		master:PlayAll(url)
	else
		print("Stop the music!")
		master:StopAll()
	end
end )

function ENT:PlayAll(url)
	for k, v in pairs(AllSpeakers()) do
		v:StartStream(url)
	end
end

function ENT:StopAll()
	all = AllSpeakers()
	for k, v in pairs(AllSpeakers()) do
		v:StopStream()
	end
end

function ENT:Use(a)
	master = ents.FindByClass("stream_visualizer")[1]
	net.Start("ShowControllerVGUI")
	net.WriteEntity(self)

	if !master then
		net.WriteUInt(self.NETCODE.VGUI_NO_OUTPUTS,
			self.NETINTLEN)
	elseif !master:GetNowPlaying() then
		net.WriteUInt(self.NETCODE.VGUI_NOT_PLAYING,
			self.NETINTLEN)
	else
		net.WriteUInt(self.NETCODE.VGUI_NOW_PLAYING,
			self.NETINTLEN)
	end

	net.Send(a)
end
