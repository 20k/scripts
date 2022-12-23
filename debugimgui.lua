local gui = require('gui')

MyScreen = defclass(MyScreen, gui.Screen)

state = false;

imgui = dfhack.imgui

is_filtered = imgui.Ref(false)
has_mouse = false

function MyScreen:render()
	self:renderParent()
	
	if(imgui.IsKeyPressed(6)) then
		self:dismiss()
	end
	
    --[[imgui.Begin("Script Title");
	imgui.Text("Help I'm Trapped In A Script!!")
	
	if(imgui.Button("Button")) then
		state = not state
	end
	
	imgui.Text("Button State: " .. tostring(state))
	imgui.End()]]--
	
	--I really need to sort out the constants
	imgui.Begin("Script 2", 0, (1<<10))
	
	if imgui.BeginMenuBar() then
		if imgui.BeginMenu("Menu") then
			imgui.Text("Hello!")
			
			imgui.EndMenu()
		end
		
		if imgui.BeginMenu("Second") then
			imgui.Button("I Click")
			
			imgui.EndMenu()
		end
		
		imgui.EndMenuBar()
	end
	
	imgui.Text("Two Windows! Send Help")
			
	imgui.TextColored(COLOR_RED, "Bottom text")
	imgui.Text("After Col")
	
	imgui.Text("On Line")
	
	imgui.SameLine()
	
	imgui.Text("Line continuation")
	
	--for i = 0,512 do
	--	if(imgui.IsKeyPressed(i)) then
	--		imgui.Text(tostring(i))
	--	end
	--end
	
	if imgui.IsKeyPressed("STRING_A097") then
		imgui.Text("A Pressed")
	end
	
	imgui.Checkbox("Block Inputs", is_filtered);
	
	imgui.Text("Want Capture Keyboard"..tostring(imgui.WantCaptureKeyboard()))
	
	--if imgui.Get(is_filtered) then
		--imgui.EatKeyboardInputs()
	--end
	imgui.Text("HasLMouseOnInput " .. tostring(has_mouse))
	has_mouse = false

	imgui.End()
end

function MyScreen:onDismiss()
    view = nil
end

function MyScreen:onInput(keys)
	if keys._MOUSE_L then
		has_mouse = true
		return
	end
	
	if not imgui.WantCaptureInput() and not imgui.Get(is_filtered) then
		imgui.FeedUpwards()
	end
end

screen = MyScreen{ }:show()