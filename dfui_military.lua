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

function render_military()
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
	local squad_ids = {}
	local dwarf_histfigs_in_squads = {}
	local all_elegible_dwarf_units = get_valid_units()
	
	for _,squad_id in ipairs(entity.squads) do	
		local squad = df.squad.find(squad_id)
		
		if squad == nil then
			goto badsquad
		end
		
		local lsquad = {}
		
		for k,spos in ipairs(squad.positions) do
			local real_unit = nobles.histfig_to_unit(spos.occupant)
			
			if real_unit == nil then
				lsquad[k] = -1
				goto notreal
			end
			
			lsquad[k] = spos.occupant
			
			::notreal::
		end
		
		local next_id = #squad_ids + 1
		
		squad_ids[next_id] = squad_id
		dwarf_histfigs_in_squads[next_id] = lsquad
		
		::badsquad::
	end
	
	local selected_squad = 2
	
	local max_len = 10
	
	local columns = {squad_ids, dwarf_histfigs_in_squads, all_elegible_dwarf_units}
	
	if imgui.BeginTable("Tt1", 3, (1<<13)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();
		
		--[[for i=1,max_len do
			for c=1,3 do
				if i > #columns[c] then
					goto skip
				end
			
				if c == 1 then
					local squad_id = squad_ids[i]
					
					local squad = df.squad.find(squad_id)
					
					imgui.Text(get_squad_name(squad))
				end
				
				if c == 2 then
					local histfig = dwarf_histfigs_in_squads[selected_squad][i]
				
					if histfil ~= nil then
						if histfig == -1 then
							imgui.Text("Available")
						else
							local real_unit = nobles.histfig_to_unit(histfig)
							
							local unit_name = render.get_user_facing_name(real_unit)
						
							imgui.Text(unit_name)
						end
					end
				end
				
				if c == 3 then
					local unit = all_elegible_dwarf_units[i]
					
					if unit == nil then
						goto skip
					end
					
					local unit_name = render.get_user_facing_name(unit)
			
					imgui.Text(unit_name)
				end
				
				::skip::
			
				imgui.TableNextColumn();
			end
			
			imgui.TableNextRow();
			imgui.TableNextColumn();
		end]]--
		
		for _,i in ipairs(squad_ids) do
			local squad_id = i
			
			local squad = df.squad.find(squad_id)
			
			imgui.Text(get_squad_name(squad))
		end
		
		imgui.TableNextColumn()
		
		for _,histfig in pairs(dwarf_histfigs_in_squads[selected_squad]) do
			if histfig == -1 then
				imgui.Text("Available")
			else
				local real_unit = nobles.histfig_to_unit(histfig)
				
				local unit_name = render.get_user_facing_name(real_unit)
			
				imgui.Text(unit_name)
			end
		end
		
		imgui.TableNextColumn()
		
		for _,unit in ipairs(all_elegible_dwarf_units) do				
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
	
	--[[if imgui.BeginTable("Tt1", 1, (1<<13)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();
	
		for _,squad_id in ipairs(squad_ids) do
			local squad = df.squad.find(squad_id)
			
			imgui.Text(get_squad_name(squad))
			
			imgui.TableNextRow();
			imgui.TableNextColumn();
		end
	
		imgui.EndTable()
	end
	
	imgui.SameLine()
	
	local selected_squad = 1
	
	if imgui.BeginTable("Tt2", 1, (1<<13)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();
	
		for _,histfig in pairs(dwarf_histfigs_in_squads[selected_squad]) do
			--local squad = df.squad.find(squad_id)
			
			--imgui.Text(get_squad_name(squad))
			
			if histfig == -1 then
				imgui.Text("Available")
			else
				local real_unit = nobles.histfig_to_unit(histfig)
				
				local unit_name = render.get_user_facing_name(real_unit)
			
				imgui.Text(unit_name)
			end
			
			imgui.TableNextRow();
			imgui.TableNextColumn();
		end
	
		imgui.EndTable()
	end]]--
end