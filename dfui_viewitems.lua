--@ module = true

render = reqscript('dfui_render')
imgui = dfhack.imgui

selected_building_pos = {x=-1, y=-1, z=-1}


function render_viewitems()
	local top_left = render.get_camera()

	local mouse_pos = imgui.GetMousePos()
	
	local lx = top_left.x+mouse_pos.x - 1
	local ly = top_left.y+mouse_pos.y - 1
	
	local check_x = selected_building_pos.x
	local check_y = selected_building_pos.y
	local check_z = selected_building_pos.z
	
	local has_item = render.get_menu_item()
	
	if not has_item then
		check_x = lx
		check_y = ly
		check_z = top_left.z
	end
	
	local building = dfhack.buildings.findAtTile(xyz2pos(check_x, check_y, check_z))
	
	if building ~= nil then	
		local str = df.new("string")
		building:getName(str)
		
		imgui.Text(str.value)
		
		str:delete()
	end
	
	if imgui.Button("Back") or (imgui.IsWindowHovered(0) and imgui.IsMouseClicked(1)) then
		render.pop_menu()
	end
end

function handle_mouseover()
	local top_left = render.get_camera()

	local mouse_pos = imgui.GetMousePos()
	
	local lx = top_left.x+mouse_pos.x - 1
	local ly = top_left.y+mouse_pos.y - 1
	
	local building = dfhack.buildings.findAtTile(xyz2pos(lx, ly, top_left.z))
	
	if building ~= nil then	
		if imgui.IsMouseClicked(0) and not imgui.WantCaptureMouse() then
			selected_building_pos.x = lx
			selected_building_pos.y = ly
			selected_building_pos.z = top_left.z
			
			render.push_menu("View Items In Buildings")
			render.set_menu_item(true)
		end
	
		local str = df.new("string")
		building:getName(str)
		
		imgui.SetTooltip(str.value)
		
		str:delete()
	end
end