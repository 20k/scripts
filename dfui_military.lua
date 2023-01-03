--@ module = true

imgui = dfhack.imgui
nobles = reqscript('dfui_nobles')
render = reqscript('dfui_render')

function valid_unit(unit)
	if not dfhack.units.isOwnGroup(unit) then
		return false
	end
	
	if not dfhack.units.isOwnCiv(unit) then
		return false
	end
	
	if not dfhack.units.isActive(unit) then
		return false
	end
	
	if unit.flags2.visitor then
		return false
	end
	
	if unit.flags3.ghostly then
		return false
	end
	
	if dfhack.units.isChild(unit) or dfhack.units.isBaby(unit) then
		return false
	end
	
	return true
end

function get_valid_units()
	local result = {}
	
	local units = df.global.world.units.active
	
	for i=0,#units-1 do
		local unit = units[i]

		if not valid_unit(unit) then
			goto continue
		end
		
		result[#result+1] = unit
		
		::continue::
	end
	
	return result
end

function get_squad_name(squad)
	local name = dfhack.df2utf(dfhack.TranslateName(squad.name, true, false))
		
	if squad.alias and #squad.alias ~= 0 then
		name = dfhack.df2utf(squad.alias)
	end
	
	return name
end

last_dwarf_list = nil
selected_squad = -1
selected_dwarf = -1

function appoint_to(squad_id, slot, pending_unit)
	local squad = df.squad.find(squad_id)
	
	if squad == nil then
		dfhack.println("Bad squad id in appoint")
		return
	end

	--squad.positions is 0 index based
	local existing_position = squad.positions[slot - 1]
	local existing_histfig_id = existing_position.occupant
	local pending_unit_histfig = nobles.unit_to_histfig(pending_unit)
	
	local leader_assignment_id = squad.leader_assignment
	
	local leader_assignment = nobles.assignment_id_to_assignment(leader_assignment_id)
	
	if leader_assignment == nil then
		dfhack.println("No leader assignment")
		return
	end
	
	--if the current leader is the person I'm replacing, or we're slotting into an empty slot 1 and there is no leader
	--note that this is a very cautious check because I'm not sure if slot 1 is guaranteed to be the leader
	--testing has shown that this is probably unnecessary
	--because noble positions appear to be *derived* from squad positions, rather than vice versa
	--that said it does show that I probably *do* need to modify squads when assigning nobles
	if (leader_assignment.histfig == existing_histfig_id) or (leader_assignment.histfig == -1 and existing_histfig_id == -1 and slot == 1) then
		if nobles.add_or_transfer_fort_title_to(pending_unit, leader_assignment_id) then
			squad.positions[slot - 1].occupant = pending_unit_histfig.id
		end
	else
		squad.positions[slot - 1].occupant = pending_unit_histfig.id
	end
end

function remove_from(squad_id, slot)
	local squad = df.squad.find(squad_id)
	
	if squad == nil then
		dfhack.println("Bad squad id in remove")
		return
	end
	
	local existing_position = squad.positions[slot - 1]
	local existing_histfig_id = existing_position.occupant
	
	local leader_assignment_id = squad.leader_assignment
	
	local leader_assignment = nobles.assignment_id_to_assignment(leader_assignment_id)
	
	if leader_assignment == nil then
		dfhack.println("No leader assignment in remove")
		return
	end
	
	if existing_histfig_id ~= -1 and leader_assignment.histfig == existing_histfig_id then
		nobles.remove_fort_title(leader_assignment_id)
	end
	
	squad.positions[slot - 1].occupant = -1
end

dwarf_page = 0

function get_sorted_squad_ids_by_precedence(squads)
	local vals = {}
	
	for _,v in ipairs(squads) do
		vals[#vals + 1] = v
	end
	
	function comp(a,b)
		--yeesh
		local s1 = df.squad.find(a)
		local s2 = df.squad.find(b)
	
		local p1 = nobles.position_id_to_position(s1.leader_position)
		local p2 = nobles.position_id_to_position(s2.leader_position)

		return p1.precedence < p2.precedence
	end
	
	table.sort(vals, comp)
	
	return vals
end

function get_all_uncreated_squad_assignments(squads)
	local assignments = nobles.collect_assignment_objects_with_possible_squads()
	
	local real_squads = get_sorted_squad_ids_by_precedence(squads)
	
	for _,k in ipairs(real_squads) do
		local squad = df.squad.find(k)
	
		for i,v in ipairs(assignments) do
			if squad.leader_assignment == v.id then
				table.remove(assignments, i)
				goto done
			end
		end
		
		::done::
	end
	
	local sorted = nobles.get_sorted_assignment_objects_by_precedence(assignments)
	
	return sorted
end

function render_military()
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
	local squad_ids = {}
	local dwarf_histfigs_in_squads = {}
	local all_elegible_dwarf_units = last_dwarf_list
	local commandable_assignments_without_squads = get_all_uncreated_squad_assignments(entity.squads)
	
	if render.menu_was_changed() or all_elegible_dwarf_units == nil then
		all_elegible_dwarf_units = get_valid_units()
		last_dwarf_list = all_elegible_dwarf_units
		render.menu_change_clear()
	end
	
	local dwarf_count = 300
	local start_dwarf = 1
	
	start_dwarf = math.min(start_dwarf, (#all_elegible_dwarf_units-dwarf_count) + 1)
	start_dwarf = math.max(start_dwarf, 0)
	
	local sorted_squads = get_sorted_squad_ids_by_precedence(entity.squads)
	
	for _,squad_id in ipairs(sorted_squads) do	
		local squad = df.squad.find(squad_id)
		
		if squad == nil then
			goto badsquad
		end
		
		local lsquad = {}
		
		for k,spos in ipairs(squad.positions) do
			local real_unit = nobles.histfig_to_unit(spos.occupant)
			
			if real_unit == nil then
				lsquad[k+1] = -1
				goto notreal
			end
			
			lsquad[k+1] = spos.occupant
			
			::notreal::
		end
		
		local next_id = #squad_ids + 1
		
		squad_ids[next_id] = squad_id
		dwarf_histfigs_in_squads[next_id] = lsquad
		
		::badsquad::
	end
	
	local dwarf_slice = {}
	
	for i=start_dwarf,(start_dwarf+dwarf_count-1) do
		dwarf_slice[#dwarf_slice + 1] = all_elegible_dwarf_units[i]
	end
	
	--dfhack.println(render.get_user_facing_name(all_elegible_dwarf_units[#all_elegible_dwarf_units]))
	
	if (selected_squad == -1 or selected_squad == nil) and #squad_ids > 0 then
		selected_squad = 1
	end
	
	if (selected_dwarf == -1 or selected_dwarf == nil) then
		selected_dwarf = 1
	end

	local table_height = math.max(10, #entity.squads)

	if imgui.BeginTable("Tt1", 1, (1<<13) | (1<<16)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();

		for o,squad_id in ipairs(squad_ids) do
			local squad = df.squad.find(squad_id)

			if imgui.Selectable(get_squad_name(squad).."##squadname_" .. tostring(squad_id), selected_squad == o) then
				selected_squad = o
			end
		end
		
		for o,a in ipairs(commandable_assignments_without_squads) do
			local position = nobles.position_id_to_position(nobles.assignment_to_position(a.id))

			local offset_index = o + #squad_ids
			
			if imgui.Selectable(position.name[0].."##unclaimed_"..tostring(a.id), selected_squad==offset_index) then
				selected_squad = offset_index
			end
		end
		
		imgui.EndTable()
	end
	
	if selected_squad ~= -1 and selected_squad <= #squad_ids then 
		imgui.SameLine()
			
		if imgui.BeginTable("Tt2##t"..tostring(selected_squad), 1, (1<<13) | (1<<16)) then
			imgui.TableNextRow();
			imgui.TableNextColumn();
			
			if selected_squad ~= -1 then
				for o,histfig in ipairs(dwarf_histfigs_in_squads[selected_squad]) do
					if histfig == -1 then
						imgui.Text("   ")
						
						imgui.SameLine()
					
						if imgui.Selectable("Available##dorfsel2_" .. tostring(o), selected_dwarf == o) then
							selected_dwarf = o
						end
					else
						local real_unit = nobles.histfig_to_unit(histfig)
						
						local unit_name = render.get_user_facing_name(real_unit)
						
						if imgui.ButtonColored({fg=COLOR_RED}, "[X]##rem"..tostring(histfig)) then
							remove_from(squad_ids[selected_squad], o)
						end
						
						if imgui.IsItemHovered() then
							imgui.SetTooltip("Remove From Squad")
						end
						
						imgui.SameLine()
										
						if imgui.Selectable(unit_name .. "##dorfsel_" .. tostring(histfig), selected_dwarf == o) then
							selected_dwarf = o
						end
					end
				end
			end
			
			imgui.EndTable()
		end

		local keyboard_friendly_nav = imgui.IsNavVisible()

		if selected_squad ~= -1 and selected_dwarf ~= -1 then
			imgui.SameLine()

			if imgui.BeginTable("Tt3##b"..tostring(selected_squad), 1, (1<<13)) then
				imgui.TableNextRow();
				imgui.TableNextColumn();
				
				local num_per_page = 17
				
				local start_idx = dwarf_page * num_per_page + 1
				
				local max_page = math.floor(#dwarf_slice / num_per_page)
				
				imgui.Text("Page: " .. tostring(dwarf_page + 1) .. "/" .. tostring(max_page+1))
				
				if imgui.Button("Leave Vacant") then
					remove_from(squad_ids[selected_squad], selected_dwarf)
				end
				
				start_idx = math.max(start_idx, 1)
				
				local end_idx = start_idx + num_per_page - 1
				
				local rendered_count = 0
				
				for i=start_idx,end_idx do
					local unit = dwarf_slice[i]
					
					if unit == nil then
						goto skip
					end
					
					local unit_name = render.get_user_facing_name(unit)

					rendered_count = rendered_count+1

					--the reason for the ### indexing here is so that the keyboard nav
					--active highlight target remains the same across different pages
					if imgui.Button(unit_name .. "###namesel_" .. tostring(i-start_idx)) then
						appoint_to(squad_ids[selected_squad], selected_dwarf, unit)
					end

					::skip::
				end
				
				for i=rendered_count,num_per_page-1 do
					imgui.Text(" ")
				end
				
				imgui.NewLine()

				if render.render_hotkey_text({key="q", text="Prev"}) then
					dwarf_page = dwarf_page - 1
					
					dwarf_page = math.max(dwarf_page, 0)
				end
				
				imgui.SameLine()
				
				if render.render_hotkey_text({key="e", text="Next"}) then
					dwarf_page = dwarf_page + 1
					
					dwarf_page = math.max(dwarf_page, 0)
					dwarf_page = math.min(dwarf_page, max_page)
				end

				imgui.EndTable()
			end
		end
	end
end