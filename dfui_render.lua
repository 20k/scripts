--@ module = true

imgui = dfhack.imgui
menu_state = {"main"}
menu_item = nil

-- must be part of network api
function get_camera()
	return {x=df.global.window_x, y=df.global.window_y, z=df.global.window_z}
end

function reset_menu_to(st)
	menu_state = {st}
end

function push_menu(st)
	menu_state[#menu_state+1] = st
	menu_item = nil
end

function pop_menu(st)
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
			if state == description then
				pushed = true
				imgui.PushStyleColor(imgui.StyleIndex("Text"), {fg=COLOR_WHITE})
			end
			
			if imgui.Button(description) or imgui.Shortcut(keyboard_key) then
				if state == description then
					state = "None"
				else
					state = description
				end
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
