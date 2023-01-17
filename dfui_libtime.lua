--@ module = true

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

function ticks_in_year()
	return ticks_in_month() * 12
end

function year_to_tick(year)
    return ticks_in_year() * year
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
