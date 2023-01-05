--@ module = true

imgui = dfhack.imgui
nobles = reqscript('dfui_nobles')
render = reqscript('dfui_render')

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
	
	local leader_assignment_id = squad.leader_assignment
	
	local leader_assignment = nobles.assignment_id_to_assignment(leader_assignment_id)
	
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
		if nobles.add_or_transfer_fort_title_to(pending_unit, leader_assignment_id) then
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
	
	local leader_assignment_id = squad.leader_assignment
	
	local leader_assignment = nobles.assignment_id_to_assignment(leader_assignment_id)
	
	if leader_assignment == nil then
		dfhack.println("No leader assignment in remove")
		return
	end

	unit.military.squad_id = -1
	unit.military.squad_position = -1
	unit.military.cur_uniform = 0
	
	if existing_histfig_id ~= -1 and leader_assignment.histfig == existing_histfig_id then
		nobles.remove_fort_title(leader_assignment_id)
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
		local s1 = df.squad.find(a)
		local s2 = df.squad.find(b)
		
		--[[local s3 = df.global.world.squads.bad.find(a)
		
		if s3 ~= nil then
			dfhack.println("hi")
		end]]--
		
		local p1 = nobles.position_id_to_position(s1.leader_position)
		local p2 = nobles.position_id_to_position(s2.leader_position)

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
			if squad.leader_assignment == v.id then
				table.remove(assignments, i)
				goto done
			end
		end
		
		::done::
	end
	
	local sorted = nobles.get_sorted_assignment_objects_by_precedence(assignments)
	
	return sorted
end

--intentionally using a fixed seed
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

