local gui = require('gui')

MyScreen = defclass(MyScreen, gui.Screen)

state = false;

is_filtered = dfhack.imgui.Ref(false)

function MyScreen:render()
	self:renderParent()
	
	if(dfhack.imgui.IsKeyPressed(6)) then
		self:dismiss()
	end
	
    --[[dfhack.imgui.Begin("Script Title");
	dfhack.imgui.Text("Help I'm Trapped In A Script!!")
	
	if(dfhack.imgui.Button("Button")) then
		state = not state
	end
	
	dfhack.imgui.Text("Button State: " .. tostring(state))
	dfhack.imgui.End()]]--
	
	dfhack.imgui.Begin("Script 2")
	dfhack.imgui.Text("Two Windows! Send Help")
			
	dfhack.imgui.TextColored(COLOR_RED, "Bottom text")
	dfhack.imgui.Text("After Col")
	
	dfhack.imgui.Text("On Line")
	
	dfhack.imgui.SameLine()
	
	dfhack.imgui.Text("Line continuation")
	
	for i = 0,512 do
		if(dfhack.imgui.IsKeyPressed(i)) then
			dfhack.imgui.Text(tostring(i))
		end
	end
	
	dfhack.imgui.Checkbox("Filter Inputs", is_filtered);
	
	dfhack.imgui.Text("Want Capture Keyboard"..tostring(dfhack.imgui.WantCaptureKeyboard()))
	
	if dfhack.imgui.Get(is_filtered) then
		dfhack.imgui.EatKeyboardInputs()
	end
	
	dfhack.imgui.End()
end

function MyScreen:onDismiss()
    view = nil
end

--[[function MyScreen:onInput(keys)
	for k, v in pairs(keys) do
		dfhack.imgui.FeedUpwards(v)
	end
	
	return false
end]]--


screen = MyScreen{ }:show()