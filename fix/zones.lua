local utils=require('utils')

local function id_sorter(a, b)
	if a.id == b.id then
		return 0
	end

	if a.id > b.id then
		return 1
	end

	return -1
end

function building_into_zone_unidir(bld, zone)
	zone.contained_buildings:insert('#', bld)

	utils.sort_vector(zone.contained_buildings, nil, id_sorter)
end

function zone_into_building_unidir(bld, zone)
	bld.relations:insert('#', zone)

	utils.sort_vector(bld.relations, nil, id_sorter)
end

local function add_to_zones(bld)
	if not bld:canMakeRoom() then
		return
	end

	local pos = xyz2pos(bld.centerx, bld.centery, bld.z)

	local zones = dfhack.buildings.findCivzonesAt(pos)
	
	if zones == nil then
		return
	end

	for _, zone in ipairs(zones) do
		zone_into_building_unidir(bld, zone)
		building_into_zone_unidir(bld, zone)
	end
end

for k, zone in ipairs(df.global.world.buildings.other.ACTIVITY_ZONE) do
	zone.contained_buildings:resize(0)
end

for k, bld in ipairs(df.global.world.buildings.other.IN_PLAY) do
	bld.relations:resize(0)

	add_to_zones(bld)
end