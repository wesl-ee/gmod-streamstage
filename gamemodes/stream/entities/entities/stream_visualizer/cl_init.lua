include("shared.lua")

local ElectricTeal = Color(10, 255, 255)
local Orange = Color(255, 140, 0)
local Black = Color(0, 0, 0)

function ENT:Draw()
	-- Constant parameters for drawing visualizer
	local VIS_HEIGHT = 600
	local VIS_WIDTH = 960
	local BAR_WIDTH = 8
	local PLOT_TO = 120
	local PLOT_FROM = 1

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

	-- (Orange) rectangle for visualizer BG, black for FG
	local bg = Black
	local fg = ElectricTeal

	surface.SetDrawColor(bg.r, bg.g, bg.b)
	surface.DrawRect(0, 0, VIS_WIDTH, VIS_HEIGHT)
	surface.SetDrawColor(fg.r, fg.g, fg.b)

	-- Normalize based on peak value
	local AMP = VIS_HEIGHT
	local maxamp = math.log(math.max(unpack(data))*AMP+1)
	for i = PLOT_FROM, PLOT_TO do
		local relval = (math.log(data[i] * AMP + 1) / maxamp)

		-- Prevent visualizer bleeding beyond height
		local drawx = VIS_WIDTH - i * BAR_WIDTH
		local drawheight = relval * AMP
		if drawheight > VIS_HEIGHT then drawheight = VIS_HEIGHT end
		if drawheight < 0 then drawheight = 0 end

		-- Actually draw
		surface.DrawRect(drawx, 0, BAR_WIDTH + 1, relval*AMP)
	end

	cam.End3D2D()
end

