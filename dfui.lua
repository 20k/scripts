local gui = require('gui')
local designations = reqscript('dfui_designations')
local announcements = reqscript('dfui_announcements')
local building = reqscript('dfui_building')
local render = reqscript('dfui_render')

MyScreen = defclass(MyScreen, gui.Screen)

imgui = dfhack.imgui
last_hovered_announce_id = -1

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
				   {key="122", text="Status"},
				   {key="107", text="Look"},
				   {key="009", text="Move this menu/map"},
				   {key="063", text="Help"},
				   {key="027", text="Options"},
				   {key="059", text="Movies"},
				   {key="068", text="Depot Access"},
				   {key="032", text="Resume"},
				   {key="046", text="One-Step"}}

	local next_state = render.render_table_impl(menus, "main")
	
	if next_state ~= "main" then
		render.push_menu(next_state)
	end
end

function MyScreen:init()
	render.reset_menu_to("main")
end

function MyScreen:render()
	self:renderParent()
	
	--[[if(imgui.IsKeyPressed(6) and state == "main") then
		self:dismiss()
	end
	
	if(imgui.IsKeyPressed(6)) then
		state = "main"
		--self:dismiss()
	end]]--
	
	if imgui.IsKeyPressed(6) then
		render.pop_menu()
	end
	
	local text_style = imgui.StyleIndex("Text")
	
	imgui.PushStyleColor(text_style, {fg=COLOR_GREY, bg=COLOR_GREY})
	
	--I really need to sort out the constants
	imgui.Begin("Main")
	
	--root menu state
	local state = render.get_menu()
	
	if state == nil then
		self:dismiss()
	end
	
	if state == "View Announcements" then
		announcements.render_announcements()
	end
	
	if state == "Building" then
		building.render_buildings()
	end
	
	if state == "Designations" then
		designations.render_designations()
	end
	
	if state == "main" then
		render_menu()
	end
	
	imgui.End()
	
	imgui.PopStyleColor(1)
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