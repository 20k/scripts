local gui = require('gui')

MyScreen = defclass(MyScreen, gui.Screen)

function MyScreen:render()
	self:renderParent()
    dfhack.internal.debugImGui()
end

screen = MyScreen{ }:show()