local gui = require('gui')
local designations = reqscript('dfui_designations')
local announcements = reqscript('dfui_announcements')
local building = reqscript('dfui_building')
local viewitems = reqscript('dfui_viewitems')
local render = reqscript('dfui_render')
local nobles = reqscript('dfui_nobles')
local setbuilding = reqscript('dfui_setbuilding')
local military = reqscript('dfui_military')

MyScreen = defclass(MyScreen, gui.Screen)

imgui = dfhack.imgui
last_hovered_announce_id = -1
one_step = false

function render_menu()
	local menus = {{key="097", text="View Announcements"},
				   {key="098", text="Building"},
				   {key="114", text="Reports"},
				   {key="099", text="Civilizations/World Info"},
				   {key="100", text="Designations"},
				   {key="111", text="Set Order"},
				   {key="117", text="Unit List"},
				   {key="106", text="Job List"},
				   {key="109", text="Military"},
				   {key="115", text="Squads"},
				   {key="078", text="Points/Routes/Notes"},
				   {key="119", text="Make Burrows"},
				   {key="104", text="Hauling"},
				   {key="112", text="Stockpiles"},
				   {key="105", text="Zones"},
				   {key="113", text="Set Building Tasks/Prefs"},
				   {key="082", text="View Rooms/Buildings"},
				   {key="116", text="View Items In Buildings"},
				   {key="118", text="View Units"},
				   {key="072", text="Hot Keys"},
				   {key="108", text="Locations and Occupations"},
				   {key="n",   text="Nobles and Administrators"},
				   {key="122", text="Status"},
				   {key="107", text="Look"},
				   {key="009", text="Move this menu/map"},
				   {key="063", text="Help"},
				   {key="027", text="Options"},
				   {key="059", text="Movies"},
				   {key="068", text="Depot Access"}}

	local is_paused = dfhack.world.ReadPauseState()

	if is_paused then
		menus[#menus + 1] = {key="032", text="Resume"}
		menus[#menus + 1] = {key="046", text="One-Step"}
	else
		menus[#menus + 1] = {key="032", text="Pause"}
	end

	local next_state = render.render_table_impl(menus, "main")

	if next_state == "Resume" then
		next_state = "main"

		dfhack.world.SetPauseState(false)
	end

	if next_state == "One-Step" then
		next_state = "main"
		one_step = true

		dfhack.world.SetPauseState(false)
	end

	if next_state == "Pause" then
		next_state = "main"

		dfhack.world.SetPauseState(true)
	end

	if next_state ~= "main" then
		render.push_menu(next_state)
	end
end

function MyScreen:init()
	render.reset_menu_to("main")
end

last_camera = {x=0, y=0}
has_last_camera = false

function render_stock()
	local zones = df.global.world.buildings.other[df.buildings_other_id.ACTIVITY_ZONE]

	local camera = render.get_camera()

	for i=0,(#zones-1) do
		local zone = zones[i]

		if not zone.room.extents or zone.z ~= camera.z then
			goto continue
		end

		local tl = {x=zone.room.x, y=zone.room.y}
		local size = {x=zone.room.width, y=zone.room.height}

		local br = {x=tl.x + size.x - 1, y=tl.y + size.y - 1}

		for x=tl.x,br.x do
			for y=tl.y,br.y do
				render.render_absolute_text("=", COLOR_GREY, COLOR_BLACK, {x=x+1, y=y+1, z=camera.z})
			end
		end

		::continue::
	end
end

function MyScreen:render()
	self:renderParent()

	if self._native and self._native.parent then
        self._native.parent:render()
    else
        dfhack.screen.clear()
    end

	df.global.gps.force_full_display_count = 1

	--[[if(imgui.IsKeyPressed(6) and state == "main") then
		self:dismiss()
	end

	if(imgui.IsKeyPressed(6)) then
		state = "main"
		--self:dismiss()
	end]]--

	if imgui.IsKeyPressed("LEAVESCREEN") and imgui.WantCaptureInput() then
		render.pop_menu()
	end

	local text_style = imgui.StyleIndex("Text")

	imgui.PushStyleColor(text_style, {fg=COLOR_GREY, bg=COLOR_GREY})

	--I really need to sort out the constants
	imgui.Begin("Main", 0, 1)

	local mouse_world_pos = render.get_mouse_world_coordinates()

	--imgui.Text(tostring(mouse_world_pos.x));
	--imgui.Text(tostring(mouse_world_pos.y));

	local state = render.get_menu()

	if state == nil then
		self:dismiss()
	end

	if state == "main" then
		render_menu()
	end

	if state == "View Items In Buildings" then
		viewitems.render_viewitems()
	end

	if state == "View Announcements" then
		announcements.render_announcements()
	end

	if state == "Building" then
		building.render_buildings()
	end

	if state == "Reports" then
		announcements.render_reports()
	end

	if state == "make_building" then
		building.render_make_building()
	end

	if state == "Designations" then
		designations.render_designations()
	end

	if state == "Stockpiles" then
		building.render_stockpiles()
	end

	if state == "Zones" then
		render_stock()
		building.render_zones()
	end

	if state == "Nobles and Administrators" then
		nobles.render_titles()
	end

	if state == "Set Building Tasks/Prefs" then
		setbuilding.render_setbuilding()
	end

	if state == "Military" then
		military.render_military()
	end

	if state == "Squads" then
		military.render_squads()
	end

	viewitems.handle_building_mouseover()
	viewitems.handle_unit_mouseover()

	if not imgui.IsMouseDragging(2) or not has_last_camera then
		last_camera = render.get_camera()
		has_last_camera = true
	end

	if imgui.IsMouseDragging(2) then
		local delta = imgui.GetMouseDragDelta(2)

		local next_camera = {x=last_camera.x - delta.x, y=last_camera.y - delta.y, z=render.get_camera().z}

		render.set_camera(next_camera.x, next_camera.y, next_camera.z)
	end

	imgui.End()

	imgui.PopStyleColor(1)
end

function MyScreen:onIdle()
	if self._native and self._native.parent then
		self._native.parent:logic()
	end

	if one_step then
		one_step = false
		dfhack.world.SetPauseState(true)
	end
end

function MyScreen:onDismiss()
	if self._native and self._native.parent then
        self._native.parent:render()
    else
        dfhack.screen.clear()
    end

	df.global.gps.force_full_display_count = 1

	state = "main"
    view = nil
end

function MyScreen:onInput(keys)
	if not imgui.WantCaptureInput() then
		imgui.FeedUpwards()
	end
end

screen = MyScreen{ }:show()