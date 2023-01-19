local function id_sorter(a, b)
	return a.id < b.id
end

function building_into_zone_unidir(bld, zone)
	for k,v in ipairs(zone.contained_buildings) do
		if v == bld then
			return
		end
	end
	
	zone.contained_buildings:insert('#', bld)
	
	table.sort(zone.contained_buildings, id_sorter)
end

function zone_into_building_unidir(bld, zone)
	for k,v in ipairs(zone.relations) do
		if v == zone then
			return
		end
	end

	bld.relations:insert('#', zone)

	table.sort(bld.relations, id_sorter)

    bld->relations.push_back(zone);
end

local function add_to_zones(bld)
	if not bld.canBeZone() then
		return
	end
	
	local pos = xyz2pos(bld.centerx, bld.centery, bld.z)
	
	local zones = dfhack.buildings.findCivzonesAt(pos)
	
	for _, zone in ipairs(zones) do
		zone_into_building_unidir(bld, zone)
		building_into_zone_unidir(bld, zone)
	end
end

for k,zone in ipairs(df.global.world.buildings.other.ACTIVITY_ZONE) do
	zone.contained_buildings:clear()
end

for k, bld in ipairs(df.global.world.buildings.other.IN_PLAY) do
	bld.relations:clear()

	add_to_zones(bld)
end