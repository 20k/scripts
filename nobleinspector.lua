local gui = require('gui')

imgui = dfhack.imgui

Inspector = defclass(Inspector, gui.Screen)

function Inspector:init()
	render.reset_menu_to("main")
end


function Inspector:render()
	self:renderParent()
	
	if(imgui.IsKeyPressed(6)) then
		state = "main"
		--self:dismiss()
	end
	
	imgui.Begin("Hi")
	
	local units = df.global.word.units.active
	
	for i=0,#units-1 do
		local unit = units[i]
		
		local race_name = dfhack.units.getRaceName(unit)
		local language_name = dfhack.units.getVisibleName(unit)
		
		local first_name = language_name.first_name
		
		imgui.Text("Race: " .. race_name .. " : Name:" .. first_name) 
	end
	
	imgui.End()
	
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