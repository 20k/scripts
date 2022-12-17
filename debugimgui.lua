local gui = require('gui')

MyScreen = defclass(MyScreen, gui.Screen)

state = false;

function MyScreen:render()
	self:renderParent()
    dfhack.imgui.Begin("Script Title");
	dfhack.imgui.Text("Help I'm Trapped In A Script!!")
	
	if(dfhack.imgui.Button("Button")) then
		state = not state
	end
	
	dfhack.imgui.Text("Button State: " .. tostring(state))
	
	dfhack.imgui.End();
end

screen = MyScreen{ }:show()