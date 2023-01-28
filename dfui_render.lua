--@ module = true

time = reqscript('dfui_libtime')
locations = reqscript('dfui_locations')

imgui = dfhack.imgui
menu_state = {"main"}
menu_substate = {{}}
menu_can_window_pop = false
menu_can_global_pop = false
menu_item = nil
menu_changed = true
mouse_rclick_poppable = false
menu_popping_pops_everything = false

mouse_click_start = {x=-1, y=-1, z=-1}
mouse_click_end = {x=-1, y=-1, z=-1}
mouse_has_drag = false
mouse_which_clicked = 0

function dump_flags(f)
	for k,v in pairs(f) do
		if v and v ~= 0 then
			imgui.Text("Flag: " .. tostring(k) .. " : " .. tostring(v))
		end
	end
end

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
	menu_substate = {{}}
	menu_changed = true
end

local function reset_pop()
	menu_can_window_pop = false
	menu_can_global_pop = false
	mouse_rclick_poppable = false
	menu_popping_pops_everything = false
end

function push_menu(st)
	mouse_has_drag = false
	menu_state[#menu_state+1] = st
	menu_substate[#menu_substate+1] = {}
	menu_item = nil
	menu_changed = true
	reset_pop()
end

function pop_menu()
	mouse_has_drag = false
	table.remove(menu_state, #menu_state)
	table.remove(menu_substate, #menu_substate)
	menu_item = nil
	menu_changed = true
	reset_pop()
end

function pop_incremental()
	local current = menu_substate[#menu_state]

	if #current ~= 0 then
		pop_submenu()
		return false
	else
		pop_menu()
		return true
	end
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

function push_submenu(st)
	local current = menu_substate[#menu_state]
	current[#current + 1] = {data=st, transparent=false}
	menu_changed = true
	reset_pop()
end

function push_transparent_submenu(st)
	local current = menu_substate[#menu_state]
	current[#current + 1] = {data=st, transparent=true}
	menu_changed = true
	reset_pop()
end

function pop_submenu()
	local current = menu_substate[#menu_state]

	if #current == 0 then
		return
	end

	table.remove(current, #current)
	reset_pop()
end

function get_submenu()
	local current = menu_substate[#menu_state]

	if #current == 0 then
		return nil
	end

	return current[#current].data
end

function get_all_submenus()
	local result = {}

	for _,v in ipairs(menu_substate[#menu_state]) do
		result[#result + 1] = v.data
	end

	return result
end

function pop_all_submenus()
	menu_substate[#menu_state] = {}
end

function can_pop()
	return (menu_can_window_pop and imgui.WantCaptureInput()) or menu_can_global_pop
end

function set_can_window_pop(p)
	menu_can_window_pop = p
end

function set_can_global_pop(p)
	menu_can_global_pop = p
end

function set_can_mouse_pop(p)
	mouse_rclick_poppable = p
end

function set_menu_item(i)
	menu_item = i
end

function get_menu_item()
	return menu_item
end

function clear_menu_item()
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

function translate_name(name)
    return dfhack.df2utf(dfhack.TranslateName(name, true))
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

	local result = imgui.Button(v.text) or (imgui.Shortcut(keyboard_key) and not imgui.WantTextInput())

	if pushed then
		imgui.PopStyleColor(1)
	end

	return result
end

function render_table_impl(menus, old_state)
	local state = old_state

	local last_merged = false
	local just_changed = false
	local clicked_idx = -1

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

			if imgui.Button(description) or (imgui.Shortcut(keyboard_key) and not imgui.WantTextInput()) then
				--if state == description then
				--	state = "None"
				--else
					state = description
					just_changed = true
					clicked_idx = k
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

	return state, just_changed, clicked_idx
end

-- ideally should be part of network api
function render_absolute_text(str, fg, bg, pos)
	local off = get_camera()

	dfhack.screen.paintTile({fg=fg, bg=bg, ch=str}, pos.x - off.x, pos.y - off.y, nil, nil, true)
end

function cancel_mouse_drag()
	mouse_has_drag = false
end

function check_start_mouse_drag()
	if mouse_has_drag and imgui.IsMouseClicked((mouse_which_clicked + 1) % 2) then
		mouse_has_drag = false
		return
	end

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


function migration_date_name(unit)
    local current_tick = df.global.cur_year_tick
    local current_year = df.global.cur_year
    local arrival_time = current_tick - unit.curse.time_on_site;

    local full_time = time.year_to_tick(current_year) + arrival_time

    local ymd = time.time_to_ymd(full_time)

    return time.months()[ymd.month+1] .. ", " .. tostring(ymd.year)
end


function sort_by_migration_wave(units)
    function cmp(a, b)
        return a.curse.time_on_site > b.curse.time_on_site
    end

    table.sort(units, cmp)
end

local dwarf_page = 0
local search = imgui.Ref("")
local rich_search = imgui.Ref("")

function filter_by_matched(units_in, search_text)
	local out = {}

	local low_search = string.lower(search_text)

	for k,v in ipairs(units_in) do
		local name = get_user_facing_name(v)

		local low = string.lower(name)

		if string.find(low, low_search) then
			out[#out+1] = v
		end
	end

	return out
end

function get_rich_text_name(item)
	if item.type == "unit" then
		return get_user_facing_name(item.data)
	end

	if item.type == "button" then
		return item.data
	end

	if item.type == "location" then
		--return locations.get_location_type_name(item.data:getType(), true) .. ": " .. locations.get_location_name(item.data)
		return locations.get_location_name(item.data)
	end

	if item.type == "text" then
		return item.data
	end

	if item.type == "tree" then
		return item.data
	end

	if item.type == "deity" then
		return translate_name(item.data.name)
	end

	if item.type == "religion" then
		return translate_name(item.data.name)
	end

	if item.type == "profession" then
		return tostring(df.profession[item.data])
	end
end

function filter_by_matched_rich(rich_text, search_text)
	local out = {}

	local low_search = string.lower(search_text)

	for k,v in ipairs(rich_text) do
		local name = get_rich_text_name(v)

		local low = string.lower(name)

		if string.find(low, low_search) then
			out[#out+1] = v
		end
	end

	return out
end

--rich text is {type="type", data=payload}
--currently supported types
--{type="dwarf", data=unit}
--{type="location", data=location}
--{type="text", data=text}
--{type="button", data=text}
--{type="tree", data=text}
--{type="deity", data=histfig}
--{type="religion", data=entity}
--{type="profession", data=profession}
function display_rich_text(rich_text_in, opts)
	local rich_text = {}

	for _,v in ipairs(rich_text_in) do
		rich_text[#rich_text+1] = v
	end

	if #imgui.Get(rich_search) > 0 then
		rich_text = filter_by_matched_rich(rich_text, imgui.Get(rich_search))
	end

    local last_migration_date_name = ""
    local active = true
	local has_tree = false

	local start_dwarf = 1
	local end_dwarf = #rich_text
	local num_per_page = 17
	local max_page = math.floor(#rich_text / num_per_page)

	local first_hover = true

	local which_id = {type="none"}

	if opts.paginate then
		local clamped_page = math.min(dwarf_page, max_page)

		start_dwarf = math.max(clamped_page * num_per_page + 1, 1)

		imgui.Text("Page: " .. tostring(clamped_page + 1) .. "/" .. tostring(max_page+1))

		end_dwarf = start_dwarf + num_per_page - 1
	end

	if opts.cancel then
		local cancel_str = opts.cancel_str

		if cancel_str == nil then
			cancel_str = "Cancel"
		end

		if imgui.Button(cancel_str) then
			which_id = {type="cancel"}
		end
	end

	if opts.leave_vacant then
		local str = opts.leave_vacant_str

		if str == nil then
			str = "Leave Vacant"
		end

		if imgui.Button(str) then
			which_id = {type="vacant"}
		end
	end

	local rendered_count = 0
	local max_render_height = 0
	local indented = false

	local count_per_page = {}

	function bump_page(cpage)
		if count_per_page[cpage] == nil then
			count_per_page[cpage] = 0
		end

		count_per_page[cpage] = count_per_page[cpage] + 1
	end

	local first_unindented_visible = true

	for i=1,#rich_text do
		local text = rich_text[i]

		local cpage = math.max((i - 1) // num_per_page, 0) + 1

		local visible = i >= start_dwarf and i <= end_dwarf

		bump_page(cpage)

		if text.type == "tree" and visible then
			if has_tree then
				imgui.TreePop()
			end

			if indented then
				imgui.Unindent()
			end

			if opts.paginate then
				imgui.Text(text.data)
				active = true
			else
				has_tree = imgui.TreeNodeEx(text.data, (1<<5))
				active = has_tree
			end

			imgui.Indent()
			indented = true
			first_unindented_visible = false

			rendered_count = rendered_count + 1

			goto done
		end

		if active and visible then
			if first_unindented_visible and not indented then
				imgui.Indent()
				indented = true
			end

			first_unindented_visible = false

			rendered_count = rendered_count + 1

            local name = get_rich_text_name(text)

			local col = COLOR_WHITE

			if text.type == "unit" then
				col = get_unit_colour(text.data)
			end

			if text.type == "deity" then
				col = COLOR_LIGHTCYAN
			end

			if text.type == "religion" then
				col = COLOR_YELLOW
			end

			if text.type == "profession" then
				col = COLOR_YELLOW
			end

            if imgui.ButtonColored(col, name) then
				if opts.center_on_click then
					centre_camera(text.data.pos.x, text.data.pos.y, text.data.pos.z)
				end

				which_id = text
            end

			if text.open_popup then
				text.open_popup()
			end

            if text.type == "unit" and imgui.IsItemHovered() then
                render_absolute_text('X', COLOR_YELLOW, COLOR_BLACK, text.data.pos)
            end

			if text.hover ~= nil and imgui.IsItemHovered()  and first_hover then
				imgui.BeginTooltip()
				imgui.Text(text.hover)
				imgui.EndTooltip()

				first_hover = false
			end

			if text.hover_array ~= nil and imgui.IsItemHovered() and first_hover then
				imgui.BeginTooltip()

				for k,v in ipairs(text.hover_array) do
					imgui.Text(v)
				end

				imgui.EndTooltip()

				first_hover = false
			end
		end

		::done::
    end

	local max_page_height = 0

	for k,v in ipairs(count_per_page) do
		max_page_height = math.max(max_page_height, v)
	end

	if indented then
		imgui.Unindent()
 	end

	if opts.paginate then
		local pad_height = math.max(num_per_page, max_page_height)

		for i=rendered_count,pad_height do
			imgui.Text(" ")
		end
	end

	imgui.Text("Search:")
	imgui.SameLine()
	imgui.InputText("##inputunits", rich_search)

	if render_hotkey_text({key="c", text="Clear"}) then
		rich_search = imgui.Ref("")
	end

	imgui.SameLine()

	if render_hotkey_text({key="s", text="Focus"}) then
		imgui.SetKeyboardFocusHere(-1)
	end

	if opts.paginate then
		if render_hotkey_text({key="q", text="Prev"}) then
			dwarf_page = dwarf_page - 1

			dwarf_page = math.max(dwarf_page, 0)
		end

		imgui.SameLine()

		if render_hotkey_text({key="e", text="Next"}) then
			dwarf_page = dwarf_page + 1

			dwarf_page = math.max(dwarf_page, 0)
			dwarf_page = math.min(dwarf_page, max_page)
		end
	end

    if has_tree then
        imgui.TreePop()
    end

	return which_id
end

function display_unit_list(units_in, opts)
	local units = {}

	for _,v in ipairs(units_in) do
		units[#units+1] = v
	end

	sort_by_migration_wave(units)

	local units_with_waves = {}

	local last_migration_date_name = ""

	for k,unit in ipairs(units) do
		local migration_name = migration_date_name(unit)

		if imgui.Get(rich_search) == "" and last_migration_date_name ~= migration_name then
			units_with_waves[#units_with_waves+1] = {type="tree", data="Arrived: " .. migration_name}
			last_migration_date_name = migration_name
		end

		units_with_waves[#units_with_waves+1] = {type="unit", data=unit}
	end

	return display_rich_text(units_with_waves, opts)
end