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
	self.dragging = false
	self.drag_name = ""
	self.hovered = "";
	self.inputfocused = false
end

function clamp(x, left, right)
	if x < left then
		return left
	end
	
	if x > right then
		return right
	end
	
	return x
end

function on_drag(name, delta)
	local state = overlay.get_state()
	local my_config = state.config[name];
	
	local next_x = tonumber(my_config.pos.x) + delta[1]
	local next_y = tonumber(my_config.pos.y) + delta[2]
	
	local display_size = dfhack.imgui.GetDisplaySize()
	
	if tonumber(my_config.pos.x) > 0 then
		next_x = clamp(next_x, 1, display_size[1] - 1)
	end

	if tonumber(my_config.pos.x) < 0 then
		next_x = clamp(next_x, -display_size[1] + 1, -1)
	end

	if tonumber(my_config.pos.y) > 0 then
		next_y = clamp(next_y, 1, display_size[2] - 1)
	end
	
	if tonumber(my_config.pos.y) < 0 then
		next_y = clamp(next_y, -display_size[2] + 1, -1)
	end

	overlay.overlay_command({'position', name, tostring(next_x), tostring(next_y)},true)

	dfhack.imgui.ResetMouseDragDelta(0)
end

function OverlayConfig:render()
	self:renderParent()
	
	if(dfhack.imgui.IsKeyPressed(6)) then
		self:dismiss()
	end
	
	local display_size = dfhack.imgui.GetDisplaySize()
	
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
	
	dfhack.imgui.NewLine()
	
	local filter_name = "Showing: " .. get_filter_name(filterState)
	
	if(dfhack.imgui.Button(filter_name)) then
		filterState = (filterState + 1) % 2
	end
	
	dfhack.imgui.NewLine()
	
	if self.inputfocused then
		dfhack.imgui.PushStyleColor(dfhack.imgui.StyleIndex("ImGuiCol_Text"), dfhack.imgui.Name2Col("RED", "BLACK", false))
	end
	
	dfhack.imgui.Text("Search:")
	
	if self.inputfocused then
		dfhack.imgui.PopStyleColor(1)
	end
		
	dfhack.imgui.SameLine()

	if((dfhack.imgui.IsWindowFocused(0) or dfhack.imgui.IsWindowFocused(4)) and not dfhack.imgui.IsAnyItemActive()) then
		--dfhack.imgui.SetKeyboardFocusHere(0);
	end
		
	dfhack.imgui.InputText("##InputSearch", self.searchtext)

	self.inputfocused = dfhack.imgui.IsItemFocused()

	dfhack.imgui.NewLine()

	dfhack.imgui.AddNavGate()

	local real_search = dfhack.imgui.Get(self.searchtext)
		
	local to_set = {}
	local any_hovered = false;
	
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
		
		local cfg = state.config[name]
		
		local textcolor = light_cyan
		
		if(not cfg.enabled) then
			textcolor = cyan
		end

		local col = cfg.enabled and "LIGHTGREEN" or "YELLOW"
		local txt = cfg.enabled and "enabled" or "disabled"
		
		local col_imgui = dfhack.imgui.Name2Col(col, "BLACK", false)
		local style_index = dfhack.imgui.StyleIndex("ImGuiCol_Text")
		
		dfhack.imgui.BeginGroup()
		
		dfhack.imgui.PushStyleColor(style_index, col_imgui)

		dfhack.imgui.TextColored(textcolor, "[")
		dfhack.imgui.SameLine(0,0)

		if(dfhack.imgui.Button(txt.. "###enable" .. name)) then
			cfg.enabled = not cfg.enabled
			
			local command = 'disable'
			
			if(cfg.enabled) then
				command = 'enable'
			end
			
			to_set[name] = command;
		end
		
		dfhack.imgui.SameLine(0,0)
		dfhack.imgui.TextColored(textcolor, "]")
		
		dfhack.imgui.PushStyleColor(style_index, dfhack.imgui.Name2Col("RED", "BLACK", false))
		
		dfhack.imgui.SameLine()
		
		dfhack.imgui.TextColored(textcolor, "[")
		dfhack.imgui.SameLine(0,0)
		
		if dfhack.imgui.Button("reset###reset"..name) then
			overlay.overlay_command({'position', name, 'default'}, true)
		end
		
		dfhack.imgui.SameLine(0,0)
		dfhack.imgui.TextColored(textcolor, "]")
		
		dfhack.imgui.PushStyleColor(style_index, dfhack.imgui.Name2Col("YELLOW", "BLACK", false))
		
		dfhack.imgui.SameLine()
		
		local next_x = cfg.pos.x
		local next_y = cfg.pos.y
		local dirty_anchor = false
		local widget_width = widget.frame_rect.x2 - widget.frame_rect.x1		
		local widget_height = widget.frame_rect.y2 - widget.frame_rect.y1		

		if cfg.pos.x < 0 then
			if dfhack.imgui.Button("R###LT"..name) then		
				if cfg.pos.x < 0 then
					next_x = display_size[1] + cfg.pos.x - widget_width + 1
					dirty_anchor = true
				end
			end
			
			if dfhack.imgui.IsItemHovered() then
				dfhack.imgui.SetTooltip("Right Anchored")
			end
		else 
			if dfhack.imgui.Button("L###LT"..name) then		
				if cfg.pos.x > 0 then
					next_x = -display_size[1] + cfg.pos.x + widget_width - 1
					dirty_anchor = true
				end
			end
			
			if dfhack.imgui.IsItemHovered() then
				dfhack.imgui.SetTooltip("Left Anchored")
			end
		end
		
		dfhack.imgui.SameLine()
		
		if cfg.pos.y < 0 then
			if dfhack.imgui.Button("B###RT"..name) then
				if cfg.pos.y < 0 then
					next_y = display_size[2] + cfg.pos.y - widget_height + 1
					dirty_anchor = true
				end
			end
			
			if dfhack.imgui.IsItemHovered() then
				dfhack.imgui.SetTooltip("Bottom Anchored")
			end
		else
			if dfhack.imgui.Button("T###RT"..name) then
				if cfg.pos.y > 0 then
					next_y = -display_size[2] + cfg.pos.y + widget_height - 1
					dirty_anchor = true
				end
			end
			
			if dfhack.imgui.IsItemHovered() then
				dfhack.imgui.SetTooltip("Top Anchored")
			end
		end
				
		if dirty_anchor then
			overlay.overlay_command({'position', name, tostring(next_x), tostring(next_y)},true)
		end
		
		dfhack.imgui.PopStyleColor(3)
		
		dfhack.imgui.SameLine()
		
		if self.hovered == name then
			textcolor = dfhack.imgui.Name2Col("LIGHTMAGENTA", "BLACK", false)
		end
		
		dfhack.imgui.BeginGroup()
		
		dfhack.imgui.TextColored(textcolor, name)
		
		dfhack.imgui.EndGroup()

		if dfhack.imgui.IsItemHovered() then
			self.hovered = name
			any_hovered = true
		end

		dfhack.imgui.EndGroup()
		
		local border_col = frame_colour
		
		if not dfhack.imgui.IsItemHovered() then
			border_col = dfhack.imgui.Name2Col("GREY", "GREY", false)
		end
		
		if not widget.overlay_only then
			local frame = widget.frame
			local rect = widget.frame_rect

			if mouse_pos[1] >= rect.x1-1 and mouse_pos[1] <= rect.x2 + 1 
			    and mouse_pos[2] >= rect.y1-1 and mouse_pos[2] <= rect.y2 + 1 then
				dfhack.imgui.AddBackgroundRectFilled({rect.x1, rect.y1}, {rect.x2, rect.y2}, frame_highlight_colour)				

				if not dfhack.imgui.WantCaptureMouse() and dfhack.imgui.IsMouseDragging(0) and not self.dragging then
					self.drag_name = name;
					self.dragging = true;
				end
				
				self.hovered = name
				any_hovered = true
			end
			
			dfhack.imgui.AddBackgroundRect({rect.x1-1, rect.y1-1}, {rect.x2+2, rect.y2+2}, border_col)
		end
		
		if self.dragging and dfhack.imgui.IsMouseDragging(0) and self.drag_name == name then
			on_drag(name, dfhack.imgui.GetMouseDragDelta(0))
		end

		
		::continue::
	end

	dfhack.imgui.End();
	
	if self.dragging and not dfhack.imgui.IsMouseDragging(0) then
		self.dragging = false;
	end
	
	if not any_hovered then
		self.hovered = ""
	end
	
	for name, command in pairs(to_set) do
		overlay.overlay_command({command, name}, true)
	end
end

function OverlayConfig:onDismiss()
    view = nil
end

function OverlayConfig:onInput(keys)
	if dfhack.imgui.WantCaptureKeyboard() then
		return true
	end
	
	return self:inputToSubviews(keys)
end

if dfhack_flags.module then
    return
end

view = view or OverlayConfig{}:show()
