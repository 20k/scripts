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
		
		::notnoble::
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
		
		noble_position(unit)
		
		::continue::
	end
	
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