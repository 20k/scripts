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
        ["Library"] = df.abstract_building_type.LIBRARY,
        ["Inn/Tavern"] = df.abstract_building_type.INN_TAVERN,
        ["Guildhall"] = df.abstract_building_type.GUILDHALL,
        ["Hospital"] = df.abstract_building_type.HOSPITAL,
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

rng = dfhack.random.new(2345)

function location_type_to_word_type(location_type)
    if location_type == df.abstract_building_type.TEMPLE then
        return df.language_name_type.Temple
    end

    if location_type == df.abstract_building_type.LIBRARY then
        return df.language_name_type.Library
    end

    if location_type == df.abstract_building_type.GUILDHALL then
        return df.language_name_type.Guildhall
    end

    if location_type == df.abstract_building_type.INN_TAVERN then
        return df.language_name_type.SymbolFood
    end

    if location_type == df.abstract_building_type.HOSPITAL then
        return df.language_name_type.Hospital
    end
end

function generate_language_name_object(location_type)
	local result = {}

	result.type = location_type_to_word_type(type)
	result.nickname = ""
	result.first_name = ""
	result.has_name = 1
	result.language = 0
	result.words = {-1, -1, -1, -1, -1, -1, -1}
	result.parts_of_speech = {df.part_of_speech.Noun, df.part_of_speech.Noun, df.part_of_speech.Adjective, df.part_of_speech.Noun, df.part_of_speech.Noun, df.part_of_speech.NounPlural, df.part_of_speech.Noun}

	local lwords = df.global.world.raws.language.word_table[0][35].words[0]

	result.words[3] = lwords[math.floor(rng:drandom() * (#lwords - 1))]
	result.words[6] = lwords[math.floor(rng:drandom() * (#lwords - 1))]

	return result
end

function make_occupation(location, type)
    local occupation = df.new(df.occupation)
    occupation.id = df.global.occupation_next_id
    occupation.type = type

    occupation.histfig_id = -1
    occupation.unit_id = -1
    occupation.location_id = location.id
    occupation.site_id = location.site_id
    occupation.group_id = -1
    occupation.unk_2 = 0
    occupation.army_controller_id = 0

    df.global.occupation_next_id = df.global.occupation_next_id+1

    df.global.world.occupations.all:insert('#', occupation)
    location.occupations:insert('#', occupation)

    return occupation
end

---sigh. So it has actual occupations, and pending occupations. This is a HUGE pain
--tavern: 0 = tavern_keeper. Infinite
--tavern: 1 = performer. Infinite
--temple: 1 = performer
--guildhall: none
--library: phew none
--hospital: 7=doctor
--hospital: 8=diagnostician
--hospital: 9=surgeon
--hospital: 10=bone doctor

--occupations are lazily generated, so if we screw this up its not the end of the world
function make_occupations_for(location)
    local type = location:getType()

    if type == df.abstract_building_type.INN_TAVERN then
        make_occupation(location, 0)
        make_occupation(location, 1)
    end

    if type == df.abstract_building_type.TEMPLE then
        make_occupation(location, 1)
    end

    if type == df.abstract_building_type.HOSPITAL then
        make_occupation(location, 7)
        make_occupation(location, 8)
        make_occupation(location, 9)
        make_occupation(location, 10)
    end

    return {}
end

function make_location(type)
    local world_site = df.global.plotinfo.main.fortress_site

    local name = generate_language_name_object(location_type)

    local generic_setup = nil

    --TODO: the rest
    if type == df.abstract_building_type.INN_TAVERN then
        local ptr = df.new(df.abstract_building_inn_tavernst)
        ptr.next_room_info_id = 0

        generic_setup = ptr
    end

    generic_setup.name = name
    --TODO
    ---SET CONTENTS. Guildhalls have a specific profession which I definitely need to set

    --don't care about inhabitants

    --guildhalls default to OnlyMembers. Temples *can* be members only
    --the other flags are {All} = AllowVisitors | AllowResidents
    --Only Residents = AllowResidents
    --Citizens Only = none set

    if type == df.abstract_building_type.GUILDHALL then
        generic_setup.flags.OnlyMembers = true
    else
        generic_setup.flags.AllowVisitors = true
        generic_setup.flags.AllowResidents = true
    end

    generic_setup.unk1 = nil
    --don't care about unk2
    --don't care about parent_building_id
    --don't care about child_building_ids
    generic_setup.site_owner_id = df.global.plotinfo.main.fortress_entity.id
    generic_setup.scribeinfo = nil
    generic_setup.reputation_reports = nil
    generic_setup.unk_v42_3 = nil
    generic_setup.site_id = world_site.id
    generic_setup.pos = world_site.pos
    generic_setup.id = world_site.next_building_id

    world_site.next_building_id = world_site.next_building_id + 1
    world_site.buildings:insert('#', generic_setup)

    make_occupations_for(generic_setup)
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

    --imgui.Text(tostring(df.global.plotinfo.group_id))

    local locations = get_locations()

    for k,location in ipairs(locations) do
        imgui.Text(get_location_name(location))

        imgui.SameLine()

        imgui.Text(get_location_type_name(location))

        local contents = location:getContents()

        --[[if contents then
            for i,j in ipairs(contents.building_ids) do
                imgui.Text(tostring(j))
            end
        end]]--

        --imgui.Text(tostring(location.name.type))
        --imgui.Text(tostring(location.pos.x))
        --imgui.Text(tostring(location.pos.y))

        --render.dump_flags(location.flags)
        --local world_site = df.global.plotinfo.main.fortress_site

        --imgui.Text(tostring(location.site_owner_id))
        --imgui.Text(tostring())

        imgui.Text(location.scribeinfo)
    end
end