local gui = require('gui')

MyScreen = defclass(MyScreen, gui.Screen)

state = false;

function MyScreen:render()
	self:renderParent()
	
	if(dfhack.imgui.IsKeyPressed(27)) then
		self:dismiss()
	end
	
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
	
	for i = 0,512 do
		if(dfhack.imgui.IsKeyPressed(i)) then
			dfhack.imgui.Text(tostring(i))
		end
	end
	
	dfhack.imgui.End()
end

screen = MyScreen{ }:show()