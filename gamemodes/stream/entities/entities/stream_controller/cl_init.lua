include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:ShowUsePanel()
	local frame = vgui.Create("DFrame")
	frame:SetTitle("Stream Controller")
	frame:SetDraggable(false)
	frame.btnMinim:SetVisible(false)
	frame.btnMaxim:SetVisible(false)

	frame:SetSize(520, 200)

	local audiolabel = vgui.Create("DLabel", frame)
	audiolabel:SetPos(10, 30)
	audiolabel:SetText("Audio URL:")
	audiolabel:SizeToContents()

	local videolabel = vgui.Create("DLabel", frame)
	videolabel:SetPos(10, 70)
	videolabel:SetText("Video URL (Optional):")
	videolabel:SizeToContents()

	local videobox = vgui.Create("DTextEntry", frame)
	videobox:SetPos(10, 90)
	videobox:SetSize(500, 20)

	if GAMEMODE.VideoURL then
		videobox:SetText(GAMEMODE.VideoURL)
	end

	videobox.OnEnter = function(me)
	end


	local audiobox = vgui.Create("DTextEntry", frame)
	audiobox:SetPos(10, 50)
	audiobox:SetSize(500,20)

	if GAMEMODE.SoundURL then
		audiobox:SetText(GAMEMODE.SoundURL)
	end

	audiobox.OnEnter = function(me)
	end

	local vollabel = vgui.Create("DLabel", frame)
	vollabel:SetPos(10, 130)
	vollabel:SetText("Vol.:")
	vollabel:SetSize(30, 20)
	local vol = vgui.Create("DNumberWang", frame)
	vol:SetPos(40, 130)
	vol:SetSize(40, 20)

	if GAMEMODE.Volume then
		vol:SetText(GAMEMODE.Volume)
	else vol:SetText(100) end

	local attenlabel = vgui.Create("DLabel", frame)
	attenlabel:SetPos(90, 130)
	attenlabel:SetText("Attenuation:")
	attenlabel:SetSize(70, 20)
	local atten = vgui.Create("DNumberWang", frame)
	atten:SetPos(170, 130)
	atten:SetSize(40, 20)
	if GAMEMODE.Attenuation then
		atten:SetText(GAMEMODE.Attenuation)
	else atten:SetText(100) end

	local playbutton = vgui.Create("DButton", frame)
	playbutton:SetText("Play")
	playbutton:SetPos(0, 160)
	playbutton:SetSize(40, 20)
	playbutton:CenterHorizontal()

	playbutton.DoClick = function(me)
		net.Start("streamstage-parameters")
		net.WriteUInt(atten:GetValue(), GAMEMODE.NetUIntSize)
		net.WriteUInt(self:EntIndex(), GAMEMODE.NetUIntSize)
		net.WriteString(audiobox:GetValue())
		net.WriteString(videobox:GetValue())
		net.WriteUInt(vol:GetValue(), GAMEMODE.NetUIntSize)
		net.WriteBool(true)
		net.SendToServer()

		me:GetParent():Close()
	end

	local stopbutton = vgui.Create("DButton", frame)
	stopbutton:SetText("Stop")
	stopbutton:SetPos(470, 160)
	stopbutton:SetSize(40, 20)

	stopbutton.DoClick = function(me)
		net.Start("streamstage-stop")
		net.SendToServer()

		me:GetParent():Close()
	end

	audiobox:RequestFocus()
	frame:Center()
	frame:SetVisible(true)
	frame:MakePopup()

end

net.Receive("ShowControllerVGUI", function()
	local controller = net.ReadEntity()
	controller:ShowUsePanel()
end )

