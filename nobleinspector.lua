local gui = require('gui')

imgui = dfhack.imgui

Inspector = defclass(Inspector, gui.Screen)

function Inspector:init()
	
end

function fnd(array, fieldname, fieldvalue)
	--for _,v in ipairs(array) do
	for i=0,#array-1 do
		if array[i].id == fieldvalue then
			return array[i]
		end
	end
	
	return nil
end

function noble_position(unit)
	local histfig = df.historical_figure.find(unit.hist_figure_id)
		
	if histfig == nil then
		imgui.Text("No noble")
		return
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
			imgui.Text("no noble 2")
			goto notnoble
		end

		local assignment = fnd(entity.positions.assignments, "id", epos.assignment_id)
		
		if assignment == nil then
			imgui.Text("no noble 3")
			goto notnoble
		end
		
		local position = fnd(entity.positions.own, "id", assignment.position_id)
		
		if position == nil then 
			imgui.Text("no noble 4")
			goto notnoble
		end
		
		imgui.Text("Is noble")
		imgui.Text(position.code .. " pid " .. tostring(assignment.position_id) .. " aid " .. epos.assignment_id)
		
		--imgui.Text("Dbg pid " .. tostring(get_title_id(position.code, entity.id)) .. " aid " .. tostring(get_assignment_id(position.code, get_title_id(position.code, entity.id), entity.id)))
		
		imgui.Text("Eid: " .. tostring(epos.entity_id))
		imgui.Text("Fid: " .. tostring(df.global.ui.group_id))
				
		::notnoble::
	end
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

