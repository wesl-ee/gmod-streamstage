function InThirdPerson()
	-- First-person cases
	v = GetConVar("stream_forcefirstperson")
	if v and v:GetBool() then return false end
	if g_VR and g_VR.active then return false end

	-- Default to third-person
	return true
end

function ThirdPerson(ply, pos, angles, fov)
	if not InThirdPerson() then return end

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
	trace.filter = function(ent)
		if not (ent == LocalPlayer()) then return true end
	end

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
	if not InThirdPerson() then return end

	local ply = LocalPlayer();
	local p = LocalPlayer():GetEyeTrace().HitPos:ToScreen()
	local x,y = p.x, p.y

	draw.SimpleText( '+', 'Default', x, y, color_white, 1, 1 )
end


hook.Add("CalcView", "ThirdPerson", ThirdPerson)

hook.Add("ShouldDrawLocalPlayer", "ShouldDrawLocalPlayer", function(p)
	if not InThirdPerson() then return end

	return true
end)

function GM:DrawName(p)
	-- if !p or !p:Alive() or (vrmod and p == LocalPlayer() and vrmod.IsPlayerInVR(LocalPlayer())) then return end
	if !p or !p:Alive() then return end

	-- Don't even bother with far-away friends
	local dist = LocalPlayer():GetPos():DistToSqr(p:GetPos())

	-- Too far! Gotta squint (700*700)
	if dist > 490000 then return end

	local dispname = p:GetName()
	if !dispname then
		dispname = "[NULL]"
	end

	local fontname = "Trebuchet24"
	local scale
	if p == LocalPlayer() then
		scale = 0.15
	else
		scale = 0.2
	end
	local color = GAMEMODE:GetTeamColor(p)
	local above = Vector(0, 0, 81)
	local ang = LocalPlayer():EyeAngles()
	local pos = p:GetPos() + above + ang:Up()

	-- [xXx] cL4NT4Gsz 4 tHA R341 G4MM3RZ
	if p:Team() == GAMEMODE.TeamCreator then
		dispname = "[CREATOR] "..dispname

		if GAMEMODE.NameThing then
			if p.Seq == nil then p.Seq = 3 end
			p.Seq = p.Seq + 1
			if p.Seq >= 100 then p.Seq = 3 end
			if p.Seq > 50 then
				dispname = "[CREATOR] DJR"..string.format("%02d", p.Seq)
			else
				dispname = "<CR34TOR> DJR"..string.format("%02d", p.Seq)
			end

			if p.Seq > 75 or p.Seq < 25 then
				color = Color(255, 255, 255)
			end
		end
	end
	if p:Team() == GAMEMODE.TeamDJCrew then
		dispname = "[DJ] "..dispname
	elseif p:Team() == GAMEMODE.TeamAdmin then
		dispname = "[Admin] "..dispname
	end

	-- Bootleg centering cause TEXT_ALIGN_CENTER is broken
	surface.SetFont(fontname)
	local tX, _ = surface.GetTextSize(dispname)
	local tHalfWidth = scale * tX / 2
	pos = pos - tHalfWidth * ang:Right()

	-- Orient towards viewpoint
	ang:RotateAroundAxis(ang:Forward(), 90)
	ang:RotateAroundAxis(ang:Right(), 90)

	cam.Start3D2D(pos, Angle(0, ang.y, 90), scale)
		draw.DrawText(dispname, fontname, 0, 0, color, TEXT_ALIGN_LEFT)
	cam.End3D2D()
end

-- Draw everyone's name...
hook.Add("PostPlayerDraw", "DrawName", function(p)
	if IsValid(p) then GAMEMODE:DrawName(p) end
end )
