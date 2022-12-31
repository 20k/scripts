--@ module = true

workshops = require("dfhack.workshops")
render = reqscript('dfui_render')

imgui = dfhack.imgui

function add_job(building, job)

end

function display_jobs(building, jobs)
	for i,v in ipairs(jobs) do
		if imgui.Button(v.name .. "##" .. tostring(i)) then
			add_job(building, v)
			
			goto done
		end
	end
	
	::done::
end

function display_existing_jobs(building)
	local jobs = building.jobs
	
	for _,j in ipairs(jobs) do
		imgui.Text(df.job_type.attrs[j.job_type].caption)
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