--[[function remove_title_from_anyone(titlename)
	local entity_id, position_id, assignment_id = entity_id_with_title(titlename)
	
	if entity_id == nil then
		return nil
	end
	
	local my_entity = df.historical_entity.find(entity_id)
	
	local assignment = fnd(my_entity.positions.assignments, "id", assignment_id)
	local position = fnd(my_entity.positions.own, "id", position_id)
		
	local current_hist_fig = df.historical_figure.find(assignment.histfig)
	
	---modify state
	assignment.histfig = -1

	for k,v in pairs(current_hist_fig.entity_links) do
		if df.histfig_entity_link_positionst:is_instance(v) and v.assignment_id==assignment_id and v.entity_id==entity_id then --hint:df.histfig_entity_link_positionst
			current_hist_fig.entity_links:erase(k)
			break
		end
	end
	
	return position_id, assignment_id
end

function add_title(position_id, assignment_id)

end

function take_title(unit, titlename)
	local newfig=dfhack.units.getNemesis(unit).figure
	
	local entity_id = entity_id_with_title(titlename)
	
	if entity_id == nil then
		return
	end
	
	local my_entity = df.historical_entity.find(entity_id)
	local title_id

	for k,v in pairs(my_entity.positions.own) do
		if v.code == titlename then
			title_id = v.id
			break
		end
	end
		
	if not title_id then return end

	local old_id
	for pos_id,v in pairs(my_entity.positions.assignments) do
		if v.position_id==title_id then
			old_id=v.histfig
			v.histfig=newfig.id
						
			local oldfig=df.historical_figure.find(old_id)

			for k,v in pairs(oldfig.entity_links) do
				if df.histfig_entity_link_positionst:is_instance(v) and v.assignment_id==pos_id and v.entity_id==entity_id then --hint:df.histfig_entity_link_positionst
					oldfig.entity_links:erase(k)
					break
				end
			end
			newfig.entity_links:insert("#",{new=df.histfig_entity_link_positionst,entity_id=entity_id,
				link_strength=100,assignment_id=pos_id,start_year=df.global.cur_year})
			break
		end
	end
end

--[[function dump_titles(eid)
	local my_entity=df.historical_entity.find(eid)

	for k, v in pairs(my_entity.positions.assignments) do
		imgui.Text(" Ass_id " .. v.id)
	end

	--for k,v in pairs(my_entity.positions.own) do
	--	imgui.Text(v.code .. " position_id " .. v.id)
	--end
end]]--

local function contains(table, val)
   for i=1,#table do
      if table[i] == val then 
         return true
      end
   end
   return false
end

function dump_titles(eid)
	local my_entity=df.historical_entity.find(eid)
	
	if my_entity == nil then
		return
	end
	
	for k,v in pairs(my_entity.positions.assignments) do 
		local position = fnd(my_entity.positions.own, "id", v.position_id)
		
		if position == nil then 
			goto borked
		end
		
		imgui.Text(position.code .. " position_id " .. position.id .. " ass_id " .. v.id .. " hist_fig " .. v.histfig )
		
		if #position.appointed_by > 0 then
			for i,j in pairs(position.appointed_by) do
				imgui.Text("Appointed by " .. tostring(j))
			end
		end
		
		if position.requires_population > 0 then
			imgui.Text("Pop required " .. position.requires_population)
		end
		
		--unk1-4 seem to be -1, unk 6 is 0
		--imgui.Text("Unk_1 " .. tostring(v.unk_1))
		--imgui.Text("Unk_2 " .. tostring(v.unk_2))
		--imgui.Text("Unk_3 " .. tostring(v.unk_3))
		--imgui.Text("Unk_4 " .. tostring(v.unk_4))
		--imgui.Text("Unk_6 " .. tostring(v.unk_6))
		--imgui.Text("Unk5 " .. tostring(#v.unk_5))
		
		for j,k in pairs(position.commander_id) do
			imgui.Text("Commanderid " .. tostring(k))
		end
		
		::borked::
	end
end

function basic_title_selector(unit)
	local codes = {"CHIEF_MEDICAL_DWARF", "EXPEDITION_LEADER"}

	local assignments = {}
	
	local my_entity=df.historical_entity.find(df.global.ui.group_id)
	
	if my_entity == nil then
		return
	end
	
	for k,v in pairs(my_entity.positions.assignments) do 
		local position = fnd(my_entity.positions.own, "id", v.position_id)
		
		if(contains(codes, position.code)) then
			assignments[#assignments+1] = v.id
		end
	end
	
	for k,v in ipairs(assignments) do
		if imgui.Button("Make " .. codes[k] .. "##" .. tostring(unit.id)) then
			add_or_transfer_fort_title_to(unit, v)
		end
	end
end

function Inspector:render()
	self:renderParent()
	
	if(imgui.IsKeyPressed(6)) then
		self:dismiss()
	end
	
	imgui.Begin("Hi")
	
	local units = df.global.world.units.active
	
	for i=0,#units-1 do
		local unit = units[i]
		
		local race_name = dfhack.df2utf(dfhack.units.getRaceName(unit))
		
		if race_name ~= "DWARF" then
			goto continue
		end
		
		local language_name = dfhack.units.getVisibleName(unit)
		
		local first_name = dfhack.df2utf(language_name.first_name)
		
		imgui.Text("Race: " .. race_name .. " : Name:" .. first_name) 
		
		--noble_position(unit)
		
		local unit_assignment_ids = get_unit_title_assignment_ids(unit)
		
		for k,v in ipairs(unit_assignment_ids) do
			local position_id = assignment_id_to_assignment(v).position_id
			
			local position = position_id_to_position(position_id)
			
			imgui.Text("Assignment: " .. position.code)
			
			if imgui.Button("Remove This Title##" .. tostring(unit.id)) then
				remove_fort_title(v)
			end
		end
		
		--basic_title_selector(unit)
		
		if imgui.Button("Make Expedition Leader##" .. tostring(unit.id)) then
			take_title(unit, "EXPEDITION_LEADER")
		end
		
		::continue::
	end
	
	--imgui.Text("Civ Titles:")
	
	--dump_titles(df.global.ui.civ_id)
	
	--imgui.Text("Site Titles")
	
	--dump_titles(df.global.ui.site_id)
	
	if imgui.Button("No medical dwarves!!") then
		remove_title_from_anyone("CHIEF_MEDICAL_DWARF")
	end
	
	imgui.Text("Group Titles")
	dump_titles(df.global.ui.group_id)
	
	--imgui.Text("Test?")
	--noble_position2(df.global.ui.civ_id)
	
	--doesn't exist
	--imgui.Text("Assigned group titles")
	--dump_assigned_titles(df.global.ui.group_id)
	
	imgui.End()
	
end

function Inspector:onDismiss()
	state = "main"
    view = nil
end

function Inspector:onInput(keys)
	if not imgui.WantCaptureInput()then
		imgui.FeedUpwards()
	end
end

screen = Inspector{ }:show()