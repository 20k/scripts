local gui = require('gui')

MyScreen = defclass(MyScreen, gui.Screen)

imgui = dfhack.imgui
state = "main"

function brighten(col, should_bright)
	if not should_bright then
		return col
	end

	local arr = {7, 9, 10, 11, 12, 13, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15}
	return arr[col + 1]
end

function render_announcements()
	local reports = df.global.world.status.reports
	local count = #reports
		
	for i=0,(count-1) do
		local report = reports[i]
	
		local a_type = report.type
		local text = dfhack.df2utf(report.text)
		local col = report.color
		local bright = report.bright
		
		--imgui.Text(tostring(col) .. " " ..tostring(bright))
		
		col = brighten(col, bright)
		
		imgui.TextColored({fg=col}, text)
	end
end

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
	
	local last_merged = false
	
	if dfhack.imgui.BeginTable("Table", 2, (1 << 20)) then
		dfhack.imgui.TableNextRow();
		dfhack.imgui.TableNextColumn();
			for k, v in ipairs(menus) do
			local keyboard_key = "STRING_A" .. v.key
		
			local shortcut_name = imgui.GetKeyDisplay(keyboard_key)
			
			imgui.TextColored(COLOR_LIGHTGREEN, shortcut_name)
			imgui.SameLine(0,0)
			imgui.Text(": ")
			imgui.SameLine(0,0)
			
			local description = v.text
			
			if imgui.Button(description) or imgui.Shortcut(keyboard_key) then
				state = description
			end
			
			if #description < 13 and not last_merged then
				--imgui.SameLine()
				dfhack.imgui.TableNextColumn();
				
				last_merged = true
			else
				dfhack.imgui.TableNextRow();
				dfhack.imgui.TableNextColumn();
			
				last_merged = false
			end
		end
		
		dfhack.imgui.EndTable()
	end
end

function MyScreen:render()
	self:renderParent()
	
	if(imgui.IsKeyPressed(6) and state == "main") then
		self:dismiss()
	end
	
	if(imgui.IsKeyPressed(6)) then
		state = "main"
		--self:dismiss()
	end
	
	local text_style = imgui.StyleIndex("Text")
	
	imgui.PushStyleColor(text_style, {fg=COLOR_GREY, bg=COLOR_GREY})
	
	--I really need to sort out the constants
	imgui.Begin("Main")
	
	if state == "main" then
		render_menu()
	end
	
	if state == "View Announcements" then
		render_announcements()
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