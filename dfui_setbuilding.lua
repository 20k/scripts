--@ module = true

workshops = require("dfhack.workshops")
render = reqscript('dfui_render')

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
		ji.has_tool_use = 0
		
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
		out_job[k] = v
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
	
	local existing_item = render.get_menu_item();
	
	existing_item.screen = "base"
	
	render.set_menu_item(existing_item)
end

function display_jobs(building, jobs)
	for i,v in pairs(jobs) do
		if imgui.Button(v.name .. "##" .. tostring(i)) then
			add_job(building, v)
			
			goto done
		end
	end
	
	::done::
end

function get_job_name(j)	
	--[[if #j.reaction_name > 0 then
		return j.reaction_name
	end
	
	return df.job_type.attrs[j.job_type].caption]]--
	
	return dfhack.job.getName(j)
end

function display_existing_jobs(building)
	local jobs = building.jobs
	
	for _,j in ipairs(jobs) do
		imgui.Text(get_job_name(j))
	end
end

function render_setbuilding()
	local mouse_world_pos = render.get_mouse_world_coordinates()
	
	local state = {screen="base"}
	local selected_building = mouse_world_pos
	
	if render.get_menu_item() ~= nil then
		state = render.get_menu_item()
		selected_building = state.pos
	end
	
	local building = dfhack.buildings.findAtTile(selected_building)
	
	if building == nil then
		return
	end

	local is_workshop = df.building_workshopst:is_instance(building)
	local is_furnace = df.building_furnacest:is_instance(building)
	
	if is_workshop or is_furnace then
		local name = df.workshop_type.attrs[building.type].name
		
		imgui.Text(name)
		
		imgui.NewLine()
	end
	
	if state.screen == "Add new task" then
		if is_workshop then
			local type = df.building_type.Workshop
			local subtype = building.type
			
			local jobs = workshops.getJobs(type, subtype, -1)
			
			display_jobs(building, jobs)
		end
		
		if is_furnace then
			local type = df.building_type.Furnace
			local subtype = building.type
			--what is melt_remainder?
			
			local jobs = workshops.getJobs(type, subtype, -1)
			
			display_jobs(building, jobs)
		end
	end
	
	if state.screen == "base" then
		display_existing_jobs(building)
		
		imgui.NewLine()
		
		local strings = {{key="a", text="Add new task"}}
		
		local next_state = render.render_table_impl(strings, "none")
		
		if next_state == "Add new task" then
			render.set_menu_item({screen=next_state, pos=selected_building})
		end
	end
	
	if imgui.IsMouseClicked(0) and not imgui.WantCaptureMouse() then
		render.set_menu_item({screen="base", pos=mouse_world_pos})
	end
	
	if imgui.IsMouseClicked(1) and imgui.WantCaptureMouse() then
		render.set_menu_item(nil)
	end
end