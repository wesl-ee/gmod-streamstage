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

hook.Add("ShouldDrawLocalPlayer", "ShouldDrawLocalPlayer", function(p)
	return true
end)

function DrawName(p)
	if !p:Alive() then return end

	-- Don't even bother with far-away friends
	if p ~= LocalPlayer() then
		local dist = LocalPlayer():GetPos():Distance(p:GetPos())

		-- Too far! Gotta squint
		if dist > 1000 then return end
	end

	local dispname = p:GetName()
	local fontname = "CloseCaption_Normal"
	local color = GAMEMODE:GetTeamColor(p)
	local above = Vector(0, 0, 81)
	local ang = LocalPlayer():EyeAngles()
	local pos = p:GetPos() + above + ang:Up()

	-- [xXx] cL4NT4Gsz 4 tHA R341 G4MM3RZ
	if p:Team() == GAMEMODE.TeamCreator then
		dispname = "[CREATOR] "..dispname
		fontname = "CloseCaption_Bold"
	end
	if p:Team() == GAMEMODE.TeamDJCrew then
		dispname = "[DJ] "..dispname
	elseif p:Team() == GAMEMODE.TeamAdmin then
		dispname = "[Admin] "..dispname
	end

	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), 90)

	cam.Start3D2D(pos, Angle(0, ang.y, 90), 0.15)
		draw.DrawText(dispname, fontname, _, _, color, TEXT_ALIGN_CENTER)
	cam.End3D2D()
end

-- Draw everyone's name...
hook.Add("PostPlayerDraw", "DrawName", function(p)
	if p ~= LocalPlayer() then DrawName(p) end
end )

-- ...but your name is special ^.^
hook.Add("PreDrawViewModel", "DrawMyName", function()
	DrawName(LocalPlayer())
end )
