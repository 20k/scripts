--@ module = true

render = reqscript('dfui_render')
imgui = dfhack.imgui
utils = require('utils')
buildingd = reqscript('dfui_building')
nobles = reqscript('dfui_nobles')
jobinspector = reqscript('jobinspector')

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

function get_slated_for_removal_job(building)
	local jobs = building.jobs

	for i=0,(#jobs-1) do
		local job = jobs[i]

		if job.job_type == df.job_type.DestroyBuilding then
			return job
		end
	end

	return nil
end

function item_name(item)
	return utils.getItemDescription(item)
end

function building_name(building)
	return utils.getBuildingName(building)
end

function b2n(b)
	if b then
		return 1
	else
		return 0
	end
end

function debug_stock(building)
	if df.building_stockpilest:is_instance(building) then
		local settings = building.settings

		local gcount = 0

		for name,v in pairs(settings) do
			if name == "flags" then
				goto skip
			end

			if type(v) == "userdata" then
				for vecname,vec in pairs(v) do
					if vecname == "quality_core" or vecname == "quality_total" then
						goto lskip
					end

					if type(vec) == "userdata" or type(vec) == "table" then
						if #vec ~= 0 then
							imgui.Text(name .. "." .. vecname .. " " .. tostring(#vec))
						end
					else
						if vec then
							imgui.Text(name .. "." .. vecname .. " " .. tostring(vec))
						end
					end

					if vecname == "quality_core" or vecname == "quality_total" then
						for _, k in ipairs(vec) do
							imgui.Text(tostring(k))
						end
					end

					::lskip::
				end
			else
				imgui.Text(name .. " " .. tostring(v))
			end

			::skip::
		end
	end
end

function debug_zones()
	for _,v in ipairs(df.building.get_vector()) do
		if df.building_civzonest:is_instance(v) then

			render.dump_flags(v.flags)

			imgui.Text("Id", tostring(v.id))
			imgui.Text("Civzonebuilding")

			imgui.Text("Jobs", tostring(#v.jobs))
			imgui.Text("Specific", tostring(#v.specific_refs))
			imgui.Text("General", tostring(#v.general_refs))

			imgui.Text("Relations", tostring(#v.relations))

			for _,r in ipairs(v.relations) do
				imgui.Text("Relation", tostring(r))
			end

			imgui.Text("Assigned Units: ", tostring(#v.assigned_units))
			imgui.Text("Assigned Items: ", tostring(#v.assigned_items))

			imgui.Text(v.name)
			imgui.Text(tostring(v.x1))
			imgui.Text(tostring(v.y1))
			imgui.Text(tostring(v.x2))
			imgui.Text(tostring(v.y2))

			if v.room.extents then
				imgui.Text("Extents " .. tostring(v.room.extents[0]))
			end

			--imgui.Text(tostring(v.id))
			imgui.Text("is_active " .. tostring(v.is_active))
			imgui.Text("1 " .. tostring(v.anon_1))
			imgui.Text("2 " .. tostring(v.anon_2))
			--imgui.Text("5 " .. tostring(v.anon_5))
			--imgui.Text("6 " .. tostring(v.anon_6))

			imgui.Text("zone_num " .. tostring(v.zone_num))
			--imgui.Text("'dir_x " .. tostring(v.zone_settings.whole.i1))
			--imgui.Text("'dir_y " .. tostring(v.zone_settings.whole.i2))

			if v.type == df.civzone_type.ArcheryRange then
				imgui.Text("Dir_x " .. tostring(v.zone_settings.archery.dir_x))
				imgui.Text("Dir_y " .. tostring(v.zone_settings.archery.dir_y))
			elseif v.type == df.civzone_type.PlantGathering then
				render.dump_flags(v.zone_settings.gather)
			elseif v.type == df.civzone_type.Pen then
				imgui.Text("Pen " .. tostring(v.zone_settings.pen.unk))
			elseif v.type == df.civzone_type.Tomb then
				render.dump_flags(v.zone_settings.tomb)
			elseif v.type == df.civzone_type.Pond then
				imgui.Text("Pond: " .. tostring(v.zone_settings.pit_pond))
			else
				imgui.Text("Unknown ", tostring(v.zone_settings.whole.i1), tostring(v.zone_settings.whole.i2))
			end

			imgui.Text("3 " .. tostring(v.anon_3))
			imgui.Text("4 " .. tostring(#v.anon_4))

			for k,d in pairs(v.contained_buildings) do
				imgui.Text("b " .. tostring(d), "id", tostring(d.id))
			end

			imgui.Text("assigned " .. tostring(v.assigned_unit_id))
			imgui.Text("5 " .. tostring(v.anon_5))

			if v.assigned_unit_id ~= -1 then
				imgui.Text("unit " .. v.assigned_unit.id)
			end

			--imgui.Text("6 " .. tostring(v.anon_6))
			--imgui.Text("7 " .. tostring(v.anon_7))
			imgui.Text("rinfo " .. tostring(#v.squad_room_info))

			for k,d in pairs(v.squad_room_info) do
				imgui.Text("id " .. tostring(d.squad_id))
				--imgui.Text("flags " .. tostring(d.flags))
				render.dump_flags(d.mode)
			end

			imgui.Text("6 " .. tostring(v.anon_6))
			imgui.Text("7 " .. tostring(v.anon_7))

			--[[for k,v in pairs(df.global.world.schedules.all) do
				imgui.Text(tostring(d))
			end]]--

			--imgui.Text("Building_next " .. tostring(df.global.building_next_id))

			--[[for k,d in pairs(df.squad.get_vector()) do
				for s,v in pairs(d.positions) do
					imgui.Text(tostring(v))
				end
			end]]--

			--[[for k,d in pairs(df.global.plotinfo.main.fortress_entity.positions.own) do
				imgui.Text(tostring(d))
			end]]--

			--[[for k,d in pairs(df.squad.get_vector()) do
				imgui.Text(tostring(d))
			end]]--

			--[[for k,v in ipairs(df.global.world.units.active) do
				imgui.Text("hi")
				imgui.Text(tostring(v.id))

				local val = nobles.unit_to_histfig(v)

				if val ~= nil then
					imgui.Text(tostring(val.id))
				end
			end]]--
		end
	end
end

function inspect_building(b)
	imgui.Text("canMakeRoom", tostring(b:canMakeRoom()))
	imgui.Text("Jobs: ", tostring(#b.jobs))
	imgui.Text("Specific: ", tostring(#b.specific_refs))
	imgui.Text("General: ", tostring(#b.general_refs))
	imgui.Text("Relations: ", tostring(#b.relations))

	render.dump_flags(b.flags)

	for _, r in ipairs(b.relations) do
		imgui.Text("Relation ", tostring(r))
	end
end

function render_viewitems()
	render.set_can_window_pop(true)

	local world_pos = render.get_mouse_world_coordinates()

	local check_x = selected_building_pos.x
	local check_y = selected_building_pos.y
	local check_z = selected_building_pos.z

	local has_item = render.get_submenu()

	if not has_item then
		check_x = world_pos.x
		check_y = world_pos.y
		check_z = world_pos.z
	end

	local building = dfhack.buildings.findAtTile(xyz2pos(check_x, check_y, check_z))

	--debug_zones()

	--imgui.Text("Hovered: " .. tostring(building))

	function item_sort(a, b)
		return b2n(a.flags.in_building) > b2n(b.flags.in_building)
	end

	if building ~= nil then
		--imgui.Text("Normal? " .. tostring(building:canMakeRoom()))
		--imgui.Text("CXY", tostring(building.centerx), tostring(building.centery))

		--jobinspector.inspect_workshop(building)

		--inspect_building(building)

		--debug_stock(building)

		local str = utils.getBuildingName(building)
		imgui.Text(str)

		local removal_job = get_slated_for_removal_job(building)

		if removal_job == nil then
			local items_in_building = items_in_thing(building)

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
				if not dfhack.buildings.markedForRemoval(building) then

					if building.room and building.room.extents then
						for idx,v in ipairs(building.room.extents) do
							local lx  = idx % building.room.width
							local ly = math.floor(idx / building.room.width)

							local tx = building.room.x
							local ty = building.room.y

							local nx = lx + tx
							local ny = ly + ty

							local chunk = dfhack.maps.getTileBlock({x=nx, y=ny, z=check_z})

							local des = chunk.designation[nx&15][ny&15]
							local occ = chunk.occupancy[nx&15][ny&15]

							building.room.extents[idx] = df.building_extents_type.None
							des.pile = false
							occ.building = df.tile_building_occ.None
						end
					end

					dfhack.buildings.deconstruct(building)
				end
			end
		else
			imgui.Text("Slated for removal")

			imgui.Text("s: ")

			imgui.SameLine(0,0)

			if imgui.Button("Stop Removal") or imgui.Shortcut("STRING_A115") then
				dfhack.job.removeJob(removal_job)
			end
		end
	else
		render.pop_submenu()
	end

	if imgui.Button("Back") then
		render.pop_menu()
	end
end


function handle_building_mouseover()
	if imgui.WantCaptureMouse() then
		return
	end

	local mouse_world_pos = render.get_mouse_world_coordinates()

	local building = dfhack.buildings.findAtTile(xyz2pos(mouse_world_pos.x, mouse_world_pos.y, mouse_world_pos.z))

	local current_menu = render.get_menu()
	local target_menu = "View Items In Buildings"

	if building ~= nil then
		imgui.EatMouseInputs()

		if (current_menu == "main" or current_menu == target_menu) and imgui.IsMouseClicked(0) then
			selected_building_pos.x = mouse_world_pos.x
			selected_building_pos.y = mouse_world_pos.y
			selected_building_pos.z = mouse_world_pos.z

			if render.get_menu() ~= target_menu then
				render.push_menu(target_menu)
			end

			render.pop_all_submenus()
			render.push_transparent_submenu(true)
		end

		local str = building_name(building)

		imgui.BeginTooltip()
		imgui.Text(str)
		imgui.EndTooltip()
	end

	local civzones = dfhack.buildings.findCivzonesAt(xyz2pos(mouse_world_pos.x, mouse_world_pos.y, mouse_world_pos.z))

	if civzones ~= nil and current_menu == "Zones" then
		imgui.EatMouseInputs()

		for _,civzone in ipairs(civzones) do
			if (current_menu == "main" or current_menu == "Zones") and imgui.IsMouseClicked(0) then
				if render.get_menu() ~= "Zones" then
					render.push_menu("Zones")
				end

				local current = render.get_submenu()

				if current == nil or (current and current.type == "Selected" or current.type == "Select Zone") then
					local data = {type="Selected", id=civzone.id}

					render.pop_all_submenus()
					render.push_submenu(data)
				end
			end

			local str = buildingd.get_zone_name(civzone)

			imgui.BeginTooltip()
			--imgui.Text(str .. " " .. tostring(civzone:getSubtype()))
			imgui.Text(str)
			imgui.EndTooltip()
		end
	end
end

function handle_unit_mouseover()
	if imgui.WantCaptureMouse() then
		return
	end

	local mouse_pos = render.get_mouse_world_coordinates()

	local units = df.global.world.units.active

	for _,v in ipairs(units) do
		local px, py, pz = dfhack.units.getPosition(v)

		if px == mouse_pos.x and py == mouse_pos.y and pz == mouse_pos.z then
			imgui.BeginTooltip()

			render.TextColoredUnit(v)

			imgui.EndTooltip()
		end
	end
end