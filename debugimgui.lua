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
	dfhack.imgui.End()
	
	dfhack.imgui.Begin("Script 2")
	dfhack.imgui.Text("Two Windows! Send Help")
	
	local test_colour = dfhack.imgui.Name2Col("RED", "RED", 0)
		
	dfhack.imgui.TextColored(test_colour, "Bottom text")
	dfhack.imgui.Text("After Col")
	
	dfhack.imgui.Text("On Line")
	
	dfhack.imgui.SameLine()
	
	dfhack.imgui.Text("Line continuation")
	
	dfhack.imgui.End()
end

screen = MyScreen{ }:show()