--@ module = true

local utils = require 'utils'

function get_subtype_of(id)
    --todo: Unconditionally check subtypes of everything
    local types = {df.itemdef_ammost, df.itemdef_armorst, df.itemdef_floodst, df.itemdef_glovesst, df.itemdef_helmst,
    df.itemdef_instrumentst, df.itemdef_pantsst, df.itemdef_shieldst, df.itemdef_shoesst, df.itemdef_siegeammost, df.itemdef_toolst,
    df.itemdef_toyst, df.itemdef_trapcompst, df.itemdef_weaponst}

    for _,l in pairs(types) do
        local vec = l.get_vector()

        --[[if l == df.itemdef_weaponst then
            for k,v in pairs(vec) do
                dfhack.println(k, v.id)
            end
        end]]--

        for k,v in pairs(vec) do
            if v.id == id then
                return v.subtype
            end
        end
    end

    dfhack.println("Error, no subtype")

    return nil
end

job_types = df.job_type

input_filter_defaults = {
    item_type = -1,
    item_subtype = -1,
    mat_type = -1,
    mat_index = -1,
    flags1 = {},
    -- Instead of noting those that allow artifacts, mark those that forbid them.
    -- Leaves actually enabling artifacts to the discretion of the API user,
    -- which is the right thing because unlike the game UI these filters are
    -- used in a way that does not give the user a chance to choose manually.
    --flags2 = { allow_artifact = true },
    flags2 = {},
    flags3 = {},
    flags4 = 0,
    flags5 = 0,
    reaction_class = '',
    has_material_reaction_product = '',
    metal_ore = -1,
    min_dimension = -1,
    has_tool_use = -1,
    quantity = 1
}

function make_carpentry(name, type, subtype_s)
    --[[local subtype = nil

    if subtype_s ~= nil then
        subtype = get_subtype_of(subtype_s)
    end]]--

	return {
		name=name,
		items={{}},
		job_fields={job_type=type, material_category={wood=true}, item_subtype_s=subtype_s}
	}
end

function make_masonry(name, type, subtype_s)
    return {
        name=name,
        items={{}},
        job_fields={job_type=type, mat_type=0, mat_index=-1, item_subtype_s=subtype_s}
    }
end

fix_throne = false
fix_casket = false

function get_coffin_name()
    if fix_casket then
        return "Coffin"
    end

    return "Casket"
end

function get_throne_name()
    if fix_throne then
        return "Chair"
    end

    return "Throne"
end

function get_carpenter_workshop()
    return {
        defaults={item_type=df.item_type.WOOD,vector_id=df.job_item_vector_id.WOOD},
        --make_carpentry("Make wooden shield", df.job_type.)
        make_carpentry("Make wooden barrel", df.job_type.MakeBarrel),
        make_carpentry("Construct wooden blocks", df.job_type.ConstructBlocks),
        make_carpentry("Make wooden Bucket", df.job_type.MakeBucket),
        make_carpentry("Make wooden Animal Trap", df.job_type.MakeAnimalTrap),
        make_carpentry("Make wooden Cage", df.job_type.MakeCage),
        make_carpentry("Construct wooden Armor Stand", df.job_type.ConstructArmorStand),
        make_carpentry("Construct Bed", df.job_type.ConstructBed),
        make_carpentry("Construct wooden Chair", df.job_type.ConstructThrone),
        make_carpentry("Construct wooden " .. get_coffin_name(), df.job_type.ConstructCoffin),
        make_carpentry("Construct wooden Door", df.job_type.ConstructDoor),
        make_carpentry("Construct wooden Floodgate", df.job_type.ConstructFloodgate),
        make_carpentry("Construct wooden Hatch Cover", df.job_type.ConstructHatchCover),
        make_carpentry("Construct wooden Grate", df.job_type.ConstructGrate),
        make_carpentry("Construct wooden Cabinet", df.job_type.ConstructCabinet),
        make_carpentry("Construct wooden Bin", df.job_type.ConstructBin),
        make_carpentry("Construct wooden Chest", df.job_type.ConstructChest),
        make_carpentry("Construct wooden Weapon Rack", df.job_type.ConstructWeaponRack),
        make_carpentry("Construct wooden Table", df.job_type.ConstructTable),
        make_carpentry("Make wooden Minecart", df.job_type.MakeTool, "ITEM_TOOL_MINECART"),
        make_carpentry("Make wooden Wheelbarrow", df.job_type.MakeTool, "ITEM_TOOL_WHEELBARROW"),
        make_carpentry("Make wooden Stepladder", df.job_type.MakeTool, "ITEM_TOOL_STEPLADDER"),
        make_carpentry("Make wooden Bookcase", df.job_type.MakeTool, "ITEM_TOOL_BOOKCASE"),
        make_carpentry("Make wooden Pedestal", df.job_type.MakeTool, "ITEM_TOOL_PEDESTAL"),
        make_carpentry("Make wooden Altar", df.job_type.MakeTool, "ITEM_TOOL_ALTAR"),
        make_carpentry("Make wooden Splint", df.job_type.ConstructSplint),
        make_carpentry("Make wooden Crutch", df.job_type.ConstructCrutch),
    }
end

function get_masonry_workshop()
    return {
        defaults={item_type=df.item_type.BOULDER,item_subtype=-1,vector_id=df.job_item_vector_id.BOULDER, mat_type=0,mat_index=-1, flags2={non_economic=true},flags3={hard=true}},

        make_masonry("Construct rock Armor Stand", df.job_type.ConstructArmorStand),
        make_masonry("Construct rock Blocks", df.job_type.ConstructBlocks),
        make_masonry("Construct rock " .. get_throne_name(), df.job_type.ConstructThrone),
        make_masonry("Construct rock Coffin", df.job_type.ConstructCoffin),
        make_masonry("Construct rock Door", df.job_type.ConstructDoor),
        make_masonry("Construct rock Floodgate", df.job_type.ConstructFloodgate),
        make_masonry("Construct rock Hatch Cover", df.job_type.ConstructHatchCover),
        make_masonry("Construct rock Grate", df.job_type.ConstructGrate),
        make_masonry("Construct rock Cabinet", df.job_type.ConstructCabinet),
        make_masonry("Construct rock Coffer", df.job_type.ConstructChest),
        make_masonry("Construct rock Statue", df.job_type.ConstructStatue),
        make_masonry("Construct rock Slab", df.job_type.ConstructSlab),
        make_masonry("Construct rock Table", df.job_type.ConstructTable),
        make_masonry("Construct rock Weapon Rack", df.job_type.ConstructWeaponRack),
        make_masonry("Construct rock Quern", df.job_type.ConstructQuern),
        make_masonry("Construct rock Millstone", df.job_type.ConstructMillstone),
        make_masonry("Make rock Bookcase", df.job_type.MakeTool, "ITEM_TOOL_BOOKCASE"),
        make_masonry("Make rock Pedestal", df.job_type.MakeTool, "ITEM_TOOL_PEDESTAL"),
        make_masonry("Make rock Altar", df.job_type.MakeTool, "ITEM_TOOL_ALTAR"),
    }
