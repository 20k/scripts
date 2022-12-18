-- overlay plugin gui config
--@ module = true

local gui = require('gui')
local guidm = require('gui.dwarfmode')
local widgets = require('gui.widgets')

local overlay = require('plugins.overlay')

filterState = 0

function get_filter_name(state)
	if(state == 0) then
		return "overlays for the current screen"
	end
	
	if(state == 1) then
		return "all overlays"
	end
end

OverlayConfig = defclass(OverlayConfig, gui.Screen)

function OverlayConfig:init()
	self.scr_name = overlay.simplify_viewscreen_name(
            getmetatable(dfhack.gui.getCurViewscreen(true)))

	self.searchtext = dfhack.imgui.Ref("")
end

function OverlayConfig:render()
	self:renderParent()
	
	if(dfhack.imgui.IsKeyPressed(27)) then
		self:dismiss()
	end
	
	dfhack.imgui.Begin("Overlay ImGui Config")
	
	local mouse_pos = dfhack.imgui.GetMousePos();
	--local mouse_col = dfhack.imgui.Name2Col("WHITE", "WHITE", false)
	--dfhack.imgui.AddRectFilled({mouse_pos[1], mouse_pos[2]}, {mouse_pos[1], mouse_pos[2]}, mouse_col)
	
	local frame_colour = dfhack.imgui.Name2Col("GREEN", "GREEN", false)
	local frame_highlight_colour = dfhack.imgui.Name2Col("LIGHTGREEN", "LIGHTGREEN", false)
	
	local state = overlay.get_state()
	
	local cyan = dfhack.imgui.Name2Col("CYAN", "BLACK", false)
	local light_cyan = dfhack.imgui.Name2Col("LIGHTCYAN", "BLACK", false)
		
	dfhack.imgui.Text("Current screen: ")
	
	dfhack.imgui.SameLine()
	
	dfhack.imgui.TextColored(cyan, self.scr_name)
	
	local filter_name = "Showing: " .. get_filter_name(filterState)
	
	if(dfhack.imgui.Button(filter_name)) then
		filterState = (filterState + 1) % 2
	end
	
	dfhack.imgui.Text("Search:")
	
	dfhack.imgui.SameLine()

	if((dfhack.imgui.IsWindowFocused(0) or dfhack.imgui.IsWindowFocused(4)) and not dfhack.imgui.IsAnyItemActive()) then
		dfhack.imgui.SetKeyboardFocusHere(0);
	end
		
	dfhack.imgui.InputText("##InputSearch", self.searchtext)
	
	local real_search = dfhack.imgui.Get(self.searchtext)
		
	local to_set = {}
	
	for _,name in ipairs(state.index) do
		if(#real_search > 0) then
			if(string.find(name, real_search) == nil) then
				goto continue
			end
		end
	
		local db_entry = state.db[name]
        local widget = db_entry.widget
        if not widget.hotspot and filterState ~= 1 then
            local matched = false
            for _,scr in ipairs(overlay.normalize_list(widget.viewscreens)) do
                if overlay.simplify_viewscreen_name(scr) == self.scr_name then
                    matched = true
                    break
                end
            end
            if not matched then goto continue end
        end
		
		if not widget.overlay_only then
			local frame = widget.frame
			local rect = widget.frame_rect
						
			if mouse_pos[1] >= rect.x1-1 and mouse_pos[1] <= rect.x2 + 1 
			    and mouse_pos[2] >= rect.y1-1 and mouse_pos[2] <= rect.y2 + 1 then
				dfhack.imgui.AddBackgroundRectFilled({rect.x1, rect.y1}, {rect.x2, rect.y2}, frame_highlight_colour)				
			end
			
			dfhack.imgui.AddBackgroundRect({rect.x1-1, rect.y1-1}, {rect.x2+2, rect.y2+2}, frame_colour)

			--overlay.overlay_command({'position', name, posx, posy},true)
		end

		local cfg = state.config[name]

		local col = cfg.enabled and "LIGHTGREEN" or "YELLOW"
		local txt = cfg.enabled and "enabled" or "disabled"
		
		local col_imgui = dfhack.imgui.Name2Col(col, "BLACK", false)
		local style_index = dfhack.imgui.StyleIndex("ImGuiCol_Text")
		
		dfhack.imgui.PushStyleColor(style_index, col_imgui)

		if(dfhack.imgui.Button("[" .. txt .. "]##" .. name)) then
			cfg.enabled = not cfg.enabled
			
			local command = 'disable'
			
			if(cfg.enabled) then
				command = 'enable'
			end
			
			to_set[name] = command;
		end
		
		dfhack.imgui.PopStyleColor(1)
		
		dfhack.imgui.SameLine()
		
		if(not cfg.enabled) then
			dfhack.imgui.TextColored(cyan, name)
		else
			dfhack.imgui.TextColored(light_cyan, name)
		end
		
		::continue::
	end

	dfhack.imgui.End();
	
	for name, command in pairs(to_set) do
		--dfhack.imgui.Text(name)
		--dfhack.imgui.Text(command)
	
		overlay.overlay_command({command, name}, true)
	end
end

function OverlayConfig:onDismiss()
    view = nil
end

if dfhack_flags.module then
    return
end

view = view or OverlayConfig{}:show()
