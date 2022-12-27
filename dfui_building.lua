--@ module = true

imgui = dfhack.imgui
quickfort = reqscript('internal/quickfort/build')
render = reqscript('dfui_render')

local building_db = quickfort.get_building_db()

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

function render_make_building()
	local building = render.get_menu_item()
	
	imgui.Text(building)
	
	if imgui.Button("Back") or ((imgui.IsWindowFocused(0) or imgui.IsWindowHovered(0)) and imgui.IsMouseClicked(1)) then
		render.pop_menu()
	end
end