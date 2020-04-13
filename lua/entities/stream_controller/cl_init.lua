include("shared.lua")

function ENT:Draw()
	self:DrawModel()
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
		frame:SetSize(520, 100)
		local label = vgui.Create("DLabel", frame)
		label:SetPos(10, 30)

		label:SetText("There are no speakers!")
		label:SizeToContents()
	else
		frame:SetSize(520, 100)

		local box = vgui.Create("DTextEntry", frame)
		box:SetPos(10, 50)
		box:SetSize(500,20)

		local label = vgui.Create("DLabel", frame)
		label:SetPos(10, 30)

		if nc == netcodes.VGUI_NOW_PLAYING then
			box:SetValue(controller.URL)
			label:SetText("Currently Playing")
		else
			label:SetText("Stream URL")
		end


		label:SizeToContents()

		box.OnEnter = function(me)
			net.Start("StartMusicStream")
			net.WriteString(me:GetValue())
			net.SendToServer()

			controller.URL = me:GetValue()
			me:GetParent():Close()
		end

		box:RequestFocus()
	end

	frame:Center()
	frame:SetVisible(true)
	frame:MakePopup()

end )

