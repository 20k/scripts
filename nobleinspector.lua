local gui = require('gui')

imgui = dfhack.imgui

Inspector = defclass(Inspector, gui.Screen)

function Inspector:init()
	
end

function noble_position(unit)

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