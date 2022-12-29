--@ module = true

imgui = dfhack.imgui
quickfort = reqscript('internal/quickfort/build')
quickfort2 = reqscript('internal/quickfort/building')
render = reqscript('dfui_render')
place = reqscript('internal/quickfort/place')
zone = reqscript('internal/quickfort/zone')
utils = require('utils')
require('dfhack.buildings')

building_db = quickfort.get_building_db()

building_w = 3
building_h = 3

local ui_order = {
    -- basic building types
   "a",
   "b",
   "c",
   "n",
   "d",
   "x",
   "H",
   "W",
   "G",
   "B",
   '{Alt}b',
   "f",
   "h",
   "k",
   "p",
   "r",
   "s",
   '{Alt}s',
   "t",
   "o",
   "O",
   "gs",
   "gw",
   "gd",
   "gx",
   "ga",
   "l",
   -- siege engines
   "ib",
   "ic",
   -- workshops
   "we",
   "wq",
   "wM",
   "wo",
   "wk",
   "wb",
   "wc",
   "wf",
   "wv",
   "wj",
   "wm",
   "wu",
   "wn",
   "wr",
   "ws",
   "wt",
   "wl",
   "ww",
   "wz",
   "wh",
   "wy",
   "wd",
   "wS",
   "wp",
   -- furnaces
   "ew",
   "es",
   "el",
   "eg",
   "ea",
   "ek",
   "en",
   "y",
   "Y",
   -- constructions
   "Cw",
   "Cf",
   "Cr",
   "Cu",
   "Cd",
   "Cx",
   "CF",
    -- traps
   "CS",
   "CSa",
   "CSaa",
   "CSaaa",
   "CSaaaa",
   "CSd",
   "CSda",
   "CSdaa",
   "CSdaaa",
   "CSdaaaa",
   "CSdd",
   "CSdda",
   "CSddaa",
   "CSddaaa",
   "CSddaaaa",
   "CSddd",
   "CSddda",
   "CSdddaa",
   "CSdddaaa",
   "CSdddaaaa",
   "CSdddd",
   "CSdddda",
   "CSddddaa",
   "CSddddaaa",
   "CSddddaaaa",
   "D",
   "Ts",
    -- TODO: by default a weapon trap is configured with a single weapon.
    -- maybe add Tw1 through Tw10 for choosing how many weapons?
    -- material preferences can help here for choosing weapon types.
   "Tw",
   "Tl",
    -- TODO: lots of configuration here with no natural order. may need
    -- special-case logic when we read the keys.
   "Tp",
   "Tc",
    -- TODO: Same as weapon trap above
   "TS",
    -- tracks (CT...). there aren't any shortcut keys in the UI so we use the
    -- aliases from python quickfort
   "Msu",
   "Msk",
   "Msm",
   "Msh",
    -- there is no enum for water wheel and horiz axle directions, we just have
    -- to pass a non-zero integer (but not a boolean)
   "Mw",
   "Mws",
   "Mg",
   "Mh",
   "Mhs",
   "Mv",
   "Mr",
   "Mrq",
   "Mrqq",
   "Mrqqq",
   "Mrqqqq",
   "Mrs",
   "Mrsq",
   "Mrsqq",
   "Mrsqqq",
   "Mrsqqqq",
   "Mrss",
   "Mrssq",
   "Mrssqq",
   "Mrssqqq",
   "Mrssqqqq",
   "Mrsss",
   "Mrsssq",
   "Mrsssqq",
   "Mrsssqqq",
   "Mrsssqqqq",
    -- Instruments are not yet supported by DFHack
    -- I,
   "S",
   "m",
   "v",
   "j",
   "A",
   "R",
   "N",
   '{Alt}h',
   '{Alt}a',
   '{Alt}c',
   "F"--[[,
   
   "trackN",
   "trackS",
   "trackE",
   "trackW",
   "trackNS",
   "trackEW",
   "trackNE",
   "trackNW",
   "trackSE",
   "trackSW",
   "trackNSE",
   "trackNSW",
   "trackNEW",
   "trackSEW",
   "trackNSEW",
   "trackrampN",
   "trackrampS",
   "trackrampE",
   "trackrampW",
   "trackrampNS",
   "trackrampEW",
   "trackrampNE",
   "trackrampNW",
   "trackrampSE",
   "trackrampSW",
   "trackrampNSE",
   "trackrampNSW",
   "trackrampNEW",
   "trackrampSEW",
   "trackrampNSEW"]]--
}

