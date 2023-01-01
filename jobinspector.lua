--@ module = true

imgui = dfhack.imgui

function dump_flags(f)
	local test = f

	for k,v in pairs(f) do
		if v and v ~= 0 then
			imgui.Text("Flag: " .. tostring(k) .. " : " .. tostring(v))
		end
	end
end

function any_flags(f)
	for k,v in pairs(f) do
		if v and v ~= 0 then
			return true
		end
	end
	
	return false
end

--so, the building_holder's general ref id *is* simply the buildings id, good good
--think thats its only real propery, other than type, which is general_ref_building_holderst
function dump_general_ref(gr)
	local type = gr:getType()
	local id = gr:getID()
	
	--dump_flags(df.general_ref)
	
	--imgui.Text(df.general_ref_type._identity)
	
	--dump_flags(df.general_ref_type)
	
	--local type_name = df.general_ref_type.attrs[type].key_table
	
	imgui.Text("Type: " .. df.general_ref_type[type])
	
	if df.general_ref_building:is_instance(gr) then
		imgui.Text("Building id: " .. tostring(gr.building_id))
	end
	
	--[[local str = df.new('string')
	
	gr:getDescription(str)
	
	imgui.Text("Desc: " .. str.value)
	
	df.delete(str)]]--
	
	
end

function neq(a, b)
	return tostring(a) ~= tostring(b)
end

--job.job_items
function dump_job_item(ji)
	imgui.Text("item_type: " .. df.item_type[ji.item_type] .. " (" .. tostring(ji.item_type) .. ")")
	
	if neq(ji.item_subtype, -1) then
		imgui.Text("Subtype: " .. ji.item_subtype)
	end
	
	if neq(ji.mat_type, -1) then
		imgui.Text("Mat_type: " .. ji.mat_type)
	end	
	
	if neq(ji.mat_index, -1) then
		imgui.Text("mat_index: " .. ji.mat_index)
	end
	
	if any_flags(ji.flags1) then
		imgui.Text("flags1")
	end
	
	dump_flags(ji.flags1)
	
	imgui.Text("Quantity: " .. ji.quantity)
	
	if neq(ji.vector_id, -1) then
		imgui.Text("Vector_id: " .. df.job_item_vector_id[ji.vector_id])
	end
	
	if any_flags(ji.flags2) then
		imgui.Text("flags2")
	end
	
	dump_flags(ji.flags2)
	
	if any_flags(ji.flags3) then
		imgui.Text("flags3")
	end
	
	dump_flags(ji.flags3)
	
	if neq(ji.flags4, 0) then
		imgui.Text("flags4 ".. tostring(ji.flags4))
	end
	
	if neq(ji.flags5, 0) then
		imgui.Text("flags5 ".. tostring(ji.flags5))
	end
	
	if neq(ji.metal_ore, -1) then
		imgui.Text("metal_ore ".. tostring(ji.metal_ore))
	end
	
	if #ji.reaction_class > 0 then
		imgui.Text("reaction_class ".. tostring(ji.reaction_class))
	end
	
	if #tostring(ji.has_material_reaction_product) > 0 then
		imgui.Text("has_product ".. tostring(ji.has_material_reaction_product))
	end
	
	if neq(ji.min_dimension, -1) then
		imgui.Text("mindim ".. tostring(ji.min_dimension))
	end
	
	if neq(ji.has_tool_use, -1) then
		imgui.Text("has_tool_use ".. tostring(ji.has_tool_use))
	end
	
	if neq(ji.unk_v43_1, 0) then
		imgui.Text("unk_v43_1 ".. tostring(ji.unk_v43_1))
	end
	
	if neq(ji.unk_v43_2, -1) then
		imgui.Text("unk_v43_2 ".. tostring(ji.unk_v43_2))
	end
	
	if neq(ji.unk_v43_3, -1) then
		imgui.Text("unk_v43_3 ".. tostring(ji.unk_v43_3))
	end
	
	if neq(ji.unk_v43_4, 0) then
		imgui.Text("unk_v43_4 ".. tostring(ji.unk_v43_4))
	end
end

function dump_job(j)
	imgui.BeginTooltip()

	--[[for k, v in pairs(df.job_type.attrs[0]) do
		imgui.Text("Test " .. tostring(k) .. " " .. tostring(v))
	end]]--
	
	if j.job_type == df.job_type.MakeTool then
		local base_types = df.itemdef_toolst.get_vector()
		
		for _,v in pairs(base_types) do
			if v.subtype == j.item_subtype then
				imgui.Text("Match")
				imgui.Text(v.name)
				
				--imgui.Text("Hfid " .. tostring(v.source_hfid))
				--imgui.Text("efid " .. tostring(v.source_enid))
				imgui.Text("id " .. tostring(v.id))
			end
		end
	end
	
	imgui.Text(tostring(df.job_type.attrs[j.job_type].caption))
	
	--imgui.Text("Type: " .. tostring(j.job_type))
	
	--surgery only apparently
	if neq(j.job_subtype, -1) then
		imgui.Text("job_subtype: " .. tostring(j.job_subtype))
	end
	
	if neq(j.item_subtype, -1) then
		imgui.Text("item_subtype: " .. tostring(j.item_subtype))
	end
	
	--imgui.Text("Flags: " .. tostring(j.flags))
	
	if any_flags(j.flags) then
		imgui.Text("Job flags")
	end
	
	dump_flags(j.flags)
	
	--apparently garbage
	--imgui.Text("unk4: " .. tostring(j.unk4))
	
	--not set for eg beds, both -1
	
	if neq(j.mat_type, -1) then
		imgui.Text("mat_type: " .. tostring(j.mat_type))
	end
	
	if neq(j.mat_index, -1) then
		imgui.Text("mat_index: " .. tostring(j.mat_index))
	end
	
	--always -1
	--imgui.Text("unk5: " .. tostring(j.unk5))
	
	if any_flags(j.material_category) then
		imgui.Text("material_category")
	end
	
	dump_flags(j.material_category)
		
	--imgui.Text("material cat: " .. tostring(j.material_category))
	
	--blank
	--imgui.Text("reaction name: " .. tostring(j.reaction_name))
	
	-- -1
	--imgui.Text("unk11: " .. tostring(j.unk11))
	
	if #j.items > 0 then
		imgui.Text("#items: " .. tostring(#j.items))
	end
	
	if #j.specific_refs > 0 then
		imgui.Text("#specific_refs: " .. tostring(#j.specific_refs))
	end
	
	imgui.Text("#general_refs: " .. tostring(#j.general_refs))
	
	for k,v in pairs(j.general_refs) do
		dump_general_ref(v)
	end
	
	imgui.Text("#job_items: " .. tostring(#j.job_items))
	
	for k,v in pairs(j.job_items) do
		dump_job_item(v)
	end
	
	imgui.EndTooltip()
end

function inspect_workshop(workshop)
	local jobs = workshop.jobs
	
	--imgui.BeginTooltip()
	--imgui.Text("Real Building Id " .. tostring(workshop.id))
	--imgui.EndTooltip()
	
	for _,v in ipairs(jobs) do
		dump_job(v)
	end
end