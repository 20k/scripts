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
	
	local dwarf_count = 20
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
	
	local selected_squad = 2
			
	if imgui.BeginTable("Tt1", 3, (1<<13)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();

		for _,i in ipairs(squad_ids) do
			local squad_id = i
			
			local squad = df.squad.find(squad_id)
			
			imgui.Text(get_squad_name(squad))
		end
		
		imgui.TableNextColumn()
		
		for _,histfig in ipairs(dwarf_histfigs_in_squads[selected_squad]) do
			if histfig == -1 then
				imgui.Text("Available")
			else
				local real_unit = nobles.histfig_to_unit(histfig)
				
				local unit_name = render.get_user_facing_name(real_unit)
			
				imgui.Text(unit_name)
			end
		end
		
		imgui.TableNextColumn()
		
		for _,unit in ipairs(dwarf_slice) do				
			if unit == nil then
				goto skip
			end
			
			local unit_name = render.get_user_facing_name(unit)
	
			imgui.Text(unit_name)
			
			::skip::
		end
		
		imgui.TableNextColumn();
		
		imgui.EndTable()
	end
end