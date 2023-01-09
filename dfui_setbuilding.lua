--@ module = true

workshops = reqscript("workshopreactions")
render = reqscript('dfui_render')
utils = require("utils")

imgui = dfhack.imgui

function add_job(building, job)
	--so
	--need a general_ref which is a building holder
	--general_ref_building_holderst

	--then need a job_item, the flags for which are all set by the job up above
	local ji_array = {}

	for k,v in ipairs(job.items) do
		local ji = df.job_item:new()

		ji.vector_id = 0
		ji.unk_v43_1 = 0
		ji.unk_v43_2 = -1
		ji.unk_v43_3 = -1
		ji.unk_v43_4 = 0
		ji.has_tool_use = -1

		for m,n in pairs(v) do
			ji[m] = n
		end

		ji_array[#ji_array+1] = ji
	end

	--imgui.Text("Mat_type: " .. ji.mat_type)
	--imgui.Text("mat_index: " .. ji.mat_index)

	local gr = df.general_ref_building_holderst:new()
	gr.building_id = building.id

	local out_job = df.job:new()

	--sets job_type
	for k,v in pairs(job.job_fields) do
		if k == "material_category" then
			goto skip
		end

		out_job[k] = v

		::skip::
	end

	--[[for k,v in pairs(job.job_fields.material_category) do
		out_job.material_category[k] = v
	end]]--

	if job.job_fields.material_category ~= nil then
		for k,v in pairs(job.job_fields.material_category) do
			out_job.material_category[k] = v
		end
	end

	out_job.pos.x = building.centerx
	out_job.pos.y = building.centery
	out_job.pos.z = building.z

	for _,v in ipairs(ji_array) do
		out_job.job_items:insert('#', v)
	end

	out_job.general_refs:insert('#', gr)

	building.jobs:insert('#', out_job)

	dfhack.job.linkIntoWorld(out_job)

	return true
end

function toggle_suspend(job)
	if job.flags.suspend then
		job.flags.suspend = 0
	else
		job.flags.suspend = 1
	end
end

function display_jobs(building, jobs)
	if jobs == nil then
		return false
	end

	local any_added = false

	for i,v in pairs(jobs) do
		if imgui.Button(dfhack.df2utf(v.name) .. "##" .. tostring(i)) and not any_added then
			if add_job(building, v) then
				any_added = true
			end
		end
	end

	return any_added
end

function mismatch_index(longer, shorter)
	if longer == nil and shorter == nil then
		return nil
	end

	if #longer == 0 and shorter == nil then
		return nil
	end

	if #longer > 0 and shorter == nil then
		return nil
	end

	if #shorter > #longer then
		return nil
	end

	for i=1,#shorter do
		if shorter[i] ~= longer[i] then
			return nil
		end
	end

	return #shorter + 1
end

function menu_eq(a, b)
	if a == nil and b == nil then
		return true
	end

	if #a == 0 and b == nil then
		return true
	end

	if #a ~= #b then
		return false
	end

	for i=1,#a do
		if a[i] ~= b[i] then
			return false
		end
	end

	return true
end

function jobs_by_menu(jobs, menu_stack)
	local result = {}
	local additional = {}

	for _,v in pairs(jobs) do
		if v.menu ~= nil then
			if #v.menu > #menu_stack then
				local pref = mismatch_index(v.menu, menu_stack)

				if pref == nil then
					goto nope
				end

				additional[v.menu[pref]] = true

				goto nope
			end
		end

		--imgui.Text(tostring(key))

		if menu_eq(menu_stack, v.menu) then
			result[#result+1] = v
		end

		::nope::
	end

	return result, additional
end

function get_job_name(j)
	--[[if #j.reaction_name > 0 then
		return j.reaction_name
	end

	return df.job_type.attrs[j.job_type].caption]]--

	return dfhack.df2utf(dfhack.job.getName(j))
end

function select(c, a, b)
	if c then
		return a
	end

	return b
end

function display_existing_jobs(building)
	local jobs = building.jobs

	local should_kill = {}

	for idx,j in ipairs(jobs) do
		local is_suspended = j.flags.suspend

		local col = COLOR_GREEN

		if is_suspended then
			col = COLOR_RED
		end

		if imgui.ButtonColored({fg=col}, "[S]##job_"..tostring(idx)) then
			toggle_suspend(j)
		end

		if imgui.IsItemHovered() then
			if j.flags.suspend then
				imgui.SetTooltip("unsuspend")
			else
				imgui.SetTooltip("suspend")
			end
		end

		imgui.SameLine()

		local repeat_col = select(j.flags["repeat"], COLOR_LIGHTBLUE, COLOR_DARKGREY)

		if imgui.ButtonColored({fg=repeat_col}, "[R]##repeat_"..tostring(idx)) then
			j.flags["repeat"] = not j.flags["repeat"]
		end

		if imgui.IsItemHovered() then
			imgui.SetTooltip("repeat")
		end

		imgui.SameLine()

		if imgui.ButtonColored({fg=COLOR_RED}, "[X]##cancel_"..tostring(idx)) then
			should_kill[idx] = true
		end

		if imgui.IsItemHovered() then
			imgui.SetTooltip("cancel")
		end

		imgui.SameLine()

		imgui.Text(get_job_name(j))

		if j.flags.working then
			imgui.SameLine()

			imgui.TextColored({fg=COLOR_LIGHTGREEN}, "A")
		end
	end

	for ix=#jobs-1,0,-1 do
		if should_kill[ix] then
			local current = jobs[ix]

			building.jobs:erase(ix)

			if not dfhack.job.removeJob(current) then
				dfhack.println("Something bad happened killing the job :(")
			end
		end
	end
end

job_cache = {}

function get_jobs(t, s, c, adv)
	for _,v in ipairs(job_cache) do
		if v.type == t and v.subtype == s then
			return v.jobs
		end
	end

	jobs = workshops.getJobs(t, s, c, adv)

	job_cache[#job_cache + 1] = {type=t, subtype=s, jobs=jobs}

	return jobs
end

function get_biomeFlagMap()
	local type = df.biome_type

	local map = {}

	for v=type._first_item,type._last_item do
		map[df.plant_raw_flags["BIOME_" .. tostring(df.biome_type[v])]] = v
	end

	for k,v in pairs(map) do
		if k == nil or v == nil then
			dfhack.println(df.plant_raw_flags[k], df.biome_type[v])
		end
	end

	return map
end

local flag_map = get_biomeFlagMap()

local seasons = {df.plant_raw_flags.SPRING, df.plant_raw_flags.SUMMER,
                 df.plant_raw_flags.AUTUMN, df.plant_raw_flags.WINTER}

local function is_plantable(plant, season_index)
	local has_seed = plant.flags.SEED
	local is_tree = plant.flags.TREE

	return has_seed and not is_tree and plant.flags[seasons[season_index]]
end

function any_set(plant, biome)
	for d,v in pairs(plant.flags) do
		if v then
			local converted = df.plant_raw_flags[d]

			if flag_map[converted] == biome then
				return true
			end
		end
	end

	return false
end

function get_plant_in_season(season, building)
	local plant_raws = {}

	for k,plant in ipairs(df.global.world.raws.plants.all) do
		if is_plantable(plant, season) then
			local rx, ry = dfhack.maps.getTileBiomeRgn(building.centerx, building.centery, building.z)

			local biome = dfhack.maps.GetBiomeType(rx, ry)

			local tile_flags = dfhack.maps.getTileFlags(building.centerx, building.centery, building.z)

			if tile_flags.subterranean then
				biome = df.biome_type.SUBTERRANEAN_WATER
			end

			if any_set(plant, biome) then
				plant_raws[#plant_raws+1] = plant
			end
		end
	end

	return plant_raws
end

function render_farm(building)
	local mouse_world_pos = render.get_mouse_world_coordinates()

	local season_plants = {}
	local max_rows = 0

	local counter = 1

	for season=1,4 do
		local plants = get_plant_in_season(season,building)

		season_plants[season] = plants
		max_rows = math.max(max_rows, #plants)
	end

	local bid = 0

	if imgui.BeginTable("Table", 4, (1 << 20)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();

		imgui.Text("Spring")
		imgui.TableNextColumn();
		imgui.Text("Summer")
		imgui.TableNextColumn();
		imgui.Text("Autumn")
		imgui.TableNextColumn();
		imgui.Text("Winter")

		imgui.TableNextRow();
		imgui.TableNextColumn();

		for row=1,max_rows do
			for season=1,4 do
				bid = bid + 1

				if row <= #season_plants[season] then
					local current_id = building.plant_id[season - 1]

					local set = false
					local off = false

					if current_id == season_plants[season][row].index then
						off = imgui.ButtonColored({fg=COLOR_LIGHTGREEN}, season_plants[season][row].name .. "##plnt" .. bid)
					else
						set = imgui.Button(season_plants[season][row].name .. "##plnt" .. bid)
					end

					local potential_index = season_plants[season][row].index

					if set then
						building.plant_id[season - 1] = potential_index
					end

					if off then
						building.plant_id[season - 1] = -1
					end
				end

				imgui.TableNextColumn()
			end
		end

		imgui.EndTable()
	end

	if imgui.IsMouseClicked(1) and render.get_menu_item().screen == "base" then
		render.pop_menu()
	end

	if imgui.IsMouseClicked(0) and not imgui.WantCaptureMouse() and dfhack.buildings.findAtTile(mouse_world_pos) ~= nil then
		render.set_menu_item({screen="base", pos=mouse_world_pos})
	end

	if imgui.IsMouseClicked(1) and imgui.WantCaptureMouse() then
		render.set_menu_item(nil)
	end
end

function render_setbuilding()
	local mouse_world_pos = render.get_mouse_world_coordinates()

	local state = {screen="base"}
	local selected_building = nil

	if render.get_menu_item() ~= nil then
		state = render.get_menu_item()
		selected_building = state.pos
	end

	if not imgui.WantCaptureMouse() and dfhack.buildings.findAtTile(mouse_world_pos) then
		selected_building = mouse_world_pos
	end

	if selected_building == nil then
		render.set_menu_item(nil)
		return
	end

	local next_state = utils.clone(state, true)
	local building = dfhack.buildings.findAtTile(selected_building)

	if building == nil then
		render.set_menu_item(nil)
		return
	end

	local name = utils.getBuildingName(building)

	imgui.Text(name)

	imgui.NewLine()

	if df.building_farmplotst:is_instance(building) then
		render_farm(building)
		return
	end

	local is_workshop = df.building_workshopst:is_instance(building)
	local is_furnace = df.building_furnacest:is_instance(building)

	local go_back = false

	local jobs = nil

	if is_workshop then
		jobs = get_jobs(df.building_type.Workshop, building.type, -1, true)
	end

	if is_furnace then
		jobs = get_jobs(df.building_type.Furnace, building.type, -1, true)
	end

	if state.screen == "Add new task" and jobs ~= nil then
		if state.subscreen == nil then
			state.subscreen = {}
			next_state.subscreen = {}
		end

		local real_jobs, categories = jobs_by_menu(jobs, state.subscreen)

		for k,v in pairs(categories) do
			if k ~= "" and imgui.Button(k .. "##setbuilding_" .. building.id) then
				table.insert(next_state.subscreen, k)
			end
		end

		if #state.subscreen > 0 then
			if imgui.Button("back##subback") or (imgui.IsMouseClicked(1) and imgui.WantCaptureMouse()) then
				table.remove(next_state.subscreen, #next_state.subscreen)
				go_back = true
			end
		end

		if display_jobs(building, real_jobs) then
			next_state.screen = "base"
			next_state.subscreen = {}
			go_back = true
		end

		if #state.subscreen == 0 and (imgui.Button("back##subback2") or (imgui.IsMouseClicked(1) and imgui.WantCaptureMouse())) and not go_back then
			next_state.screen = "base"
			next_state.subscreen = {}

			go_back = true
		end
	end

	if state.screen == "base" and jobs ~= nil then
		display_existing_jobs(building)

		imgui.NewLine()

		local strings = {{key="a", text="Add new task"}}

		local next = render.render_table_impl(strings, "none")

		if next == "Add new task" then
			next_state = {screen=next, pos=selected_building}
		end
	end

	render.set_menu_item(next_state)

	if imgui.IsMouseClicked(1) and state.screen == "base" then
		render.pop_menu()
	end

	if imgui.IsMouseClicked(0) and not imgui.WantCaptureMouse() and dfhack.buildings.findAtTile(mouse_world_pos) ~= nil then
		render.set_menu_item({screen="base", pos=mouse_world_pos})
	end

	if imgui.IsMouseClicked(1) and imgui.WantCaptureMouse() and not go_back then
		render.set_menu_item(nil)
	end
end