--@ module = true

imgui = dfhack.imgui

function onLoad() -- global variables are exported
    -- do initialization here
end

function brighten(col, should_bright)
	if not should_bright then
		return col
	end

	local arr = {7, 9, 10, 11, 12, 13, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15}
	return arr[col + 1]
end

function months()
	return {"Granite", "Slate", "Felsite", "Hematite","Malachite","Galena", "Limestone", "Sandstone","Timber", "Moonstone","Opal","Obsidian"}
end

function days_in_month()
	return 28
end

function days_in_year()
	return 336
end

function ticks_in_day()
	return 1200
end

function ticks_in_month()
	return ticks_in_day() * days_in_month()
end

function ordinal_suffix(which)
	local as_str = tostring(which)
	
	local back = as_str[#as_str]
	
	if back == 1 then
		return "st"
	end
	
	if back == 2 then
		return "nd"
	end
	
	if back == 3 then
		return "rd"
	end
		
	return "th"
end

function time_to_ymd(t)
	local fhour = t % 50
	local fday = (t / ticks_in_day()) % 28
	local fmonth = (t / ticks_in_month()) % 12
	local fyear = (t / (ticks_in_month() * 12))
	
	fhour = math.floor(fhour)
	fday = math.floor(fday)
	fmonth = math.floor(fmonth)
	fyear = math.floor(fyear)
	
	return {year=fyear, month=fmonth, day=fday, hour=fhour}
end

-- must be part of network api
function centre_camera(x, y, z)
	local sx = df.global.gps.dimx
	local sy = df.global.gps.dimy

	df.global.window_x = x - math.floor(sx/2)
	df.global.window_y = y - math.floor(sy/2)
	
	df.global.window_z = z
end

-- ideally should be part of network api
function render_absolute_text(str, fg, bg, pos)
	local draw_list = imgui.GetForegroundDrawList()
	
	imgui.AddTextBackgroundColoredAbsolute(draw_list, {fg=fg, bg=bg}, "X", pos)
end

function render_announcements()
	local reports = df.global.world.status.reports
	local count = #reports
		
	local df_year = -1
	local df_time = -1
	
	local any_hovered_yet = false
	
	for i=0,(count-1) do
		local report = reports[i]
	
		local a_type = report.type
		local text = dfhack.df2utf(report.text)
		local col = report.color
		local bright = report.bright
		
		local lx = report.pos.x
		local ly = report.pos.y
		local lz = report.pos.z
				
		col = brighten(col, bright)
		
		imgui.ButtonColored({fg=col}, text)
		
		if imgui.IsItemHovered() or (not any_hovered_yet and report.id == last_hovered_announce_id) then 
			df_year = report.year
			df_time = report.time
			
			last_hovered_announce_id = report.id
			
			local pos = {x=lx+1, y=ly+1, z=lz}
			
			render_absolute_text("X", COLOR_YELLOW, COLOR_BLACK, pos)
			
			if imgui.Shortcut("STRING_A122") and imgui.IsItemHovered() then
				centre_camera(lx, ly, lz)
			end
		end
		
		if imgui.IsItemClicked(0) then 
			centre_camera(lx, ly, lz)
		end
	end
	
	if df_time ~= -1 then
		local ymd = time_to_ymd(df_time)
		
		imgui.Text("Date: " .. tostring(ymd.day+1) .. ordinal_suffix(ymd.day+1) .. " "
							.. months()[ymd.month + 1]
							.. ", " .. tostring(df_year))
	
		--imgui.Text("Date: " .. tostring(df_time) .. ", " .. tostring(df_year))
	end
end

--return _ENV