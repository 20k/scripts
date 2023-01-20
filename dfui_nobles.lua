--@ module = true

local gui = require('gui')

imgui = dfhack.imgui
render = reqscript('dfui_render')

function fnd(array, fieldname, fieldvalue)
	--for _,v in ipairs(array) do
	for i=0,#array-1 do
		if array[i].id == fieldvalue then
			return array[i]
		end
	end

	return nil
end

function assignment_to_position(assignment_id)
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	if entity == nil then
		return nil
	end

	local assignment = fnd(entity.positions.assignments, "id", assignment_id)

	if assignment == nil then
		return nil
	end

	return assignment.position_id
end

function assignment_id_to_assignment(assignment_id)
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	if entity == nil then
		return nil
	end

	return fnd(entity.positions.assignments, "id", assignment_id)
end

function position_id_to_position(id)
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	if entity == nil then
		return nil
	end

	return fnd(entity.positions.own, "id", id)
end

--won't remove eg monarch
function remove_fort_title(assignment_id)
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	if entity == nil then
		return nil
	end

	local assignment = fnd(entity.positions.assignments, "id", assignment_id)

	if assignment == nil then
		return
	end

	local current_hist_fig = df.historical_figure.find(assignment.histfig)

	if current_hist_fig ~= nil then
		for k,v in pairs(current_hist_fig.entity_links) do
			if df.histfig_entity_link_positionst:is_instance(v) and v.assignment_id==assignment_id and v.entity_id==entity.id then --hint:df.histfig_entity_link_positionst
				current_hist_fig.entity_links:erase(k)

				break
			end
		end
	end

	assignment.histfig = -1

	return nil
end

function unit_to_histfig(unit)
	local nem = dfhack.units.getNemesis(unit)

	if nem == nil then
		return nil
	end

	if nem.figure == nil then
		return nil
	end

	return nem.figure
end

function find_offset(df_array, id)
	for i,v in ipairs(df_array) do
		if v.id == id then
			return i
		end
	end

	return -1
end

--doesn't work for eg monarch
function add_or_transfer_fort_title_to(unit, assignment_id)
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	if entity == nil then
		return nil
	end

	local assignment = assignment_id_to_assignment(assignment_id)

	if assignment == nil then
		return false
	end

	local newfig=dfhack.units.getNemesis(unit).figure

	if newfig == nil then
		return false
	end

	local assignment_vector_idx = find_offset(entity.positions.assignments, assignment_id)

	remove_fort_title(assignment_id)

	newfig.entity_links:insert("#",{new=df.histfig_entity_link_positionst,entity_id=df.global.plotinfo.group_id,
				link_strength=100,assignment_id=assignment_id, assignment_vector_idx=assignment_vector_idx,start_year=df.global.cur_year})

	--as far as I can tell, histfig2 is never any different to histfig
	--tested using a vampire bookkeeper
	--the game also doesn't set histfig or histfgi2 any differently to how I'm doing it in that case either
	assignment.histfig=newfig.id
	assignment.histfig2=newfig.id

	return true
end

