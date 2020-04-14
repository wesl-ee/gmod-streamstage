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

		net.Receive("streamstage-start", function() GAMEMODE.BroadcastStart() end)
		net.Receive("streamstage-stop", function() GAMEMODE.BroadcastStop() end)
	else
		-- GM-specific client functions
		net.Receive("streamstage-start", function() GAMEMODE.StartShow() end)
		net.Receive("streamstage-stop", function() GAMEMODE.StopShow() end)
	end

	self.NetUIntSize = 32
	self.FFTType = FFT_256
	self.FFTAveragingWindow = 3
	self.SmoothFFT = { }
	for i = 1, 128 do
		self.SmoothFFT[i] = 0
	end
end

function GM:AttenuatedVolume(sqdist)
	-- Distance parameters
	local MinDistance = 25
	local MaxDistance = (GAMEMODE.Attenuation + 1) * MinDistance

	-- Maximum relative volume w.r.t. gamemode parameters
	local relvol = GAMEMODE.Volume

	-- Linear region
	local maxsqr = MaxDistance ^ 2
	local minsqr = MinDistance ^ 2

	-- No attenuation outside linear region
	if sqdist < minsqr then return relvol end
	if sqdist > maxsqr then return 0 end

	-- Calculate the linear attenuation curve
	local linearatten = sqdist * 1 / (minsqr - maxsqr) + maxsqr / (maxsqr - minsqr)

	-- Adjust the curve to behave parabolically
	local parabolicatten = linearatten * (maxsqr - sqdist) / (maxsqr + sqdist)

	-- Scale to the parameterized volume
	return parabolicatten * relvol
end


net.Receive("streamstage-parameters", function()
	GAMEMODE.Attenuation = net.ReadUInt(GAMEMODE.NetUIntSize)
	GAMEMODE.Emitter = Entity(net.ReadUInt(GAMEMODE.NetUIntSize))
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