end

--todo: clean this up
function make_wood_item(job_item)
    local default_item = {item_type=df.item_type.WOOD,vector_id=df.job_item_vector_id.WOOD}

    utils.assign(default_item, job_item)

    return default_item
end

function make_wood_job(unfinished_job)
    local default_job = {material_category={wood=true}}

    utils.assign(default_job, unfinished_job)

    return default_job
end

function make_rock_item(job_item)
    local default_item = {item_type=df.item_type.BOULDER,vector_id=df.job_item_vector_id.BOULDER, mat_type=0,mat_index=-1, flags2={non_economic=true},flags3={hard=true}}

    utils.assign(default_item, job_item)

    return default_item
end

function make_rock_job(unfinished_job)
    local default_job = {mat_type=0, mat_index=-1}

    utils.assign(default_job, unfinished_job)

    return default_job
end

function make_bone_item(job_item)
    local default_item = {item_type=-1, flags1={unrotten=true}, vector_id=df.job_item_vector_id.ANY_REFUSE, flags2={bone=true, body_part=true}}

    utils.assign(default_item, job_item)

    return default_item
end

function make_bone_job(unfinished_job)
    local default_job = {material_category={bone=true}}

    utils.assign(default_job, unfinished_job)

    return default_job
end

function make_shell_item(job_item)
    local default_item = {item_type=-1, flags1={unrotten=true}, vector_id=df.job_item_vector_id.ANY_REFUSE, flags2={shell=true, body_part=true}}

    utils.assign(default_item, job_item)

    return default_item
end

function make_shell_job(unfinished_job)
    local default_job = {material_category={shell=true}}

    utils.assign(default_job, unfinished_job)

    return default_job
end

function make_cloth_item(job_item)
    local default_item = {item_type=df.item_type.CLOTH, quantity=10000, vector_id=df.job_item_vector_id.CLOTH, flags2={plant=true}, mindim=10000}

    utils.assign(default_item, job_item)

    return default_item
end

function make_cloth_job(unfinished_job)
    local default_job = {material_category={cloth=true}}

    utils.assign(default_job, unfinished_job)

    return default_job
end

function make_silk_item(job_item)
    local default_item = {item_type=df.item_type.CLOTH, quantity=10000, vector_id=df.job_item_vector_id.CLOTH, flags2={silk=true}, mindim=10000}

    utils.assign(default_item, job_item)

    return default_item
end

function make_silk_job(unfinished_job)
    local default_job = {material_category={silk=true}}

    utils.assign(default_job, unfinished_job)

    return default_job
end

function make_yarn_item(job_item)
    local default_item = {item_type=df.item_type.CLOTH, quantity=10000, vector_id=df.job_item_vector_id.CLOTH, flags2={yarn=true}, mindim=10000}

    utils.assign(default_item, job_item)

    return default_item
end

function make_yarn_job(unfinished_job)
    local default_job = {material_category={yarn=true}}

    utils.assign(default_job, unfinished_job)

    return default_job
end

function make_tooth_item(job_item)
    local default_item = {item_type=-1, quantity=1, flags1={unrotten=true}, vector_id=df.job_item_vector_id.ANY_REFUSE, flags2={body_part=true, ivory_tooth=true}}

    utils.assign(default_item, job_item)

    return default_item
end

function make_tooth_job(unfinished_job)
    local default_job = {material_category={tooth=true}}

    utils.assign(default_job, unfinished_job)

    return default_job
end

function make_horn_item(job_item)
    local default_item = {item_type=-1, quantity=1, flags1={unrotten=true}, vector_id=df.job_item_vector_id.ANY_REFUSE, flags2={body_part=true, horn=true}}

    utils.assign(default_item, job_item)

    return default_item
end

function make_horn_job(unfinished_job)
    local default_job = {material_category={horn=true}}

    utils.assign(default_job, unfinished_job)

    return default_job
end

function make_pearl_item(job_item)
    local default_item = {item_type=-1, quantity=1, flags1={unrotten=true}, vector_id=df.job_item_vector_id.ANY_REFUSE, flags2={body_part=true, pearl=true}}

    utils.assign(default_item, job_item)

    return default_item
end

function make_pearl_job(unfinished_job)
    local default_job = {material_category={pearl=true}}

    utils.assign(default_job, unfinished_job)

    return default_job
end

function make_leather_item(job_item)
    local default_item = {item_type=df.item_type.SKIN_TANNED, quantity=1, vector_id=df.job_item_vector_id.SKIN_TANNED}

    utils.assign(default_item, job_item)

    return default_item
end

function make_leather_job(unfinished_job)
    local default_job = {material_category={leather=true}}

    utils.assign(default_job, unfinished_job)

    return default_job
end

function make_item_type(name, base)
    if base == nil then
        base = {}
    end

    local m = {wood=make_wood_item(base),
               rock=make_rock_item(base),
               bone=make_bone_item(base),
               shell=make_shell_item(base),
               cloth=make_cloth_item(base),
               silk=make_silk_item(base),
               yarn=make_yarn_item(base),
               tooth=make_tooth_item(base),
               horn=make_horn_item(base),
               pearl=make_pearl_item(base),
               leather=make_leather_item(base),
             }

    return m[name]
end

function make_job_type(name, base)
    if base == nil then
        base = {}
    end

    local m = {wood=make_wood_job(base),
               rock=make_rock_job(base),
               bone=make_bone_job(base),
               shell=make_shell_job(base),
               cloth=make_cloth_job(base),
               silk=make_silk_job(base),
               yarn=make_yarn_job(base),
               tooth=make_tooth_job(base),
               horn=make_horn_job(base),
               pearl=make_pearl_job(base),
               leather=make_leather_job(base),
             }

    return m[name]
