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

function translate_name(name)
    return dfhack.df2utf(dfhack.TranslateName(name, true))
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

    dfhack.println("Bad location name type")

    return nil
end

function generate_language_name_object(location_type)
	local result = {}

	result.type = location_type_to_word_type(location_type)
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

function fill_contents(location, data)
    local type = location:getType()
    local contents = location:getContents()

    contents.profession = -1
    contents.desired_copies = 0
    contents.unk_v47_2 = 0
    contents.unk_v47_3 = 2
    contents.anon_13 = 100

    if type == df.abstract_building_type.INN_TAVERN then
        --so. I think I need to fill profession through unk_v47_2
        contents.desired_goblets  = 10
        contents.desired_instruments = 5
    end

    if type == df.abstract_building_type.GUILDHALL then
        contents.profession = data.profession
    end

    if type == df.abstract_building_type.TEMPLE then
        contents.desired_instruments = 5
    end

    if type == df.abstract_building_type.LIBRARY then
        contents.desired_paper = 10
    end

    --int32_t max_splints;
    --int32_t max_thread;
    --int32_t max_cloth;
    --int32_t max_crutches;
    --int32_t max_plaster;
    --int32_t max_buckets;
    --int32_t max_soap;

    if type == df.abstract_building_type.HOSPITAL then
        --max_splints;
        --max_thread;
        --max_cloth;
        --max_crutches;
        --max_plaster;
        --max_buckets;
        --max_soap;
        contents.desired_copies = 5
        contents.location_tier = 75000
        contents.location_value = 50000
        contents.count_goblets = 5
        contents.count_instruments = 750
        contents.count_paper = 2
        contents.unk_v47_2 = 750
    end
end

function make_location(type, data)
    local world_site = df.global.plotinfo.main.fortress_site

    local name = generate_language_name_object(type)

    local generic_setup = nil

    --TODO: the rest
    if type == df.abstract_building_type.INN_TAVERN then
        generic_setup = df.new(df.abstract_building_inn_tavernst)
        generic_setup.next_room_info_id = 0
    end

    --guildhall needs profession
    --todo: we need a general opts struct
    --data.profession
    if type == df.abstract_building_type.GUILDHALL then
        generic_setup = df.new(df.abstract_building_guildhallst)
    end

    --data.deity_type
    --data.deity_data
    --Deity == 0 == historical_figure
    --Religion == 1 == historical_entity
    if type == df.abstract_building_type.TEMPLE then
        --deity_type
        --deity_data
        generic_setup = df.new(df.abstract_building_templest)
        generic_setup.deity_type = data.deity_type

        --doing it 'properly', could be a 1 liner
        if generic_setup.deity_type == -1 then
            generic_setup.deity_data.Deity = -1
        end

        if generic_setup.deity_type == 0 then
            generic_setup.deity_data.Deity = data.deity_data
        end

        if generic_setup.deity_type == 1 then
            generic_setup.deity_data.Religion = data.deity_data
        end
    end

    --none?
    if type == df.abstract_building_type.LIBRARY then
        generic_setup = df.new(df.abstract_building_libraryst)
        generic_setup.unk_1 = -1
        generic_setup.unk_2 = -1
        generic_setup.unk_3 = -1
        generic_setup.unk_4 = -1
    end

    --none?
    if type == df.abstract_building_type.HOSPITAL then
        generic_setup = df.new(df.abstract_building_hospitalst)
    end

    generic_setup.name.type = name.type
	generic_setup.name.nickname = name.nickname
	generic_setup.name.first_name = name.first_name
	generic_setup.name.has_name = 1
	generic_setup.name.language = 0

	for i,j in ipairs(name.words) do
		generic_setup.name.words[i - 1] = j
	end

	for i,j in ipairs(name.parts_of_speech) do
		generic_setup.name.parts_of_speech[i - 1] = j
	end

    --[[for i,j in pairs(generic_setup.contents) do
        --imgui.Text("Key", i, "Value", tostring(j))
        dfhack.println("key", i, "value", j)
    end]]--

    --TODO
    ---SET CONTENTS. Guildhalls have a specific profession which I definitely need to set
    fill_contents(generic_setup, data)

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
    generic_setup.pos.x = world_site.pos.x
    generic_setup.pos.y = world_site.pos.y
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

function unit_to_histfig(unit)
    return df.historical_figure.find(unit.hist_figure_id)
end

