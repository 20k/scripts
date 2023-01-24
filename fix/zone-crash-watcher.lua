function fix_zone_crash()
	local valid_zones = {}

	for k, zone in ipairs(df.global.world.buildings.other.ACTIVITY_ZONE) do
		local azone = df.reinterpret_cast('uint64_t', zone)

		valid_zones[azone.value] = true
	end

	for k, unit in ipairs(df.global.world.units.active) do
		local old_size = #unit.owned_buildings

		for i=#unit.owned_buildings-1,0,-1 do
			local building = df.reinterpret_cast('uint64_t', unit.owned_buildings[i])

			if valid_zones[building.value] == nil then
				unit.owned_buildings:erase(i)
			end
		end

		if #unit.owned_buildings ~= old_size then
			dfhack.println("Removed", old_size - #unit.owned_buildings, "possibly invalid buildings from unit")
		end
	end
end

local gui = require('gui')

MyScreen = defclass(MyScreen, gui.Screen)

function MyScreen:render()
	if dfhack.imgui.IsKeyPressed("LEAVESCREEN") then
		self:dismiss()
	end

	if self._native and self._native.parent then
        self._native.parent:render()
    end

	fix_zone_crash()
end

function MyScreen:onIdle()
	if self._native and self._native.parent then
		self._native.parent:logic()
	end

	fix_zone_crash()
end

function MyScreen:onInput(keys)
	return self:sendInputToParent(keys)
end

function MyScreen:onDismiss()
	dfhack.println("Quit")
	view = nil
end

screen = MyScreen{ }:show()