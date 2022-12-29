--@ module = true

imgui = dfhack.imgui
menu_state = {"main"}
menu_item = nil

mouse_click_start = {x=-1, y=-1, z=-1}
mouse_click_end = {x=-1, y=-1, z=-1}
mouse_has_drag = false
mouse_which_clicked = 0

-- must be part of network api
function get_camera()
	return {x=df.global.window_x, y=df.global.window_y, z=df.global.window_z}
end

function set_camera(x, y, z)
	df.global.window_x = x
	df.global.window_y = y
	df.global.window_z = z
end

-- must be part of network api
function centre_camera(x, y, z)
	local sx = df.global.gps.dimx
	local sy = df.global.gps.dimy

	df.global.window_x = x - math.floor(sx/2)
	df.global.window_y = y - math.floor(sy/2)
	
	df.global.window_z = z
end


function reset_menu_to(st)
	menu_state = {st}
end

function push_menu(st)
	mouse_has_drag = false
	menu_state[#menu_state+1] = st
	menu_item = nil
end

function pop_menu(st)
	mouse_has_drag = false
	table.remove(menu_state, #menu_state)
	menu_item = nil
end

function get_menu(which)
	if #menu_state == 0 then
		return nil
	end
		
	if which ~= nil then
		return menu_state[which]
	end

	return menu_state[#menu_state]
end

function set_menu_item(i)
	menu_item = i
end

function get_menu_item()
	return menu_item
end

function clear_menu_item(i)
	menu_item = nil
end

function render_table_impl(menus, old_state)
	local state = old_state
		
	local last_merged = false
	
	if imgui.BeginTable("Table", 2, (1 << 20)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();
			for k, v in ipairs(menus) do
			
			local keyboard_key = 0;
			
			if #v.key > 1 then
				keyboard_key = "STRING_A" .. v.key
			else
				local byt = tostring(string.byte(v.key))
				
				if #byt < 3 then
					byt = "0"..byt
				end
					
				keyboard_key = "STRING_A"..byt
			end
		
			local shortcut_name = imgui.GetKeyDisplay(keyboard_key)
			
			imgui.TextColored(COLOR_LIGHTGREEN, shortcut_name)
			imgui.SameLine(0,0)
			imgui.Text(": ")
			imgui.SameLine(0,0)
			
			local description = v.text
			
			local pushed = false
			if state == description or v.highlight then
				pushed = true
				imgui.PushStyleColor(imgui.StyleIndex("Text"), {fg=COLOR_WHITE})
			end
			
			if imgui.Button(description) or imgui.Shortcut(keyboard_key) then
				--if state == description then
				--	state = "None"
				--else
					state = description
				--end
			end
			
			if pushed then
				imgui.PopStyleColor(1)
			end
			
			if #description < 13 and not last_merged then
				--imgui.SameLine()
				imgui.TableNextColumn();
				
				last_merged = true
			else
				imgui.TableNextRow();
				imgui.TableNextColumn();
			
				last_merged = false
			end
		end
		
		imgui.EndTable()
	end

	return state
end

-- ideally should be part of network api
function render_absolute_text(str, fg, bg, pos)
	local draw_list = imgui.GetForegroundDrawList()
	
	imgui.AddTextBackgroundColoredAbsolute(draw_list, {fg=fg, bg=bg}, "X", pos)
end

function check_start_mouse_drag()
	local window_blocked = imgui.IsWindowHovered(0) or imgui.WantCaptureMouse()
	
	if window_blocked then
		return
	end

	local top_left = get_camera()
	
	local mouse_pos = imgui.GetMousePos()
	
	local lx = top_left.x+mouse_pos.x-1
	local ly = top_left.y+mouse_pos.y-1
	
	local current_world_mouse_pos = {x=lx, y=ly, z=top_left.z}
	
	if imgui.IsMouseClicked(0) or imgui.IsMouseClicked(1) then
		mouse_click_start = current_world_mouse_pos
		mouse_has_drag = true
		
		if imgui.IsMouseClicked(0) then
			mouse_which_clicked = 0
		else
			mouse_which_clicked = 1
		end
	end
end

function check_end_mouse_drag()
	if mouse_has_drag and imgui.IsMouseClicked((mouse_which_clicked + 1) % 2) then
		mouse_has_drag = false
	end
end

function get_dragged_tiles()
	local tiles = {}
	
	if not mouse_has_drag then
		return {}
	end
	
	local top_left = get_camera()
	
	local mouse_pos = imgui.GetMousePos()
	
	local lx = top_left.x+mouse_pos.x-1
	local ly = top_left.y+mouse_pos.y-1

	local current_world_mouse_pos = {x=lx, y=ly, z=top_left.z}
	
	local min_pos_x = math.min(mouse_click_start.x, current_world_mouse_pos.x)
	local min_pos_y = math.min(mouse_click_start.y, current_world_mouse_pos.y)
	local min_pos_z = math.min(mouse_click_start.z, current_world_mouse_pos.z)
	
	local max_pos_x = math.max(mouse_click_start.x, current_world_mouse_pos.x)
	local max_pos_y = math.max(mouse_click_start.y, current_world_mouse_pos.y)
	local max_pos_z = math.max(mouse_click_start.z, current_world_mouse_pos.z)
	
	if mouse_has_drag then		
		for z=min_pos_z,max_pos_z do
			for y=min_pos_y,max_pos_y do
				for x=min_pos_x,max_pos_x do
					--this is the most lua line of code ever
					tiles[#tiles+1] = {x=x, y=y, z=z}
				end
			end
		end
		
		for k, v in ipairs(tiles) do
			if v.z == top_left.z then
				render_absolute_text("X", COLOR_BLACK, COLOR_YELLOW, {x=v.x+1, y=v.y+1, z=v.z})
			end
		end
	end
	
	return tiles
end

function check_trigger_mouse()
	local top_left = get_camera()
	
	local mouse_pos = imgui.GetMousePos()
	
	local lx = top_left.x+mouse_pos.x-1
	local ly = top_left.y+mouse_pos.y-1

	local current_world_mouse_pos = {x=lx, y=ly, z=top_left.z}

	local should_trigger = false

	if mouse_has_drag then
		if imgui.IsMouseReleased(mouse_which_clicked) then
			should_trigger = true
			mouse_click_end = current_world_mouse_pos
			mouse_has_drag = false
		end
	end

	if not imgui.IsMouseDown(mouse_which_clicked) then
		mouse_has_drag = false
	end
	
	return should_trigger
end