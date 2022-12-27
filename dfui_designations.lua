--@ module = true

local render = reqscript('dfui_render')

imgui = dfhack.imgui

selected_designation = "None"
selected_designation_filter = "walls"
selected_designation_marker = false

mouse_click_start = {x=-1, y=-1, z=-1}
mouse_click_end = {x=-1, y=-1, z=-1}
mouse_has_drag = false
mouse_which_clicked = 0

function onLoad()
    
end

function remove_jobs_for_tile(x, y, z, filter)
	local link = df.global.world.jobs.list.next

	while link ~= nil do
		local nxt = link.next
		local job = link.item

		if job ~= nil and 
		   job.pos.x == x and job.pos.y == y and job.pos.z == z and
		   filter(job) then
			dfhack.job.removeJob(job)
		end

		link = nxt
	end
end

function find_job(filter)
	local link = df.global.world.jobs.list.next
	
	while link ~= nil do
		local nxt = link.next
		local job = link.item

		if job ~= nil and filter(job) then
			return job
		end

		link = nxt
	end
	
	return nil
end

--https://github.com/DFHack/scripts/blob/791748739ada792591995585a0c8218ea87402ec/internal/quickfort/dig.lua may have more accurate designation logic
function render_designations()
	local menus = {{key="d", text="Mine"}, -- done!
				   {key="h", text="Channel"}, -- done
				   {key="u", text="Up Stair"}, -- done. Must be built on wall
				   {key="j", text="Down Stair"},  -- done. Ramp, wall, floor, ie not open
				   {key="i", text="U/D Stair"},   -- done. See up stair. Need to down stair automatically
				   {key="r", text="Up Ramp"}, -- done
				   {key="z", text="Remove Up Stairs/Ramps"}, -- done
				   {key="t", text="Chop Down Trees"}, -- done, or at least enough done
				   {key="p", text="Gather Plants"}, -- done
				   {key="s", text="Smooth Stone"}, -- done
				   {key="e", text="Engrave Stone"}, -- done
				   {key="F", text="Carve Fortifications"}, -- done
				   {key="T", text="Carve Track"},
				   {key="v", text="Toggle Engravings"},
				   {key="M", text="Toggle Standard/Marking"},
				   {key="n", text="Remove Construction"}, -- partly done, though untested
				   {key="x", text="Remove Designation"}, -- done
				   {key="b", text="Set Building/Item Property"},
				   {key="o", text="Set Traffic Areas"}}

	selected_designation = render.render_table_impl(menus, selected_designation)
	
	if imgui.Button("Back") or (imgui.IsWindowHovered(0) and imgui.IsMouseClicked(1)) then
		render.pop_menu()
	end

	local top_left = render.get_camera()
	
	local mouse_pos = imgui.GetMousePos()
	
	local lx = top_left.x+mouse_pos.x
	local ly = top_left.y+mouse_pos.y
	
	local window_blocked = imgui.IsWindowHovered(0) or imgui.WantCaptureMouse()
		
	local current_world_mouse_pos = {x=lx, y=ly, z=top_left.z}
		
	if not window_blocked and selected_designation ~= "None" then
		if imgui.IsMouseClicked(0) or imgui.IsMouseClicked(1) then
			mouse_click_start = current_world_mouse_pos
			mouse_has_drag = true
			
			if imgui.IsMouseClicked(0) then
				mouse_which_clicked = 0
			else
				mouse_which_clicked = 1
			end
		end
	end
	
	if mouse_has_drag and imgui.IsMouseClicked((mouse_which_clicked + 1) % 2) then
		mouse_has_drag = false
	end
	
	local tiles = {}
	local should_trigger_mouse = false
	local trigger_rmouse = false

	local min_pos_x = math.min(mouse_click_start.x, current_world_mouse_pos.x)
	local min_pos_y = math.min(mouse_click_start.y, current_world_mouse_pos.y)
	local min_pos_z = math.min(mouse_click_start.z, current_world_mouse_pos.z)
	
	local max_pos_x = math.max(mouse_click_start.x, current_world_mouse_pos.x)
	local max_pos_y = math.max(mouse_click_start.y, current_world_mouse_pos.y)
	local max_pos_z = math.max(mouse_click_start.z, current_world_mouse_pos.z)
	
	if mouse_has_drag then		
		for z=min_pos_z,max_pos_z do
			for y=min_pos_y,max_pos_y do
				for x=min_pos_x,max_pos_x do
					--this is the most lua line of code ever
					tiles[#tiles+1] = {x=x, y=y, z=z}
				end
			end
		end
		
		for k, v in ipairs(tiles) do
			if v.z == top_left.z then
				render.render_absolute_text("X", COLOR_BLACK, COLOR_YELLOW, v)
			end
		end

		if imgui.IsMouseReleased(mouse_which_clicked) then
			should_trigger_mouse = true
			mouse_click_end = current_world_mouse_pos
			mouse_has_drag = false
		end
	end

	if not imgui.IsMouseDown(mouse_which_clicked) then
		mouse_has_drag = false
	end

	local dirty_block = false

	--todo: one pass job and tree searching
	if should_trigger_mouse then
		for k, v in ipairs(tiles) do
			--tile_designation
			local tile, occupancy = dfhack.maps.getTileFlags(xyz2pos(v.x - 1, v.y - 1, v.z))
			
			local selected = selected_designation
			local marker = selected_designation_marker
			
			if mouse_which_clicked == 1 then
				selected = "Remove Designation"
				marker = false
			end

			if tile ~= nil then
				local tile_type = dfhack.maps.getTileType(xyz2pos(v.x-1, v.y-1, v.z))
				local tile_block = dfhack.maps.getTileBlock(xyz2pos(v.x - 1, v.y - 1, v.z))
				
				local tiletype_attrs = df.tiletype.attrs;
				local my_shape = df.tiletype.attrs[tile_type].shape
				local my_material = df.tiletype.attrs[tile_type].material
				local my_special = df.tiletype.attrs[tile_type].special
				
				local tilematerials_attrs = df.tiletype_material.attrs;
				
				local basic_shape_attrs = df.tiletype_shape_basic;
				local my_basic_shape = df.tiletype_shape.attrs[my_shape].basic_shape
				
				local is_hidden = tile.hidden
			
				local smooth_bits = tile.smooth
				
				--tiletypes.h
				local is_wall = my_basic_shape == df.tiletype_shape_basic.Wall
				local is_floor = my_basic_shape == df.tiletype_shape_basic.Floor
				local is_ramp = my_basic_shape == df.tiletype_shape_basic.Ramp
				local is_stair = my_basic_shape == df.tiletype_shape_basic.Stair
				local is_open = my_basic_shape == df.tiletype_shape_basic.Open
				
				local is_tree = my_material == df.tiletype_material.TREE
				local is_shrub = my_material == df.tiletype_material.PLANT
				
				local is_smooth = my_special == df.tiletype_special.SMOOTH
				
				local is_solid = not is_open
				
				--imgui.Text(my_material)

				--so, default digs walls, removes stairs, deletes ramps, gathers plants, and fells trees
				--not the end of the world, need to collect a tile list and then filter
				if selected == "Mine" and (is_wall or is_hidden) then
					tile.dig = df.tile_dig_designation.Default
				end

				if selected == "Channel" and (is_solid or is_hidden) then
					tile.dig = df.tile_dig_designation.Channel
				end

				if selected == "Up Stair" and (is_wall or is_hidden) then
					tile.dig = df.tile_dig_designation.UpStair
				end
				
				if selected == "Down Stair" and (is_solid or is_hidden) then
					tile.dig = df.tile_dig_designation.DownStair
				end
				
				if selected == "U/D Stair" and (is_wall or is_hidden) then
					tile.dig = df.tile_dig_designation.UpDownStair
				end
				
				if selected == "Up Ramp" and (is_wall or is_hidden) then
					tile.dig = df.tile_dig_designation.Ramp
				end
				
				if selected == "Remove Up Stairs/Ramps" and (is_ramp or is_stair) and not is_hidden then
					tile.dig = df.tile_dig_designation.Default
				end
				
				local all_plants = df.global.world.plants.all
				
				--this isn't that fast, probably because of all the meta methods
				if selected == "Chop Down Trees" and is_tree and not is_hidden then
					for i=0,#all_plants-1 do
						local plant = all_plants[i]
						local ppos = plant.pos
						
						if ppos.x == v.x-1 and ppos.y == v.y-1 and ppos.z == v.z then
							dfhack.designations.markPlant(plant)
							goto skip
						end
					end
									
					--tile.dig = df.tile_dig_designation.Default
				end
				
				if selected == "Gather Plants" and is_shrub and my_special ~= df.tiletype_special.DEAD and not is_hidden then
					for i=0,#all_plants-1 do
						local plant = all_plants[i]
						local ppos = plant.pos
						
						if ppos.x == v.x-1 and ppos.y == v.y-1 and ppos.z == v.z then
							dfhack.designations.markPlant(plant)
							goto skip
						end
					end
				end
				
				function test_detail_job(j)
					return (j.job_type == df.job_type.DetailWall or j.job_type == df.job_type.DetailFloor) and j.pos.x == v.x-1 and j.pos.y == v.y-1 and j.pos.z == v.z
				end
				
				if selected == "Smooth Stone" and not is_hidden and not is_smooth and (is_floor or is_wall) then
					if find_job(test_detail_job) ~= nil then
						goto skip
					end
					
					tile.smooth = 1
					tile.dig = df.tile_dig_designation.No
				end
				
				if selected == "Engrave Stone" and not is_hidden and is_smooth and (is_floor or is_wall) then
					if find_job(test_detail_job) ~= nil then
						goto skip
					end
					
					for _,e in ipairs(df.global.world.engravings) do
						local pos = e.pos
						
						if pos.x == v.x-1 and pos.y == v.y-1 and pos.z == v.z then
							goto skip
						end
					end
					
					tile.smooth = 2
					tile.dig = df.tile_dig_designation.No
				end
				
				if selected == "Carve Fortifications" and not is_hidden and is_smooth and is_wall then
					if find_job(test_detail_job) ~= nil then
						goto skip
					end
					
					for _,e in ipairs(df.global.world.engravings) do
						local pos = e.pos
						
						if pos.x == v.x-1 and pos.y == v.y-1 and pos.z == v.z then
							goto skip
						end
					end
					
					tile.smooth = 1
					tile.dig = df.tile_dig_designation.No
				end
				
				--todo, is construction
				if selected == "Remove Construction" and not is_hidden then				
					dfhack.constructions.designateRemove(xyz2pos(v.x-1,v.y-1,v.z))
				end
				
				--tiles * jobs = bad
				if selected == "Remove Designation" then
					tile.dig = df.tile_dig_designation.No
					tile.smooth = 0
					
					dfhack.constructions.designateRemove(xyz2pos(v.x-1,v.y-1,v.z))
					
					function is_any(j)
						return true
					end
					
					remove_jobs_for_tile(v.x-1, v.y-1, v.z, is_any)
				end
				
				if (tile.dig > 0 or tile.smooth > 0) then
					if tile_block ~= nil then
						tile_block.flags.designated = true
					end
				end
			end

			if occupancy ~= nil then
				occupancy.dig_marked = marker
			end
			
			::skip::
		end
	end
end

--return _ENV