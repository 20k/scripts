--@ module = true
imgui = dfhack.imgui
render = reqscript('dfui_render')
utils = require('utils')

function get_locations()
    local world_site = df.global.plotinfo.main.fortress_site

    local result = {}

	for k,location in ipairs(world_site.buildings) do
        result[#result+1] = location
    end

    return result
end

function get_location_type_name(location)
    local name_to_type = {
        ["Temple"] = df.abstract_building_type.TEMPLE,
        ["Tomb"] = df.abstract_building_type.TOMB,
        ["Inn/Tavern"] = df.abstract_building_type.INN_TAVERN,
        ["Guildhall"] = df.abstract_building_type.GUILDHALL,
        ["Hospital"] = df.abstract_building_type.HOSPITAL
    }

    local type_to_name = {}

    for i,j in pairs(name_to_type) do
        type_to_name[j] = i
    end

    return type_to_name[location:getType()]
end

function get_location_name(location)
    local language_name = location:getName()

    return dfhack.TranslateName(language_name, true)
end

function display_location_selector()
    local locations = get_locations()

    local rich_locations = {}

    for k,v in ipairs(locations) do
        rich_locations[#rich_locations+1] = {type="location", data=v, hover=get_location_type_name(v)}
    end

    local opts = {paginate=true, leave_vacant=true}

    return render.display_rich_text(rich_locations, opts)
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

local function id_sorter(a, b)
	if a == b then
		return 0
	end

	if a > b then
		return 1
	end

	return -1
end

function clean_invalid_ids(location)
    local buildings = location:getContents().building_ids

    for i=#buildings-1, 0, -1 do
        if df.building.find(buildings[i]) == nil then
            buildings:erase(i)
        end
    end
end

function remove_zone_from_all_locations(zone)
    local locations = get_locations()

    for k,location in ipairs(locations) do
        local buildings = location:getContents().building_ids

        for i=#buildings-1,0,-1 do
            if buildings[i] == zone.id then
                buildings:erase(i)
            end
        end
    end

    zone.location_id = -1
    zone.site_id = -1
end

function on_assign_location(zone, location)
    remove_zone_from_all_locations(zone)

    if location ~= nil then
        clean_invalid_ids(location)

        local buildings = location:getContents().building_ids

        zone.location_id = location.id
        zone.site_id = location.site_id

        for i=#buildings-1,0,-1 do
            if buildings[i] == zone.id then
                return
            end
        end

        buildings:insert('#', zone.id)
        utils.sort_vector(buildings, nil, id_sorter)
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

    --[[local type_to_name = {
        df.abstract_building_type.TEMPLE="Temple",
        df.abstract_building_type.TOMB="Tomb",
        df.abstract_building_type.INN_TAVERN="Inn/Tavern",
        df.abstract_building_type.GUILDHALL="Guildhall",
        df.abstract_building_type.HOSPITAL="Hospital"
    }]]--

    local locations = get_locations()

    for k,location in ipairs(locations) do
        imgui.Text(get_location_name(location))

        imgui.SameLine()

        imgui.Text(get_location_type_name(location))

        local contents = location:getContents()

        if contents then
            for i,j in ipairs(contents.building_ids) do
                imgui.Text(tostring(j))
            end
        end
    end
end