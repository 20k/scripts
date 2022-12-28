--@ module = true

imgui = dfhack.imgui
quickfort = reqscript('internal/quickfort/build')
quickfort2 = reqscript('internal/quickfort/building')
render = reqscript('dfui_render')
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

function render_make_building()
	local building = render.get_menu_item()
	
	local quickfort_building = building_db[building]
	
	local label = quickfort_building.label
	local build_type = quickfort_building.type --native df type, eg df.building_type.GrateWall
	local build_subtype = quickfort_building.subtype
	
	imgui.Text(label)
	
	if imgui.Button("Wm") or imgui.Shortcut(get_key("j")) then
		building_w = building_w - 2
	end
	
	if imgui.Button("Wp") or imgui.Shortcut(get_key("l")) then
		building_w = building_w + 2
	end
	
	if imgui.Button("Hm") or imgui.Shortcut(get_key("i")) then
		building_h = building_h - 2
	end
	
	if imgui.Button("Hp") or imgui.Shortcut(get_key("m")) then
		building_h = building_h + 2
	end
		
	if imgui.Button("Back") or ((imgui.IsWindowFocused(0) or imgui.IsWindowHovered(0)) and imgui.IsMouseClicked(1)) then
		render.pop_menu()
	end
	
	local top_left = render.get_camera()
	local mouse_pos = imgui.GetMousePos()
	
	local use_extents = quickfort_building.has_extents
	
	if quickfort_building.has_extents then
		building_w = clamp(building_w, quickfort_building.min_width, quickfort_building.max_width)
		building_h = clamp(building_h, quickfort_building.min_height, quickfort_building.max_height)
	else
		building_w = quickfort_building.min_width
		building_h = quickfort_building.min_height
	end
	
	local extent_grid = {}
	
	for x = 1, building_w do
		extent_grid[x] = {}
	
		for y = 1, building_h do
			extent_grid[x][y] = true
		end
	end
	
	local extents_interior1 = nil
	
	if quickfort_building.has_extents then
		extents_interior1 = quickfort2.make_extents({width=building_w, height=building_h, extent_grid=extent_grid}, false)
	end

	local width = math.floor((building_w - 1) / 2)
	local height = math.floor((building_h - 1) / 2)

	local build_pos = {x=top_left.x + mouse_pos.x-1-width, y=top_left.y + mouse_pos.y-1-height, z=top_left.z}
	
	local room1 = {x=build_pos.x, y=build_pos.y, width=building_w, height=building_h, extents=extents_interior1}
	
	local size = {x=building_w, y=building_h}
		
	local build_col = COLOR_RED
	
	--if dfhack.buildings.checkFreeTiles(build_pos, size, room, false, false, false) then
	--	build_col = COLOR_GREEN
	--end
	
	if dfhack.buildings.constructBuilding({type=build_type, subtype=build_subtype, x=build_pos.x, y=build_pos.y, z=build_pos.z, width=building_w, height=building_h, fields={room=room1}, dryrun=true}) then
		build_col = COLOR_GREEN
	end
	
	for y=-height,height do
		for x=-width,width do
			local lx = top_left.x+mouse_pos.x + x
			local ly = top_left.y+mouse_pos.y + y
		
			local pos = {x=lx, y=ly, z=top_left.z}
		
			render.render_absolute_text("X", build_col, COLOR_BLACK, pos)
		end
	end
	
	local is_clicked = (not imgui.IsWindowHovered(0)) and imgui.IsMouseClicked(0)
	
	if not is_clicked then
		--if room.extents ~= nil then
		--	df.delete(room.extents)
		--end
		return
	end

	local extents_interior2 = nil

	if quickfort_building.has_extents then
		extents_interior2 = quickfort2.make_extents({width=building_w, height=building_h, extent_grid=extent_grid}, false)
	end

	local room2 = {x=build_pos.x, y=build_pos.y, width=building_w, height=building_h, extents=extents_interior2}
	
	local build_info = {type=build_type, subtype=build_subtype, x=build_pos.x, y=build_pos.y, z=build_pos.z, width=building_w, height=building_h}
	build_info.fields = {room=room2}

	local a, b = dfhack.buildings.constructBuilding(build_info)
	
	--imgui.Text(tostring(a))
	--imgui.Text(tostring(b))
	
	--IF AND ONLY IF WE'RE NOT PRESSING SHIFT OK THANKS
	--render.pop_menu()
end