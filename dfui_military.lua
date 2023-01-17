--@ module = true

imgui = dfhack.imgui
nobles = reqscript('dfui_nobles')
render = reqscript('dfui_render')
utils = require('utils')

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

	if dfhack.units.isChild(unit) or dfhack.units.isBaby(unit) then
		return false
	end

	return true
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

function get_squad_name(squad)
	local name = dfhack.df2utf(dfhack.TranslateName(squad.name, true, false))

	if squad.alias and #squad.alias ~= 0 then
		name = dfhack.df2utf(squad.alias)
	end

	return name
end

last_dwarf_list = nil
selected_squad = -1
selected_dwarf = -1

function appoint_to(squad_id, slot, pending_unit)
	local squad = df.squad.find(squad_id)

	if squad == nil then
		dfhack.println("Bad squad id in appoint")
		return
	end

	--squad.positions is 0 index based
	local existing_position = squad.positions[slot - 1]
	local existing_histfig_id = existing_position.occupant
	local pending_unit_histfig = nobles.unit_to_histfig(pending_unit)

	local leader_assignment = nobles.squad_id_to_assignment(squad.id)

	if leader_assignment == nil then
		dfhack.println("No leader assignment")
		return
	end

	--if the current leader is the person I'm replacing, or we're slotting into an empty slot 1 and there is no leader
	--note that this is a very cautious check because I'm not sure if slot 1 is guaranteed to be the leader
	--testing has shown that this is probably unnecessary
	--because noble positions appear to be *derived* from squad positions, rather than vice versa
	--that said it does show that I probably *do* need to modify squads when assigning nobles
	if (leader_assignment.histfig == existing_histfig_id) or (leader_assignment.histfig == -1 and existing_histfig_id == -1 and slot == 1) then
		if nobles.add_or_transfer_fort_title_to(pending_unit, leader_assignment.id) then
			squad.positions[slot - 1].occupant = pending_unit_histfig.id
		end
	else
		squad.positions[slot - 1].occupant = pending_unit_histfig.id
	end
end

--don't think either of the manip functions are correct, dwarves have a squad_id and a squad_position
--When adding a dwarf, the game appears to fix them up, but not when removing
function remove_from(squad_id, slot)
	local squad = df.squad.find(squad_id)

	if squad == nil then
		dfhack.println("Bad squad id in remove")
		return
	end

	local existing_position = squad.positions[slot - 1]
	local existing_histfig_id = existing_position.occupant
	local unit = nobles.histfig_to_unit(existing_histfig_id)

	local leader_assignment = nobles.squad_id_to_assignment(squad.id)

	if leader_assignment == nil then
		dfhack.println("No leader assignment in remove")
		return
	end

	unit.military.squad_id = -1
	unit.military.squad_position = -1
	unit.military.cur_uniform = 0

	if existing_histfig_id ~= -1 and leader_assignment.histfig == existing_histfig_id then
		nobles.remove_fort_title(leader_assignment.id)
	end

	squad.positions[slot - 1].occupant = -1
end

dwarf_page = 0

