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

function render_military()
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
	local squad_ids = {}
	local dwarf_histfigs_in_squads = {}
	local all_elegible_dwarf_units = last_dwarf_list
	
	if render.menu_was_changed() or all_elegible_dwarf_units == nil then
		all_elegible_dwarf_units = get_valid_units()
		last_dwarf_list = all_elegible_dwarf_units
		render.menu_change_clear()
	end
	
	local dwarf_count = 300
	local start_dwarf = 1
	
	start_dwarf = math.min(start_dwarf, (#all_elegible_dwarf_units-dwarf_count) + 1)
	start_dwarf = math.max(start_dwarf, 0)
	
	for _,squad_id in ipairs(entity.squads) do	
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
	
	if selected_squad == -1 and #squad_ids > 0 then
		selected_squad = 1
	end

	if imgui.BeginTable("Tt1", 3, (1<<13)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();

		for o,i in ipairs(squad_ids) do
			local squad_id = i

			local squad = df.squad.find(squad_id)

			if imgui.Selectable(get_squad_name(squad).."##squadname_" .. tostring(squad_id), selected_squad == o) then
				selected_squad = o
			end
		end
		
		imgui.TableNextColumn()
		
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
		
		imgui.TableNextColumn()
		
		if selected_squad ~= -1 then
			if imgui.Button("Leave Vacant") then
				remove_from(squad_ids[selected_squad], selected_dwarf)
			end
		end
		
		for _,unit in ipairs(dwarf_slice) do				
			if unit == nil then
				goto skip
			end
			
			local unit_name = render.get_user_facing_name(unit)
	
			if selected_squad ~= -1 and selected_dwarf ~= -1 then
				if imgui.ButtonColored({fg=COLOR_GREEN}, "[A]##"..tostring(unit.id)) then
					appoint_to(squad_ids[selected_squad], selected_dwarf, unit)
				end
				
				imgui.SameLine()
			end
	
			imgui.Text(unit_name)
			
			::skip::
		end
		
		imgui.TableNextColumn();
		
		imgui.EndTable()
	end
end