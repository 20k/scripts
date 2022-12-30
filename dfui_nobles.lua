--@ module = true

local gui = require('gui')

imgui = dfhack.imgui
render = reqscript('dfui_render')

function fnd(array, fieldname, fieldvalue)
	--for _,v in ipairs(array) do
	for i=0,#array-1 do
		if array[i].id == fieldvalue then
			return array[i]
		end
	end
	
	return nil
end

function assignment_to_position(assignment_id)
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
	if entity == nil then
		return nil
	end
	
	local assignment = fnd(entity.positions.assignments, "id", assignment_id)
	
	if assignment == nil then
		return nil
	end
	
	return assignment.position_id
end

function assignment_id_to_assignment(assignment_id)
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
	if entity == nil then
		return nil
	end
	
	return fnd(entity.positions.assignments, "id", assignment_id)
end

function position_id_to_position(id)
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
	if entity == nil then
		return nil
	end
	
	return fnd(entity.positions.own, "id", id)
end

--won't remove eg monarch
function remove_fort_title(assignment_id)
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
	if entity == nil then
		return nil
	end
	
	local assignment = fnd(entity.positions.assignments, "id", assignment_id)
	
	if assignment == nil then
		return
	end

	local current_hist_fig = df.historical_figure.find(assignment.histfig)
		
	if current_hist_fig ~= nil then
		for k,v in pairs(current_hist_fig.entity_links) do
			if df.histfig_entity_link_positionst:is_instance(v) and v.assignment_id==assignment_id and v.entity_id==entity.id then --hint:df.histfig_entity_link_positionst
				current_hist_fig.entity_links:erase(k)
				
				break
			end
		end
	end
	
	assignment.histfig = -1
	
	return nil
end

--doesn't work for eg monarch
function add_or_transfer_fort_title_to(unit, assignment_id)	
	local assignment = assignment_id_to_assignment(assignment_id)
	
	if assignment == nil then
		return
	end
	
	local newfig=dfhack.units.getNemesis(unit).figure
	
	if newfig == nil then
		return
	end
	
	remove_fort_title(assignment_id)
	
	newfig.entity_links:insert("#",{new=df.histfig_entity_link_positionst,entity_id=df.global.ui.group_id,
				link_strength=100,assignment_id=assignment_id,start_year=df.global.cur_year})
				
	assignment.histfig=newfig.id
end