end

function add_item_type_to_job(job, name, extra)
    if job.items == nil then
        job.items = {}
    end

    job.items[#job.items+1] = make_item_type(name, extra)
end

function add_custom_item_to_job(job, extra)
    if job.items == nil then
        job.items = {}
    end

    job.items[#job.items+1] = extra
end

function make_rock_sword()
    --local item_1 = {item_type=df.item_type.BOULDER, flags1={sharpenable=true}, vector_id=df.job_item_vector_id.BOULDER, flags3={hard=true}, mat_type=0, mat_index=-1}
    --why plant? Who knows! But its what the game does
    --local item_2 = {item_type=df.item_type.WOOD, flags2={plant=true}}

    --local job_fields = {job_type=job_types.MakeWeapon, mat_type=0, mat_index=-1, item_subtype_s="ITEM_WEAPON_SWORD_SHORT"}

    --return {name="make rock short sword", items={item_1, item_2}, job_fields=job_fields}

    local job = {name="make rock short sword"}

    local rock_job = make_rock_job({item_subtype_s="ITEM_WEAPON_SWORD_SHORT"})

    job.job_fields = rock_job
    job.job_fields.job_type = df.job_type.MakeWeapon,

    add_item_type_to_job(job, "rock", {flags1={sharpenable=true}, flags2={non_economic=false}})
    add_item_type_to_job(job, "wood", {flags2={plant=true}})

    return job
end

function make_totem()
    local job = {name="make totem"}

    job.job_fields = {}
    job.job_fields.job_type = df.job_type.MakeTotem

    add_custom_item_to_job(job, {item_type=-1, flags1={unrotten=true}, vector_id=df.job_item_vector_id.ANY_REFUSE, flags2={totemable=true, body_part=true}})

    return job
end

function make_strands()
    local strand_jobs = {}

    --RAW_ADAMANTINE
    local rock_types = df.global.world.raws.inorganics

    for rock_id = #rock_types-1, 0, -1 do
        local mat_type = 0
        local mat_index = rock_id

        local name = rock_types[rock_id].material.state_adj.Solid

        if #rock_types[rock_id].thread_metal.mat_index > 0 then
            local job = {name="Extract metal " .. name .. " strands"}

            local job_fields = {job_type=df.job_type.ExtractMetalStrands, mat_type=0, mat_index=rock_id}

            job.job_fields = job_fields

            add_custom_item_to_job(job, {item_type=df.item_type.BOULDER, mat_type=0, mat_index=rock_id, quantity=1, vector_id=df.job_item_vector_id.BOULDER})

            strand_jobs[#strand_jobs+1] = job
        end
    end

    return strand_jobs
end

function get_craftsdwarf_workshop()
    local rock_items = {"Crafts", "Mug", "short sword", "Nest Box", "Jug", "Pot", "Hive", "Scroll Rollers",
                        "Book Binding", "Bookcase", "Pedestal", "Altar", "Die", "Toy", "Figurine", "Amulet", "Scepter",
                        "Crown", "Ring", "Earring", "Bracelet", "Large Gem"}
    local wood_items = {"Crafts", "Cup", "bolts", "Nest Box", "Jug", "Pot", "Hive", "Scroll Rolls", "Book Binding", "Die", "Amulet",
                        "Bracelet", "Earring", "Crown", "Figurine", "Ring", "Large Gem", "Scepter"}

    local bone_items = {"bolts", "Decorate With", "leggings", "greaves", "helm", "Amulet", "Bracelet", "Earring",
                        "Crown", "Figurine", "Ring","Large Gem", "Scepter"}

    local shell_items = {"Decorate With", "Crafts", "leggings", "gauntlet", "helm", "Amulet", "Bracelet",
                         "Earring", "Crown", "Figurine", "Ring", "Large Gem"}

    local cloth_items = {"Crafts", "Amulet", "Bracelet", "Earring"}

    local silk_items = {"Crafts", "Amulet", "Bracelet", "Earring"}

    local yarn_items = {"Crafts", "Amulet", "Braelet", "Earring"}

    local tooth_items = {"Decorate With", "Crafts", "Amulet", "Bracelet", "Earring", "Crown", "Figurine", "Ring",
                         "Large Gem", "Scepter"}

    local horn_items = {"Decorate With", "Crafts", "Amulet", "Bracelet", "Earring", "Crown", "Figurine", "Ring", "Large Gem","Scepter"}

    local pearl_items = {"Decorate With", "Crafts", "Amulet", "Bracelet", "Earring","Crown", "Figurine", "Ring", "Large Gem"}

    local leather_items = {"Crafts", "Amulet", "Bracelet", "Earring"}

    local wax_items = {"Crafts"}

    local all_simple_typed = {rock=rock_items, wood=wood_items, bone=bone_items, shell=shell_items,
                              cloth=cloth_items, silk=silk_items, yarn=yarn_items, tooth=tooth_items,
                              horn=horn_items, pearl=pearl_items, leather=leather_items, wax=wax_items}

    local labours = {Crafts={t=job_types.MakeCrafts},
                     Mug={t=job_types.MakeGoblet},
                     bolts={t=job_types.MakeAmmo, st="ITEM_AMMO_BOLTS"},
                     --don't know how to decorate with
                     ["Nest Box"]={t=job_types.MakeTool, st="ITEM_TOOL_NEST_BOX"},
                     Jug={t=job_types.MakeTool, st="ITEM_TOOL_JUG"},
                     Pot={t=job_types.MakeTool, st="ITEM_TOOL_LARGE_POT"},
                     Hive={t=job_types.MakeTool, st="ITEM_TOOL_HIVE"},
                     ["Scroll Rollers"]={t=job_types.MakeTool, st="ITEM_TOOL_SCROLL_ROLLERS"},
                     ["Book Binding"]={t=job_types.MakeTool, st="ITEM_TOOL_BOOK_BINDING"},
                     ["Bookcase"]={t=job_types.MakeTool, st="ITEM_TOOL_BOOKCASE"},
                     ["Pedestal"]={t=job_types.MakeTool, st="ITEM_TOOL_PEDESTAL"},
                     ["Altar"]={t=job_types.MakeTool, st="ITEM_TOOL_ALTAR"},
                     ["Die"]={t=job_types.MakeTool, st="ITEM_TOOL_DIE"},
                     ["Toy"]={t=job_types.MakeToy},
                     ["Figurine"]={t=job_types.MakeFigurine},
                     ["Amulet"]={t=job_types.MakeAmulet},
                     ["Scepter"]={t=job_types.MakeScepter},
                     ["Crown"]={t=job_types.MakeCrown},
                     ["Ring"]={t=job_types.MakeRing},
                     ["Earring"]={t=job_types.MakeEarring},
                     ["Bracelet"]={t=job_types.MakeBracelet},
                     ["Large Gem"]={t=job_types.MakeGem},
                     }

    local result = {}

    for class,types in pairs(all_simple_typed) do
        for _,name in ipairs(types) do
            if class == "wax" then
                goto nope
            end

            local info = labours[name]

            if info == nil then
                goto nope
            end

            local job = {name="Make " .. tostring(class) .. " " .. name}

            job.job_fields = make_job_type(class, {})
            job.job_fields.job_type = info.t
            job.job_fields.item_subtype_s = info.st
            job.menu = {class}

            if info.t == nil then
                dfhack.println("Ruh roh ", class, name)
                goto nope
            end

            add_item_type_to_job(job, class)

            result[#result+1] = job

            ::nope::
        end
    end

    local rs = make_rock_sword()
    rs.menu = {"rock"}

    result[#result+1] = rs

    local tot = make_totem()
    tot.menu = {"bone"}

    result[#result+1] = tot

    local strands = make_strands()

    for _,v in ipairs(strands) do
        result[#result+1] = v
    end

    result.defaults = {}

    --todo: engrave memorial slab, make totem, extract metal strands, make instrument piece and instrument
    --make scroll, make quire, bind book

    return result
end

function get_bowyers_workshop()
    local bone_job = {name="Make bone crossbow"}
    local wood_job = {name="Make wood crossbow"}

    bone_job.job_fields = make_bone_job({item_subtype_s="ITEM_WEAPON_CROSSBOW"})
    wood_job.job_fields = make_wood_job({item_subtype_s="ITEM_WEAPON_CROSSBOW"})

    bone_job.job_fields.job_type = df.job_type.MakeWeapon
    wood_job.job_fields.job_type = df.job_type.MakeWeapon

    add_item_type_to_job(bone_job, "bone")
    add_item_type_to_job(wood_job, "wood")

    return {bone_job, wood_job}
end

function attach_job_props(mod, name, job_type, extras)
    mod.name = name
    mod.menu = {}

    if mod.items == nil then
        mod.items = {}
    end

    if mod.job_fields == nil then
        mod.job_fields = {}
    end

    if job_type == nil then
        dfhack.println("Nil job type for job type ", name)
    end

    mod.job_fields.job_type = job_type

    if extras == nil then
        extras = {}
    end

    utils.assign(mod.job_fields, extras)
end

function get_farmers_workshop()
    --local process_plants_job = {job_fields={job_type=df.job_type.ProcessPlants}}

    local process_plants_job = {}
    attach_job_props(process_plants_job, "Process Plants", df.job_type.ProcessPlants)
    add_custom_item_to_job(process_plants_job, {item_type=df.item_type.PLANT, flags1={unrotten=true, processable=true}, vector_id=df.job_item_vector_id.PLANT})

    local process_plants_vial_job = {}
    attach_job_props(process_plants_vial_job, "Process Plants (Vial)", df.job_type.ProcessPlantsVial)
    add_custom_item_to_job(process_plants_vial_job, {item_type=df.item_type.PLANT, flags1={unrotten=true, processable_to_vial=true}, vector_id=df.job_item_vector_id.PLANT})
    add_custom_item_to_job(process_plants_vial_job, {item_type=df.item_type.FLASK, flags1={empty=true, glass=true}, vector_id=df.job_item_vector_id.FLASK})

    local process_plants_barrel_job = {}
    attach_job_props(process_plants_barrel_job, "Process Plants (Barrel)", df.job_type.ProcessPlantsBarrel)
    add_custom_item_to_job(process_plants_barrel_job, {item_type=df.item_type.PLANT, flags1={unrotten=true, processable_to_barrel=true}, vector_id=df.job_item_vector_id.PLANT})
    add_custom_item_to_job(process_plants_barrel_job, {item_type=df.item_type.BARREL, flags1={empty=true}, vector_id=df.job_item_vector_id.BARREL})

    local make_cheese_job = {}
    attach_job_props(make_cheese_job, "Make Cheese", df.job_type.MakeCheese)
    add_custom_item_to_job(make_cheese_job, {flags1={unrotten=true, milk=true}, vector_id=df.job_item_vector_id.ANY_COOKABLE})

    local milk_job = {}
    attach_job_props(milk_job, "Milk Creature", df.job_type.MilkCreature)
    local shear_job = {}
    attach_job_props(shear_job, "Shear Creature", df.job_type.ShearCreature)

    local spin_thread = {}
    attach_job_props(spin_thread, "Spin Thread", df.job_type.SpinThread, {material_category={strand=true}})
    add_custom_item_to_job(spin_thread, {flags1={unrotten=true}, vector_id=df.job_item_vector_id.ANY_REFUSE, flags2={body_part=true, hair_wool=true}})

    return {process_plants_job, process_plants_vial_job, process_plants_barrel_job, make_cheese_job, milk_job, shear_job, spin_thread}
end

--df.workshop_type.Tanners
function get_tanners()
    return {}
end

function get_still()
    local extract_job = {}
    attach_job_props(extract_job, "Extract from Plants", df.job_type.ExtractFromPlants)
    add_custom_item_to_job(extract_job, {item_type=df.item_type.PLANT, flags1={unrotten=true, extract_bearing_plant=true}, vector_id=df.job_item_vector_id.PLANT})
    add_custom_item_to_job(extract_job, {item_type=df.item_type.FLASK, flags1={empty=true, glass=true}, vector_id=df.job_item_vector_id.FLASK})

    return {extract_job}
end

function get_ashery()
    local make_lye = {}
    attach_job_props(make_lye, "Make Lye", df.job_type.MakeLye)
    add_custom_item_to_job(make_lye, {item_type=df.item_type.BAR, mat_type=df.builtin_mats.ASH, vector_id=df.job_item_vector_id.BAR})
    add_custom_item_to_job(make_lye, {item_type=df.item_type.BUCKET, flags1={empty=true}, vector_id=df.job_item_vector_id.BUCKET})

    local make_potash_from_lye = {}
    attach_job_props(make_potash_from_lye, "Make Potash From Lye", df.job_type.MakePotashFromLye)
    add_custom_item_to_job(make_potash_from_lye, {flags1={lye_bearing=true}, vector_id=df.job_item_vector_id.BARREL})

    local make_potash_from_ash = {}
    attach_job_props(make_potash_from_ash, "Make Potash From Ash", df.job_type.MakePotashFromAsh)
    add_custom_item_to_job(make_potash_from_ash, {item_type=df.item_type.BAR, mat_type=df.builtin_mats.ASH, vector_id=df.job_item_vector_id.BAR})

    return {make_lye, make_potash_from_lye, make_potash_from_ash}
end

--[[wS={label='Soap Maker\'s Workshop',
        type=df.building_type.Workshop, subtype=df.workshop_type.Custom,
        custom=0},
    wp={label='Screw Press',
        type=df.building_type.Workshop, subtype=df.workshop_type.Custom,
        custom=1, min_width=1, max_width=1, min_height=1, max_height=1},]]

local fuel={item_type=df.item_type.BAR,mat_type=df.builtin_mats.COAL,vector_id=df.job_item_vector_id.BAR}

function add_jobs_to(result, types, itemdefs, job_type, category, material_info, is_permitted, is_magma)
    for _,itemid in ipairs(types) do
        local item_subtype = itemid

        local def = itemdefs[itemid]

        if is_permitted and not is_permitted(def) then
            goto nope
        end

        local name = "Make " .. material_info.name ..  " " .. def.name

        local test_job = {}
        attach_job_props(test_job, name, job_type, {mat_type=material_info.mat_type, mat_index=material_info.mat_index, item_subtype=item_subtype})
        add_custom_item_to_job(test_job, {item_type=df.item_type.BAR, quantity=450, min_dimension=150,
                                          mat_type=material_info.mat_type, mat_index=material_info.mat_index, vector_id=df.job_item_vector_id.BAR})

        if not is_magma then
            add_custom_item_to_job(test_job, fuel)
        end

        if category ~= nil then
            test_job.menu = {category, material_info.name}
        end

        result[#result+1] = test_job

        ::nope::
    end
end

function add_mat_job(result, job_type, category, material_info, is_magma)
    local name = df.job_type.attrs[job_type].caption .. " (" .. material_info.name .. ")"

    local test_job = {}
    attach_job_props(test_job, name, job_type, {mat_type=material_info.mat_type, mat_index=material_info.mat_index})

    add_custom_item_to_job(test_job, {item_type=df.item_type.BAR, quantity=450, min_dimension=150,
                                      mat_type=material_info.mat_type, mat_index=material_info.mat_index, vector_id=df.job_item_vector_id.BAR})

    if not is_magma then
        add_custom_item_to_job(test_job, fuel)
    end

    test_job.menu = {category, material_info.name}

    result[#result+1] = test_job
end

function add_clothes_to(result, category, material_info, permiss, is_magma)
    local entity = df.historical_entity.find(df.global.plotinfo.civ_id)
    local itemdefs = df.global.world.raws.itemdefs

    add_jobs_to(result, entity.resources.armor_type, itemdefs.armor, df.job_type.MakeArmor, category, material_info, permiss, is_magma)
    add_jobs_to(result, entity.resources.pants_type, itemdefs.pants, df.job_type.MakePants, category, material_info, permiss, is_magma)
    add_jobs_to(result, entity.resources.gloves_type, itemdefs.gloves, df.job_type.MakeGloves, category, material_info, permiss, is_magma)
    add_jobs_to(result, entity.resources.helm_type, itemdefs.helms, df.job_type.MakeHelm, category, material_info, permiss, is_magma)
    add_jobs_to(result, entity.resources.shoes_type, itemdefs.shoes, df.job_type.MakeShoes, category, material_info, permiss, is_magma)
end

function get_forge(is_magma)
    local result = {}

    local entity = df.historical_entity.find(df.global.plotinfo.civ_id)
    local itemdefs = df.global.world.raws.itemdefs
    local rock_types = df.global.world.raws.inorganics

    for rock_id = 0, #rock_types - 1 do
        local material = rock_types[rock_id].material

        if not material.flags.IS_METAL then
            goto notmetal
        end

        local material_name = material.state_adj.Solid

        local mat_type = 0
        local mat_index = rock_id

        material_info = {mat_type=mat_type, mat_index=mat_index, name=material_name}

        function is_not_ranged_weapon(def) return def.skill_ranged == -1 end
        function is_ranged_weapon(def) return not is_not_ranged_weapon(def) end

        function any(def) return true end

        function is_metal_clothing(def) return def.props.flags.METAL end

        if material.flags.ITEMS_WEAPON then
            add_jobs_to(result, entity.resources.weapon_type, itemdefs.weapons, df.job_type.MakeWeapon, "Weapons and Ammunition", material_info, is_not_ranged_weapon, is_magma)

            add_mat_job(result, df.job_type.MakeBallistaArrowHead, "Siege Equipment", material_info, is_magma)

            add_jobs_to(result, entity.resources.trapcomp_type, itemdefs.trapcomps, df.job_type.MakeTrapComponent, "Trap Components", material_info, any, is_magma)
        end

        if material.flags.ITEMS_WEAPON_RANGED then
            add_jobs_to(result, entity.resources.weapon_type, itemdefs.weapons, df.job_type.MakeWeapon, "Weapons and Ammunition", material_info, is_ranged_weapon, is_magma)
        end

        if material.flags.ITEMS_DIGGER then
            add_jobs_to(result, entity.resources.digger_type, itemdefs.weapons, df.job_type.MakeWeapon, "Weapons and Ammunition", material_info, any, is_magma)
        end

        if material.flags.ITEMS_AMMO then
            add_jobs_to(result, entity.resources.ammo_type, itemdefs.ammo, df.job_type.MakeAmmo, "Weapons and Ammunition", material_info, any, is_magma)
        end

        if material.flags.ITEMS_ARMOR then
            add_clothes_to(result, "Armor", material_info, is_metal_clothing, is_magma)

            add_jobs_to(result, entity.resources.shield_type, itemdefs.shields, df.job_type.MakeShield, "Armor", material_info, any, is_magma)
        end

        if material.flags.ITEMS_HARD then
            add_mat_job(result, df.job_type.ConstructMechanisms, "Trap Components", material_info, is_magma)

            add_mat_job(result, df.job_type.MakeCage, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeChain, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeAnimalTrap, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeBucket, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeBarrel, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructArmorStand, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructBlocks, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructDoor, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructFloodgate, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructHatchCover, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructGrate, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructStatue, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructCabinet, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructChest, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructThrone, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructCoffin, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructTable, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructWeaponRack, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructBin, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.MakePipeSection, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructSplint, "Furniture", material_info, is_magma)
            add_mat_job(result, df.job_type.ConstructCrutch, "Furniture", material_info, is_magma)
        end

        if material.flags.ITEMS_ANVIL then
            add_mat_job(result, df.job_type.ForgeAnvil, "Other Objects", material_info, is_magma)
        end

        if material.flags.ITEMS_HARD then
            add_mat_job(result, df.job_type.MakeCrafts, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeGoblet, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeToy, "Other Objects", material_info, is_magma)
        end

        function is_suitable_tool(itemdef) return ((material.flags.ITEMS_HARD and itemdef.flags.HARD_MAT) or (material.flags.ITEMS_METAL and itemdef.flags.METAL_MAT)) and not itemdef.flags.NO_DEFAULT_JOB end

        add_jobs_to(result, entity.resources.tool_type, itemdefs.tools, df.job_type.MakeTool, "Other Objects", material_info, is_suitable_tool, is_magma)

        if material.flags.ITEMS_HARD then
            add_mat_job(result, df.job_type.MakeFlask, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.MintCoins, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.StudWith, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeAmulet, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeBracelet, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeEarring, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeCrown, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeFigurine, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeRing, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeGem, "Other Objects", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeScepter, "Other Objects", material_info, is_magma)
        end

        if material.flags.ITEMS_SOFT then
            local metalclothing = (function(itemdef) return itemdef.props.flags.SOFT and itemdef.props.flags.METAL end)
            add_clothes_to(result, "Metal Clothing", material_info, any, is_magma)

            add_mat_job(result, df.job_type.MakeBackpack, "Metal Clothing", material_info, is_magma)
            add_mat_job(result, df.job_type.MakeQuiver, "Metal Clothing", material_info, is_magma)
        end

        ::notmetal::
    end

    return result
end

function get_siege()
    local result = {{
        name="construct ballista parts",
        items={{item_type=df.item_type.WOOD, vector_id=df.job_item_vector_id.WOOD}},
        job_fields={job_type=df.job_type.ConstructBallistaParts}
    },
    {
        name="construct catapult parts",
        items={{item_type=df.item_type.WOOD, vector_id=df.job_item_vector_id.WOOD}},
        job_fields={job_type=df.job_type.ConstructCatapultParts}
    }}

    local entity = df.historical_entity.find(df.global.plotinfo.civ_id)
    local itemdefs = df.global.world.raws.itemdefs
    local rock_types = df.global.world.raws.inorganics

    for rock_id = 0, #rock_types - 1 do
        local material = rock_types[rock_id].material

        if not material.flags.IS_METAL then
            goto notmetal
        end

        local material_name = material.state_adj.Solid

        local mat_type = 0
        local mat_index = rock_id

        material_info = {mat_type=mat_type, mat_index=mat_index, name=material_name}

        if material.flags.ITEMS_WEAPON then
            add_jobs_to(result, entity.resources.siegeammo_type, itemdefs.siege_ammo, df.job_type.AssembleSiegeAmmo, nil, material_info, nil, false)
        end

        ::notmetal::
    end

    local wood_job = {name = "Make wooden ballista arrow"}
    wood_job.job_fields = make_wood_job({item_subtype_s="ITEM_SIEGEAMMO_BALLISTA"})
    wood_job.job_fields.job_type=df.job_type.AssembleSiegeAmmo
    add_item_type_to_job(wood_job, "wood")

    result[#result+1] = wood_job

    return result
end

function get_jobs_furnace()

local jobs_furnace={
    [df.furnace_type.Smelter]={
        {
            name="Melt metal object",
            items={fuel,{flags2={allow_melt_dump=true, melt_designated=true}, vector_id=df.job_item_vector_id.ANY_MELT_DESIGNATED}},
            job_fields={job_type=df.job_type.MeltMetalObject}
        }
    },
    [df.furnace_type.MagmaSmelter]={
        {
            name="Melt metal object",
            items={{flags2={allow_melt_dump=true, melt_designated=true}, vector_id=df.job_item_vector_id.ANY_MELT_DESIGNATED}},
            job_fields={job_type=df.job_type.MeltMetalObject}
        }
    },
    [df.furnace_type.GlassFurnace]={
        {
            name="collect sand",
            items={},
            job_fields={job_type=df.job_type.CollectSand}
        },
        --glass crafts x3
    },
    [df.furnace_type.WoodFurnace]={
        defaults={item_type=df.item_type.WOOD,vector_id=df.job_item_vector_id.WOOD},
        {
            name="make charcoal",
            items={{}},
            job_fields={job_type=df.job_type.MakeCharcoal}
        },
        {
            name="make ash",
            items={{}},
            job_fields={job_type=df.job_type.MakeAsh}
        }
    },
    [df.furnace_type.Kiln]={
        {
            name="collect clay",
            items={},
            job_fields={job_type=df.job_type.CollectClay}
        }
    },
}

return jobs_furnace
end

function get_jobs_workshop()
local jobs_workshop={
    [df.workshop_type.Jewelers]={
        {
            name="cut gems",
            items={{item_type=df.item_type.ROUGH,flags1={unrotten=true}}},
            job_fields={job_type=df.job_type.CutGems}
        },
        {
            name="encrust finished goods with gems",
            items={{item_type=df.item_type.SMALLGEM},{flags1={improvable=true,finished_goods=true}}},
            job_fields={job_type=df.job_type.EncrustWithGems}
        },
        {
            name="encrust ammo with gems",
            items={{item_type=df.item_type.SMALLGEM},{flags1={improvable=true,ammo=true}}},
            job_fields={job_type=df.job_type.EncrustWithGems}
        },
        {
            name="encrust furniture with gems",
            items={{item_type=df.item_type.SMALLGEM},{flags1={improvable=true,furniture=true}}},
            job_fields={job_type=df.job_type.EncrustWithGems}
        },
    },
    [df.workshop_type.Bowyers] = get_bowyers_workshop(),
    [df.workshop_type.Fishery]={
        {
            name="prepare raw fish",
            items={{item_type=df.item_type.FISH_RAW,flags1={unrotten=true}, vector_id=df.job_item_vector_id.FISH_RAW}},
            job_fields={job_type=df.job_type.PrepareRawFish}
        },
        {
            name="extract from raw fish",
            items={{flags1={unrotten=true,extract_bearing_fish=true}, vector_id=df.job_item_vector_id.FISH_RAW},{vector_id=df.job_item_vector_id.ANY_GENERIC24, item_type=df.item_type.FLASK,flags1={empty=true,glass=true}}},
            job_fields={job_type=df.job_type.ExtractFromRawFish}
        },
        {
            name="catch live fish",
            items={},
            job_fields={job_type=df.job_type.CatchLiveFish}
        }, -- no items?
    },
    [df.workshop_type.Masons]=get_masonry_workshop(),
    [df.workshop_type.Carpenters] = get_carpenter_workshop(),
    [df.workshop_type.Craftsdwarfs] = get_craftsdwarf_workshop(),
    [df.workshop_type.Farmers] = get_farmers_workshop(),
    [df.workshop_type.Tanners] = get_tanners(),
    [df.workshop_type.Still] = get_still(),
    [df.workshop_type.Ashery] = get_ashery(),
    [df.workshop_type.MetalsmithsForge]=get_forge(false),
    [df.workshop_type.MagmaForge]=get_forge(true),
    [df.workshop_type.Kitchen]={
        --mat_type=2,3,4
        defaults={flags1={unrotten=true,cookable=true},vector_id=df.job_item_vector_id.ANY_COOKABLE},
        {
            name="prepare easy meal",
            items={{flags1={solid=true}},{flags1={}}},
            job_fields={job_type=df.job_type.PrepareMeal,mat_type=2}
        },
        {
            name="prepare fine meal",
            items={{flags1={solid=true}},{flags1={}},{flags1={}}},
            job_fields={job_type=df.job_type.PrepareMeal,mat_type=3}
        },
        {
            name="prepare lavish meal",
            items={{flags1={solid=true}},{flags1={}},{flags1={}},{flags1={}}},
            job_fields={job_type=df.job_type.PrepareMeal,mat_type=4}
        },
    },
    [df.workshop_type.Butchers]={
        {
            name="butcher an animal",
            items={{vector_id=df.job_item_vector_id.ANY_BUTCHERABLE, flags1={butcherable=true,unrotten=true,nearby=true}}},
            job_fields={job_type=df.job_type.ButcherAnimal}
        },
        {
            name="extract from land animal",
            items={{vector_id=df.job_item_vector_id.ANY_GENERIC24, flags1={extract_bearing_vermin=true,unrotten=true}},{item_type=df.item_type.FLASK,flags1={empty=true,glass=true}}},
            job_fields={job_type=df.job_type.ExtractFromLandAnimal}
        },
        {
            name="catch live land animal",
            items={},
            job_fields={job_type=df.job_type.CatchLiveLandAnimal}
        },
    },
    [df.workshop_type.Mechanics]={
        {
            name="construct mechanisms",
            items={{item_type=df.item_type.BOULDER,item_subtype=-1,vector_id=df.job_item_vector_id.BOULDER, mat_type=0,mat_index=-1,quantity=1,
                flags3={hard=true}}},
            job_fields={job_type=df.job_type.ConstructMechanisms, mat_type=0, mat_index=-1}
        },
        {
            name="construct traction bench",
            items={{item_type=df.item_type.TABLE,vector_id=df.job_item_vector_id.TABLE},{item_type=df.item_type.TRAPPARTS,vector_id=df.job_item_vector_id.TRAPPARTS},{item_type=df.item_type.CHAIN,vector_id=df.job_item_vector_id.CHAIN}},
            job_fields={job_type=df.job_type.ConstructTractionBench}
        },
    },
    [df.workshop_type.Loom]={
        {
            name="weave plant thread cloth",
            items={{item_type=df.item_type.THREAD,quantity=15000,min_dimension=15000,flags1={collected=true},flags2={plant=true},vector_id=df.job_item_vector_id.THREAD}},
            job_fields={job_type=df.job_type.WeaveCloth, material_category={plant=true}}
        },
        {
            name="weave silk thread cloth",
            items={{item_type=df.item_type.THREAD,quantity=15000,min_dimension=15000,flags1={collected=true},flags2={silk=true},vector_id=df.job_item_vector_id.THREAD}},
            job_fields={job_type=df.job_type.WeaveCloth, material_category={silk=true}}
        },
        {
            name="weave yarn cloth",
            items={{item_type=df.item_type.THREAD,quantity=15000,min_dimension=15000,flags1={collected=true},flags2={yarn=true},vector_id=df.job_item_vector_id.THREAD}},
            job_fields={job_type=df.job_type.WeaveCloth, material_category={yarn=true}}
        },
        {
            name="weave inorganic cloth",
            items={{item_type=df.item_type.THREAD,quantity=15000,min_dimension=15000,flags1={collected=true},mat_type=0,vector_id=df.job_item_vector_id.THREAD}},
            job_fields={job_type=df.job_type.WeaveCloth, material_category={strand=true}}
        },
        {
            name="collect webs",
            items={{item_type=df.item_type.THREAD,quantity=10,min_dimension=10,flags1={undisturbed=true},vector_id=df.job_item_vector_id.ANY_WEBS}},
            job_fields={job_type=df.job_type.CollectWebs}
        },
    },
    [df.workshop_type.Leatherworks]={
        defaults={item_type=df.item_type.SKIN_TANNED,vector_id=df.job_item_vector_id.SKIN_TANNED},
        {
            name="construct leather bag",
            items={{}},
            job_fields={job_type=df.job_type.ConstructChest, material_category={leather=true}}
        },
        {
            name="construct waterskin",
            items={{}},
            job_fields={job_type=df.job_type.MakeFlask, material_category={leather=true}}
        },
        {
            name="construct backpack",
            items={{}},
            job_fields={job_type=df.job_type.MakeBackpack, material_category={leather=true}}
        },
        {
            name="construct quiver",
            items={{}},
            job_fields={job_type=df.job_type.MakeQuiver, material_category={leather=true}}
        },
        {
            name="sew leather image",
            items={{item_type=-1,flags1={empty=true},flags2={sewn_imageless=true},vector_id=df.job_item_vector_id.IN_PLAY},{}},
            job_fields={job_type=df.job_type.SewImage, material_category={leather=true}}
        },
    },
    [df.workshop_type.Dyers]={
        {
            name="dye thread",
            items={{item_type=df.item_type.THREAD,quantity=15000,min_dimension=15000,flags1={collected=true},flags2={dyeable=true}},
                {flags1={unrotten=true},flags2={dye=true},vector_id=df.job_item_vector_id.ANY_COOKABLE}},
            job_fields={job_type=df.job_type.DyeThread}
        },
        {
            name="dye cloth",
            items={{item_type=df.item_type.CLOTH,quantity=10000,min_dimension=10000,flags2={dyeable=true}},
                {flags1={unrotten=true},flags2={dye=true},vector_id=df.job_item_vector_id.ANY_COOKABLE}},
            job_fields={job_type=df.job_type.DyeCloth}
        },
    },
    [df.workshop_type.Siege]=get_siege()

        --[[{
            name="assemble ballista arrow",
            items={{item_type=df.item_type.WOOD}},
            job_fields={job_type=df.job_type.AssembleSiegeAmmo}
        },
        {
            name="assemble tipped ballista arrow",
            items={{item_type=df.item_type.WOOD},{item_type=df.item_type.BALLISTAARROWHEAD}},
            job_fields={job_type=df.job_type.AssembleSiegeAmmo}
        },]]--
    ,
}
return jobs_workshop
end
local function matchIds(bid1,wid1,cid1,bid2,wid2,cid2)
    if bid1~=-1 and bid2~=-1 and bid1~=bid2 then
        return false
    end
    if wid1~=-1 and wid2~=-1 and wid1~=wid2 then
        return false
    end
    if cid1~=-1 and cid2~=-1 and cid1~=cid2 then
        return false
    end
    return true
end
local function scanRawsReaction(buildingId,workshopId,customId,adventure_check)
    local is_adventure_mode = dfhack.world.isAdventureMode(df.global.gamemode)

    local ret={}
    for idx,reaction in ipairs(df.global.world.raws.reactions.reactions) do
        if adventure_check and not is_adventure_mode then
            for k,v in pairs(reaction.flags) do
                if k == "ADVENTURE_MODE_ENABLED" and v then
                    goto nope
                end
            end
        end

        for k,v in pairs(reaction.building.type) do
            if matchIds(buildingId,workshopId,customId,v,reaction.building.subtype[k],reaction.building.custom[k]) then
                table.insert(ret,reaction)
            end
        end

        ::nope::
    end
    return ret
end
local function reagentToJobItem(reagent,react_id,reagentId)
    local ret_item
    ret_item=utils.clone_with_default(reagent, input_filter_defaults, true)
    ret_item.reaction_id=react_id
    ret_item.reagent_index=reagentId
    return ret_item
end
local function addReactionJobs(ret,bid,wid,cid,adventure_check)
    local reactions=scanRawsReaction(bid,wid or -1,cid or -1,adventure_check)
    for idx,react in pairs(reactions) do
    local job={name=react.name,
               items={},job_fields={job_type=df.job_type.CustomReaction,reaction_name=react.code},
               menu={"extra"}
              }
        for reagentId,reagent in pairs(react.reagents) do
            table.insert(job.items,reagentToJobItem(reagent,idx,reagentId))
        end
        if react.flags.FUEL then
            table.insert(job.items,fuel)
        end
        table.insert(ret,job)
    end
end
local function scanRawsOres()
    local ret={}
    for idx,ore in ipairs(df.global.world.raws.inorganics) do
        if #ore.metal_ore.mat_index~=0 then
            ret[idx]=ore
        end
    end
    return ret
end
local function addSmeltJobs(ret,use_fuel)
    local ores=scanRawsOres()
    for idx,ore in pairs(ores) do
        --print("adding:",ore.material.state_name.Solid)
        --printall(ore)
    local job={name="smelt "..ore.material.state_name.Solid,job_fields={job_type=df.job_type.SmeltOre,mat_type=df.builtin_mats.INORGANIC,mat_index=idx},items={
        {item_type=df.item_type.BOULDER,mat_type=df.builtin_mats.INORGANIC,mat_index=idx,vector_id=df.job_item_vector_id.BOULDER}}}
        if use_fuel then
            table.insert(job.items,fuel)
        end
        table.insert(ret,job)
    end
    return ret
end
function getJobs(buildingId,workshopId,customId,adventure_check)
    local ret={}
    local c_jobs
    if buildingId==df.building_type.Workshop then
        c_jobs=get_jobs_workshop()[workshopId]
    elseif buildingId==df.building_type.Furnace then
        c_jobs=get_jobs_furnace()[workshopId]

        if workshopId == df.furnace_type.Smelter or workshopId == df.furnace_type.MagmaSmelter then
            c_jobs=utils.clone(c_jobs,true)
            addSmeltJobs(c_jobs,workshopId == df.furnace_type.Smelter)
        end
    else
        return nil
    end
    if c_jobs==nil then
        c_jobs={}
    else
        c_jobs=utils.clone(c_jobs,true)
    end

    addReactionJobs(c_jobs,buildingId,workshopId,customId,adventure_check)
    for jobId,contents in pairs(c_jobs) do
        if jobId~="defaults" then
            local entry={}
            entry.menu=utils.clone(contents.menu)
            entry.name=contents.name
            local lclDefaults=utils.clone(input_filter_defaults,true)
            if c_jobs.defaults ~=nil then
                    utils.assign(lclDefaults,c_jobs.defaults)
            end
            entry.items={}

            if contents.items == nil then
                for k,item in pairs(contents) do
                    dfhack.println(k, item)
                end
            end

            for k,item in pairs(contents.items) do
                entry.items[k]=utils.clone(lclDefaults,true)
                utils.assign(entry.items[k],item)
            end
            if contents.job_fields~=nil then
                entry.job_fields={}
                utils.assign(entry.job_fields,contents.job_fields)

                --todo: all subtypes classes, use a hardcoded list of ids?
                if entry.job_fields.item_subtype_s then
                    entry.job_fields.item_subtype = get_subtype_of(entry.job_fields.item_subtype_s)
                    entry.job_fields.item_subtype_s = nil
                end
            end
            ret[jobId]=entry
        end
    end
    --get jobs, add in from raws
    return ret
end