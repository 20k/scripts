--@ module = true

render = reqscript('dfui_render')
imgui = dfhack.imgui

function render_viewitems()
	local top_left = render.get_camera()

	local mouse_pos = imgui.GetMousePos()
	
	local lx = top_left.x+mouse_pos.x - 1
	local ly = top_left.y+mouse_pos.y - 1
	
	local building = dfhack.buildings.findAtTile(xyz2pos(lx, ly, top_left.z))
	
	if building ~= nil then	
		local str = df.new("string")
		building:getName(str)
		
		imgui.Text(str.value)
		imgui.SetTooltip(str.value)
		
		str:delete()
	end
	
	if imgui.Button("Back") or (imgui.IsWindowHovered(0) and imgui.IsMouseClicked(1)) then
		render.pop_menu()
	end
end