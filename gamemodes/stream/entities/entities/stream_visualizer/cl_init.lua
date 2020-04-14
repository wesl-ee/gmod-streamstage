include("shared.lua")

-- Global
-- local smoothdata = {}
-- for i = 1, 128 do
--	smoothdata[i] = 0
-- end

function ENT:Draw()
	-- Constant parameters for drawing visualizer
	local VIS_HEIGHT = 600
	local VIS_WIDTH = 960
	local BAR_WIDTH = 8
	local PLOT_TO = 120
	local PLOT_FROM = 1
	local SMOOTHING_FACTOR = 2 * FrameTime()

	-- Of course...
	self:DrawModel()

	-- Don't attempt to draw visualizers when there
	-- is no sound being output
	if !GAMEMODE.NowPlaying then return end

	-- Visualizer drawbox
	local ang = self:GetAngles()
	local screenvect = Vector(0, 60, 2)

	-- Data to plot
	local data = GAMEMODE.SmoothFFT
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
	local maxamp = math.log(math.max(unpack(data))*AMP+1)
	for i = PLOT_FROM, PLOT_TO do
		local relval = (math.log(data[i] * AMP + 1) / maxamp)

		-- Prevent visualizer bleeding beyond height
		local drawx = VIS_WIDTH - i * BAR_WIDTH
		local drawheight = relval * AMP
		if drawheight > VIS_HEIGHT then drawheight = VIS_HEIGHT end

		-- Actually draw
		surface.DrawRect(drawx, 0, BAR_WIDTH + 1, relval*AMP)
	end

	cam.End3D2D()
end

