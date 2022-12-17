local gui = require('gui')
local imgui = require('imgui')

MyScreen = defclass(MyScreen, gui.Screen)

function MyScreen:render()
	self:renderParent()
    dfhack.imgui.Begin()
	dfhack.imgui.Text("Help I'm Trapped In A Script!!")
	dfhack.imgui.End();
end

screen = MyScreen{ }:show()