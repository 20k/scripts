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

function display_existing_jobs(building)
	local jobs = building.jobs
	
	for _,j in ipairs(jobs) do
		local is_suspended = j.flags.suspend
		
		local col = COLOR_GREEN
		
		if is_suspended then
			col = COLOR_RED
		end
		
		if imgui.ButtonColored({fg=col}, "[S]##job_"..tostring(j.id)) then
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
		
		imgui.Text(get_job_name(j))
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

function render_setbuilding()
	local mouse_world_pos = render.get_mouse_world_coordinates()
	
	local state = {screen="base"}
	local selected_building = mouse_world_pos
	
	if render.get_menu_item() ~= nil then
		state = render.get_menu_item()
		selected_building = state.pos
	end
	
	if selected_building == nil then
		selected_building = mouse_world_pos
	end
	
	local next_state = utils.clone(state, true)
	
	local building = dfhack.buildings.findAtTile(selected_building)
	
	if building == nil then
		render.set_menu_item(nil)
		return
	end

	local is_workshop = df.building_workshopst:is_instance(building)
	local is_furnace = df.building_furnacest:is_instance(building)
	
	local name = utils.getBuildingName(building)

	imgui.Text(name)
	
	imgui.NewLine()
	
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
	
	if imgui.IsMouseClicked(0) and not imgui.WantCaptureMouse() and dfhack.buildings.findAtTile(mouse_world_pos) ~= nil then
		render.set_menu_item({screen="base", pos=mouse_world_pos})
	end
	
	if imgui.IsMouseClicked(1) and imgui.WantCaptureMouse() and not go_back then
		render.set_menu_item(nil)
	end
end