include("shared.lua")

-- Client-side globals for sound synchronization
CL_VISUALIZERS = CL_VISUALIZERS or {}

-- Global
local smoothdata = {}
for i = 1, 128 do
	smoothdata[i] = 0
end

function ENT:Draw()
	-- Constant parameters for drawing visualizer
	local VIS_HEIGHT = 600
	local VIS_WIDTH = 960
	local BAR_WIDTH = 8
	local FFT_TYPE = FFT_256
	local PLOT_TO = 120
	local PLOT_FROM = 1
	local SMOOTHING_FACTOR = 2 * FrameTime()

	-- Of course...
	self:DrawModel()

	-- Don't attempt to draw visualizers when there
	-- is no sound being output
	local schannel = self:GetVar("SoundChannel")
	if not schannel then
		return
	end

	if schannel:GetState() ~= GMOD_CHANNEL_PLAYING then
		-- Because Draw() is called often skip this most of the time
		if schannel:GetState() == GMOD_CHANNEL_BUFFERING then
			-- Pause all speakers if / while we are buffering over the network
			for k, v in pairs(CL_VISUALIZERS) do
				if v ~= self then
					v:GetVar("SoundChannel"):Pause()
				end
			end
			return
		end

		-- Ready to resume playing when all devices are paused
		local allpaused = true
		for k, v in pairs(CL_VISUALIZERS) do
			local sc = v:GetVar("SoundChannel")
			if not sc or sc:GetState() ~= GMOD_CHANNEL_PAUSED then
				allpaused = false
				break
			end
		end
		if not allpaused then return end

		-- Play when we're ready
		for _, v in pairs(CL_VISUALIZERS) do
			v:GetVar("SoundChannel"):Play()
		end
	end

	-- Actual FFT computation
	local master = CL_VISUALIZERS[1]
	if self == master then
		-- Only compute the FFT once
		local media = self:GetVar("SoundChannel")
		if not IsValid(media) then
			return
		end
		self.FFT = {}
		media:FFT(self.FFT, FFT_TYPE)
	end

	-- Visualizer drawbox
	local ang = self:GetAngles()
	local screenvect = Vector(0, 60, 2)

	-- Data to plot
	local data = master.FFT
	if not data then
		-- Guard against wonky accesses
		return
	end

	-- Data is ready, now we can draw on the model
	cam.Start3D2D(self:LocalToWorld(screenvect), ang, 0.1)

	-- (Orange) rectangle for visualizer BG
	surface.SetDrawColor(255, 140, 0)
	surface.DrawRect(0, 0, VIS_WIDTH, VIS_HEIGHT)

	-- FG visualizer color is black
	surface.SetDrawColor(0, 0, 0)

	-- Normalize based on peak value
	local AMP = VIS_HEIGHT
	local maxamp = math.log(math.max(unpack(smoothdata))*AMP+1)
	for i = PLOT_FROM, PLOT_TO do
		if self == master then
			if data[i] then
				smoothdata[i] = Lerp(SMOOTHING_FACTOR, smoothdata[i], data[i])
			end
		end

		local relval
		if not smoothdata[i] then
			-- Error guard
			relval = 0
		else
			relval = (math.log(smoothdata[i] * AMP + 1)) / maxamp
		end

		-- Prevent visualizer bleeding beyond height
		local drawx = VIS_WIDTH - i * BAR_WIDTH
		local drawheight = relval * AMP
		if drawheight > VIS_HEIGHT then drawheight = VIS_HEIGHT end

		-- Actually draw
		surface.DrawRect(drawx, 0, BAR_WIDTH + 1, relval*AMP)
	end

	cam.End3D2D()
end

function ENT:Initialize()
	self:SetVar("visIndex", table.insert(CL_VISUALIZERS, self))
end

function ReloadStream(streamurl, vol)
	for k, v in pairs(CL_VISUALIZERS) do
		-- Restart existing players
		if v:GetVar("SoundChannel") then
			v:GetVar("SoundChannel"):Stop()
		end

		-- Renew the SoundChannel for each device
		sound.PlayURL(streamurl, "3d", function(media)
			-- EQ Params
			media:Set3DFadeDistance(500, 100000)
			media:SetVolume(vol)

			-- Start paused
			v:SetVar("SoundChannel", media)
			media:Pause()
		end )
	end

end

net.Receive("start-stream", function(len, pl)
	-- Grab parameters and start streaming
	local streamurl = net.ReadString()
	local vol = net.ReadDouble()
	ReloadStream(streamurl, vol)

	-- Update all radios if / when moved
	hook.Add("Think", "UpdatePos", function()
		for k, v in pairs(CL_VISUALIZERS) do
			local media = v:GetVar("SoundChannel")
			if IsValid(media) then
				media:SetPos(v:GetPos())
			end
		end
	end )
end )

net.Receive("stop-stream", function(len, pl)
	-- Remove the hook established in the start-stream
	hook.Remove("UpdatePos")

	-- Stop all streams
	for k, v in pairs(CL_VISUALIZERS) do
		if v:GetVar("SoundChannel") then
			v:GetVar("SoundChannel"):Stop()

			-- Just to remind us! Stop() invalidates the SoundChannel
			v:SetVar("SoundChannel", nil)
		end
	end
end )

function ENT:OnRemove()
	local media = self:GetVar("SoundChannel")
	local index = self:GetVar("visIndex")
	RemoveVisualizer(index)

	-- Stop / invalidate if playing
	if media then media:Stop() end
end

function RemoveVisualizer(i)
	table.remove(CL_VISUALIZERS, i)

	-- Update index (for O(1) access to CL_VISUALIZERS)
	for k, v in pairs(CL_VISUALIZERS) do
		v:SetVar("visIndex", k)
	end
end
