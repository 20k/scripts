--@ module = true

imgui = dfhack.imgui
render = reqscript('dfui_render')

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

function render_report(report)
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

		render.render_absolute_text("X", COLOR_YELLOW, COLOR_BLACK, pos)

		if imgui.Shortcut("STRING_A122") and imgui.IsItemHovered() then
			render.centre_camera(lx, ly, lz)
		end
	end

	if imgui.IsItemClicked(0) then
		render.centre_camera(lx, ly, lz)
	end
end

function render_announcements()
	local reports = df.global.world.status.announcements
	local count = #reports

	local df_year = -1
	local df_time = -1

	local any_hovered_yet = false

	for i=0,(count-1) do
		local report = reports[i]

		render_report(report)
	end

	if imgui.Button("Back") or ((imgui.IsWindowFocused(0) or imgui.IsWindowHovered(0)) and imgui.IsMouseClicked(1)) then
		render.pop_menu()
	end

	if df_time ~= -1 then
		local ymd = time_to_ymd(df_time)

		imgui.Text("Date: " .. tostring(ymd.day+1) .. ordinal_suffix(ymd.day+1) .. " "
							.. months()[ymd.month + 1]
							.. ", " .. tostring(df_year))

		--imgui.Text("Date: " .. tostring(df_time) .. ", " .. tostring(df_year))
	end
end

function valid_unit(unit)
	if dfhack.units.isHidden(unit) then
		return false
	end

	if #unit.reports.log[0] == 0 and #unit.reports.log[1] == 0 and #unit.reports.log[2] == 0 then
		return false
	end

	return true
end

function lookup_report(id)
	return df.report.find(id)
end

function get_reportable_units()
	local result = {}

	local units = df.global.world.units.active

	for i=0,#units-1 do
		local unit = units[i]

		if not valid_unit(unit) then
			goto continue
		end

		result[#result+1] = unit

		::continue::
	end

	return result
end

local function get_reports_for_impl(into, unit, type)
	if type == nil then
		get_reports_for_impl(into, unit, 0)
		get_reports_for_impl(into, unit, 1)
		get_reports_for_impl(into, unit, 2)
		return
	end

	for _,report_id in ipairs(unit.reports.log[type]) do
		local report = lookup_report(report_id)

		if report then
			into[#into+1] = {type=type, report=report}
		end
	end
end

function get_reports_for(unit, type)
	local reports = {}
	get_reports_for_impl(reports, unit, type)
	return reports
end

--unit_report_type.h
--different order for types from other places
function get_unit_report_type_name(type)
	if type == 0 then
		return "is fighting!"
	end

	if type == 1 then
		return "is sparring"
	end

	if type == 2 then
		return "is hunting"
	end

	return "Error in get_unit_report_type_name"
end

function get_unit_report_type_color(type)
	if type == 0 then
		return COLOR_LIGHTRED
	end

	if type == 1 then
		return COLOR_LIGHTCYAN
	end

	if type == 2 then
		return COLOR_GREY
	end

	return COLOR_WHITE
end

--todo: recency
function render_reports()
	local reportable = get_reportable_units()

	if render.get_menu_item() then
		local menu = render.get_menu_item()

		local unit = df.unit.find(menu.id)

		if unit == nil then
			render.set_menu_item(nil)
			return
		end

		local reports = get_reports_for(unit, menu.type)

		for _,v in ipairs(reports) do
			render_report(v.report)
		end
	else
		for o,unit in ipairs(reportable) do
			local display_name = render.get_user_facing_name(unit)

			for i=0,2 do
				local reports = get_reports_for(unit, i)

				if #reports > 0 then
					local report_str = get_unit_report_type_name(i)
					local report_col = get_unit_report_type_color(i)

					local to_display = display_name .. " " .. dfhack.df2utf(report_str)

					if imgui.ButtonColored({fg=report_col}, to_display .. "##" .. tostring(unit.id)) then
						render.set_menu_item({id=unit.id, type=i})
					end
				end
			end
		end
	end

	if imgui.IsMouseClicked(1) and imgui.WantCaptureMouse() then
		if render.get_menu_item() ~= nil then
			render.set_menu_item(nil)
		else
			render.pop_menu()
		end
	end
end

--return _ENV