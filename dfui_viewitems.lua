--@ module = true

render = reqscript('dfui_render')
imgui = dfhack.imgui
utils = require('utils')

selected_building_pos = {x=-1, y=-1, z=-1}

--contains item?
function items_in_thing(thing)
	local items = df.global.world.items.other[df.items_other_id.IN_PLAY]
	
	local result = {}
	
	for i=0,#items-1 do
		local item = items[i]
		
		local flags = item.flags
		
		--if not(flags.in_inventory or flags.in_building or flags.container or flags.encased or flags.in_chest) then
		--	goto continue
		--end
		
		for j=0,(#item.general_refs-1) do
			local ref = item.general_refs[j]
			
			local t = ref:getType()
			
			local fthing = nil
			
			if t == df.general_ref_type.CONTAINED_IN_ITEM then
				fthing = ref:getItem()
			elseif t == df.general_ref_type.UNIT_HOLDER then
				fthing = ref:getUnit()
			elseif t == df.general_ref_type.BUILDING_HOLDER then
				fthing = ref:getBuilding()
			end
			
			if fthing == thing then
				result[#result + 1] = item
				goto continue
			end
		end
		
		::continue::
	end
	
	return result
end

function item_name(item)
	return utils.getItemDescription(item)
end

function b2n(b)
	if b then
		return 1
	else
		return 0
	end
end

function render_viewitems()
	local top_left = render.get_camera()

	local mouse_pos = imgui.GetMousePos()
	
	local lx = top_left.x+mouse_pos.x - 1
	local ly = top_left.y+mouse_pos.y - 1
	
	local check_x = selected_building_pos.x
	local check_y = selected_building_pos.y
	local check_z = selected_building_pos.z
	
	local has_item = render.get_menu_item()
	
	if not has_item then
		check_x = lx
		check_y = ly
		check_z = top_left.z
	end
	
	local building = dfhack.buildings.findAtTile(xyz2pos(check_x, check_y, check_z))
	
	function item_sort(a, b)
		return b2n(a.flags.in_building) > b2n(b.flags.in_building)
	end
	
	if building ~= nil then	
		local items_in_building = items_in_thing(building)
	
		local str = utils.getBuildingName(building)
		
		imgui.Text(str)
		
		table.sort(items_in_building, item_sort)
		
		for k, v in ipairs(items_in_building) do	
			local name = tostring(item_name(v))
			
			if v.flags.in_building then 
				name = name .. " [B]"
			end
		
			imgui.Text(name)
		end
		
		imgui.Text("x: ")
			
		imgui.SameLine(0,0)
		
		if imgui.Button("Deconstruct") or imgui.Shortcut("STRING_A120") then
			dfhack.buildings.deconstruct(building)
		end
	end
	
	if imgui.Button("Back") or imgui.IsMouseClicked(1) then
		render.pop_menu()
	end
end

function handle_mouseover()
	local top_left = render.get_camera()

	local mouse_pos = imgui.GetMousePos()
	
	local lx = top_left.x+mouse_pos.x - 1
	local ly = top_left.y+mouse_pos.y - 1
	
	local building = dfhack.buildings.findAtTile(xyz2pos(lx, ly, top_left.z))
	
	if building ~= nil then	
		if imgui.IsMouseClicked(0) and not imgui.WantCaptureMouse() then
			selected_building_pos.x = lx
			selected_building_pos.y = ly
			selected_building_pos.z = top_left.z
			
			render.push_menu("View Items In Buildings")
			render.set_menu_item(true)
		end
	
		local str = df.new("string")
		building:getName(str)
		
		imgui.SetTooltip(str.value)
		
		str:delete()
	end
end