--@ module = true

imgui = dfhack.imgui
menu_state = {"main"}
menu_item = nil
menu_changed = true

mouse_click_start = {x=-1, y=-1, z=-1}
mouse_click_end = {x=-1, y=-1, z=-1}
mouse_has_drag = false
mouse_which_clicked = 0

-- must be part of network api
function get_camera()
	return {x=df.global.window_x, y=df.global.window_y, z=df.global.window_z}
end

function set_camera(x, y, z)
	df.global.window_x = math.floor(x)
	df.global.window_y = math.floor(y)
	df.global.window_z = math.floor(z)
end

-- must be part of network api
function centre_camera(x, y, z)
	local sx = df.global.gps.dimx
	local sy = df.global.gps.dimy

	df.global.window_x = x - math.floor(sx/2)
	df.global.window_y = y - math.floor(sy/2)

	df.global.window_z = z
end

function menu_was_changed()
	return menu_changed
end

function menu_change_clear()
	menu_changed = false
end

function reset_menu_to(st)
	menu_state = {st}
	menu_changed = true
end

function push_menu(st)
	mouse_has_drag = false
	menu_state[#menu_state+1] = st
	menu_item = nil
	menu_changed = true
end

function pop_menu(st)
	mouse_has_drag = false
	table.remove(menu_state, #menu_state)
	menu_item = nil
	menu_changed = true
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

function get_mouse_world_coordinates()
	--[[local top_left = get_camera()

	local mouse_pos = imgui.GetMousePos()

	local lx = top_left.x+mouse_pos.x - 1
	local ly = top_left.y+mouse_pos.y - 1

	return {x=lx, y=ly, z=top_left.z}]]--

	local mouse_world_pos = imgui.GetMouseWorldPos()

	mouse_world_pos.x = math.floor(mouse_world_pos.x);
	mouse_world_pos.y = math.floor(mouse_world_pos.y);
	mouse_world_pos.z = get_camera().z

	return mouse_world_pos
end

function check_hostile(unit)
	return dfhack.units.isCrazed(unit) or
		   dfhack.units.isInvader(unit) or
		   dfhack.units.isUndead(unit, false) or
		   dfhack.units.isSemiMegabeast(unit) or
		   dfhack.units.isNightCreature(unit) or
		   dfhack.units.isGreatDanger(unit)
end

function get_user_facing_name(unit)
	local name_type = dfhack.units.getVisibleName(unit)

	local main_name = dfhack.df2utf(dfhack.TranslateName(name_type, false, false))

	--lots of things don't appear to have a proper name, and instead have a profession
	local profession = dfhack.units.getProfessionName(unit, false, false)

	local tag = ""

	if dfhack.units.isKilled(unit) then
		tag = tag.."[dead] "
	end

	if dfhack.units.isUndead(unit) then
		tag = tag.."[undead] "
	end

	if dfhack.units.isNightCreature(unit) then
		tag = tag.."[nightcreature] "
	end

	if dfhack.units.isSemiMegabeast(unit) then
		tag = tag.."[semimegabeast] "
	end

	if dfhack.units.isMegabeast(unit) then
		tag = tag.."[megabeast] "
	end

	if dfhack.units.isTitan(unit) then
		tag = tag.."[titan] "
	end

	if dfhack.units.isDemon(unit) then
		tag = tag.."[demon] "
	end

	if unit.flags3.ghostly then
		tag = tag.."[ghost] "
	end

	if (unit.curse.add_tags1.OPPOSED_TO_LIFE or unit.curse.add_tags1.NOT_LIVING) and not unit.curse.add_tags1.BLOODSUCKER then
		tag = tag.."[zombie] "
	end

	if not unit.curse.add_tags1.NOT_LIVING and unit.curse.add_tags1.NO_EAT and unit.curse.add_tags1.NO_DRINK and unit.curse.add_tags2.NO_AGING then
		tag = tag.."[necromancer] "
	end

	if dfhack.units.isInvader(unit) then
		tag = tag.."[invader] "
	elseif check_hostile(unit) then
		tag = tag.."[hostile] "
	end

	if dfhack.units.isVisitor(unit) and not dfhack.units.isInvader(unit) then
		tag = tag.."[visitor] "
	end

	if dfhack.units.isMerchant(unit) then
		tag = tag.."[merchant] "
	end

	if #tag > 0 then
		profession = profession .. " " .. tag
	end

	if #main_name == 0 then
		return profession
	else
		return main_name .. ", " .. profession
	end
end

function get_unit_colour(unit)
	local is_hostile = check_hostile(unit)
	local is_forts = dfhack.units.isFortControlled(unit)
	local is_dead = dfhack.units.isKilled(unit)

	local col = COLOR_GREY

	if is_forts then
		if is_dead then
			col = COLOR_DARKGREY
		else
			col = COLOR_WHITE
		end
	end

	if dfhack.units.isAnimal(unit) then
		if is_dead then
			col = COLOR_DARKGREY
		else
			col = COLOR_GREY
		end
	end

	if is_hostile then
		if is_dead then
			col = COLOR_BROWN
		else
			col = COLOR_LIGHTRED
		end
	end

	if is_hostile and dfhack.units.isAnimal(unit) then
		if is_dead then
			col = COLOR_BROWN
		else
			col = COLOR_RED
		end
	end

	return col
end

function TextColoredUnit(unit)
	local col = get_unit_colour(unit)

	imgui.TextColored({fg=col}, get_user_facing_name(unit))
end

function render_hotkey_text(v)
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

	local pushed = false

	if v.highlight then
		pushed = true
		local col = v.highlight_col or COLOR_WHITE
		imgui.PushStyleColor(imgui.StyleIndex("Text"), {fg=col})
	end

	local result = imgui.Button(v.text) or imgui.Shortcut(keyboard_key)

	if pushed then
		imgui.PopStyleColor(1)
	end

	return result
end

function render_table_impl(menus, old_state)
	local state = old_state

	local last_merged = false
	local just_changed = false

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
					just_changed = true
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

	return state, just_changed
end

-- ideally should be part of network api
function render_absolute_text(str, fg, bg, pos)
	local draw_list = imgui.GetForegroundDrawList()

	imgui.AddTextBackgroundColoredAbsolute(draw_list, {fg=fg, bg=bg}, str, pos)
end

function check_start_mouse_drag()
	local window_blocked = imgui.IsWindowHovered(0) or imgui.WantCaptureMouse()

	if window_blocked then
		return
	end

	imgui.EatMouseInputs()

	if imgui.IsMouseClicked(0) or imgui.IsMouseClicked(1) then
		mouse_click_start = get_mouse_world_coordinates()
		mouse_has_drag = true

		if imgui.IsMouseClicked(0) then
			mouse_which_clicked = 0
		else
			mouse_which_clicked = 1
		end
	end
end

function check_end_mouse_drag()
	if mouse_has_drag then
		imgui.EatMouseInputs()
	end

	if mouse_has_drag and imgui.IsMouseClicked((mouse_which_clicked + 1) % 2) then
		mouse_has_drag = false
	end
end

function get_dragged_tiles()
	local tiles = {}

	if not mouse_has_drag then
		return {}
	end

	local current_world_mouse_pos = get_mouse_world_coordinates()

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
			if v.z == current_world_mouse_pos.z then
				render_absolute_text("X", COLOR_BLACK, COLOR_YELLOW, {x=v.x, y=v.y, z=v.z})
			end
		end
	end

	return tiles
end

function check_trigger_mouse()
	local should_trigger = false

	if mouse_has_drag then
		if imgui.IsMouseReleased(mouse_which_clicked) then
			should_trigger = true
			mouse_click_end = get_mouse_world_coordinates()
			mouse_has_drag = false
		end
	end

	if not imgui.IsMouseDown(mouse_which_clicked) then
		mouse_has_drag = false
	end

	return should_trigger
end