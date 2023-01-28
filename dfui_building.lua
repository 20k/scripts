--@ module = true

imgui = dfhack.imgui
quickfort = reqscript('internal/quickfort/build')
quickfort2 = reqscript('internal/quickfort/building')
render = reqscript('dfui_render')
--place = reqscript('internal/quickfort/place')
zone = reqscript('internal/quickfort/zone')
utils = require('utils')
military = reqscript('dfui_military')
locations = reqscript('dfui_locations')
require('dfhack.buildings')

--workaround
function get_stockpile_db()
	local stockpile_template = {
		has_extents=true, min_width=1, max_width=31, min_height=1, max_height=31,
		is_valid_tile_fn = is_valid_stockpile_tile,
		is_valid_extent_fn = is_valid_stockpile_extent
	}

	local all_bits = {
		df.stockpile_group_set.animals,
		df.stockpile_group_set.food,
		df.stockpile_group_set.furniture,
		df.stockpile_group_set.coins,
		df.stockpile_group_set.corpses,
		df.stockpile_group_set.refuse,
		df.stockpile_group_set.stone,
		df.stockpile_group_set.wood,
		df.stockpile_group_set.gems,
		df.stockpile_group_set.bars_blocks,
		df.stockpile_group_set.cloth,
		df.stockpile_group_set.leather,
		df.stockpile_group_set.ammo,
		df.stockpile_group_set.sheet,
		df.stockpile_group_set.finished_goods,
		df.stockpile_group_set.weapons,
		df.stockpile_group_set.armor
	}

	local stockpile_db = {
		a={label='Animal', bit={df.stockpile_group_set.animals}},
		f={label='Food', bit={df.stockpile_group_set.food}, want_barrels=true},
		u={label='Furniture', bit={df.stockpile_group_set.furniture}},
		n={label='Coins', bit={df.stockpile_group_set.coins}, want_bins=true},
		y={label='Corpses', bit={df.stockpile_group_set.corpses}},
		r={label='Refuse', bit={df.stockpile_group_set.refuse}},
		s={label='Stone', bit={df.stockpile_group_set.stone}, want_wheelbarrows=true},
		w={label='Wood', bit={df.stockpile_group_set.wood}},
		e={label='Gem', bit={df.stockpile_group_set.gems}, want_bins=true},
		b={label='Bar/Block', bit={df.stockpile_group_set.bars_blocks}, want_bins=true},
		h={label='Cloth', bit={df.stockpile_group_set.cloth}, want_bins=true},
		l={label='Leather', bit={df.stockpile_group_set.leather}, want_bins=true},
		z={label='Ammo', bit={df.stockpile_group_set.ammo}, want_bins=true},
		S={label='Sheets', bit={df.stockpile_group_set.sheet}, want_bins=true},
		g={label='Finished Goods', bit={df.stockpile_group_set.finished_goods}, want_bins=true},
		p={label='Weapons', bit={df.stockpile_group_set.weapons}, want_bins=true},
		d={label='Armor', bit={df.stockpile_group_set.armor}, want_bins=true},
		q={label='All', bit=all_bits, want_bins=true},
		c={label='Custom', bit={}}
	}

	for _, v in pairs(stockpile_db) do utils.assign(v, stockpile_template) end

	return stockpile_db
end

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
	imgui.EatMouseInputs()

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

	local world_pos = render.get_mouse_world_coordinates()

	if use_extents then
		building_w = clamp(building_w, quickfort_building.min_width, quickfort_building.max_width)
		building_h = clamp(building_h, quickfort_building.min_height, quickfort_building.max_height)
	else
		building_w = quickfort_building.min_width
		building_h = quickfort_building.min_height
	end

	local width = math.floor((building_w - 1) / 2)
	local height = math.floor((building_h - 1) / 2)

	local build_pos = {x=world_pos.x-width, y=world_pos.y-height, z=world_pos.z}
	local size = {x=building_w, y=building_h}

	local build_col = COLOR_RED

	function none(fields, tiles)

	end

	if handle_construct(build_type, build_subtype, build_pos, {x=building_w, y=building_h}, use_extents, false, true, none) then
		build_col = COLOR_GREEN
	end

	for x=build_pos.x,(build_pos.x+building_w-1) do
		for y=build_pos.y,(build_pos.y+building_h-1) do
			local pos = {x=x, y=y, z=world_pos.z}

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

function fill_vec1(vec, num)
	vec:resize(0)

	for i=0,(num-1) do
		vec:insert('#', 1)
	end
end

function get_leathers_count()
	local leather_count = 0

	for _,c in pairs(df.creature_raw.get_vector()) do
		for d,v in pairs(c.material) do
			if v and v.flags.LEATHER then
				leather_count = leather_count+1
			end
		end
	end

	return leather_count
end

function count_mats(list, flags)
	local count = 0

	for _,v in pairs(list) do
		for _,m in pairs(v.material) do
			local all_flags = true

			for name,k in pairs(flags) do
				if m.flags[k] ~= true then
					all_flags = false
				end
			end

			if all_flags == true then
				count = count + 1
			end
		end
	end

	return count
end

