--@ module = true

local utils = require 'utils'

--[[function get_subtype_of(class, id)
    local base_types = class.get_vector()

    for _,v in pairs(base_types) do
        if v.id == id then
            return v.subtype
        end
    end

    return nil
end

function get_tool_subtype_of(id)
    return get_subtype_of(df.itemdef_toolst, id)
end]]--

function get_subtype_of(id)
    --todo: Unconditionally check subtypes of everything
    local base_types = df.itemdef_toolst.get_vector()

    for _,v in pairs(base_types) do
        if v.id == id then
            return v.subtype
        end
    end

    return nil
end

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
    flags2 = { allow_artifact = true },
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
		job_fields={job_type=type, material_category=df.job_material_category.wood, item_subtype_s=subtype_s}
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
        make_carpentry("Make wooden barrel", df.job_type.Makebarrel),
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

function make_wood_item(job_item)
    local default_item = {item_type=df.item_type.WOOD,vector_id=df.job_item_vector_id.WOOD}

    utils.assign(default_item, job_item)

    return default_item
end

function make_wood_job(unfinished_job)
    local default_job = {material_category=df.job_material_category.wood}

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
    local default_job = {material_category={bone=true}}}

    utils.assign(default_job, unfinished_job)

    return default_job
end

local fuel={item_type=df.item_type.BAR,mat_type=df.builtin_mats.COAL}
jobs_furnace={
    [df.furnace_type.Smelter]={
        {
            name="Melt metal object",
            items={fuel,{flags2={allow_melt_dump=true}}},--also maybe melt_designated
            job_fields={job_type=df.job_type.MeltMetalObject}
        }
    },
    [df.furnace_type.MagmaSmelter]={
        {
            name="Melt metal object",
            items={{flags2={allow_melt_dump=true}}},--also maybe melt_designated
            job_fields={job_type=df.job_type.MeltMetalObject}
        }
    },
    --[[ [df.furnace_type.MetalsmithsForge]={
        unpack(concat(furnaces,mechanism,anvil,crafts,coins,flask))

    },
    ]]
    --MetalsmithsForge,
    --MagmaForge
    --[[
        forges:
            weapons and ammo-> from raws...
            armor -> raws
            furniture -> builtins?
            siege eq-> builtin (only balista head)
            trap eq -> from raws+ mechanisms
            other object-> anvil, crafts, goblets,toys,instruments,nestbox... (raws?) flask, coins,stud with iron
            metal clothing-> raws???
    ]]
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
jobs_workshop={
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
    [df.workshop_type.Fishery]={
        {
            name="prepare raw fish",
            items={{item_type=df.item_type.FISH_RAW,flags1={unrotten=true}}},
            job_fields={job_type=df.job_type.PrepareRawFish}
        },
        {
            name="extract from raw fish",
            items={{flags1={unrotten=true,extract_bearing_fish=true}},{item_type=df.item_type.FLASK,flags1={empty=true,glass=true}}},
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
    [df.workshop_type.Kitchen]={
        --mat_type=2,3,4
        defaults={flags1={unrotten=true}},
        {
            name="prepare easy meal",
            items={{flags1={solid=true,cookable=true}},{flags1={cookable=true}}},
            job_fields={job_type=df.job_type.PrepareMeal,mat_type=2}
        },
        {
            name="prepare fine meal",
            items={{flags1={solid=true,cookable=true}},{flags1={cookable=true}},{flags1={cookable=true}}},
            job_fields={job_type=df.job_type.PrepareMeal,mat_type=3}
        },
        {
            name="prepare lavish meal",
            items={{flags1={solid=true,cookable=true}},{flags1={cookable=true}},{flags1={cookable=true}},{flags1={cookable=true}}},
            job_fields={job_type=df.job_type.PrepareMeal,mat_type=4}
        },
    },
    [df.workshop_type.Butchers]={
        {
            name="butcher an animal",
            items={{flags1={butcherable=true,unrotten=true,nearby=true}}},
            job_fields={job_type=df.job_type.ButcherAnimal}
        },
        {
            name="extract from land animal",
            items={{flags1={extract_bearing_vermin=true,unrotten=true}},{item_type=df.item_type.FLASK,flags1={empty=true,glass=true}}},
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
            job_fields={job_type=df.job_type.ConstructMechanisms}
        },
        {
            name="construct traction bench",
            items={{item_type=df.item_type.TABLE},{item_type=df.item_type.MECHANISM},{item_type=df.item_type.CHAIN}},
            job_fields={job_type=df.job_type.ConstructTractionBench}
        },
    },
    [df.workshop_type.Loom]={
        {
            name="weave plant thread cloth",
            items={{item_type=df.item_type.THREAD,quantity=15000,min_dimension=15000,flags1={collected=true},flags2={plant=true}}},
            job_fields={job_type=df.job_type.WeaveCloth, material_category=df.job_material_category.plant}
        },
        {
            name="weave silk thread cloth",
            items={{item_type=df.item_type.THREAD,quantity=15000,min_dimension=15000,flags1={collected=true},flags2={silk=true}}},
            job_fields={job_type=df.job_type.WeaveCloth, material_category=df.job_material_category.silk}
        },
        {
            name="weave yarn cloth",
            items={{item_type=df.item_type.THREAD,quantity=15000,min_dimension=15000,flags1={collected=true},flags2={yarn=true}}},
            job_fields={job_type=df.job_type.WeaveCloth, material_category=df.job_material_category.yarn}
        },
        {
            name="weave inorganic cloth",
            items={{item_type=df.item_type.THREAD,quantity=15000,min_dimension=15000,flags1={collected=true},mat_type=0}},
            job_fields={job_type=df.job_type.WeaveCloth, material_category=df.job_material_category.strand}
        },
        {
            name="collect webs",
            items={{item_type=df.item_type.THREAD,quantity=10,min_dimension=10,flags1={undisturbed=true}}},
            job_fields={job_type=df.job_type.CollectWebs}
        },
    },
    [df.workshop_type.Leatherworks]={
        defaults={item_type=SKIN_TANNED},
        {
            name="construct leather bag",
            items={{}},
            job_fields={job_type=df.job_type.ConstructChest}
        },
        {
            name="construct waterskin",
            items={{}},
            job_fields={job_type=df.job_type.MakeFlask}
        },
        {
            name="construct backpack",
            items={{}},
            job_fields={job_type=df.job_type.MakeBackpack}
        },
        {
            name="construct quiver",
            items={{}},
            job_fields={job_type=df.job_type.MakeQuiver}
        },
        {
            name="sew leather image",
            items={{item_type=-1,flags1={empty=true},flags2={sewn_imageless=true}},{}},
            job_fields={job_type=df.job_type.SewImage}
        },
    },
    [df.workshop_type.Dyers]={
        {
            name="dye thread",
            items={{item_type=df.item_type.THREAD,quantity=15000,min_dimension=15000,flags1={collected=true},flags2={dyeable=true}},
                {flags1={unrotten=true},flags2={dye=true}}},
            job_fields={job_type=df.job_type.DyeThread}
        },
        {
            name="dye cloth",
            items={{item_type=df.item_type.CLOTH,quantity=10000,min_dimension=10000,flags2={dyeable=true}},
                {flags1={unrotten=true},flags2={dye=true}}},
            job_fields={job_type=df.job_type.DyeThread}
        },
    },
    [df.workshop_type.Siege]={
        {
            name="construct ballista parts",
            items={{item_type=df.item_type.WOOD}},
            job_fields={job_type=df.job_type.ConstructBallistaParts}
        },
        {
            name="construct catapult parts",
            items={{item_type=df.item_type.WOOD}},
            job_fields={job_type=df.job_type.ConstructCatapultParts}
        },
        {
            name="assemble ballista arrow",
            items={{item_type=df.item_type.WOOD}},
            job_fields={job_type=df.job_type.AssembleSiegeAmmo}
        },
        {
            name="assemble tipped ballista arrow",
            items={{item_type=df.item_type.WOOD},{item_type=df.item_type.BALLISTAARROWHEAD}},
            job_fields={job_type=df.job_type.AssembleSiegeAmmo}
        },
    },
}
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
    ret_item=utils.clone_with_default(reagent, input_filter_defaults)
    ret_item.reaction_id=react_id
    ret_item.reagent_index=reagentId
    return ret_item
end
local function addReactionJobs(ret,bid,wid,cid,adventure_check)
    local reactions=scanRawsReaction(bid,wid or -1,cid or -1,adventure_check)
    for idx,react in pairs(reactions) do
    local job={name=react.name,
               items={},job_fields={job_type=df.job_type.CustomReaction,reaction_name=react.code}
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
        c_jobs=jobs_workshop[workshopId]
    elseif buildingId==df.building_type.Furnace then
        c_jobs=jobs_furnace[workshopId]

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
            entry.name=contents.name
            local lclDefaults=utils.clone(input_filter_defaults,true)
            if c_jobs.defaults ~=nil then
                    utils.assign(lclDefaults,c_jobs.defaults)
            end
            entry.items={}
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