function get_sorted_squad_ids_by_precedence(squads)
	local vals = {}

	for _,v in ipairs(squads) do
		vals[#vals + 1] = v
	end

	function comp(a,b)
		--yeesh
		local a1 = nobles.squad_id_to_assignment(a)
		local a2 = nobles.squad_id_to_assignment(b)

		local p1_id = nobles.assignment_to_position(a1.id)
		local p2_id = nobles.assignment_to_position(a2.id)

		local p1 = nobles.position_id_to_position(p1_id)
		local p2 = nobles.position_id_to_position(p2_id)

		return p1.precedence < p2.precedence
	end

	table.sort(vals, comp)

	return vals
end

function get_all_uncreated_squad_assignments(squads)
	local assignments = nobles.collect_assignment_objects_with_possible_squads()

	local real_squads = get_sorted_squad_ids_by_precedence(squads)

	for _,k in ipairs(real_squads) do
		local squad = df.squad.find(k)

		for i,v in ipairs(assignments) do
			if squad.id == v.squad_id then
				table.remove(assignments, i)
				goto done
			end
		end

		::done::
	end

	local sorted = nobles.get_sorted_assignment_objects_by_precedence(assignments)

	return sorted
end

rng = dfhack.random.new(1234)

--words: -1, -1, 1731, -1, -1, 1182, -1. Seems to be common
--parts of speech: noun, noun, adjective, noun, noun, nounplural, noun
function generate_language_name_object()
	local result = {}

	--result.language = math.floor(rng:drandom() * #df.world.raws.language.translations)
	result.type = df.language_name_type.Squad
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

function fnd(id, parent)
	for _,v in ipairs(parent) do
		if v == id then
			return true
		end
	end

	return false
end

function create_squad_from_noble(assignment)
	local squad = dfhack.units.makeSquad(assignment.id)

	local name = generate_language_name_object()

	squad.name.type = name.type
	squad.name.nickname = name.nickname
	squad.name.first_name = name.first_name
	squad.name.has_name = 1
	squad.name.language = 0

	for i,j in ipairs(name.words) do
		squad.name.words[i - 1] = j
	end

	for i,j in ipairs(name.parts_of_speech) do
		squad.name.parts_of_speech[i - 1] = j
	end
end

function render_squad_unit_selection()
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	local squad_ids = {}
	local dwarf_histfigs_in_squads = {}
	local all_elegible_dwarf_units = last_dwarf_list
	local commandable_assignments_without_squads = get_all_uncreated_squad_assignments(entity.squads)

	if render.menu_was_changed() or all_elegible_dwarf_units == nil then
		all_elegible_dwarf_units = get_valid_units()
		last_dwarf_list = all_elegible_dwarf_units
		render.menu_change_clear()
	end

	local dwarf_count = 300
	local start_dwarf = 1

	start_dwarf = math.min(start_dwarf, (#all_elegible_dwarf_units-dwarf_count) + 1)
	start_dwarf = math.max(start_dwarf, 0)

	local sorted_squads = get_sorted_squad_ids_by_precedence(entity.squads)

	for _,squad_id in ipairs(sorted_squads) do
		local squad = df.squad.find(squad_id)

		if squad == nil then
			goto badsquad
		end

		local lsquad = {}

		for k,spos in ipairs(squad.positions) do
			--imgui.Text(tostring(spos.uniform[0][0].color))

			local real_unit = nobles.histfig_to_unit(spos.occupant)

			if real_unit == nil then
				lsquad[k+1] = -1
				goto notreal
			end

			lsquad[k+1] = spos.occupant

			::notreal::
		end

		local next_id = #squad_ids + 1

		squad_ids[next_id] = squad_id
		dwarf_histfigs_in_squads[next_id] = lsquad

		::badsquad::
	end

	local dwarf_slice = {}

	for i=start_dwarf,(start_dwarf+dwarf_count-1) do
		dwarf_slice[#dwarf_slice + 1] = all_elegible_dwarf_units[i]
	end

	if (selected_squad == -1 or selected_squad == nil) and #squad_ids > 0 then
		selected_squad = 1
	end

	if (selected_dwarf == -1 or selected_dwarf == nil) then
		selected_dwarf = 1
	end

	local table_height = math.max(10, #entity.squads)

	if imgui.BeginTable("Tt1", 1, (1<<13) | (1<<16)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();

		for o,squad_id in ipairs(squad_ids) do
			local squad = df.squad.find(squad_id)

			local name = get_squad_name(squad)

			if imgui.Selectable(name.."##squadname_" .. tostring(squad_id), selected_squad == o) then
				selected_squad = o
			end
		end

		for o,a in ipairs(commandable_assignments_without_squads) do
			local position = nobles.position_id_to_position(nobles.assignment_to_position(a.id))

			local offset_index = o + #squad_ids

			if imgui.Selectable(position.name[0].."##unclaimed_"..tostring(a.id), selected_squad==offset_index) then
				selected_squad = offset_index
			end
		end

		imgui.EndTable()
	end

	--need to use squad ids instead of selected squad for multiplayer if squads dynamically change
	if selected_squad ~= -1 and selected_squad <= #squad_ids then
		imgui.SameLine()

		if imgui.BeginTable("Tt2##t"..tostring(selected_squad), 1, (1<<13) | (1<<16)) then
			imgui.TableNextRow();
			imgui.TableNextColumn();

			if selected_squad ~= -1 then
				for o,histfig in ipairs(dwarf_histfigs_in_squads[selected_squad]) do
					if histfig == -1 then
						imgui.Text("   ")

						imgui.SameLine()

						if imgui.Selectable("Available##dorfsel2_" .. tostring(o), selected_dwarf == o) then
							selected_dwarf = o
						end
					else
						local real_unit = nobles.histfig_to_unit(histfig)

						local unit_name = render.get_user_facing_name(real_unit)

						if imgui.ButtonColored({fg=COLOR_RED}, "[X]##rem"..tostring(histfig)) then
							remove_from(squad_ids[selected_squad], o)
						end

						if imgui.IsItemHovered() then
							imgui.SetTooltip("Remove From Squad")
						end

						imgui.SameLine()

						if imgui.Selectable(unit_name .. "##dorfsel_" .. tostring(histfig), selected_dwarf == o) then
							selected_dwarf = o
						end
					end
				end
			end

			imgui.EndTable()
		end

		local keyboard_friendly_nav = imgui.IsNavVisible()

		if selected_squad ~= -1 and selected_dwarf ~= -1 then
			imgui.SameLine()

			if imgui.BeginTable("Tt3##b"..tostring(selected_squad), 1, (1<<13)) then
				imgui.TableNextRow();
				imgui.TableNextColumn();

				local num_per_page = 17

				local start_idx = dwarf_page * num_per_page + 1

				local max_page = math.floor(#dwarf_slice / num_per_page)

				imgui.Text("Page: " .. tostring(dwarf_page + 1) .. "/" .. tostring(max_page+1))

				if imgui.Button("Leave Vacant") then
					remove_from(squad_ids[selected_squad], selected_dwarf)
				end

				start_idx = math.max(start_idx, 1)

				local end_idx = start_idx + num_per_page - 1

				local rendered_count = 0

				for i=start_idx,end_idx do
					local unit = dwarf_slice[i]

					if unit == nil then
						goto skip
					end

					local unit_name = render.get_user_facing_name(unit)

					rendered_count = rendered_count+1

					--the reason for the ### indexing here is so that the keyboard nav
					--active highlight target remains the same across different pages
					if imgui.Button(unit_name .. "###namesel_" .. tostring(i-start_idx)) then
						appoint_to(squad_ids[selected_squad], selected_dwarf, unit)
					end

					::skip::
				end

				for i=rendered_count,num_per_page-1 do
					imgui.Text(" ")
				end

				imgui.NewLine()

				if render.render_hotkey_text({key="q", text="Prev"}) then
					dwarf_page = dwarf_page - 1

					dwarf_page = math.max(dwarf_page, 0)
				end

				imgui.SameLine()

				if render.render_hotkey_text({key="e", text="Next"}) then
					dwarf_page = dwarf_page + 1

					dwarf_page = math.max(dwarf_page, 0)
					dwarf_page = math.min(dwarf_page, max_page)
				end

				imgui.EndTable()
			end
		end
	end

	if selected_squad > #squad_ids then
		imgui.NewLine()

		if render.render_hotkey_text({key="c", text="Create Squad"}) then
			local real_offset = selected_squad - #squad_ids

			local assignment = commandable_assignments_without_squads[real_offset]

			create_squad_from_noble(assignment)
		end
	end
end


--[[selected_alert = 1
selected_squad_alert = 1

function render_alerts()
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)
	local sorted_squads = get_sorted_squad_ids_by_precedence(entity.squads)

	local alerts = {}

	for _,v in ipairs(df.global.plotinfo.alerts.list) do
		alerts[#alerts + 1] = v
	end

	local civ_alert_idx = df.global.plotinfo.alerts.civ_alert_idx + 1

	if imgui.BeginTable("Alerts", 1, (1<<13) | (1<<16)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();

		imgui.NewLine()
		imgui.Text("ALERTS")
		imgui.NewLine()

		for o,alert in ipairs(alerts) do
			local name = alert.name

			if civ_alert_idx == o then
				imgui.TextColored({fg=COLOR_LIGHTGREEN}, "[CIV]")
			else
				imgui.Text("     ")
			end

			imgui.SameLine()

			if imgui.Selectable(name.."##"..tostring(selected_alert), selected_alert==o) then
				selected_alert = o
			end
		end

		imgui.EndTable()
	end

	imgui.SameLine()

	if imgui.BeginTable("Alerts2", 1, (1<<13) | (1<<16)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();

		imgui.NewLine()
		imgui.Text("SQUADS")
		imgui.NewLine()

		for o,squad_id in ipairs(sorted_squads) do
			local squad = df.squad.find(squad_id)

			local name = get_squad_name(squad)

			local squad_alert = squad.cur_alert_idx + 1

			if squad_alert == selected_alert then
				imgui.TextColored({fg=COLOR_LIGHTGREEN}, "A")
			else
				imgui.Text(" ")
			end

			imgui.SameLine()

			if imgui.Selectable(name.."##sq"..tostring(squad_id), selected_squad_alert==o) then
				selected_squad_alert = o
			end
		end

		imgui.EndTable()
	end

	imgui.NewLine()

	if render.render_hotkey_text({key="c", text="Set civilian alert"}) then
		df.global.plotinfo.alerts.civ_alert_idx = math.min(math.max(0, selected_alert - 1), #alerts - 1)
	end

	imgui.SameLine()

	if render.render_hotkey_text({key="v", text="Set squad to alert, retaining orders"}) then
		local squad_id = sorted_squads[selected_squad_alert]

		local squad = df.squad.find(squad_id)

		if squad ~= nil then
			squad.cur_alert_idx = math.min(math.max(0, selected_alert - 1), #alerts - 1)
		end
	end
end]]--

function b2n(b)
	if b then
		return 1
	end

	return 0
end

function invert(v)
	if v == 0 then
		return 1
	end

	return 0
end

function copy_flags(target, source)
	for k,v in pairs(target) do
		target[k] = false
	end

	for k,v in pairs(source) do
		target[k] = v
	end
end

--does this have a f1 == f2?
function same_flags(f1, f2)
	for k,v in pairs(f1) do
		if f2[k] ~= v then
			return false
		end
	end

	for k,v in pairs(f2) do
		if f1[k] ~= v then
			return false
		end
	end

	return true
end

function position_uniform_matches_entity_uniform(position, entity_uniform)
	if not same_flags(position.flags, entity_uniform.flags) then
		return false
	end

	for i=0,6 do
		local uniform_length = #entity_uniform.uniform_item_types[i]

		local position_uniform_length = #position.uniform[i]

		if uniform_length ~= position_uniform_length then
			return false
		end

		for k=0,(uniform_length-1) do
			local item_type = entity_uniform.uniform_item_types[i][k]
			local item_subtype = entity_uniform.uniform_item_subtypes[i][k]
			local item_eui = entity_uniform.uniform_item_info[i][k]

			local p_spec = position.uniform[i][k]

			if item_type ~= p_spec.item_filter.item_type then
				return false
			end

			if item_subtype ~= p_spec.item_filter.item_subtype then
				return false
			end

			--if item_eui.item_color ~= p_spec.color

			if item_eui.material_class ~= p_spec.item_filter.material_class then
				return false
			end

			if not same_flags(item_eui.indiv_choice, p_spec.indiv_choice) then
				return false
			end

			if item_eui.mattype ~= p_spec.item_filter.mattype then
				return false
			end

			if item_eui.matindex ~= p_spec.item_filter.matindex then
				return false
			end
		end
	end

	return true
end

--return spec
function entity_uniform_to_uniform_spec(uniform_spec, part, which)
	local item_type_vector_in = uniform_spec.uniform_item_types[part]
	local item_subtype_vector_in = uniform_spec.uniform_item_subtypes[part]
	local item_uniform_in = uniform_spec.uniform_item_info[part]

	local item_type = item_type_vector_in[which]
	local item_subtype = item_subtype_vector_in[which]
	local item_uniform = item_uniform_in[which]

	local squad_uniform = df.squad_uniform_spec:new()
	squad_uniform.item = -1
	squad_uniform.color = -1

	--TEST UNIFORM ITEM.ITEM_COLOR
	--think it mathes to squad_uniform.color

	squad_uniform.item_filter.item_type = item_type
	squad_uniform.item_filter.item_subtype = item_subtype
	squad_uniform.item_filter.material_class = item_uniform.material_class
	squad_uniform.item_filter.mattype = item_uniform.mattype
	squad_uniform.item_filter.matindex = item_uniform.matindex

	copy_flags(squad_uniform.indiv_choice, item_uniform.indiv_choice)

	return squad_uniform
end

selected_squad_uniform = 1

function render_assign_uniforms()
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	local uniforms = entity.uniforms

	local sorted_squads = get_sorted_squad_ids_by_precedence(entity.squads)

	if imgui.BeginTable("SquadUniformss", 1, (1<<13) | (1<<16)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();

		for o,squad_id in ipairs(sorted_squads) do
			local squad = df.squad.find(squad_id)

			local name = get_squad_name(squad)

			if imgui.Selectable(name.."##usq"..tostring(squad_id), selected_squad_uniform==o) then
				selected_squad_uniform = o
			end
		end

		imgui.EndTable()
	end

	local csquad_id = sorted_squads[selected_squad_uniform]

	if csquad_id == nil then
		goto nope
	end

	local csquad = df.squad.find(csquad_id)

	if csquad == nil then
		goto nope
	end

	imgui.SameLine()

	if imgui.BeginTable("UniformTemplates", 1, (1<<13) | (1<<16)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();

		for i,v in ipairs(uniforms) do
			local num_matching = 0

			for _,position in ipairs(csquad.positions) do
				if position_uniform_matches_entity_uniform(position, v) then
					num_matching = num_matching + 1
				end
			end

			local pad = ""

			---todo: this is probably better solved with tables
			if num_matching < 10 then
				pad = " "
			end

			imgui.Text("("..tostring(num_matching)..")" .. pad)

			imgui.SameLine()

			if imgui.Button(v.name .. "##" .. tostring(i)) then
				for i=0,6 do
					local flags = v.flags

					for pi,pp in ipairs(csquad.positions) do
						--leak memory
						pp.uniform[i]:resize(0)

						for o,_ in ipairs(v.uniform_item_types[i]) do
							local spec = entity_uniform_to_uniform_spec(v, i, o)

							pp.uniform[i]:insert('#', spec)
						end

						copy_flags(pp.flags, flags)
					end
				end
			end
		end

		imgui.EndTable()
	end

	imgui.NewLine()

	local num_non_replace = 0
	local num_replace = 0

	local num_non_exact = 0
	local num_exact = 0

	for _,p in ipairs(csquad.positions) do
		num_non_replace = num_non_replace + b2n(p.flags.replace_clothing == false)
		num_replace = num_replace + b2n(p.flags.replace_clothing == true)

		num_non_exact = num_non_exact + b2n(p.flags.exact_matches == false)
		num_exact = num_exact + b2n(p.flags.exact_matches == true)
	end

	local replace_text = {"Over clothing", "Replacing clothing"}
	local exact_text = {"Non exact matches", "Exact matches"}

	local is_replace = 0
	local is_exact = 0

	if num_replace >= num_non_replace then
		is_replace = 1
	end

	if num_exact >= num_non_exact then
		is_exact = 1
	end

	local current_replace_text = replace_text[is_replace + 1]
	local current_exact_text = exact_text[is_exact + 1]

	if render.render_hotkey_text({key="r", text=current_replace_text}) then
		for _,p in ipairs(csquad.positions) do
			p.flags.replace_clothing = invert(is_replace)
		end
	end

	--imgui.SameLine()

	if render.render_hotkey_text({key="t", text=current_exact_text}) then
		for _,p in ipairs(csquad.positions) do
			p.flags.exact_matches = invert(is_exact)
		end
	end

	::nope::

	--if render.render_hotkey_text({key="r", text="Set squad to alert, retaining orders"}) then
end

function debug_military()
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	local sorted_squads = get_sorted_squad_ids_by_precedence(entity.squads)

	for _,v in ipairs(sorted_squads) do
		local squad = df.squad.find(v)

		imgui.Text("Asched", tostring(#squad.schedule))
		--[[imgui.Text("Orders", tostring(#squad.orders))

		for _,p in ipairs(squad.positions) do
			imgui.Text("P", tostring(#p.orders))
		end]]--

		--local sched = squad.schedule[6][2].name
		--imgui.Text("Sched", tostring(#sched))

		imgui.Text("TSched", tostring(squad.schedule[2]))

		local sched = squad.schedule[2][0]

		imgui.Text("Sched", tostring(sched))

		--imgui.Text("Position Orders", tostring(#squad.positions[0].orders))

		--imgui.Text("Sched Orders", tostring(#sched.order_assignments))

		--[[for _,o in ipairs(sched.orders) do
			--imgui.Text("OA", tostring(o[0]))
			imgui.Text("Order")

			for _,p in ipairs(o.positions) do
				imgui.Text("P", tostring(p))
			end
		end]]--

		imgui.Text("Alert?", squad.cur_alert_idx)

		--think order assignments might be full of rubbish
		--[[imgui.Text("Sched Orders", tostring(#sched.order_assignments))

		for _,o in ipairs(sched.order_assignments) do
			imgui.Text("OA", tostring(o[0]))
		end]]--
	end

	--imgui.Text("Test", tostring(#df.global.plotinfo.alerts.anon_1))

	imgui.Text("Alert idx", tostring(df.global.plotinfo.alerts.civ_alert_idx))

	for _, v in ipairs(df.global.plotinfo.alerts.routines) do
		--imgui.Text(tostring(v[.name))

		--imgui.Text(test.name)
	end
end

function render_new_schedules()
	local entity = df.historical_entity.find(df.global.plotinfo.group_id)
	local sorted_squads = get_sorted_squad_ids_by_precedence(entity.squads)

	for _,s_id in ipairs(sorted_squads) do
		local squad = df.squad.find(s_id)

		imgui.Text(get_squad_name(squad))

		if squad then
			for _, o in ipairs(squad.schedule) do
				local name = o[1].name
				imgui.Text(tostring(name))
			end
		end
	end
end

function render_military()
	debug_military()

	render.set_can_window_pop(true)

	if imgui.BeginTabBar("Tabs", 0) then
		if imgui.BeginTabItem("Squads") then
			render_squad_unit_selection()

			imgui.EndTabItem()
		end

		if imgui.BeginTabItem("Schedules") then
			render_new_schedules()

			imgui.EndTabItem()
		end

		if imgui.BeginTabItem("Uniforms") then
			render_assign_uniforms()

			imgui.EndTabItem()
		end

		imgui.EndTabBar()
	end
end

selected_squad_order = -1

function fill_order_default(order)
	order.unk_v40_1 = -1
	order.unk_v40_2 = -1
	order.year = df.global.cur_year
	order.year_tick = df.global.cur_year_tick
	order.unk_v40_3 = -1
	order.unk_1 = 0
end

function get_hostile_units()
	local result = {}

	local units = df.global.world.units.active

	for _,unit in ipairs(units) do
		--and not dfhack.units.isFortControlled(unit)?

		local generic_wild = not dfhack.units.isOwnCiv(unit) and not dfhack.units.isOwnGroup(unit) and not dfhack.units.isFortControlled(unit) and not dfhack.units.isKilled(unit)

		local angry = render.check_hostile(unit)

		if (generic_wild or angry) and dfhack.units.isVisible(unit) and not dfhack.units.isGhost(unit) and not dfhack.units.isKilled(unit) then
			result[#result+1] = unit
		end
	end

	return result
end

function cancel_orders(squad)
	for i,j in ipairs(squad.orders) do
		j:delete()
	end

	squad.orders:resize(0)
end

function render_squads()
	render.set_can_window_pop(true)
	render.set_can_global_pop(render.get_submenu() ~= nil)

	local entity = df.historical_entity.find(df.global.plotinfo.group_id)

	local sorted_squads = get_sorted_squad_ids_by_precedence(entity.squads)

	--I actually have no idea how df handles this by default, but it must stop before 'p'
	--considering numbering them 1-9
	local keys = {"a","b","c","d","e","f","g","h","i","j"}

	if imgui.BeginTable("SquadTable", 3, (1<<13) | (1<<16)) then
		imgui.TableNextRow();
		imgui.TableNextColumn();

		for o,squad_id in ipairs(sorted_squads) do
			local squad = df.squad.find(squad_id)

			if squad == nil then
				goto badsquad
			end

			local should_highlight = selected_squad_order==o

			if render.render_hotkey_text({key=keys[o], text=get_squad_name(squad), highlight=should_highlight, highlight_col=COLOR_LIGHTCYAN}) then
				if selected_squad == o then
					selected_squad = -1
				else
					selected_squad_order = o
				end
			end

			imgui.TableNextColumn();

			local order_str = ""

			for _,order in ipairs(squad.orders) do
				order_str = order_str .. "[" .. utils.call_with_string(order, "getDescription") .. "]"
			end

			if #order_str > 0 then
				imgui.Text(order_str)
			end

			imgui.TableNextColumn();

			local count = 0

			for _,position in ipairs(squad.positions) do
				if position.occupant ~= -1 then
					count = count+1
				end
			end

			imgui.Text(count)

			imgui.TableNextRow();
			imgui.TableNextColumn();

			::badsquad::
		end

		imgui.EndTable()
	end

	imgui.NewLine()

	local current_menu_item = render.get_submenu()

	local current_menu_item_type = ""

	if current_menu_item ~= nil then
		current_menu_item_type = current_menu_item.type
	end

	local to_render = {{key="k", text="Attack"}, {key="m", text="Move"}, {key="o", text="Cancel orders"}}

	local state, clicked = render.render_table_impl(to_render, current_menu_item_type)

	local csquad_id = sorted_squads[selected_squad_order]

	if csquad_id == nil then
		goto novalidselected
	end

	local csquad = df.squad.find(csquad_id)

	if csquad == nil then
		goto novalidselected
	end

	if current_menu_item_type == "Move" and imgui.IsMouseClicked(0) and not imgui.WantCaptureMouse() then
		local mouse_pos = render.get_mouse_world_coordinates()

		local move_order = df.squad_order_movest:new()
		fill_order_default(move_order)

		--there are a lot of things that are low on the priority list
		--right at the bottom are things that I didn't know existed until I
		--dug through the source code
		move_order.point_id = -1

		move_order.pos.x = mouse_pos.x
		move_order.pos.y = mouse_pos.y
		move_order.pos.z = mouse_pos.z

		cancel_orders(csquad)

		csquad.orders:insert('#', move_order)

		render.pop_incremental()
	end

	if current_menu_item_type == "Move" and not imgui.WantCaptureMouse() then
		imgui.BeginTooltip()
		imgui.Text("Click to move here")
		imgui.EndTooltip()
	end

	--[[for o,squad_id in ipairs(sorted_squads) do
		local squad = df.squad.find(squad_id)
		imgui.Text("Orders " .. tostring(#squad.orders))

		for i,v in ipairs(squad.orders) do
			--if df.squad_order_movest:is_instance(v) then
			--	imgui.Text("Move order to .. " .. tostring(v.pos.x) .. " " .. tostring(v.pos.y) .. " " .. tostring(v.pos.z) .. " id " .. tostring(v.point_id))
			--end

			if df.squad_order_kill_listst:is_instance(v) then
				for _,d in ipairs(v.units) do
					imgui.Text(tostring(d))
				end

				for _,d in ipairs(v.histfigs) do
					imgui.Text(tostring(d))
				end
			end
		end
	end]]--

	if current_menu_item_type == "Attack" then
		local valid_units = get_hostile_units()

		local mouse_pos = render.get_mouse_world_coordinates()

		local found_unit = nil

		--todo: cycle units under cursor with ,.
		for _,unit in ipairs(valid_units) do
			if unit.pos.x == mouse_pos.x and unit.pos.y == mouse_pos.y and unit.pos.z == mouse_pos.z then
				found_unit = unit
			end
		end

		if found_unit ~= nil then
			imgui.BeginTooltip()
			imgui.Text("Kill: " .. render.get_user_facing_name(found_unit) .. "?")
			imgui.EndTooltip()
		end

		function kill_unit(squad, unit)
			cancel_orders(squad)

			local order = df.squad_order_kill_listst:new()
			fill_order_default(order)

			order.units:insert('#', unit.id)

			local histfig = nobles.unit_to_histfig(unit)

			if histfig ~= nil then
				order.histfigs:insert('#', histfig.id)
			else
				order.histfigs:insert('#', -1)
			end

			order.title = "Killing " .. render.get_user_facing_name(unit)

			csquad.orders:insert('#', order)
		end

		if imgui.IsMouseClicked(0) and not imgui.WantCaptureMouse() and found_unit then
			kill_unit(csquad, found_unit)
			render.pop_incremental()
		end

		imgui.Text("Click to kill, or select below")

		--todo: hotkeys
		for _,unit in ipairs(valid_units) do
			local col = render.get_unit_colour(unit)

			if imgui.ButtonColored({fg=col}, render.get_user_facing_name(unit) .. "##killy" ..tostring(unit.id)) then
				kill_unit(csquad, unit)
				render.pop_incremental()
			end
		end
	end

	if state == "Move" and clicked then
		render.push_submenu({type="Move"})
	end

	if state == "Cancel orders" and clicked then
		cancel_orders(csquad)
	end

	if state == "Attack" and clicked then
		render.push_submenu({type="Attack"})
	end

	::novalidselected::
end