function set_quality(q)
	for _,v in ipairs(q) do
		v = true
	end
end

--tested in 50.05
function setup_stockpile_type(sett, type)
	sett.flags[type] = true

	set_quality(sett.furniture.quality_core)
	set_quality(sett.furniture.quality_total)

	set_quality(sett.ammo.quality_core)
	set_quality(sett.ammo.quality_total)

	set_quality(sett.finished_goods.quality_core)
	set_quality(sett.finished_goods.quality_total)

	set_quality(sett.weapons.quality_core)
	set_quality(sett.weapons.quality_total)

	set_quality(sett.armor.quality_core)
	set_quality(sett.armor.quality_total)

	sett.allow_organic = true
	sett.allow_inorganic = true

	if type == df.stockpile_group_set.furniture then
		sett.animals.empty_cages = true
		sett.animals.empty_traps = true

		sett.food.prepared_meals = true
		sett.refuse.fresh_raw_hide = true
		sett.refuse.rotten_raw_hide = true

		--not sure why +2
		local type_c = df.furniture_type._last_item + 2

		fill_vec1(sett.furniture.type, type_c)

		--313 in current save
		local mats = df.global.world.raws.inorganics

		fill_vec1(sett.furniture.mats, #mats)

		--stockpileserializer furniture_setup_other_mats
		fill_vec1(sett.furniture.other_mats, 15)
	end

	if type == df.stockpile_group_set.ammo then
		sett.animals.empty_traps = true
		sett.refuse.rotten_raw_hide = true

		fill_vec1(sett.ammo.type, #df.global.world.raws.itemdefs.ammo)

		--wood + bone
		fill_vec1(sett.ammo.other_mats, 2)

		fill_vec1(sett.ammo.mats, #df.global.world.raws.inorganics)
	end

	if type == df.stockpile_group_set.gems then
		sett.animals.empty_cages = true
		sett.animals.empty_traps = true
		sett.food.prepared_meals = true
		sett.refuse.fresh_raw_hide = true
		sett.refuse.rotten_raw_hide = true

		fill_vec1(sett.gems.rough_mats, #df.global.world.raws.inorganics)
		fill_vec1(sett.gems.cut_mats, #df.global.world.raws.inorganics)

		--don't really understand why its all mats, but the numbers line up!
		local other_mats = #df.global.world.raws.mat_table.builtin

		--600 something
		fill_vec1(sett.gems.rough_other_mats, other_mats)
		fill_vec1(sett.gems.cut_other_mats, other_mats)
	end

	if type == df.stockpile_group_set.animals then
		sett.animals.empty_cages = true
		sett.animals.empty_traps = true

		--1109
		fill_vec1(sett.animals.enabled, #df.global.world.raws.creatures.all)

		sett.food.prepared_meals = true
		sett.refuse.fresh_raw_hide = true
		sett.weapons.usable = true
		sett.armor.usable = true
	end

	if type == df.stockpile_group_set.leather then
		local leather_count = get_leathers_count()

		--811
		fill_vec1(sett.leather.mats, leather_count)
	end

	if type == df.stockpile_group_set.armor then
		sett.animals.empty_cages = true
		sett.animals.empty_traps = true
		sett.food.prepared_meals = true
		sett.refuse.fresh_raw_hide = true
		sett.refuse.rotten_raw_hide = true
		sett.armor.usable = true
		sett.armor.unusable = true

		fill_vec1(sett.armor.body, #df.global.world.raws.itemdefs.armor)
		fill_vec1(sett.armor.head, #df.global.world.raws.itemdefs.helms)
		fill_vec1(sett.armor.feet, #df.global.world.raws.itemdefs.shoes)
		fill_vec1(sett.armor.hands, #df.global.world.raws.itemdefs.gloves)
		fill_vec1(sett.armor.legs, #df.global.world.raws.itemdefs.pants)
		fill_vec1(sett.armor.shield, #df.global.world.raws.itemdefs.shields)
		--weapons_armor_setup_other_mats
		fill_vec1(sett.armor.other_mats, 10)

		fill_vec1(sett.armor.mats, #df.global.world.raws.inorganics)
	end

	if type == df.stockpile_group_set.refuse then
		sett.refuse.fresh_raw_hide = true
		sett.refuse.rotten_raw_hide = true
		sett.weapons.usable = true
		sett.weapons.unusable = true

		local corpse_guess = 0

		for _,v in pairs(df.global.world.raws.creatures.all) do
			--not sure about the second flag
			if v.flags.SMALL_RACE and not v.flags.ARTIFICIAL_HIVEABLE then
				corpse_guess = corpse_guess + 1
			end
		end

		if corpse_guess ~= 113 then
			dfhack.println("Warning: Corpse guess is not 113, not sure if it works")
		end

		fill_vec1(sett.refuse.corpses, corpse_guess)

		local animals = #df.global.world.raws.creatures.all

		fill_vec1(sett.refuse.body_parts, animals)
		fill_vec1(sett.refuse.skulls, animals)
		fill_vec1(sett.refuse.bones, animals)
		fill_vec1(sett.refuse.hair, animals)
		fill_vec1(sett.refuse.shells, animals)
		fill_vec1(sett.refuse.teeth, animals)
		fill_vec1(sett.refuse.horns, animals)
		fill_vec1(sett.refuse.anon_1, animals)
	end

	if type == df.stockpile_group_set.bars_blocks then
		--bars_blocks_setup_other_mats
		fill_vec1(sett.bars_blocks.bars_other_mats, 5)
		fill_vec1(sett.bars_blocks.blocks_other_mats, 4)

		fill_vec1(sett.bars_blocks.bars_mats, #df.global.world.raws.inorganics)
		fill_vec1(sett.bars_blocks.blocks_mats, #df.global.world.raws.inorganics)
	end

	if type == df.stockpile_group_set.sheet then
		--appears to be:
		--cotton, help, jute, kenaf, linen, papyrus, pig tail, ramie, and rope reed
		fill_vec1(sett.sheet.paper, 9)

		local leather_count = get_leathers_count()

		fill_vec1(sett.sheet.parchment, leather_count)
	end

	if type == df.stockpile_group_set.cloth then
		local silks = 0

		for _,c in pairs(df.creature_raw.get_vector()) do
			for d,v in pairs(c.material) do
				if v and v.flags.SILK then
					silks = silks+1
				end
			end
		end

		for _,c in pairs(df.global.world.raws.inorganics) do
			if c and c.material.flags.SILK then
				silks = silks+1
			end
		end

		fill_vec1(sett.cloth.thread_silk, silks)
		fill_vec1(sett.cloth.cloth_silk, silks)

		local plant = 0

		for _,v in pairs(df.global.world.raws.plants.all) do
			if v.flags.THREAD then
				plant = plant + 1
			end
		end

		fill_vec1(sett.cloth.thread_plant, plant)
		fill_vec1(sett.cloth.cloth_plant, plant)

		local yarnable = 0

		for _,c in pairs(df.creature_raw.get_vector()) do
			for k,v in pairs(c.caste) do
				local layers = #v.shearable_tissue_layer

				layers = math.min(layers, 1)

				yarnable = yarnable + layers

				if layers == 1 then
					goto done
				end
			end

			::done::
		end

		fill_vec1(sett.cloth.thread_yarn, yarnable)
		fill_vec1(sett.cloth.cloth_yarn, yarnable)

		local metal = 0

		for k,v in pairs(df.global.world.raws.inorganics) do
			if #v.thread_metal.mat_index > 0 then
				metal = metal + 1
			end
		end

		fill_vec1(sett.cloth.thread_metal, metal)
		fill_vec1(sett.cloth.cloth_metal, metal)
	end

	if type == df.stockpile_group_set.stone then
		sett.refuse.fresh_raw_hide = true
		sett.refuse.rotten_raw_hide = true

		fill_vec1(sett.stone.mats, #df.global.world.raws.inorganics)
	end

	if type == df.stockpile_group_set.coins then
		sett.animals.empty_cages = true
		sett.animals.empty_traps = true
		sett.food.prepared_meals = true
		sett.refuse.fresh_raw_hide = true
		sett.refuse.rotten_raw_hide = true

		fill_vec1(sett.coins.mats, #df.global.world.raws.inorganics)
	end

	if type == df.stockpile_group_set.weapons then
		fill_vec1(sett.weapons.weapon_type, #df.global.world.raws.itemdefs.weapons)
		fill_vec1(sett.weapons.trapcomp_type, #df.global.world.raws.itemdefs.trapcomps)

		--weapons_armor_setup_other_mats
		fill_vec1(sett.weapons.other_mats, 10)
		fill_vec1(sett.weapons.mats, #df.global.world.raws.inorganics)

		sett.weapons.usable = true
		sett.weapons.unusable = true
	end

	if type == df.stockpile_group_set.corpses then
		sett.animals.empty_cages = true
		sett.animals.empty_traps = true
		sett.food.prepared_meals = true

		fill_vec1(sett.refuse.type, #df.global.world.raws.creatures.all)

		sett.refuse.fresh_raw_hide = true
		sett.refuse.rotten_raw_hide = true
	end

	if type == df.stockpile_group_set.wood then
		--this makes 0 sense to me. Why is it all plants? I mean it *is* all plants, but I don't get it
		--because eg thread isn't all metals, its just specifically filtered threads
		--<insert shrug>
		fill_vec1(sett.wood.mats, #df.global.world.raws.plants.all)
	end

	if type == df.stockpile_group_set.finished_goods then
		--so, the stockpile serializer just hardcodes 112 in
		--and I found this was 113 across two saves on 50.xx
		--suspiciously, exactly the same as the number of corpses in a refuse pile
		--the stockpile serialiser also sets type to be 112 large in a refuse stockpile
		--but observed it as always being 0
		fill_vec1(sett.finished_goods.type, 113)
		--finished_goods_setup_other_mats
		fill_vec1(sett.finished_goods.other_mats, 16)
		fill_vec1(sett.finished_goods.mats, #df.global.world.raws.inorganics)
	end

	if type == df.stockpile_group_set.food then
		local meat_count = count_mats(df.global.world.raws.creatures.all, {df.material_flags.MEAT})

		--no idea why the +2 is there other than to make numbers work. Stable across 2 saves
		fill_vec1(sett.food.meat, meat_count + 2)

		local fish_count = 0

		for _,c in pairs(df.creature_raw.get_vector()) do
			for k,v in pairs(c.caste) do
				if v.misc.fish_mat_index ~= -1 then
					fish_count = fish_count + 1
				end
			end
		end

		fill_vec1(sett.food.fish, fish_count)
		fill_vec1(sett.food.unprepared_fish, fish_count)

		local egg_count = 0

		for _,c in pairs(df.creature_raw.get_vector()) do
			for k,v in pairs(c.caste) do
				if v.misc.egg_mat_index ~= -1 then
					egg_count = egg_count + 1
				end
			end
		end

		fill_vec1(sett.food.egg, egg_count)

		fill_vec1(sett.food.plants, #df.global.world.raws.plants.all)

		local drink_plant = 0

		for _,v in pairs(df.global.world.raws.plants.all) do
			if v.flags.DRINK then
				drink_plant = drink_plant+1
			end
		end

		fill_vec1(sett.food.drink_plant, drink_plant)

		local drink_animal = count_mats(df.global.world.raws.creatures.all, {df.material_flags.ALCOHOL})

		fill_vec1(sett.food.drink_animal, drink_animal)

		local cheese_plants = count_mats(df.global.world.raws.plants.all, {df.material_flags.CHEESE_PLANT})

		fill_vec1(sett.food.cheese_plant, cheese_plants)

		local cheese_animals = count_mats(df.global.world.raws.creatures.all, {df.material_flags.CHEESE_CREATURE})

		fill_vec1(sett.food.cheese_animal, cheese_animals)

		local seeds = count_mats(df.global.world.raws.plants.all, {df.material_flags.SEED_MAT})

		fill_vec1(sett.food.seeds, seeds)

		local leaf_mat = count_mats(df.global.world.raws.plants.all, {df.material_flags.LEAF_MAT})

		fill_vec1(sett.food.leaves, leaf_mat)

		local powder_plant = count_mats(df.global.world.raws.plants.all, {df.material_flags.POWDER_MISC_PLANT})

		fill_vec1(sett.food.powder_plant, powder_plant)

		local powder_creature = count_mats(df.global.world.raws.creatures.all, {df.material_flags.POWDER_MISC_CREATURE})

		fill_vec1(sett.food.powder_creature, powder_creature)

		local glob = count_mats(df.global.world.raws.plants.all, {df.material_flags.STOCKPILE_GLOB}) + count_mats(df.global.world.raws.creatures.all, {df.material_flags.STOCKPILE_GLOB})

		fill_vec1(sett.food.glob, glob)

		local paste = count_mats(df.global.world.raws.plants.all, {df.material_flags.STOCKPILE_GLOB_PASTE}) + count_mats(df.global.world.raws.creatures.all, {df.material_flags.STOCKPILE_GLOB_PASTE})
		local pressed = count_mats(df.global.world.raws.plants.all, {df.material_flags.STOCKPILE_GLOB_PRESSED}) + count_mats(df.global.world.raws.creatures.all, {df.material_flags.STOCKPILE_GLOB_PRESSED})

		fill_vec1(sett.food.glob_paste, paste)
		fill_vec1(sett.food.glob_pressed, pressed)

		local liquid_plant = count_mats(df.global.world.raws.plants.all, {df.material_flags.LIQUID_MISC_PLANT})
		local liquid_animal = count_mats(df.global.world.raws.creatures.all, {df.material_flags.LIQUID_MISC_CREATURE})

		fill_vec1(sett.food.liquid_plant, liquid_plant)
		fill_vec1(sett.food.liquid_animal, liquid_animal)

		local liquid_misc = 0

		liquid_misc = count_mats(df.global.world.raws.plants.all, {df.material_flags.LIQUID_MISC_OTHER}) +
				 count_mats(df.global.world.raws.creatures.all, {df.material_flags.LIQUID_MISC_OTHER})

		--milk of lime
		for _,m in pairs(df.global.world.raws.inorganics) do
			if m.material.flags.LIQUID_MISC_OTHER then
				liquid_misc = liquid_misc + 1
			end
		end

		for _,m in pairs(df.global.world.raws.mat_table.builtin) do
			if m and m.flags.LIQUID_MISC_OTHER then
				liquid_misc = liquid_misc + 1
			end
		end

		--LYE. Doesn't seem to exist in the raws anywhere I can find?
		liquid_misc = liquid_misc + 1

		fill_vec1(sett.food.liquid_misc, liquid_misc)

		sett.food.prepared_meals = true
	end
end

function trigger_stockpile(tl, size, dry_run, stockpile_type)
	local quickfort_building = get_stockpile_db()[stockpile_type]

	local build_type = df.building_type.Stockpile

	local use_extents = true

	local building_w = clamp(size.x, quickfort_building.min_width, quickfort_building.max_width)
	local building_h = clamp(size.y, quickfort_building.min_height, quickfort_building.max_height)

	local build_pos = {x=tl.x, y=tl.y, z=tl.z}

	function setup(fields, ntiles)
		local db_entry = get_stockpile_db()[stockpile_type]

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
		local building = handle_construct(build_type, nil, build_pos, {x=building_w, y=building_h}, use_extents, true, false, setup)

		if building then
			local bit = get_stockpile_db()[stockpile_type].bit

			for _,v in ipairs(bit) do
				setup_stockpile_type(building.settings, v)
			end
		end
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

function remove_extent(building, v, is_zone)
	if building == nil then
		return
	end

	if building.room == nil or building.room.extents == nil then
		return
	end

	local lx = v.x - building.room.x
	local ly = v.y - building.room.y

	if lx < 0 or ly < 0 or lx >= building.room.width or ly >= building.room.height then
		return
	end

	local idx = lx + ly * building.room.width

	if building.room.extents[idx] == df.building_extents_type.None then
		return
	end

	building.room.extents[idx] = df.building_extents_type.None

	dfhack.buildings.notifyCivzoneModified(building)

	local chunk = dfhack.maps.getTileBlock({x=v.x, y=v.y, z=v.z})

	local des = chunk.designation[(v.x)&15][(v.y)&15]
	local occ = chunk.occupancy[(v.x)&15][(v.y)&15]

	if not is_zone then
		des.pile = false
		occ.building = df.tile_building_occ.None
	end

	kill_ifempty_building(building)
end

function render_stockpiles()
	render.set_can_window_pop(true)
	render.menu_popping_pops_everything = true

	local to_render = {}
	local value_to_key = {None="a", ["Remove Designation"]="x"}
	local key_to_value = {x="Remove Designation"}

	local render_order = {"a","f","u","n","y","r","s","w","e","b","h","l","z","S","g","p","d","c","q"}

	for k, v in ipairs(render_order) do
		local d = {key=v, text=get_stockpile_db()[v].label}

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

	local stockpile_type = value_to_key[next_description]

	if imgui.Button("Back") then
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

		trigger_stockpile(start_pos, size, false, stockpile_type)
	end

	if should_trigger_mouse and (next_description == "Remove Designation" or render.mouse_which_clicked == 1) then
		for k, v in ipairs(tiles) do
			local building = dfhack.buildings.findAtTile(xyz2pos(v.x, v.y, v.z))

			remove_extent(building, v, false)
		end
	end

	render.set_menu_item(stockpile_type)
end

--building subtypes are the low level subtypes, tomb, meeting hall etc
function trigger_zone(tl, size, dry_run, subtype)
	local build_type = df.building_type.Civzone

	local use_extents = true

	building_w = math.max(size.x, 1)
	building_h = math.max(size.y, 1)

	local build_pos = {x=tl.x, y=tl.y, z=tl.z}

	function setup(fields, ntiles)
	end

	local build_col = COLOR_RED

	if handle_construct(build_type, subtype, build_pos, {x=building_w, y=building_h}, use_extents, true, true, setup) then
		build_col = COLOR_GREEN
	end

	for x=build_pos.x,(build_pos.x+building_w-1) do
		for y=build_pos.y,(build_pos.y+building_h-1) do
			local pos = {x=x+1, y=y+1, z=tl.z}

			render.render_absolute_text("X", build_col, COLOR_BLACK, pos)
		end
	end

	if not dry_run then
		local bld, err = handle_construct(build_type, subtype, build_pos, {x=building_w, y=building_h}, use_extents, true, false, setup)

		if bld then
			finalise_zone(bld, subtype)
		end
	end
end

function max_zone_num()
	local max_id = 0

	for _,v in ipairs(df.building.get_vector()) do
		if df.building_civzonest:is_instance(v) then
			max_id = math.max(max_id, v.zone_num)
		end
	end

	return max_id
end

function finalise_zone(building, subtype)
	if not df.building_civzonest:is_instance(building) then
		dfhack.println("WTF")
		return
	end

	building.type = subtype
	building.is_active = 8
	building.anon_1 = -1
	building.anon_2 = -1
	--building.zone_num = max_zone_num() + 1

	building.zone_settings.whole.i1 = 0
	building.zone_settings.whole.i2 = 0

	if building.type == df.civzone_type.ArcheryRange then
		building.zone_settings.archery.dir_x = 1
		building.zone_settings.archery.dir_y = 0
	end

	if building.type == df.civzone_type.PlantGathering then
		building.zone_settings.gather.pick_trees = true
		building.zone_settings.gather.pick_shrubs = true
		building.zone_settings.gather.gather_fallen = true
	end

	if building.type == df.civzone_type.Pen then
		building.zone_settings.pen.unk = 1
	end

	if building.type == df.civzone_type.Tomb then
		building.zone_settings.tomb.no_pets = true
	end

	if building.type == df.civzone_type.Pond then
		building.zone_settings.pit_pond = df.building_civzonest.T_zone_settings.T_pit_pond.top_of_pit
	end

	building.anon_3 = -1

	building.assigned_unit_id = -1
	--building.anon_4 = -1
	building.anon_5 = -1
	building.anon_6 = -1
	building.anon_7 = -1
end

function get_assignable_units()
	local valid = {}

	local units = df.global.world.units.active

	for _,v in ipairs(units) do
        if dfhack.units.isFortControlled(v) and not
		   dfhack.units.isAnimal(v) and not
		   dfhack.units.isHidden(v) and not
		   dfhack.units.isKilled(v) then
			valid[#valid + 1] = v
        end
	end

	return valid
end


function remove_current_assigned(zone)
	for _,unit in ipairs(df.global.world.units.active) do
		for i=(#unit.owned_buildings-1),0,-1 do
			if unit.owned_buildings[i] == zone then
				unit.owned_buildings:erase(i)
			end
		end
	end
end

function assign_to_zone(zone, unit)
	remove_current_assigned(zone)

	local spouse = df.unit.find(unit.relationship_ids.Spouse)

	unit.owned_buildings:insert('#', zone)

	if spouse then
		--dfhack.println("Spose")
		spouse.owned_buildings:insert('#', zone)
	end
end

function get_assignment_display_name(unit)
	local name = render.get_user_facing_name(unit)

	local spouse = df.unit.find(unit.relationship_ids.Spouse)

	if spouse then
		name = name .. "\n          " .. render.get_user_facing_name(spouse) .. " (spouse)"
	else
		name = name .. "\n "
	end

	return name
end

function handle_specific_zone_render(building)
	if building.type == df.civzone_type.ArcheryRange then
		local base_render = {{key="l", text="L"}, {key="r", text="R"}, {key="t", text="T"}, {key="b", text="B"}}

		local highlight_index = 0

		if building.zone_settings.archery.dir_x == -1 then
			highlight_index = 0
		end

		if building.zone_settings.archery.dir_x == 1 then
			highlight_index = 1
		end

		if building.zone_settings.archery.dir_y == -1 then
			highlight_index = 2
		end

		if building.zone_settings.archery.dir_y == 1 then
			highlight_index = 3
		end

		base_render[highlight_index + 1].highlight = true

		local rendered = render.render_table_impl(base_render, "None")

		if rendered == "L" then
			building.zone_settings.archery.dir_x = -1
			building.zone_settings.archery.dir_y = 0
		end

		if rendered == "R" then
			building.zone_settings.archery.dir_x = 1
			building.zone_settings.archery.dir_y = 0
		end

		if rendered == "T" then
			building.zone_settings.archery.dir_x = 0
			building.zone_settings.archery.dir_y = -1
		end

		if rendered == "B" then
			building.zone_settings.archery.dir_x = 0
			building.zone_settings.archery.dir_y = 1
		end
	end

	if building.type == df.civzone_type.PlantGathering then
		local base_render = {{key="1", text="Gather Fruit From Trees"}, {key="2", text="Gather Plants From Shrubs"}, {key="3", text="Gather Fallen Fruit"}}

		if building.zone_settings.gather.pick_trees then
			base_render[1].highlight = true
		end

		if building.zone_settings.gather.pick_shrubs then
			base_render[2].highlight = true
		end

		if building.zone_settings.gather.gather_fallen then
			base_render[3].highlight = true
		end

		local text, clicked, which_clicked = render.render_table_impl(base_render, "None")

		if which_clicked == 1 then
			building.zone_settings.gather.pick_trees = not building.zone_settings.gather.pick_trees
		end

		if which_clicked == 2 then
			building.zone_settings.gather.pick_shrubs = not building.zone_settings.gather.pick_shrubs
		end

		if which_clicked == 3 then
			building.zone_settings.gather.gather_fallen = not building.zone_settings.gather.gather_fallen
		end
	end

	if building.type == df.civzone_type.Tomb then
		local base_render = {{key="1", text="No Pets"}, {key="2", text="No Citizens"}}

		if building.zone_settings.tomb.no_pets then
			base_render[1].highlight = true
		end

		if building.zone_settings.tomb.no_citizens then
			base_render[2].highlight = true
		end

		local text, clicked, which_clicked = render.render_table_impl(base_render, "None")

		if which_clicked == 1 then
			building.zone_settings.tomb.no_pets = not building.zone_settings.tomb.no_pets
		end

		if which_clicked == 2 then
			building.zone_settings.tomb.no_citizens = not building.zone_settings.tomb.no_citizens
		end
	end

	if building.type == df.civzone_type.Pond then
		local base_render = {{key="1", text="Top of Pit"}, {key="2", text="Top of Pond"}}

		if building.zone_settings.pit_pond == df.building_civzonest.T_zone_settings.T_pit_pond.top_of_pit then
			base_render[1].highlight = true
		end

		if building.zone_settings.pit_pond == df.building_civzonest.T_zone_settings.T_pit_pond.top_of_pond then
			base_render[2].highlight = true
		end

		local text, clicked, which_clicked = render.render_table_impl(base_render, "None")

		if which_clicked == 1 then
			building.zone_settings.pit_pond = df.building_civzonest.T_zone_settings.T_pit_pond.top_of_pit
		end

		if which_clicked == 2 then
			building.zone_settings.pit_pond = df.building_civzonest.T_zone_settings.T_pit_pond.top_of_pond
		end
	end

	local force_once = false

	if building.type == df.civzone_type.Barracks then
		local entity = df.historical_entity.find(df.global.plotinfo.group_id)
		local sorted_squads = military.get_sorted_squad_ids_by_precedence(entity.squads)

		local max_squad_name = 0

		for _, s_id in ipairs(sorted_squads) do
			max_squad_name = math.max(max_squad_name, #military.get_squad_name(df.squad.find(s_id)))
		end

		--[[imgui.Text("Zone ID", tostring(building.id))

		for _,v in ipairs(building.squad_room_info) do
			imgui.Text("Contains", tostring(v.squad_id))
		end]]--

		for _, s_id in ipairs(sorted_squads) do
			local squad = df.squad.find(s_id)

			local name = military.get_squad_name(squad)

			for i=#name,max_squad_name do
				name = name .. " "
			end

			local s_flag = false
			local t_flag = false
			local i_flag = false
			local e_flag = false

			for _, room in ipairs(squad.rooms) do
				if room.building_id == building.id then
					s_flag = room.mode.sleep
					t_flag = room.mode.train
					i_flag = room.mode.indiv_eq
					e_flag = room.mode.squad_eq

					break
				end
			end

			--[[imgui.Text("Squad id", tostring(squad.id))

			for _, room in ipairs(squad.rooms) do
				imgui.Text(tostring(room.building_id))

				imgui.SameLine()
			end]]--

			imgui.Text(name)

			local i_s_flag = imgui.Ref(s_flag)
			local i_t_flag = imgui.Ref(t_flag)
			local i_i_flag = imgui.Ref(i_flag)
			local i_e_flag = imgui.Ref(e_flag)

			function local_tooltip(str)
				if force_once then
					return
				end

				imgui.SetNextWindowSize({x=40, y=0}, 0)

				imgui.BeginTooltip()
				imgui.TextWrapped(str)
				imgui.EndTooltip()

				force_once = true
			end

			imgui.SameLine()

			imgui.Checkbox("S##" .. tostring(s_id), i_s_flag)

			if imgui.IsItemHovered() then
				local_tooltip("Toggle whether the squad will sleep here")
			end

			imgui.SameLine()

			imgui.Checkbox("T##" .. tostring(s_id), i_t_flag)

			if imgui.IsItemHovered() then
				local_tooltip("Toggle whether the squad will train here")
			end

			imgui.SameLine()

			imgui.Checkbox("I##" .. tostring(s_id), i_i_flag)

			if imgui.IsItemHovered() then
				local_tooltip("Toggle whether the soldiers will store their individually assigned weapons and armour here")
			end

			imgui.SameLine()

			imgui.Checkbox("E##" .. tostring(s_id), i_e_flag)

			if imgui.IsItemHovered() then
				local_tooltip("Toggle whether the squad will store squad-level equipment here, such as ammunition")
			end

			local flags = {sleep=imgui.Get(i_s_flag), train=imgui.Get(i_t_flag), indiv_eq=imgui.Get(i_i_flag), squad_eq=imgui.Get(i_e_flag)}

			dfhack.units.updateRoomAssignments(squad.id, building.id, flags)
		end
	end

	--todo: archery range allows training squads. Works exactly the same just with only train flag
	--todo: pit/pond and pen/pasture allow assigned animals
	--dining hall, office, bedroom, and tomb allow assigning units

	if building.type == df.civzone_type.DiningHall or
	   building.type == df.civzone_type.Office or
	   building.type == df.civzone_type.Bedroom or
	   building.type == df.civzone_type.Tomb then
		local name = "None"

		if building.assigned_unit_id ~= -1 then
			local unit = building.assigned_unit

			if unit ~= nil then
				name = get_assignment_display_name(unit)
			else
				name = "Error"
			end
		end

		if imgui.TreeNode("Assigned: " .. name .. "###assignbox") then
			local assignable = get_assignable_units()

			local opts = {paginate=true, leave_vacant=true}

			local clicked = render.display_unit_list(assignable, opts)

			if clicked ~= nil and clicked.type == "vacant" then
				remove_current_assigned(building)

				building.assigned_unit_id = -1
				building.assigned_unit = nil
			end

			if clicked ~= nil and clicked.type == "unit" then
				assign_to_zone(building, clicked.data)

				building.assigned_unit_id = clicked.data.id
				building.assigned_unit = clicked.data
			end

			imgui.TreePop()
		end
	end

	local current_location = locations.get_zone_location(building)

	local name = "None"

	if current_location then
		name = locations.get_location_name(current_location) .. " (" .. locations.get_location_type_name(current_location:getType(), false) .. ")"
	end

	if imgui.TreeNode("Location: "..name .. "###locationselect") then
		local which_id = locations.display_location_selector(building)

		--[[if which_id.type == "button" then
			locations.on_make_new(building, which_id.extra)
		end]]--

		if which_id.type == "location" then
			locations.on_assign_location(building, which_id.data)
		end

		if which_id.type == "vacant" then
			locations.on_assign_location(building, nil)
		end

		imgui.TreePop()
	end

	--[[if imgui.TreeNode("Role Select") then

	end]]--

	imgui.NewLine()

	local to_render = {}
	to_render[#to_render+1] = {key="R", text="Delete Zone"}

	local picked = render.render_table_impl(to_render, "None")

	if picked == "Delete Zone" then
		if dfhack.buildings.markedForRemoval(building) then
			return
		end

		dfhack.buildings.deconstruct(building)
	end
end

function get_subtype_map()
	local subtype_map = {
		["Meeting Area"]=df.civzone_type.MeetingHall,
		["Office"]=df.civzone_type.Office,
		["Bedroom"]=df.civzone_type.Bedroom,
		["Dormitory"]=df.civzone_type.Dormitory,
		["Dining Hall"]=df.civzone_type.DiningHall,
		["Barracks"]=df.civzone_type.Barracks,
		["Pen/Pasture"]=df.civzone_type.Pen,
		["Archery Range"]=df.civzone_type.ArcheryRange,
		["Pit/Pond"]=df.civzone_type.Pond,
		["Garbage Dump"]=df.civzone_type.Dump,
		["Tomb"]=df.civzone_type.Tomb,
		["Fishing"]=df.civzone_type.FishingArea,
		["Gather Fruit"]=df.civzone_type.PlantGathering,
		["Sand"]=df.civzone_type.SandCollection,
		["Clay"]=df.civzone_type.ClayCollection,
		["Water Source"]=df.civzone_type.WaterSource,
		["Dungeon"]=df.civzone_type.Dungeon,
		["Animal Training"]=df.civzone_type.AnimalTraining
	}

	return subtype_map
end

subtype_map = get_subtype_map()

function get_inverse_subtype_map()
	local inverse_subtype_map = {}

	local local_subtype_map = get_subtype_map()

	for k,v in pairs(local_subtype_map) do
		inverse_subtype_map[v] = k
	end

	return inverse_subtype_map
end

inverse_subtype_map = get_inverse_subtype_map()

function get_zone_name(building)
	local name = building.name

	if #name == 0 then
		return inverse_subtype_map[building.type] .. " #" .. tostring(building.zone_num)
	end

	return name
end

function render_zones()
	local to_render = {{key="s", text="Select Zone"}, {key="z", text="Place Zone"}, {key="x", text="Remove Zones"}}
	local zone_render = {{key="m", text="Meeting Area"}, {key="o", text="Office"}, {key="b", text="Bedroom"}, {key="r", text="Dormitory"},
						 {key="i", text="Dining Hall"}, {key="k", text="Barracks"}, {key="n", text="Pen/Pasture"},
						 {key="y", text="Archery Range"}, {key="p", text="Pit/Pond"}, {key="d", text="Garbage Dump"},
					  	 {key="w", text="Water Source"}, {key="t", text="Animal Training"}, {key="u", text="Dungeon"},
					 	 {key="T", text="Tomb"}, {key="f", text="Fishing"}, {key="g", text="Gather Fruit"},
					  	 {key="s", text="Sand"}, {key="c", text="Clay"}}


	local current_state = render.get_submenu()

	if current_state == nil then
		current_state = {type='Select Zone', zone_type="Meeting Area", id=nil}
		render.push_transparent_submenu(current_state)
	end

	local in_zone_cfg = false

	if current_state.type == "Selected" then
		render.cancel_mouse_drag()

		local zone_id = current_state.id

		local building = df.building.find(zone_id)

		if building ~= nil then
			imgui.Text("Selected Zone")

			local type_name = inverse_subtype_map[building.type]
			local name = get_zone_name(building)

			if type_name ~= name then
				imgui.Text(type_name);
			end

			imgui.Text(name)

			handle_specific_zone_render(building)

			in_zone_cfg = true
		else
			--reset ui
			render.pop_all_submenus()
		end
	end

	if not in_zone_cfg then
		current_state.type = render.render_table_impl(to_render, current_state.type)
		current_state.zone_type = render.render_table_impl(zone_render, current_state.zone_type)

		render.pop_all_submenus()
		render.push_transparent_submenu(current_state)

		if imgui.Button("Back") then
			render.pop_menu()
		end

		render.check_start_mouse_drag()

		local tiles = render.get_dragged_tiles()

		render.check_end_mouse_drag()

		local should_trigger_mouse = render.check_trigger_mouse()

		if should_trigger_mouse and current_state.type == "Place Zone" and render.mouse_which_clicked == 0  then
			local start_pos = render.mouse_click_start
			local end_pos = render.mouse_click_end

			start_pos, end_pos = min3(start_pos, end_pos)

			local size = {x=end_pos.x - start_pos.x + 1, y=end_pos.y-start_pos.y + 1}

			local subtype = subtype_map[current_state.zone_type]

			trigger_zone(start_pos, size, false, subtype)
		end

		if should_trigger_mouse and (current_state.type == "Remove Zones" or render.mouse_which_clicked == 1) then
			for k, v in ipairs(tiles) do
				local zones = dfhack.buildings.findCivzonesAt(xyz2pos(v.x, v.y, v.z))

				if zones then
					for _,building in ipairs(zones) do
						remove_extent(building, v, true)
					end
				end
			end
		end
	end

	render.set_can_window_pop(true)
	render.set_can_mouse_pop(true)
end