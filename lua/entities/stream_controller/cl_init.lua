include("shared.lua")

function ENT:Draw()
	self:DrawModel()
end

function ENT:DrawVGUINoOutput(p)
	p:SetSize(520, 100)
	local label = vgui.Create("DLabel", p)
	label:SetPos(10, 30)

	label:SetText("There are no speakers!")
	label:SizeToContents()
end

function ENT:DrawVGUINotPlaying(p)
	p:SetSize(520, 100)
	local label = vgui.Create("DLabel", p)
	label:SetPos(10, 30)

	label:SetText("Stream URL")
	label:SizeToContents()

	local box = vgui.Create("DTextEntry", p)
	box:SetPos(10, 50)
	box:SetSize(500,20)
	box.OnEnter = function(me)
		net.Start("StartMusicStream")
		net.WriteString(me:GetValue())
		net.SendToServer()

		self.URL = me:GetValue()
		print("Self.URL ", self.URL)
		me:GetParent():Close()
	end

	box:RequestFocus()
end

function ENT:DrawVGUINowPlaying(p)
	p:SetSize(520, 100)
	local label = vgui.Create("DLabel", p)
	label:SetPos(10, 30)

	label:SetText("Currently Playing!")
	label:SizeToContents()

	local box = vgui.Create("DTextEntry", p)
	box:SetPos(10, 50)
	box:SetSize(500,20)
	print("Self.URL ", self.URL)
	box:SetValue(self.URL)
	box.OnEnter = function(me)
		net.Start("StartMusicStream")
		net.WriteString(me:GetValue())
		net.SendToServer()

		self.URL = me:GetValue()
		me:GetParent():Close()
	end

	box:RequestFocus()
end

net.Receive("ShowControllerVGUI", function()
	local controller = net.ReadEntity()
	local netcodes = controller.NETCODE
	-- Return value from the +USE call
	local nc = net.ReadUInt(controller.NETINTLEN)

	local frame = vgui.Create("DFrame")
	frame:SetTitle("Stream Controller")
	frame:SetDraggable(false)
	frame.btnMinim:SetVisible(false)
	frame.btnMaxim:SetVisible(false)

	if nc == netcodes.VGUI_NO_OUTPUTS then
		controller:DrawVGUINoOutput(frame)
	elseif nc == netcodes.VGUI_NOT_PLAYING then
		controller:DrawVGUINotPlaying(frame)
	elseif nc == netcodes.VGUI_NOW_PLAYING then
		controller:DrawVGUINowPlaying(frame)
	end

	frame:Center()
	frame:SetVisible(true)
	frame:MakePopup()

end )

