function ThirdPerson(ply, pos, angles, fov)
	local view = {}
	local ydist = 80
	local xdist = 30
	local zdist = -20
	local wallavoid = 20
	local trace = {}

	local persp = pos - angles:Forward() * ydist +
		ply:EyeAngles():Right() * xdist +
		Angle(0, 0, ply:EyeAngles().z):Up() * zdist

	trace.start = pos
	trace.endpos = persp
	trace.filter = LocalPlayer()

	local trace = util.TraceLine(trace)
	if trace.HitPos:Distance(pos) - wallavoid < persp:Distance(pos) then
		local diff = pos - trace.HitPos
		persp = trace.HitPos + diff:GetNormalized() * 20
	end

	view.origin = persp

	view.angles = angles
	view.fov = fov

	return view
end

function GM:HUDPaint( )
	local ply = LocalPlayer();
	local p = LocalPlayer():GetEyeTrace().HitPos:ToScreen()
	local x,y = p.x, p.y

	draw.SimpleText( '+', 'Default', x, y, color_white, 1, 1 )
end


hook.Add("CalcView", "ThirdPerson", ThirdPerson)

hook.Add("ShouldDrawLocalPlayer", "ShouldDrawLocalPlayer", function(ply)
	return true
end)
