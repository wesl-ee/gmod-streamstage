include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

util.AddNetworkString("ShowControllerVGUI")
util.AddNetworkString("StartMusicStream")

net.Receive("StartMusicStream", function(a, p)
	url = net.ReadString()
--	master = MasterController()
--	if url != "" then
--		print("Start the music!")
--		print(url)
--		master:PlayAll(url)
--	else
--		print("Stop the music!")
--		master:StopAll()
--	end
	net.Start("streamstage-start")
	net.Send(p)
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

	net.Send(a)
end