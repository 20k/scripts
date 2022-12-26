local gui = require('gui')

MyScreen = defclass(MyScreen, gui.Screen)

imgui = dfhack.imgui
state = "main"
last_hovered_announce_id = -1

function brighten(col, should_bright)
	if not should_bright then
		return col
	end

	local arr = {7, 9, 10, 11, 12, 13, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15}
	return arr[col + 1]
end

function months()
	return {"Granite", "Slate", "Felsite", "Hematite","Malachite","Galena", "Limestone", "Sandstone","Timber", "Moonstone","Opal","Obsidian"}
end

function days_in_month()
	return 28
end

function days_in_year()
	return 336
end

function ticks_in_day()
	return 1200
end

function ticks_in_month()
	return ticks_in_day() * days_in_month()
end

function ordinal_suffix(which)
	local as_str = tostring(which)
	
	local back = as_str[#as_str]
	
	if back == 1 then
		return "st"
	end
	
	if back == 2 then
		return "nd"
	end
	
	if back == 3 then
		return "rd"
	end
		
	return "th"
end

function time_to_ymd(t)
	local fhour = t % 50
	local fday = (t / ticks_in_day()) % 28
	local fmonth = (t / ticks_in_month()) % 12
	local fyear = (t / (ticks_in_month() * 12))
	
	fhour = math.floor(fhour)
	fday = math.floor(fday)
	fmonth = math.floor(fmonth)
	fyear = math.floor(fyear)
	
	return {year=fyear, month=fmonth, day=fday, hour=fhour}
end

-- must be part of network api
function centre_camera(x, y, z)
	local sx = df.global.gps.dimx
	local sy = df.global.gps.dimy

	df.global.window_x = x - math.floor(sx/2)
	df.global.window_y = y - math.floor(sy/2)
	
	df.global.window_z = z
end

-- must be part of network api
function get_camera()
	return {x=df.global.window_x, y=df.global.window_y, z=df.global.window_z}
end

-- ideally should be part of network api
function render_absolute_text(str, fg, bg, pos)
	local draw_list = imgui.GetForegroundDrawList()
	
	imgui.AddTextBackgroundColoredAbsolute(draw_list, {fg=fg, bg=bg}, "X", pos)
end

function render_announcements()
	local reports = df.global.world.status.reports
	local count = #reports
		
	local df_year = -1
	local df_time = -1
	
	local any_hovered_yet = false
	
	for i=0,(count-1) do
		local report = reports[i]
	
		local a_type = report.type
		local text = dfhack.df2utf(report.text)
		local col = report.color
		local bright = report.bright
		
		local lx = report.pos.x
		local ly = report.pos.y
		local lz = report.pos.z
				
		col = brighten(col, bright)
		
		imgui.ButtonColored({fg=col}, text)
		
		if imgui.IsItemHovered() or (not any_hovered_yet and report.id == last_hovered_announce_id) then 
			df_year = report.year
			df_time = report.time
			
			last_hovered_announce_id = report.id
			
			local pos = {x=lx+1, y=ly+1, z=lz}
			
			render_absolute_text("X", COLOR_YELLOW, COLOR_BLACK, pos)
			
			if imgui.Shortcut("STRING_A122") and imgui.IsItemHovered() then
				centre_camera(lx, ly, lz)
			end
		end
		
		if imgui.IsItemClicked(0) then 
			centre_camera(lx, ly, lz)
		end
	end
	
	if df_time ~= -1 then
		local ymd = time_to_ymd(df_time)
		
		imgui.Text("Date: " .. tostring(ymd.day+1) .. ordinal_suffix(ymd.day+1) .. " "
							.. months()[ymd.month + 1]
							.. ", " .. tostring(df_year))
	
		--imgui.Text("Date: " .. tostring(df_time) .. ", " .. tostring(df_year))
	end
end

function render_table_impl(menus, old_state)
	local state = old_state
		
	local last_merged = false
	
	if imgui.BeginTable("Table", 2, (1 << 20)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();
			for k, v in ipairs(menus) do
			
			local keyboard_key = 0;
			
			if #v.key > 1 then
				keyboard_key = "STRING_A" .. v.key
			else
				local byt = tostring(string.byte(v.key))
				
				if #byt < 3 then
					byt = "0"..byt
				end
					
				keyboard_key = "STRING_A"..byt
			end
		
			local shortcut_name = imgui.GetKeyDisplay(keyboard_key)
			
			imgui.TextColored(COLOR_LIGHTGREEN, shortcut_name)
			imgui.SameLine(0,0)
			imgui.Text(": ")
			imgui.SameLine(0,0)
			
			local description = v.text
			
			local pushed = false
			if state == description then
				pushed = true
				imgui.PushStyleColor(imgui.StyleIndex("Text"), {fg=COLOR_WHITE})
			end
			
			if imgui.Button(description) or imgui.Shortcut(keyboard_key) then
				if state == description then
					state = "None"
				else
					state = description
				end
			end
			
			if pushed then
				imgui.PopStyleColor(1)
			end
			
			if #description < 13 and not last_merged then
				--imgui.SameLine()
				imgui.TableNextColumn();
				
				last_merged = true
			else
				imgui.TableNextRow();
				imgui.TableNextColumn();
			
				last_merged = false
			end
		end
		
		imgui.EndTable()
	end

	return state
end

selected_designation = "None"
selected_designation_filter = "walls"
selected_designation_marker = false

mouse_click_start = {x=-1, y=-1, z=-1}
mouse_click_end = {x=-1, y=-1, z=-1}
mouse_has_drag = false
mouse_which_clicked = 0

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

function render_designations()
	local menus = {{key="d", text="Mine"}, -- done!
				   {key="h", text="Channel"}, -- needs appropriateness checks
				   {key="u", text="Up Stair"}, -- needs appropriateness checks
				   {key="j", text="Down Stair"},  -- needs appropriateness checks
				   {key="i", text="U/D Stair"},   -- needs appropriateness checks
				   {key="r", text="Up Ramp"}, -- done
				   {key="z", text="Remove Up Stairs/Ramps"}, -- done
				   {key="t", text="Chop Down Trees"}, -- done, or at least enough done
				   {key="p", text="Gather Plants"},
				   {key="s", text="Smooth Stone"},
				   {key="e", text="Engrave Stone"},
				   {key="F", text="Carve Fortifications"},
				   {key="T", text="Carve Track"},
				   {key="v", text="Toggle Engravings"},
				   {key="M", text="Toggle Standard/Marking"},
				   {key="n", text="Remove Construction"}, -- done, though untested
				   {key="x", text="Remove Designation"}, -- done
				   {key="b", text="Set Building/Item Property"},
				   {key="o", text="Set Traffic Areas"}}

	selected_designation = render_table_impl(menus, selected_designation)

	local top_left = get_camera()
	
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
				render_absolute_text("X", COLOR_BLACK, COLOR_YELLOW, v)
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

	if should_trigger_mouse then
		for k, v in ipairs(tiles) do
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
				
				local tilematerials_attrs = df.tiletype_material.attrs;
				
				local basic_shape_attrs = df.tiletype_shape_basic;
				local my_basic_shape = df.tiletype_shape.attrs[my_shape].basic_shape
				
				local is_hidden = true
				
				if tile_block ~= nil then
					local desig = tile_block.designation[(v.x-1)&15][(v.y-1)&15]
					
					is_hidden = desig.hidden
				end
				
				--tiletypes.h
				local is_wall = my_basic_shape == df.tiletype_shape_basic.Wall;
				local is_floor = my_basic_shape == df.tiletype_shape_basic.Floor;
				local is_ramp = my_basic_shape == df.tiletype_shape_basic.Ramp;
				local is_stair = my_basic_shape == df.tiletype_shape_basic.Stair;
				local is_tree = my_material == df.tiletype_material.TREE
				local is_shrub = my_material == df.tiletype_material.SHRUB
							
				--so, default digs walls, removes stairs, deletes ramps, gathers plants, and fells trees
				--not the end of the world, need to collect a tile list and then filter
				if selected == "Mine" and (is_wall or is_hidden) then
					tile.dig = df.tile_dig_designation.Default
				end

				if selected == "Channel" then
					tile.dig = df.tile_dig_designation.Channel
				end

				if selected == "Up Stair" then
					tile.dig = df.tile_dig_designation.UpStair
				end
				
				if selected == "Down Stair" then
					tile.dig = df.tile_dig_designation.DownStair
				end
				
				if selected == "U/D Stair" then
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
							--[[local dpos = get_plant_designation_tile(plant)
							--local dpos = ppos
							
							local ptile, poccupancy = dfhack.maps.getTileFlags(dpos)
							
							ptile.dig = df.tile_dig_designation.Default
							
							if poccupancy ~= nil then
								poccupancy.dig_marked = marker
							end
							
							local ltile_block = dfhack.maps.getTileBlock(dpos)
							
							if ltile_block ~= nil then
								ltile_block.flags.designated = true
							end]]--
							
							dfhack.designations.markPlant(plant)
							
							goto skip
						end
					end
									
					--tile.dig = df.tile_dig_designation.Default
				end
				
				--todo, is construction
				if selected == "Remove Construction" and not is_hidden then				
					dfhack.constructions.designateRemove(xyz2pos(v.x-1,v.y-1,v.z))
				end
				
				--tiles * jobs = bad
				if selected == "Remove Designation" then
					tile.dig = df.tile_dig_designation.No
					
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
				
				::skip::
			end

			if occupancy ~= nil then
				occupancy.dig_marked = marker
			end
		end
	end
end

function render_menu()
	local menus = {{key="097", text="View Announcements"},
				   {key="098", text="Building"},
				   {key="114", text="Reports"},
				   {key="099", text="Civilizations/World Info"},
				   {key="100", text="Designations"},
				   {key="111", text="Set Order"},
				   {key="117", text="Unit List"},
				   {key="106", text="Job List"},
				   {key="109", text="Military"},
				   {key="115", text="Squads"},
				   {key="078", text="Points/Routes/Notes"},
				   {key="119", text="Make Burrows"},
				   {key="104", text="Hauling"},
				   {key="112", text="Stockpiles"},
				   {key="105", text="Zones"},
				   {key="113", text="Set Building Tasks/Prefs"},
				   {key="082", text="View Rooms/Buildings"},
				   {key="116", text="View Items In Buildings"},
				   {key="118", text="View Units"},
				   {key="072", text="Hot Keys"},
				   {key="108", text="Locations and Occupations"},
				   {key="122", text="Status"},
				   {key="107", text="Look"},
				   {key="009", text="Move this menu/map"},
				   {key="063", text="Help"},
				   {key="027", text="Options"},
				   {key="059", text="Movies"},
				   {key="068", text="Depot Access"},
				   {key="032", text="Resume"},
				   {key="046", text="One-Step"}}

	state = render_table_impl(menus, state)
end

function MyScreen:render()
	self:renderParent()
	
	if(imgui.IsKeyPressed(6) and state == "main") then
		self:dismiss()
	end
	
	if(imgui.IsKeyPressed(6)) then
		state = "main"
		--self:dismiss()
	end
	
	local text_style = imgui.StyleIndex("Text")
	
	imgui.PushStyleColor(text_style, {fg=COLOR_GREY, bg=COLOR_GREY})
	
	--I really need to sort out the constants
	imgui.Begin("Main")
	
	if state == "View Announcements" then
		render_announcements()
	end
	
	if state == "Designations" then
		render_designations()
	end
	
	if state == "main" then
		render_menu()
	end
	
	imgui.End()
	
	imgui.PopStyleColor(1)
end

function MyScreen:onDismiss()
	state = "main"
    view = nil
end

function MyScreen:onInput(keys)
	if not imgui.WantCaptureInput()then
		imgui.FeedUpwards()
	end
end

screen = MyScreen{ }:show()