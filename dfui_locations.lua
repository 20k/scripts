--@ module = true
imgui = dfhack.imgui
render = reqscript('dfui_render')

function get_locations()
    local world_site = df.global.plotinfo.main.fortress_site

    local result = {}

	for k,location in ipairs(world_site.buildings) do
        result[#result+1] = location
    end

    return result
end

function get_location_name(location)
    local language_name = location:getName()

    return dfhack.TranslateName(language_name, true)
end

function display_location_selector()
    local locations = get_locations()

    local which = nil
    local clicked = false

    if imgui.Button("Leave Vacant##locationselector") then
        clicked = true
    end

    for k,location in ipairs(locations) do
        if imgui.Button(get_location_name(location).."##location") then
            which = location
            clicked = true
        end
    end

    return which, clicked
end

function get_zone_location(zone)
    --assume its associated with the world site. It probably is
    local locations = get_locations()

    for k,v in ipairs(locations) do
        if v.id == zone.location_id then
            return v
        end
    end

    return nil
end

function on_assign_location(zone, location)
    if location ~= nil then

    else

    end
end

function debug_locations()
	--there are 5 types of locations that I care about
	--inns/taverns
	--temples
	--libraries
	--guildhalls
	--hospitals
	local world_site = df.global.plotinfo.main.fortress_site

	for k,v in ipairs(world_site.buildings) do
		local language_name = v:getName()

		local name = dfhack.TranslateName(language_name, true)

		imgui.Text(name)

		--imgui.Text("Inhabitants", #v.)
	end
end

function render_locations()
    render.set_can_window_pop(true)

    local locations = get_locations()

    for k,location in ipairs(locations) do
        imgui.Text(get_location_name(location))
    end
end