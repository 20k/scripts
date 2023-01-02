--@ module = true

imgui = dfhack.imgui
nobles = reqscript('dfui_nobles')
render = reqscript('dfui_render')

--[[auto entity = df::historical_entity::find(df::global::ui->group_id);
    if (!entity)
        return CR_NOT_FOUND;

    for (size_t i = 0; i < entity->squads.size(); i++)
    {
        auto squad = df::squad::find(entity->squads[i]);
        if (!squad)
            continue;

        auto item = out->add_value();
        item->set_squad_id(squad->id);

        if (squad->name.has_name)
            describeName(item->mutable_name(), &squad->name);
        if (!squad->alias.empty())
            item->set_alias(squad->alias);

        for (size_t j = 0; j < squad->positions.size(); j++)
            item->add_members(squad->positions[j]->occupant);
    }
]]--

function render_military()
	local entity = df.historical_entity.find(df.global.ui.group_id)
	
	for _,squad_id in ipairs(entity.squads) do	
		local squad = df.squad.find(squad_id)
		
		if squad == nil then
			goto badsquad
		end
		
		local name = dfhack.df2utf(dfhack.TranslateName(squad.name, true, false))
		
		if squad.alias and #squad.alias ~= 0 then
			name = dfhack.df2utf(squad.alias)
		end
		
		imgui.Text(name)
		
		for k,spos in ipairs(squad.positions) do
			local real_unit = nobles.histfig_to_unit(spos.occupant)
			
			if real_unit == nil then
				goto notreal
			end
			
			local unit_name = render.get_user_facing_name(real_unit)
			
			imgui.Text(unit_name)
			
			::notreal::
		end
		
		::badsquad::
	end
end