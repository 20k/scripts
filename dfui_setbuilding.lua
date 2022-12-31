--@ module = true

workshops = require("dfhack.workshops")
render = reqscript('dfui_render')

imgui = dfhack.imgui

selected_building_pos = {x=-1, y=-1, z=-1}

function display_jobs(jobs)
	for _,v in ipairs(jobs) do
		imgui.Text(v.name)
	end
end

function render_setbuilding()
	local mouse_world_pos = render.get_mouse_world_coordinates()
	
	local selected_building = mouse_world_pos
	
	if render.get_menu_item() ~= nil then
		selected_building = render.get_menu_item()
	end
	
	local building = dfhack.buildings.findAtTile(selected_building)
	
	if building == nil then
		return
	end
	
	local building_id = building.id
	
	local is_workshop = df.building_workshopst:is_instance(building)
	
	if is_workshop then
		local type = df.building_type.Workshop
		local subtype = building.type
		
		local jobs = workshops.getJobs(type, subtype, -1)
		
		display_jobs(jobs)
	end
	
	local is_furnace = df.building_furnacest:is_instance(building)
	
	if is_furnace then
		local type = df.building_type.Furnace
		local subtype = building.type
		--what is melt_remainder?
		
		local jobs = workshops.getJobs(type, subtype, -1)
		
		display_jobs(jobs)
	end
	
	if imgui.IsMouseClicked(0) and not imgui.WantCaptureMouse() then
		render.set_menu_item(mouse_world_pos)
	end
	
	if imgui.IsMouseClicked(1) and imgui.WantCaptureMouse() then
		render.set_menu_item(nil)
	end
end