function squad_in_entity(squad_id, entity_id)
	local entity = df.historical_entity.find(entity_id)
	
	return fnd(squad_id, entity.squads)
	--return entity.squads.find(squad_id)
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
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
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
	
	--dfhack.println(render.get_user_facing_name(all_elegible_dwarf_units[#all_elegible_dwarf_units]))
	
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
			
			--for k,p in ipairs(squad.positions) do
				--imgui.Text("Position")
								
				--[[imgui.Text(tostring(#p.orders))
				
				imgui.Text(tostring(#p.preferences[0]))
				imgui.Text(tostring(#p.preferences[1]))
				imgui.Text(tostring(#p.preferences[2]))
				imgui.Text(tostring(#p.preferences[3]))]]--
				
				--imgui.Text(p.unk_c4)
				--[[imgui.Text(tostring(p.quiver))
				imgui.Text(tostring(p.backpack))
				imgui.Text(tostring(p.flask))
				imgui.Text(tostring(p.unk_1))
				imgui.Text(tostring(p.activities[0]))
				imgui.Text(tostring(p.activities[1]))
				imgui.Text(tostring(p.activities[2]))				
				imgui.Text(tostring(p.events[0]))
				imgui.Text(tostring(p.events[1]))
				imgui.Text(tostring(p.events[2]))
				imgui.Text(tostring(p.unk_2))]]--
				
				--imgui.Text(tostring(#p.uniform[0]))
				
				--imgui.Text
			--end
			
			
			--imgui.Text(tostring(squad.schedule[0][1].name))
			

			--imgui.Text(tostring(squad.id))
			--imgui.Text(tostring(squad.uniform_priority))

			--[[imgui.Text(tostring(#squad.ammo_items))
			imgui.Text(tostring(#squad.ammo_units))
			imgui.Text(tostring(squad.carry_food))
			imgui.Text(tostring(squad.carry_water))
			imgui.Text(tostring(squad.entity_id))
			imgui.Text(tostring(squad.unk_1))
			imgui.Text(tostring(squad.activity))]]--

			--words: -1, -1, 1731, -1, -1, 1182, -1. Seems to be common
			--parts of speech: noun, noun, adjective, noun, noun, nounplural, noun

			--

			--[[for t,v in ipairs(squad.name.words) do
				imgui.Text(v)
			end]]--
			
			--[[for t,v in ipairs(squad.name.parts_of_speech) do
				imgui.Text(df.part_of_speech[v])
			end]]--
			
			--imgui.Text(dfhack.TranslateName(generate_language_name_object()))
			--imgui.Text(dfhack.TranslateName(generate_language_name_object()))
			--imgui.Text(dfhack.TranslateName(generate_language_name_object()))

			--[[imgui.Text(tostring(squad.id))
				
			for k,p in ipairs(df.global.world.squads.bad) do
				if p.id == squad.id then
					imgui.Text("In bad")
				end
			end]]--	
			
			--imgui.Text(tostring(squad_in_entity(squad_id, df.global.ui.civ_id)))
			--imgui.Text(tostring(squad_in_entity(squad_id, df.global.ui.site_id)))
			--imgui.Text(tostring(squad_in_entity(squad_id, df.global.ui.group_id)))
			--imgui.Text(tostring(squad_in_entity(squad_id, df.global.ui.race_id)))
			
			--imgui.Text(tostring(df.global.ui.group_id))
			--imgui.Text(tostring(squad.entity_id))
			
			--imgui.Text(#df.global.ui.squads.list)
			
			--imgui.Text(#squad.schedule[0][0].orders)
			
			--[[imgui.Text(tostring(squad.positions[0].events[0]))
			imgui.Text(tostring(squad.positions[0].events[1]))
			imgui.Text(tostring(squad.positions[0].events[2]))]]--
			
			--imgui.Text(squad.name.language)
			
			for i1,k in ipairs(squad.schedule) do
				--for m=0,11 do
				for m,sched in ipairs(k) do
					--local sched = k[m]
					
					--imgui.Text("Test " .. tostring(sched))
					--imgui.Text("orders " .. tostring(#sched.orders))

					for oa,v in ipairs(sched.orders) do
						--imgui.Text("alert: " .. tostring(i1) .. " " .. " month " .. tostring(m) .. " position " .. tostring(oa) .. " " .. tostring(v.min_count))
						
						--imgui.Text("A: " .. tostring(#sched.orders))
						
						--imgui.Text(tostring(#v.positions))
						
						--imgui.Text(tostring(#v.positions))
						
						--[[for d,n in ipairs(v.positions) do
							imgui.Text(tostring(n))
						end]]--
						
						--[[imgui.Text("Unky " .. tostring(v.order.unk_v40_1))
						imgui.Text(tostring(v.order.unk_v40_2))
						imgui.Text(tostring(v.order.unk_v40_2))
						imgui.Text(tostring(v.order.year))
						imgui.Text(tostring(v.order.year_tick))
						imgui.Text(tostring(v.order.unk_v40_3))
						imgui.Text("end " .. tostring(v.order.unk_1))]]--
						
						--[[for d,n in ipairs(v.positions) do
							if n == true then
							imgui.Text(tostring(n))
							end
						end]]--
					end
				end
			end

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

selected_alert = 1
selected_squad_alert = 1

function render_alerts()
	local entity = df.historical_entity.find(df.global.ui.group_id)
	local sorted_squads = get_sorted_squad_ids_by_precedence(entity.squads)

	local alerts = {}
	
	for _,v in ipairs(df.global.ui.alerts.list) do
		alerts[#alerts + 1] = v
	end
	
	local civ_alert_idx = df.global.ui.alerts.civ_alert_idx + 1
	
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
		df.global.ui.alerts.civ_alert_idx = math.min(math.max(0, selected_alert - 1), #alerts - 1)
	end
	
	imgui.SameLine()
	
	if render.render_hotkey_text({key="v", text="Set squad to alert, retaining orders"}) then
		local squad_id = sorted_squads[selected_squad_alert]
		
		local squad = df.squad.find(squad_id)
		
		if squad ~= nil then
			squad.cur_alert_idx = math.min(math.max(0, selected_alert - 1), #alerts - 1)
		end
	end
	
end

function render_military()
	if imgui.BeginTabBar("Tabs", 0) then
		if imgui.BeginTabItem("Squads") then
			render_squad_unit_selection()
		
			imgui.EndTabItem()
		end
		
		if imgui.BeginTabItem("Alerts") then
			render_alerts()
			
			imgui.EndTabItem()
		end
		
		imgui.EndTabBar()
	end
end