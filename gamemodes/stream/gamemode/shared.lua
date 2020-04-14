GM.Name = "Stream Stage"
GM.Author = "Pretty-boy Yumi"
GM.Email = "yumi@prettyboytellem.com"
GM.Website = "https://prettyboytellem.com/"

DeriveGamemode("sandbox")
function GM:Initialize()
	if SERVER then
		util.AddNetworkString("streamstage-start")
		util.AddNetworkString("streamstage-stop")
		util.AddNetworkString("streamstage-parameters")

		net.Receive("streamstage-start", function() GAMEMODE:BroadcastStart() end)
		net.Receive("streamstage-stop", function() GAMEMODE:BroadcastStop() end)
	else
		-- GM-specific client functions
		net.Receive("streamstage-start", GAMEMODE.StartShow)
		net.Receive("streamstage-stop", GAMEMODE.StopShow)
	end

	self.NetUIntSize = 8
end

net.Receive("streamstage-parameters", function()
	GAMEMODE.Attenuation = net.ReadUInt(GAMEMODE.NetUIntSize)
	GAMEMODE.SoundURL = net.ReadString()
	GAMEMODE.VideoURL = net.ReadString()
	GAMEMODE.Volume = net.ReadInt(GAMEMODE.NetUIntSize)
	local shouldPlayNow = net.ReadBool()

	if SERVER then
		GAMEMODE:BroadcastParameters()
	end

	if SERVER && shouldPlayNow then
		GAMEMODE:BroadcastStart()
	elseif !SERVER && shouldPlayNow then
		GAMEMODE:StartShow()
	end
end )