function get_unit_title_assignment_ids(unit)
	local titles = {}

	local histfig = df.historical_figure.find(unit.hist_figure_id)

	if histfig == nil then
		return titles
	end

	local entity_links = histfig.entity_links

	for i=0,#entity_links-1 do
		local link = entity_links[i]

		if not df.is_instance(df.histfig_entity_link_positionst, link) then
			goto notnoble
		end

		local epos = link

		local entity = df.historical_entity.find(epos.entity_id)

		if entity == nil then
			--imgui.Text("no noble 2")
			goto notnoble
		end

		local assignment = fnd(entity.positions.assignments, "id", epos.assignment_id)

		if assignment == nil then
			--imgui.Text("no noble 3")
			goto notnoble
		end

		local position = fnd(entity.positions.own, "id", assignment.position_id)

		if position == nil then
			--imgui.Text("no noble 4")
			goto notnoble
		end

		titles[#titles+1] = assignment.id

		::notnoble::
	end

	return titles
end

function valid_unit(unit)
	if not dfhack.units.isOwnGroup(unit) then
		return false
	end

	if not dfhack.units.isOwnCiv(unit) then
		return false
	end

	if not dfhack.units.isActive(unit) then
		return false
	end

	if unit.flags2.visitor then
		return false
	end

	if unit.flags3.ghostly then
		return false
	end

	return true
end

local override_noble_assignments = imgui.Ref(false)

function is_elected_position(position)
	for k,v in pairs(position.flags) do
		if tostring(k) == "ELECTED" and v then
			return true
		end
	end

	return false
end

function number_in_position(position_id)
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	local count = 0

	if entity == nil then
		return count
	end

	for k,assignment in pairs(entity.positions.assignments) do
		if assignment ~= nil then
			if assignment.position_id == position_id and assignment.histfig ~= -1 then
				count = count + 1
			end
		end
	end

	return count
end

function anyone_in_position(position_id)
	return number_in_position(position_id) > 0
end

function get_valid_units()
	local result = {}

	local units = df.global.world.units.active

	for i=0,#units-1 do
		local unit = units[i]

		if not valid_unit(unit) then
			goto continue
		end

		result[#result+1] = unit

		::continue::
	end

	return result
end

function can_appoint(position)
	if is_elected_position(position) then
		return false
	end

	local appoint_satisfied = false

	for k,v in ipairs(position.appointed_by) do
		if anyone_in_position(v) then
			appoint_satisfied = true
			break
		end
	end

	if not appoint_satisfied then
		return false
	end

	if position.requires_population == 0 then
		return appoint_satisfied
	end

	return #get_valid_units() >= position.requires_population
end

function push_new_assignment(position_id)
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	if entity == nil then
		return nil
	end

	local next_assignment_id = entity.positions.next_assignment_id

	local next_assignment = df.entity_position_assignment:new()

	next_assignment.id = next_assignment_id
	next_assignment.histfig = -1
	next_assignment.histfig2 = -1
	next_assignment.position_id = position_id
	next_assignment.position_vector_idx = find_offset(entity.positions.own, position_id)

	for i,j in pairs(next_assignment.flags) do
		j = 0
	end

	next_assignment.flags[0] = 1

	next_assignment.squad_id = -1

	next_assignment.unk_1 = -1
	next_assignment.unk_2 = -1
	next_assignment.unk_3 = -1
	next_assignment.unk_4 = -1
	next_assignment.unk_6 = 0

	entity.positions.assignments:insert("#", next_assignment)

	--?
	entity.positions.next_assignment_id = entity.positions.next_assignment_id + 1

	return next_assignment.id
end

function collect_commander_position_ids()
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	local result = {}

	if entity == nil then
		return result
	end

	for i=0,(#entity.positions.own)-1 do
		local position = entity.positions.own[i]

		for j=0,#position.commander_id-1 do
			result[#result+1] = position.commander_id[j]
		end
	end

	return result
end

function squad_id_to_assignment(squad_id)
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	for _,v in ipairs(entity.positions.assignments) do
		if v.squad_id == squad_id then
			return v
		end
	end

	return nil
end

function collect_assignment_objects_with_possible_squads()
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	local result = {}

	for i=0,#entity.positions.assignments-1 do
		local assignment = entity.positions.assignments[i]
		local position = position_id_to_position(assignment_to_position(assignment.id))

		if position.squad_size > 0 then
			result[#result+1] = assignment
		end
	end

	return result
end

function get_sorted_assignment_objects_by_precedence(assignment_ids)
	local sorted_assignments = shallow_copy_to_array(assignment_ids)

	function comp(a, b)
		local p1 = position_id_to_position(assignment_to_position(a.id))
		local p2 = position_id_to_position(assignment_to_position(b.id))

		return p1.precedence < p2.precedence
	end

	table.sort(sorted_assignments, comp)

	return sorted_assignments
end

function render_commander_positions(override)
	local position_ids = collect_commander_position_ids()

	for k, v in ipairs(position_ids) do
		local position = position_id_to_position(v)

		local is_valid = can_appoint(position) or override

		if not is_valid then
			goto nope
		end

		imgui.Text(position.name[0])

		imgui.TableNextColumn()

		if imgui.ButtonColored({fg=COLOR_GREEN}, "[New]##" .. position.id) then
			local id = push_new_assignment(position.id)
			render.set_menu_item(id)
		end

		if imgui.IsItemHovered() then
			imgui.SetTooltip("Create New Assignment")
		end

		imgui.TableNextColumn()

		imgui.TableNextRow();
		imgui.TableNextColumn();

		::nope::
	end
end

--other code does df.historical_figure.find(id), df.unit.find(result.unit_id)
function histfig_to_unit(histfig_id)
	if histfig_id < 0 or histfig_id == nil then
		return nil
	end

	--[[local units = df.global.world.units.active

	for i=0,#units-1 do
		local unit = units[i]

		local nemesis = dfhack.units.getNemesis(unit)

		if nemesis == nil then
			goto continue
		end

		local fig = nemesis.figure

		if fig == nil then
			goto continue
		end

		if fig.id == histfig_id then
			return unit
		end

		::continue::
	end

	return nil]]--

	local histfig_actual = df.historical_figure.find(histfig_id)

	if histfig_actual == nil then
		return nil
	end

	return df.unit.find(histfig_actual.unit_id)
end

function shallow_copy_to_array(t)
	local result = {}

	for k,v in pairs(t) do
		result[#result+1] = v
	end

	return result
end

function render_titles()
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	if entity == nil then
		return nil
	end

	local menu_item = render.get_menu_item()

	local override = imgui.Get(override_noble_assignments)

	local sorted_assignments = get_sorted_assignment_objects_by_precedence(entity.positions.assignments)

	if menu_item == nil then
		if imgui.BeginTable("NobleTable", 3, (1<<13)) then
			imgui.TableNextRow();
			imgui.TableNextColumn();

			for k,v in ipairs(sorted_assignments) do
				local current_assignment_id = v.id

				if v.flags[0] == false and not override then
					goto invalid
				end

				local position = position_id_to_position(assignment_to_position(current_assignment_id))

				local position_filled = v.histfig ~= -1

				if (can_appoint(position) or position_filled) or override then
					imgui.Text(position.name[0])

					imgui.TableNextColumn()

					local str = "[Set]"
					local col = COLOR_GREEN

					if position_filled then
						str = "[Replace]"
						col = COLOR_BROWN
					end

					if imgui.ButtonColored({fg=col}, str .. "##" .. tostring(current_assignment_id)) then
						render.set_menu_item(current_assignment_id)
					end

					if imgui.IsItemHovered() then
						if not position_filled then
							imgui.SetTooltip("Appoint Position")
						else
							imgui.SetTooltip("Replace Position")
						end
					end

					imgui.TableNextColumn()

					local unit_opt = histfig_to_unit(v.histfig)

					if unit_opt ~= nil then
						imgui.Text(render.get_user_facing_name(unit_opt))
					end

					imgui.TableNextRow();
					imgui.TableNextColumn();
				end

				::invalid::
			end

			render_commander_positions(override)

			imgui.EndTable()
		end

		if imgui.Button("Back") or (imgui.WantCaptureMouse() and imgui.IsMouseClicked(1)) then
			render.pop_menu()
		end
	else
		local units = df.global.world.units.active

		local position_id = assignment_to_position(menu_item)

		local position = position_id_to_position(position_id)

		imgui.Text("Currently Choosing: " .. position.name[0])

		if imgui.Button("Back") or (imgui.WantCaptureMouse() and imgui.IsMouseClicked(1)) then
			render.set_menu_item(nil)
		end

		if imgui.Button("Leave Vacant##-1") then
			remove_fort_title(menu_item)
			render.set_menu_item(nil)
			goto done
		end

		imgui.NewLine()

		for i=0,#units-1 do
			local unit = units[i]

			if not valid_unit(unit) then
				goto continue
			end

			if dfhack.units.isChild(unit) or dfhack.units.isBaby(unit) then
				goto continue
			end

			local name = render.get_user_facing_name(unit)

			if imgui.Button(name .. "##" .. tostring(unit.id) .. "_" .. tostring(menu_item)) then
				add_or_transfer_fort_title_to(unit, menu_item)
				render.set_menu_item(nil)

				goto done
			end

			::continue::
		end

		::done::
	end

	imgui.Checkbox("Dev: Override noble assignments", override_noble_assignments)
end