local ml_cats = {
	["w"]="Workshops",
	["g"]="Bridge",
	["M"]="Machines",
	["e"]="Furnaces",
	["i"]="Siege Engines",
	["C"]="Constructions",
	--["CS"]="Track Stops",
	["T"]="Traps"
}

function is_prefix(str, check)
	return string.sub(str, 1, #check) == check
end

function has_more_specialised_prefix_than(their_shortcut, my_prefix)
	for k, v in pairs(ml_cats) do
		if is_prefix(their_shortcut, k) and my_prefix ~= k and #k > #my_prefix then
			return true
		end
	end
	
	return false
end

function get_all_longer_prefixes(their_shortcut, my_prefix) 
	local prefixes = {}

	for k, v in pairs(ml_cats) do
		if is_prefix(their_shortcut, k) and my_prefix ~= k and #k > #my_prefix  then
			prefixes[#prefixes + 1] = k
		end
	end
	
	return prefixes
end

function render_buildings()
	local to_render = {}
	
	--ok so lets take a bed
	--prefix is ""
	--bed is b
	--bed doesn't have a more specialised prefix in ml_cats
	--so, bed needs to iterate over ml_cats
	--if bed starts with anything in ml_cats
	--and our prefix is not that thing in ml_cats
	--return true
	
	local name_hotkey = {}
	
	local rendered = {}
	
	local root_menu = render.get_menu()
	
	local prefix = render.get_menu_item()
	
	if prefix == nil then
		prefix = ""
	end

	imgui.Text("Prefix: " ..prefix)

	for k, v in ipairs(ui_order) do
		if not is_prefix(v, prefix) then
			goto skip
		end
		
		if has_more_specialised_prefix_than(v, prefix) then
			local all_prefixes = get_all_longer_prefixes(v, prefix)
						
			table.sort(all_prefixes)
			
			for m, l in ipairs(all_prefixes) do
				if #l == #all_prefixes[1] and not rendered[l] then				
					name_hotkey[#name_hotkey+1] = {key=l, value=ml_cats[l], is_cat=true}
					rendered[l] = true
				end
			end
		else
			name_hotkey[#name_hotkey+1] = {key=v, value=building_db[v].label, is_cat=false}
		end
		
		::skip::
	end

	if imgui.BeginTable("Table", 2, (1 << 20)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();
		
		for k, v in ipairs(name_hotkey) do		
			local extra_key = string.sub(v.key, #prefix+1, #v.key)

			local start_building = false

			if v.is_cat then
				if imgui.ButtonColored({fg=COLOR_YELLOW}, v.value) then
					--next_prefix = v.key
					--render.push_menu(extra_key)
					render.set_menu_item(v.key)
				end
			else
				start_building = imgui.Button(v.value)
			end

			imgui.TableNextColumn();

			local pad = 6 - #extra_key
			
			local spad = string.rep(' ', pad)
			
			local byt = tostring(string.byte(extra_key))
			
			if #byt < 3 then
				byt = "0"..byt
			end
			
			local keyboard_key = "STRING_A"..byt
			
			if imgui.Shortcut(keyboard_key) and v.is_cat then
				render.set_menu_item(v.key)
			end
			
			if imgui.Shortcut(keyboard_key) and not v.is_cat then
				start_building = true
			end
			
			if start_building then
				building_w = 3
				building_h = 3
				render.push_menu("make_building")
				render.set_menu_item(v.key)
			end
		
			imgui.Text(spad.."(")
			imgui.SameLine(0,0)
			imgui.TextColored({fg=COLOR_LIGHTGREEN}, extra_key)
			imgui.SameLine(0,0)
			imgui.Text(")")
			
			imgui.TableNextRow();
			imgui.TableNextColumn();
		end
		
		imgui.EndTable()
	end

	if imgui.Button("Back") or ((imgui.IsWindowFocused(0) or imgui.IsWindowHovered(0)) and imgui.IsMouseClicked(1)) then
		if render.get_menu_item() == nil or #render.get_menu_item() == 0 then
			render.pop_menu()
		else
			local pref = render.get_menu_item()
			
			pref = string.sub(pref, 1, #pref - 1)
			
			render.set_menu_item(pref)
		end
	end
end

function clamp(x, left, right)
	if x < left then
		return left
	end

	if x > right then
		return right
	end

	return x
end

function get_key(s)	
	local byt = tostring(string.byte(s))
	
	if #byt < 3 then
		byt = "0"..byt
	end
		
	return "STRING_A"..byt
end

function handle_construct(type, subtype, pos, size, use_extents, abstract, dry_run, init_fields)
	local extent_grid = {}
	
	for x = 1, size.x do
		extent_grid[x] = {}

		for y = 1, size.y do
			extent_grid[x][y] = true
		end
	end
	
	local extents_interior = nil
	local ntiles = 0
	
	if use_extents then
		extents_interior, ntiles = quickfort2.make_extents({width=size.x, height=size.y, extent_grid=extent_grid}, false)
	end
	
	local room = {x=pos.x, y=pos.y, width=size.x, height=size.y, extents=extents_interior}
	local size = {x=size.x, y=size.y}

	local fields = {room=room}
	
	init_fields(fields, ntiles)

	--if dfhack.buildings.checkFreeTiles(build_pos, size, room, false, false, false) then
	--	build_col = COLOR_GREEN
	--end
	
	return dfhack.buildings.constructBuilding({type=type, subtype=subtype, x=pos.x, y=pos.y, z=pos.z, width=size.x, height=size.y, fields=fields, abstract=abstract, dryrun=dry_run})
end

function handle_resizable()
	if imgui.Button("(-) ##w") or imgui.Shortcut(get_key("j")) then
		building_w = building_w - 1
	end
	
	imgui.SameLine(0,0)
	imgui.Text(tostring(building_w))
	imgui.SameLine(0,0)
	
	if imgui.Button(" (+)##w") or imgui.Shortcut(get_key("l")) then
		building_w = building_w + 1
	end
	
	imgui.SameLine()
	
	imgui.Text(" j l")
	
	if imgui.Button("(-) ##h") or imgui.Shortcut(get_key("i")) then
		building_h = building_h - 1
	end
	
	imgui.SameLine(0,0)
	imgui.Text(tostring(building_h))
	imgui.SameLine(0,0)
	
	if imgui.Button(" (+)##h") or imgui.Shortcut(get_key("m")) then
		building_h = building_h + 1
	end
	
	imgui.SameLine()
	
	imgui.Text(" i m")
end

function render_make_building()
	local building = render.get_menu_item()
	
	local quickfort_building = building_db[building]
	
	local label = quickfort_building.label
	local build_type = quickfort_building.type --native df type, eg df.building_type.GrateWall
	local build_subtype = quickfort_building.subtype
	
	local use_extents = quickfort_building.has_extents

	imgui.Text(label)
	
	if use_extents then
		handle_resizable()
	end

	if imgui.Button("Back") or ((imgui.IsWindowFocused(0) or imgui.IsWindowHovered(0)) and imgui.IsMouseClicked(1)) then
		render.pop_menu()
	end
	
	local top_left = render.get_camera()
	local mouse_pos = imgui.GetMousePos()

	if use_extents then
		building_w = clamp(building_w, quickfort_building.min_width, quickfort_building.max_width)
		building_h = clamp(building_h, quickfort_building.min_height, quickfort_building.max_height)
	else
		building_w = quickfort_building.min_width
		building_h = quickfort_building.min_height
	end
	
	local width = math.floor((building_w - 1) / 2)
	local height = math.floor((building_h - 1) / 2)

	local build_pos = {x=top_left.x + mouse_pos.x-1-width, y=top_left.y + mouse_pos.y-1-height, z=top_left.z}
	local size = {x=building_w, y=building_h}
	
	local build_col = COLOR_RED
	
	function none(fields, tiles)
	
	end
	
	if handle_construct(build_type, build_subtype, build_pos, {x=building_w, y=building_h}, use_extents, false, true, none) then
		build_col = COLOR_GREEN
	end
	
	for x=build_pos.x,(build_pos.x+building_w-1) do 
		for y=build_pos.y,(build_pos.y+building_h-1) do 	
			local pos = {x=x+1, y=y+1, z=top_left.z}
		
			render.render_absolute_text("X", build_col, COLOR_BLACK, pos)
		end
	end
	
	local is_clicked = (not imgui.IsWindowHovered(0)) and imgui.IsMouseClicked(0) and not imgui.WantCaptureMouse()
	
	if not is_clicked then
		return
	end

	local a, b = handle_construct(build_type, build_subtype, build_pos, {x=building_w, y=building_h}, use_extents, false, false, none)
	
	--imgui.Text(tostring(a))
	--imgui.Text(tostring(b))
	
	--IF AND ONLY IF WE'RE NOT PRESSING SHIFT OK THANKS
	--render.pop_menu()
end

function trigger_stockpile(tl, size, dry_run)
	local stockpile_type = render.get_menu_item()
	local quickfort_building = place.stockpile_db[stockpile_type]

	local build_type = df.building_type.Stockpile

	local use_extents = true

	local building_w = clamp(size.x, quickfort_building.min_width, quickfort_building.max_width)
	local building_h = clamp(size.y, quickfort_building.min_height, quickfort_building.max_height)
	
	local build_pos = {x=tl.x, y=tl.y, z=tl.z}

	function setup(fields, ntiles)
		local db_entry = place.stockpile_db[stockpile_type]

		if db_entry.want_barrels then
			local max_barrels = db_entry.num_barrels or 99999
			if max_barrels < 0 or max_barrels >= ntiles then
				fields.max_barrels = ntiles
			else
				fields.max_barrels = max_barrels
			end
		end
		if db_entry.want_bins then
			local max_bins = db_entry.num_bins or 99999
			if max_bins < 0 or max_bins >= ntiles then
				fields.max_bins = ntiles
			else
				fields.max_bins = max_bins
			end
		end
		if db_entry.want_wheelbarrows or db_entry.num_wheelbarrows then
			local max_wb = db_entry.num_wheelbarrows or 99999
			if max_wb < 0 then max_wb = 1 end
			if max_wb >= ntiles - 1 then
				fields.max_wheelbarrows = ntiles - 1
			else
				fields.max_wheelbarrows = max_wb
			end
		end
	end
	
	local build_col = COLOR_RED
	
	if handle_construct(build_type, nil, build_pos, {x=building_w, y=building_h}, use_extents, true, true, setup) then
		build_col = COLOR_GREEN
	end
	
	for x=build_pos.x,(build_pos.x+building_w-1) do 
		for y=build_pos.y,(build_pos.y+building_h-1) do 	
			local pos = {x=x+1, y=y+1, z=tl.z}
		
			render.render_absolute_text("X", build_col, COLOR_BLACK, pos)
		end
	end

	if not dry_run then
		handle_construct(build_type, nil, build_pos, {x=building_w, y=building_h}, use_extents, true, false, setup)
	end
	
	--imgui.Text(tostring(a))
	--imgui.Text(tostring(b))
	
	--IF AND ONLY IF WE'RE NOT PRESSING SHIFT OK THANKS
	--render.pop_menu()
end

function min3(v1, v2)
	local min_pos_x = math.min(v1.x, v2.x)
	local min_pos_y = math.min(v1.y, v2.y)
	local min_pos_z = math.min(v1.z, v2.z)
	
	local max_pos_x = math.max(v1.x, v2.x)
	local max_pos_y = math.max(v1.y, v2.y)
	local max_pos_z = math.max(v1.z, v2.z)
	
	return {x=min_pos_x, y=min_pos_y, z=min_pos_z}, {x=max_pos_x, y=max_pos_y, z=max_pos_z}
end

function kill_ifempty_building(building)
	if building == nil then
		return
	end
		
	if building.room == nil or building.room.extents == nil then
		return
	end

	for lx=0,building.room.width-1 do
		for ly=0,building.room.height-1 do
			local idx = lx + ly * building.room.width
			
			if building.room.extents[idx] ~= df.building_extents_type.None then
				return
			end
		end
	end
		
	if dfhack.buildings.markedForRemoval(building) then
		return
	end

	dfhack.buildings.deconstruct(building)
end

function render_stockpiles()
	local to_render = {}
	local value_to_key = {None="a", ["Remove Designation"]="x"}
	local key_to_value = {x="Remove Designation"}
	
	local render_order = {"a","f","u","n","y","r","s","w","e","b","h","l","z","S","g","p","d","c"}
	
	for k, v in ipairs(render_order) do
		local d = {key=v, text=place.stockpile_db[v].label}
		
		value_to_key[d.text] = d.key
		key_to_value[d.key] = d.text
	
		to_render[#to_render + 1] = d
	end
	
	render_order[#render_order+1] = "x"
	
	to_render[#to_render + 1] = {key="x", text="Remove Designation"}
	
	local current_state = render.get_menu_item()
	
	if current_state == nil then
		current_state = 'a'
	end
		
	local next_description = render.render_table_impl(to_render, key_to_value[current_state])
	
	render.set_menu_item(value_to_key[next_description])
	
	if imgui.Button("Back") or (imgui.WantCaptureMouse() and imgui.IsMouseClicked(1)) then
		render.pop_menu()
	end
	
	if next_description ~= "None" then
		render.check_start_mouse_drag()
	end
	
	local tiles = render.get_dragged_tiles()

	render.check_end_mouse_drag()

	local should_trigger_mouse = render.check_trigger_mouse()
	
	if should_trigger_mouse and next_description ~= "Remove Designation" and render.mouse_which_clicked == 0 then
		local start_pos = render.mouse_click_start
		local end_pos = render.mouse_click_end
		
		start_pos, end_pos = min3(start_pos, end_pos)
		
		local size = {x=end_pos.x - start_pos.x + 1, y=end_pos.y-start_pos.y + 1}
		
		trigger_stockpile(start_pos, size, false)
	end
	
	if should_trigger_mouse and (next_description == "Remove Designation" or render.mouse_which_clicked == 1) then
		for k, v in ipairs(tiles) do
			local building = dfhack.buildings.findAtTile(xyz2pos(v.x, v.y, v.z))
			
			if building == nil then
				goto continue
			end
			
			if building.room == nil or building.room.extents == nil then
				goto continue
			end
			
			local lx = v.x - building.room.x
			local ly = v.y - building.room.y
			
			if lx < 0 or ly < 0 or lx >= building.room.width or ly >= building.room.height then
				goto continue
			end
			
			local idx = lx + ly * building.room.width
			
			if building.room.extents[idx] == df.building_extents_type.None then
				goto continue
			end
			
			building.room.extents[idx] = df.building_extents_type.None
			
			local chunk = dfhack.maps.getTileBlock({x=v.x, y=v.y, z=v.z})
			
			local des = chunk.designation[(v.x)&15][(v.y)&15]
			local occ = chunk.occupancy[(v.x)&15][(v.y)&15]

			des.pile = false
			occ.building = df.tile_building_occ.None
			
			kill_ifempty_building(building)
			
			::continue::
		end
	end
end

function trigger_zone(tl, size, dry_run)
	local build_type = df.building_type.Civzone
	local build_subtype = df.civzone_type.ActivityZone

	local use_extents = true

	local building_w = clamp(size.x, 1, 31)
	local building_h = clamp(size.y, 1, 31)
	
	local build_pos = {x=tl.x, y=tl.y, z=tl.z}

	function setup(fields, ntiles)
		fields.is_room = true
	end
	
	local build_col = COLOR_RED
	
	if handle_construct(build_type, build_subtype, build_pos, {x=building_w, y=building_h}, use_extents, true, true, setup) then
		build_col = COLOR_GREEN
	end
	
	for x=build_pos.x,(build_pos.x+building_w-1) do 
		for y=build_pos.y,(build_pos.y+building_h-1) do 	
			local pos = {x=x+1, y=y+1, z=tl.z}
		
			render.render_absolute_text("X", build_col, COLOR_BLACK, pos)
		end
	end

	if not dry_run then
		local bld, err = handle_construct(build_type, build_subtype, build_pos, {x=building_w, y=building_h}, use_extents, true, false, setup)
		
		if bld then
			bld.zone_flags.active = true
			bld.gather_flags.pick_trees = true
			bld.gather_flags.pick_shrubs = true
			bld.gather_flags.gather_fallen = true
		end
	end
end

function handle_specific_zone_render(building)
	local zone_db = zone.zone_db
	local render_order = {"a", "w", "f", "g", "d", "n", "p", "s", "c", "m", "h", "t"}
	local label_to_key = {}
	
	local to_render = {}
	
	for _,v in ipairs(render_order) do
		local elem = {key=v, text=zone_db[v].label}

		to_render[#to_render+1] = elem
		
		label_to_key[elem.text] = elem.key
	end
	
	local picked = render.render_table_impl(to_render, "None")
	
	if picked ~= "None" then
		local key = label_to_key[picked]
	
		local flag = zone_db[key].zone_flags
		
		for _,name in ipairs(flag) do
			building.zone_flags[name] = ~building.zone_flags[name]
		end
	end
end

function render_zones()
	local to_render = {{key="p", text="Place Zone"}, {key="x", text="Remove Zones"}}
	
	local current_state = render.get_menu_item()
	
	if current_state == nil then
		current_state = {type='Place Zone', id=nil}
	end
	
	if current_state.type == "Selected" then
		local zone_id = current_state.id
		
		local building = df.building.find(zone_id)
		
		if building ~= nil then
			local name = utils.getBuildingName(building)
			
			imgui.Text("Selected Zone")
			
			imgui.Text(name)
			
			handle_specific_zone_render(building)
		end
	end
	
	current_state.type = render.render_table_impl(to_render, current_state.type)
	
	render.set_menu_item(current_state)
	
	if imgui.Button("Back") or (imgui.WantCaptureMouse() and imgui.IsMouseClicked(1)) then
		render.pop_menu()
	end
	
	if next_description ~= "None" then
		render.check_start_mouse_drag()
	end
	
	local tiles = render.get_dragged_tiles()

	render.check_end_mouse_drag()

	local should_trigger_mouse = render.check_trigger_mouse()
	
	if should_trigger_mouse and current_state.type == "Place Zone" then
		local start_pos = render.mouse_click_start
		local end_pos = render.mouse_click_end
		
		start_pos, end_pos = min3(start_pos, end_pos)
		
		local size = {x=end_pos.x - start_pos.x + 1, y=end_pos.y-start_pos.y + 1}
		
		trigger_zone(start_pos, size, false)
	end
end