function get_relations(links, filter)
    local result = {}

    for idx, link in ipairs(links) do
        if filter(link) then
            result[#result+1] = link
        end
    end

    return result
end

function get_religion_deities(religion_entity)
    local deities = {}

    for k,deity_id in ipairs(religion_entity.relations.deities) do
        local deity = df.historical_figure.find(deity_id)

        deities[#deities+1] = deity
    end

    return deities
end

function get_deity_sphere_names(deity_histfig)
    local result = {}

    for idx,sphere in ipairs(deity_histfig.info.spheres.spheres) do
        local name = tostring(df.sphere_type[sphere])

        result[#result+1] = name
    end

    return result
end

function get_religion_sphere_names(religion_entity)
    local deities = get_religion_deities(religion_entity)

    local result = {}

    for k,v in ipairs(deities) do
        local spheres = get_deity_sphere_names(v)

        for i,j in ipairs(spheres) do
            result[#result+1] = j
        end
    end

    return result
end

function count(tab, val)
    if tab[val] == nil then
        tab[val] = 0
    end

    tab[val] = tab[val] + 1
end

function sort_by_count(tab)
    local result_with_count = {}

    for data,count in pairs(tab) do
        result_with_count[#result_with_count+1] = {data=data,count=count}
    end

    function sorter(a, b)
        return a.count > b.count
    end

    table.sort(result_with_count, sorter)

    return result_with_count
end

function display_religion_selector()
    function is_deity(link)
        return link:getType() == df.histfig_hf_link_type.DEITY
    end

    function is_religion(link)
        if link:getType() == df.histfig_entity_link_type.MEMBER then
            local real_entity = df.historical_entity.find(link.entity_id)

            if real_entity == nil then
                return false
            end

            return real_entity.type == df.historical_entity_type.Religion
        end

        return false
    end

    local valid_histfigs = {}

    for k,v in ipairs(df.global.world.units.active) do
        if dfhack.units.isFortControlled(v) and not dfhack.units.isKilled(v) then
            local histfig = unit_to_histfig(v)

            if histfig then
                valid_histfigs[#valid_histfigs+1] = histfig
            end
        end
    end

    local deities_by_id = {}
    local religions_by_id = {}

    for k,v in ipairs(valid_histfigs) do
        local results = get_relations(v.histfig_links, is_deity)

        for j,d in ipairs(results) do
            count(deities_by_id, d.target_hf)
        end
    end

    for k,v in ipairs(valid_histfigs) do
        local results = get_relations(v.entity_links, is_religion)

        for j,d in ipairs(results) do
            count(religions_by_id, d.entity_id)
        end
    end

    local sorted_deities = sort_by_count(deities_by_id)
    local sorted_religions = sort_by_count(religions_by_id)

    local first_tooltip = true

    if imgui.TreeNode("Deities") then
        for idx,data in ipairs(sorted_deities) do
            local deity_id = data.data
            local histfig = df.historical_figure.find(deity_id)

            if histfig then
                imgui.Button(translate_name(histfig.name) .. "##" .. tostring(deity_id))

                if imgui.IsItemHovered() and first_tooltip then
                    local spheres = get_deity_sphere_names(histfig)

                    imgui.BeginTooltip()

                    imgui.Text(tostring(data.count), "worshippers")

                    for _,name in ipairs(spheres) do
                        imgui.Text(name)
                    end

                    imgui.EndTooltip()
                    first_tooltip = false
                end
            end
        end

        imgui.TreePop()
    end

    if imgui.TreeNode("Religions") then
        for idx,data in ipairs(sorted_religions) do
            local religion_id = data.data
            local entity = df.historical_entity.find(religion_id)

            imgui.Button(translate_name(entity.name) .. "##" .. tostring(religion_id))

            if imgui.IsItemHovered() and first_tooltip then
                local deities = get_religion_deities(entity)

                imgui.BeginTooltip()

                imgui.Text(tostring(data.count), "worshippers")

                for k,deity in ipairs(deities) do
                    imgui.Text("Worship")
                    imgui.Text(translate_name(deity.name))

                    local spheres = get_deity_sphere_names(deity)

                    for _,name in ipairs(spheres) do
                        imgui.Text(name)
                    end
                end

                imgui.EndTooltip()
                first_tooltip = false
            end
        end

        imgui.TreePop()
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

        if location:getType() == df.abstract_building_type.TEMPLE then
            imgui.Text("DType", tostring(location.deity_type))
            imgui.Text("DData", tostring(location.deity_data.Deity))
        end

        --local contents = location:getContents()

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

        --imgui.Text(location.scribeinfo)
    end

    local additional_data = {}

    if imgui.Button("Make Tavern") then
        make_location(df.abstract_building_type.INN_TAVERN, additional_data)
    end

    if imgui.Button("Make Hospital") then
        make_location(df.abstract_building_type.HOSPITAL, additional_data)
    end

    display_religion_selector()
end