--@ module = true
imgui = dfhack.imgui
render = reqscript('dfui_render')
utils = require('utils')

function get_locations(type)
    local world_site = df.global.plotinfo.main.fortress_site

    local result = {}

	for k,location in ipairs(world_site.buildings) do
        if type then
            if location:getType() == type then
                result[#result+1] = location
            end
        else
            result[#result+1] = location
        end
    end

    return result
end

function get_occupation_name(type)
    local names = {
        "Tavern Keeper",
        "Performer",
        "Scholar",
        "Mercenary",
        "Monster Slayer",
        "Scribe",
        "Messenger",
        "Doctor",
        "Diagnostician",
        "Surgeon",
        "Bone Doctor"
    }

    return names[type]
end

function get_location_type_name(type, pad)
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

    local result = type_to_name[type]

    if pad then
        local max = 0

        for k,v in pairs(name_to_type) do
            max = math.max(max,#k)
        end

        for i=#result,max do
            result = result.." "
        end
    end

    return result
end

function translate_name(name)
    return dfhack.df2utf(dfhack.TranslateName(name, true))
end

function get_location_name(location)
    local language_name = location:getName()

    return dfhack.TranslateName(language_name, true)
end

function display_location_selector(current_building)
    local locations = get_locations()

    local locations_by_type = {}

    locations_by_type[df.abstract_building_type.TEMPLE] = {}
    locations_by_type[df.abstract_building_type.LIBRARY] = {}
    locations_by_type[df.abstract_building_type.INN_TAVERN] = {}
    locations_by_type[df.abstract_building_type.GUILDHALL] = {}
    locations_by_type[df.abstract_building_type.HOSPITAL] = {}

    for k,v in ipairs(locations) do
        local type = v:getType()

        local l = locations_by_type[type]

        l[#l+1] = v
    end

    local new_loc = nil

    function on_click_make_temple()
        if imgui.BeginPopupContextItem(nil, 0) then
            local result = display_religion_selector()

            if result.type == "vacant" then
                new_loc = make_location(df.abstract_building_type.TEMPLE, {deity_type=-1, deity_data=-1})

                imgui.CloseCurrentPopup()
            end

            if result.type == "deity" then
                new_loc = make_location(df.abstract_building_type.TEMPLE, {deity_type=0, deity_data=result.data.id})

                imgui.CloseCurrentPopup()
            end

            if result.type == "religion" then
                new_loc = make_location(df.abstract_building_type.TEMPLE, {deity_type=1, deity_data=result.data.id})

                imgui.CloseCurrentPopup()
            end

            if result.type == "cancel" then
                imgui.CloseCurrentPopup()
            end

            imgui.EndPopup()
        end
    end

    function on_click_make_guildhall()
        if imgui.BeginPopupContextItem(nil, 0) then
            local result = display_profession_selector()

            if result.type == "profession" then
                new_loc = make_location(df.abstract_building_type.GUILDHALL, {profession=result.data})

                imgui.CloseCurrentPopup()
            end

            if result.type == "cancel" then
                imgui.CloseCurrentPopup()
            end
        end
    end

    local rich_locations = {}

    for k,v in pairs(locations_by_type) do
        local type_name = get_location_type_name(k)

        rich_locations[#rich_locations+1] = {type="tree", data=get_location_type_name(k)}

        local make_name = "(Make New " .. type_name .. ")"

        local open_popup = nil

        if k == df.abstract_building_type.TEMPLE then
            open_popup = on_click_make_temple
        end

        if k == df.abstract_building_type.GUILDHALL then
            open_popup = on_click_make_guildhall
        end

        rich_locations[#rich_locations+1] = {type="button", data=make_name, extra=k, open_popup=open_popup}

        for kl,vl in ipairs(v) do
            rich_locations[#rich_locations+1] = {type="location", data=vl, on_hover=do_location_on_hover}
        end
    end

    local opts = {paginate=false, leave_vacant=true}

    local selected = render.display_rich_text(rich_locations, opts)

    if selected.type == "button" then
        if selected.extra == df.abstract_building_type.INN_TAVERN then
            new_loc = make_location(selected.extra, nil)
        end

        if selected.extra == df.abstract_building_type.HOSPITAL then
            new_loc = make_location(selected.extra, nil)
        end

        if selected.extra == df.abstract_building_type.LIBRARY then
            new_loc = make_location(selected.extra, nil)
        end
    end

    if new_loc ~= nil then
        return {type="location", data=new_loc}
    end

    return selected
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

function add_occupation(location, type)
    for k,v in ipairs(location.occupations) do
        --need to double check histfig_id
        --if the type matches, and its unassigned, don't double insert
        if v.type == type and occupation.histfig_id == -1 then
            return
        end
    end

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
function ensure_occupations_for(location)
    local type = location:getType()

    if type == df.abstract_building_type.INN_TAVERN then
        add_occupation(location, 0)
        add_occupation(location, 1)
    end

    if type == df.abstract_building_type.TEMPLE then
        add_occupation(location, 1)
    end

    if type == df.abstract_building_type.HOSPITAL then
        add_occupation(location, 7)
        add_occupation(location, 8)
        add_occupation(location, 9)
        add_occupation(location, 10)
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

    if type == df.abstract_building_type.INN_TAVERN then
        generic_setup = df.new(df.abstract_building_inn_tavernst)
        generic_setup.next_room_info_id = 0
    end

    --guildhall needs profession
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

    ensure_occupations_for(generic_setup)

    return generic_setup
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

function render_array(array)
    if #array == 0 then
        return
    end

    imgui.BeginTooltip()

    for k,v in ipairs(array) do
        imgui.Text(v)
    end

    imgui.EndTooltip()
end

function get_deity_believer_count(deity)
    function is_deity(link)
        return link:getType() == df.histfig_hf_link_type.DEITY and link.target_hf == deity.id
    end

    local count = 0

    for k,v in ipairs(df.global.world.units.active) do
        if dfhack.units.isFortControlled(v) and not dfhack.units.isKilled(v) then
            local histfig = unit_to_histfig(v)

            if histfig then
                local results = get_relations(histfig.histfig_links, is_deity)

                count = count + #results
            end
        end
    end

    return count
end

--if links are bidirectional, can make this run much faster
function get_religion_believer_count(religion)
    local count = 0

    function is_religion(link)
        return link:getType() == df.histfig_entity_link_type.MEMBER and link.entity_id == religion.id
    end

    for k,v in ipairs(df.global.world.units.active) do
        if dfhack.units.isFortControlled(v) and not dfhack.units.isKilled(v) then
            local histfig = unit_to_histfig(v)

            if histfig then
                local results = get_relations(histfig.entity_links, is_religion)

                count = count + #results
            end
        end
    end

    return count
end

function get_religion_hover_info(religion)
    local hover = {}

    local entity = religion

    if entity then
        local count = get_religion_believer_count(entity)

        local worshipper_str = tostring(count) .. " worshippers"

        hover = {worshipper_str}

        local deities = get_religion_deities(entity)

        for k,deity in ipairs(deities) do
            hover[#hover+1] = "Worship"
            hover[#hover+1] = translate_name(deity.name)

            local spheres = get_deity_sphere_names(deity)

            for _,name in ipairs(spheres) do
                hover[#hover+1] = name
            end
        end
    end

    return hover
end

function get_deity_hover_info(deity)
    local hover = {}

    local histfig = deity

    if histfig then
        local count = get_deity_believer_count(deity)

        local worshipper_str = tostring(count) .. " worshippers"

        local spheres = get_deity_sphere_names(histfig)

        hover = {worshipper_str}

        for k,v in ipairs(spheres) do
            hover[#hover+1] = v
        end
    end

    return hover
end

function do_religion_hover_info(rich_text)
    render_array(get_religion_hover_info(rich_text.data))
end

function do_deity_hover_info(rich_text)
    render_array(get_deity_hover_info(rich_text.data))
end

function get_guild_hover_info(guild)
    local result = {}

    for k,v in ipairs(guild.guild_professions) do
        result[#result+1] = tostring(df.profession[v.profession])
    end

    result[#result+1] = tostring(count_valid_guild_members(guild.hist_figures)) .. " members"

    return result
end

function get_location_hover_info(location)
    local type = location:getType()

    local hover = {}

    if type == df.abstract_building_type.TEMPLE then
        if location.deity_type == -1 then
            return {"No specific deity"}
        end

        if location.deity_type == 0 then
            local real_deity = df.historical_figure.find(location.deity_data.Deity)

            return get_deity_hover_info(real_deity)
        end

        if location.deity_type == 1 then
            local real_entity = df.historical_entity.find(location.deity_data.Religion)

            return get_religion_hover_info(real_entity)
        end
    end

    --guilds are a historical entity
    if type == df.abstract_building_type.GUILDHALL then
        local guilds_of_profession = profession_to_guilds(location.contents.profession)

        for _,guild in ipairs(guilds_of_profession) do
            for _,v in ipairs(get_guild_hover_info(guild)) do
                hover[#hover+1] = v
            end
        end
    end

    return hover
end

function do_location_on_hover(rich_text)
    if rich_text.type ~= "location" then
        return
    end

    return render_array(get_location_hover_info(rich_text.data))
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

    local rich_text = {{type="text", data="Deities:"}}

    for idx,data in ipairs(sorted_deities) do
        local deity_id = data.data
        local histfig = df.historical_figure.find(deity_id)

        rich_text[#rich_text+1] = {type="deity", data=histfig, on_hover=do_deity_hover_info}
    end

    rich_text[#rich_text+1] = {type="text", data="Religions:"}

    for idx,data in ipairs(sorted_religions) do
        local religion_id = data.data
        local entity = df.historical_entity.find(religion_id)

        rich_text[#rich_text+1] = {type="religion", data=entity, on_hover=do_religion_hover_info}
    end

    local opt = {paginate=true, leave_vacant=true, leave_vacant_str="(No Specific Deity)##0", cancel=true, cancel_str="(Cancel)"}

    return render.display_rich_text(rich_text, opt)
end

function get_fortress_guilds()
    local result = {}

    local fortress_entity = df.global.plotinfo.main.fortress_entity

    for k,v in ipairs(df.global.world.entities.all) do
        if v.type == df.historical_entity_type.Guild then
            if v.founding_site_government == fortress_entity.id then
                result[#result+1] = v
            end
        end
    end

    return result
end

function profession_name(id)
    return df.profession[id]
end

function profession_parent(id)
    if id == nil then
        return -1
    end

    return df.profession.attrs[id+1].parent
end

function profession_to_guilds(profession)
    local guilds = {}

    for k,v in ipairs(get_fortress_guilds()) do
        for _,p in ipairs(v.guild_professions) do
            if p.profession == profession then
                guilds[#guilds+1] = v
            end
        end
    end

    return guilds
end

function count_valid_guild_members(histfigs)
    local count = 0

    for i,v in ipairs(histfigs) do
        local unit = df.unit.find(v.unit_id)

        if unit ~= nil and not dfhack.units.isKilled(unit) then
            count = count + 1
        end
    end

    return count
end

function display_profession_selector()
    local professions_by_type = {}

    local ordered_professions = {}

    for i=0,df.profession.SURGEON do
        if i == df.profession.STONECUTTER or i == df.profession.STONE_CARVER or
           i == df.profession.CLERK or i == df.profession.ADMINISTRATOR or i == df.profession.TRADER then
            goto toadyhatesyou
        end

        ordered_professions[#ordered_professions+1] = i

        ::toadyhatesyou::
    end

    for k,v in ipairs(df.global.world.units.active) do
        if dfhack.units.isFortControlled(v) and not dfhack.units.isKilled(v) and unit_to_histfig(v) then
            local profession = v.profession

            --[[local profession3 = nil

            if histfig then
                profession3 = histfig.profession
            end]]--

            local dat = {}

            dat[profession or -1] = 1
            dat[profession_parent(profession)] = 1

            for k,v in pairs(dat) do
                count(professions_by_type, k)
            end
        end
    end

    local guild_profession_map = {}

    for k,v in ipairs(get_fortress_guilds()) do
        for _,p in ipairs(v.guild_professions) do

            if guild_profession_map[p.profession] == nil then
                guild_profession_map[p.profession] = {}
            end

            local prof = guild_profession_map[p.profession]

            prof[#prof+1] = v
        end
    end

    local rich_text = {{type="text", data="Professions:"}}

    for k,data in ipairs(ordered_professions) do
        local count = professions_by_type[data] or 0

        local arr = {tostring(count) .. " workers"}

        local guilds = guild_profession_map[data]

        if guilds then
            for i,guild in ipairs(guilds) do
                arr[#arr+1] = "Guild:"
                arr[#arr+1] = translate_name(guild.name)
                arr[#arr+1] = tostring(count_valid_guild_members(guild.hist_figures)) .. " members"

                --[[for k,v in ipairs(guild.guild_professions) do
                    arr[#arr+1] = profession_name(v.profession)
                end]]--
            end
        end

        local dat = {type="profession", data=data, hover_array=arr}

        rich_text[#rich_text+1] = dat
    end

    local opt = {paginate=true, cancel=true, cancel_str="(Cancel)"}

    return render.display_rich_text(rich_text, opt)
end

function display_make_selector(current_building)
    --TODO: SORT PEOPLE WHO WE HAVE OPEN PETITIONS WITH AT THE TOP
    local additional_data = {}

    local loc = nil

    if imgui.Button("(Make Tavern)") then
        loc = make_location(df.abstract_building_type.INN_TAVERN, additional_data)
    end

    if imgui.Button("(Make Hospital)") then
        loc = make_location(df.abstract_building_type.HOSPITAL, additional_data)
    end

    if imgui.Button("(Make Temple)") then
        imgui.OpenPopup("maketemple")
    end

    if imgui.Button("(Make Library)") then
        loc = make_location(df.abstract_building_type.LIBRARY, additional_data)
    end

    if imgui.Button("(Make Guildhall)") then
        imgui.OpenPopup("makeguildhall")
    end

    if imgui.BeginPopup("maketemple") then
        local result = display_religion_selector()

        if result.type == "vacant" then
            loc = make_location(df.abstract_building_type.TEMPLE, {deity_type=-1, deity_data=-1})

            imgui.CloseCurrentPopup()
        end

        if result.type == "deity" then
            loc = make_location(df.abstract_building_type.TEMPLE, {deity_type=0, deity_data=result.data.id})

            imgui.CloseCurrentPopup()
        end

        if result.type == "religion" then
            loc = make_location(df.abstract_building_type.TEMPLE, {deity_type=1, deity_data=result.data.id})

            imgui.CloseCurrentPopup()
        end

        if result.type == "cancel" then
            imgui.CloseCurrentPopup()
        end

        imgui.EndPopup()
    end

    if imgui.BeginPopup("makeguildhall") then
        local result = display_profession_selector()

        if result.type == "profession" then
            loc = make_location(df.abstract_building_type.GUILDHALL, {profession=result.data})

            imgui.CloseCurrentPopup()
        end

        if result.type == "cancel" then
            imgui.CloseCurrentPopup()
        end
    end

    if loc and current_building then
        on_assign_location(current_building, loc)
    end
end

function render_locations()
    render.set_can_window_pop(true)

    --imgui.Text(tostring(df.global.plotinfo.group_id))

    local locations = get_locations()

    for k,location in ipairs(locations) do
        --[[imgui.Text(get_location_name(location))

        imgui.SameLine()

        imgui.Text(get_location_type_name(location))

        if location:getType() == df.abstract_building_type.TEMPLE then
            imgui.Text("DType", tostring(location.deity_type))
            imgui.Text("DData", tostring(location.deity_data.Deity))
        end]]--

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

    --imgui.Text(#df.global.plotinfo.main.fortress_entity.guild_professions)

end