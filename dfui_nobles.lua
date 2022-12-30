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

function render_titles()
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
	if entity == nil then
		return nil
	end
	
	local menu_item = render.get_menu_item()
	
	if menu_item == nil then 
		for k,v in pairs(entity.positions.assignments) do 
			local current_assignment_id = v.id
			
			local position = position_id_to_position(assignment_to_position(current_assignment_id))
			
			local units = df.global.world.units.active
			
			imgui.Text(position.code)
			
			local any_holders = false
			
			for i=0,#units-1 do
				local unit = units[i]
				
				if not valid_unit(unit) then
					goto continue
				end
				
				local titles = get_unit_title_assignment_ids(unit)
				
				for _,aid in ipairs(titles) do
					if aid == current_assignment_id then
						any_holders = true
					
						local name_type = dfhack.units.getVisibleName(unit)
						
						local display = dfhack.df2utf(dfhack.TranslateName(name_type, false, false))
						
						imgui.SameLine()
						
						imgui.Text(display)
						
						imgui.SameLine()
						
						if imgui.Button("Remove?##" .. tostring(unit.id)) then
							remove_fort_title(aid)
							goto continue
						end
					end
				end
				::continue::
			end		

			if not any_holders then
				imgui.SameLine()
			
				if imgui.Button("Appoint?##" .. tostring(current_assignment_id)) then
					render.set_menu_item(current_assignment_id)
				end
			end
		end
	else
		
		
		if imgui.Button("Back") then	
			render.set_menu_item(nil)
		end
	end
end