function get_unit_title_assignment_ids(unit)
	local titles = {}

	local histfig = df.historical_figure.find(unit.hist_figure_id)

	if histfig == nil then
		return titles
	end
	
	local entity_links = histfig.entity_links
	
	for i=0,#entity_links-1 do
		local link = entity_links[i]
		
		if not df.is_instance(df.histfig_entity_link_positionst, link) then
			goto notnoble
		end
		
		local epos = link
		
		local entity = df.historical_entity.find(epos.entity_id)
		
		if entity == nil then
			--imgui.Text("no noble 2")
			goto notnoble
		end
				
		local assignment = fnd(entity.positions.assignments, "id", epos.assignment_id)
		
		if assignment == nil then
			--imgui.Text("no noble 3")
			goto notnoble
		end
		
		local position = fnd(entity.positions.own, "id", assignment.position_id)
		
		if position == nil then 
			--imgui.Text("no noble 4")
			goto notnoble
		end
		
		titles[#titles+1] = assignment.id
		
		::notnoble::
	end
		
	return titles
end

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
	
	return true
end

function get_name(unit)
	local name_type = dfhack.units.getVisibleName(unit)
	
	return dfhack.df2utf(dfhack.TranslateName(name_type, false, false))
end

local override_noble_assignments = imgui.Ref(false)

function is_elected_position(position)
	for k,v in pairs(position.flags) do
		if tostring(k) == "ELECTED" and v then
			return true
		end
	end
	
	return false
end

function anyone_in_position(position_id)
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
	if entity == nil then
		return false
	end
	
	for k,v in pairs(entity.positions.assignments) do
		local assignment = v
		
		if assignment ~= nil then
			if assignment.position_id == position_id and assignment.histfig ~= -1 then
				return true
			end
		end
	end
	
	return false
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

function can_appoint(position)
	if is_elected_position(position) then
		return false
	end

	local appoint_satisfied = false

	for k,v in ipairs(position.appointed_by) do
		if anyone_in_position(v) then
			appoint_satisfied = true
			break
		end
	end
	
	if not appoint_satisfied then
		return false
	end
	
	if position.requires_population == 0 then
		return appoint_satisfied
	end

	return #get_valid_units() >= position.requires_population
end

function render_titles()
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
	if entity == nil then
		return nil
	end
	
	local menu_item = render.get_menu_item()
	
	local override = imgui.Get(override_noble_assignments)
	
	local count = 3
	
	if override then
		count = 4
	end
	
	if menu_item == nil then 
		if imgui.BeginTable("NobleTable", count, (1<<13)) then
			imgui.TableNextRow();
			imgui.TableNextColumn();
		
			for k,v in pairs(entity.positions.assignments) do
				local current_assignment_id = v.id
				
				local position = position_id_to_position(assignment_to_position(current_assignment_id))

				local is_valid_removable = (anyone_in_position(position.id) and not is_elected_position(position)) or override
				local is_valid_appointable = can_appoint(position) or override
				
				local units = df.global.world.units.active
				
				if (not is_valid_removable) and (not is_valid_appointable) then
					goto invalid
				end
				
				imgui.Text(position.name[0])
				
				imgui.TableNextColumn()
				
				local extra_info = nil
								
				local table_count = 0
				
				if (not anyone_in_position(position.id) and is_valid_appointable) or override then		
					table_count = table_count+1
				
					if imgui.ButtonColored({fg=COLOR_GREEN}, "[Set]##" .. tostring(current_assignment_id)) then
						render.set_menu_item(current_assignment_id)
					end
					
					if imgui.IsItemHovered() then
						imgui.SetTooltip("Appoint Position")
					end
					
					imgui.TableNextColumn()
				end
				
				for i=0,#units-1 do
					local unit = units[i]
					
					if not valid_unit(unit) then
						goto continue
					end
					
					local titles = get_unit_title_assignment_ids(unit)
					
					for _,aid in ipairs(titles) do
						if aid == current_assignment_id then
							if is_valid_removable then
								table_count = table_count+1
							
								if imgui.ButtonColored({fg=COLOR_RED}, "[R]##" .. tostring(unit.id) .. "_" .. tostring(current_assignment_id)) then
									remove_fort_title(aid)
									goto continue
								end
								
								if imgui.IsItemHovered() then
									imgui.SetTooltip("Remove Position")
								end
							end
							
							imgui.TableNextColumn()
							
							extra_info = get_name(unit)
						end
					end
					::continue::
				end

				if extra_info ~= nil then
					if table_count == 1 and override then
						imgui.TableNextColumn()
					end
				
					imgui.Text(extra_info)
				end
				
				imgui.TableNextRow();
				imgui.TableNextColumn();
				
				::invalid::
			end
			
			imgui.EndTable()
		end
		
		if imgui.Button("Back") then	
			render.pop_menu()
		end
	else
		local units = df.global.world.units.active
		
		for i=0,#units-1 do
			local unit = units[i]
			
			if not valid_unit(unit) then
				goto continue
			end
			
			local name = get_name(unit)
			
			if imgui.Button(name .. "##" .. tostring(unit.id) .. "_" .. tostring(menu_item)) then
				add_or_transfer_fort_title_to(unit, menu_item)
				render.set_menu_item(nil)
				
				goto done
			end
			
			::continue::
		end
		
		::done::
		
		if imgui.Button("Back") then	
			render.set_menu_item(nil)
		end
	end

	imgui.Checkbox("Dev: Override noble assignments", override_noble_assignments)
end