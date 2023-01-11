--@ module = true

render = reqscript('dfui_render')
imgui = dfhack.imgui
utils = require('utils')
--jobinspector = reqscript('jobinspector')

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

		--gcount = #df.historical_entity.find(df.global.plotinfo.group_id).resources.organic.silk.mat_type

		--[[for _,c in pairs(df.creature_raw.get_vector()) do
			for d,v in pairs(c.material) do
				if v and v.flags.SILK then
					gcount = gcount+1
				end
			end
		end]]--

		--[[for _,v in pairs(df.global.world.raws.mat_table.builtin) do
			if v and v.flags.SILK then
				gcount = gcount+1
			end
		end]]--

		--[[for _,v in pairs(df.global.world.raws.inorganics) do
			if v and v.flags.DIVINE then
				gcount = gcount+1

				imgui.Text(v.str[5][0])
			end
		end]]--

		--[[for _,v in pairs(df.global.world.raws.inorganics) do
			if v and v.material.flags.SILK then
				gcount = gcount+1
			end
		end
		]]--

		--[[for _,v in pairs(df.global.world.raws.plants.all) do
			if v.flags.THREAD then
				gcount = gcount + 1
			end
		end]]--

		--[[for _,c in pairs(df.creature_raw.get_vector()) do
			for k,v in pairs(c.caste) do
				local layers = #v.shearable_tissue_layer

				layers = math.min(layers, 1)

				gcount = gcount + layers

				if layers == 1 then
					goto done
				end
			end

			::done::
		end]]--

		local gcount = 0

		--[[for _,v in pairs(df.global.world.raws.plants.all) do
			for d,m in pairs(v.material) do
				if m.flags.WOOD then
					gcount = gcount + 1
					imgui.Text(v.name)
					goto done
				end
			end]]--

			--imgui.Text(v.name)

			--[[if v.name == "abaca tree" then
				imgui.Text(v.name)
				--render.dump_flags(v.flags)
			end]]--

			--[[if v.flags.TREE or v.flags.TREE_HAS_MUSHROOM_CAP then
				imgui.Text(v.name)
				gcount = gcount + 1
			end
			::done::
		end]]--

		--[[for _,v in pairs(df.global.world.raws.mat_table.builtin) do
			if v and v.flags.WOOD then
				gcount = gcount+1
			end
		end]]--

		--[[for k,v in pairs(df.global.world.raws.inorganics) do
			if v.material.flags.WOOD then
				gcount = gcount + 1
			end
		end]]--

		--gcount = #df.global.world.raws.itemdefs.weapons

		--[[for _,c in pairs(df.creature_raw.get_vector()) do
			for k,v in pairs(c.material) do
				if v.flags.WOOD then
					gcount = gcount + 1
				end
			end
		end]]--

		--gcount = #df.historical_entity.find(df.global.plotinfo.group_id).resources.misc_mat.wood2.mat_type

		--gcount = #df.global.world.raws.plants.trees

		--[[for _,c in pairs(df.global.world.raws.inorganics) do
			if c and c.material.flags.WOOD then
				gcount = gcount + 1
			end
		end]]--

		--[[for a,b in pairs(settings.wood.mats) do
			if b == false or b == 0 then
				imgui.Text("False")
			end
		end]]--

		--[[for _,c in pairs(df.creature_raw.get_vector()) do
			for k,v in pairs(c.material) do
				if v.flags.MEAT then
					gcount = gcount + 1
				end
			end
		end]]--

		--[[for _,c in pairs(df.global.world.raws.mat_table.builtin) do
			if c and c.flags.MEAT then
				gcount = gcount + 1
			end
		end]]--

		--[[for k,v in pairs(df.global.world.raws.itemdefs.food) do

		end]]--

		--gcount = #df.historical_entity.find(df.global.plotinfo.group_id).resources.misc_mat.wood2.mat_type

		--gcount = #df.global.world.raws.itemdefs.all

		--[[for _,c in pairs(df.creature_raw.get_vector()) do
			if c.flags.HAS_ANY_CANNOT_BREATHE_AIR and c.flags.HAS_ANY_NOT_FLIER and c.flags.HAS_ANY_CAN_SWIM then
				gcount = gcount+1
			end
		end]]--

		--[[for _,c in pairs(df.creature_raw.get_vector()) do
			for k,v in pairs(c.caste) do
				if v.misc.fish_mat_index ~= -1 then
					gcount = gcount + 1
				end
			end
		end]]--

		--[[for _,c in pairs(df.creature_raw.get_vector()) do
			for k,v in pairs(c.caste) do
				if v.misc.egg_mat_index ~= -1 then
					gcount = gcount + 1
				end
			end
		end]]--


		--[[for _, c in pairs(df.global.world.raws.creatures.all) do
			for _, m in pairs(c.material) do
				if m.flags.ALCOHOL then
					gcount = gcount + 1
				end
			end
		end]]--

		for _, c in pairs(df.global.world.raws.creatures.all) do
			for _, m in pairs(c.material) do
				if m.flags.CHEESE_CREATURE then
					gcount = gcount + 1
				end
			end
		end

		imgui.Text("Dbg " .. tostring(gcount))

		for name,v in pairs(settings) do
			if name == "flags" then
				goto skip
			end

			if type(v) == "userdata" then
				--imgui.Text(name)

				--imgui.SameLine()

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

					::lskip::
				end
			else
				imgui.Text(name .. " " .. tostring(v))
			end

			::skip::
		end
	end
end

function render_viewitems()
	imgui.EatMouseInputs()

	local world_pos = render.get_mouse_world_coordinates()

	local check_x = selected_building_pos.x
	local check_y = selected_building_pos.y
	local check_z = selected_building_pos.z

	local has_item = render.get_menu_item()

	if not has_item then
		check_x = world_pos.x
		check_y = world_pos.y
		check_z = world_pos.z
	end

	local building = dfhack.buildings.findAtTile(xyz2pos(check_x, check_y, check_z))

	function item_sort(a, b)
		return b2n(a.flags.in_building) > b2n(b.flags.in_building)
	end

	if building ~= nil then
		--jobinspector.inspect_workshop(building)

		debug_stock(building)

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
		render.set_menu_item(false)
	end

	if imgui.Button("Back") or imgui.IsMouseClicked(1) then
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

			render.set_menu_item(true)
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
			if civzone.type ~= df.civzone_type.ActivityZone then
				goto skip
			end

			if (current_menu == "main" or current_menu == "Zones") and imgui.IsMouseClicked(0) then
				selected_building_pos.x = mouse_world_pos.x
				selected_building_pos.y = mouse_world_pos.y
				selected_building_pos.z = mouse_world_pos.z

				if render.get_menu() ~= "Zones" then
					render.push_menu("Zones")
				end

				local data = {type="Selected", id=civzone.id}

				render.set_menu_item(data)
			end

			local str = building_name(civzone)

			imgui.BeginTooltip()
			imgui.Text(str)
			imgui.EndTooltip()

			::skip::
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