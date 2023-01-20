--@ module = true

imgui = dfhack.imgui
render = reqscript('dfui_render')
time = reqscript('dfui_libtime')

function brighten(col, should_bright)
	if not should_bright then
		return col
	end

	local arr = {7, 9, 10, 11, 12, 13, 14, 15, 15, 15, 15, 15, 15, 15, 15, 15}
	return arr[col + 1]
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

	if imgui.IsItemHovered() then
		df_year = report.year
		df_time = report.time

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

function on_hover_report(report)
	local df_time = report.time
	local df_year = report.year

	if df_time ~= -1 then
		local ymd = time.time_to_ymd(df_time)

		imgui.SetTooltip("Date: " .. tostring(ymd.day+1) .. time.ordinal_suffix(ymd.day+1) .. " "
							.. time.months()[ymd.month + 1]
							.. ", " .. tostring(df_year))

		--imgui.Text("Date: " .. tostring(df_time) .. ", " .. tostring(df_year))
	end
end

function render_announcements()
	render.set_can_window_pop(true)

	local reports = df.global.world.status.announcements
	local count = #reports

	local any_hovered_yet = false

	for i=0,(count-1) do
		local report = reports[i]

		render_report(report)

		if imgui.IsItemHovered() then
			on_hover_report(report)
		end

		if i == count-1 then
			if render.menu_was_changed() then
				imgui.SetScrollHereY()
			end
		end
	end

	if imgui.Button("Back") then
		render.pop_incremental()
	end

	render.menu_change_clear()
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
	render.set_can_window_pop(true)
	local reportable = get_reportable_units()

	if render.get_submenu() then
		local menu = render.get_submenu()

		local unit = df.unit.find(menu.id)

		if unit == nil then
			render.pop_submenu()
			return
		end

		local reports = get_reports_for(unit, menu.type)

		if #reports == 0 then
			imgui.Text("No recent reports")
		else
			for _,v in pairs(reports) do
				render_report(v.report)

				if imgui.IsItemHovered() then
					on_hover_report(v.report)
				end
			end
		end
	else
		local units_by_recent_reports = {}

		for o,unit in ipairs(reportable) do
			for i=0,2 do
				local reports = unit.reports.log[i]

				if #reports > 0 then
					local len = #unit.reports.log[i]

					table.insert(units_by_recent_reports, {unit=unit, sort=unit.reports.log[i][len - 1], last_report_id=unit.reports.log[i][len - 1], type=i})
				end
			end
		end

		function cmp(a,b)
			return a.sort > b.sort
		end

		table.sort(units_by_recent_reports, cmp)

		for _,v in ipairs(units_by_recent_reports) do
			local unit = v.unit
			local type = v.type

			local display_name = render.get_user_facing_name(unit)

			local report_str = get_unit_report_type_name(type)
			local report_col = get_unit_report_type_color(type)

			local to_display = display_name .. " " .. dfhack.df2utf(report_str)

			if imgui.ButtonColored({fg=report_col}, to_display .. "##" .. tostring(unit.id)) then
				render.push_submenu({id=unit.id, type=type})
			end

			if imgui.IsItemHovered() then
				local report = df.report.find(v.last_report_id)

				if report then
					on_hover_report(report)
				end
			end
		end
	end
end

--return _ENV