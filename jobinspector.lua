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

--job.job_items
function dump_job_item(ji)
	imgui.Text("Type: " .. df.item_type[ji.item_type])
	imgui.Text("Subtype: " .. ji.item_subtype)
	imgui.Text("Mat_type: " .. ji.mat_type)
	imgui.Text("mat_index: " .. ji.mat_index)
	
	imgui.Text("flags1")
	
	dump_flags(ji.flags1)
	
	imgui.Text("Quantity: " .. ji.quantity)
	imgui.Text("Vector_id: " .. df.job_item_vector_id[ji.vector_id])
	
	imgui.Text("flags2")
	
	dump_flags(ji.flags2)
	
	imgui.Text("flags3")
	
	dump_flags(ji.flags3)
	
	imgui.Text("flags4 ".. tostring(ji.flags4))
	imgui.Text("flags5 ".. tostring(ji.flags5))
	
	imgui.Text("metal_ore ".. tostring(ji.metal_ore))
	
	imgui.Text("reaction_class ".. tostring(ji.reaction_class))
	imgui.Text("has_product ".. tostring(ji.has_material_reaction_product))
	
	imgui.Text("mindim ".. tostring(ji.min_dimension))
	
	imgui.Text("has_tool_use ".. tostring(ji.min_dimension))
	
	imgui.Text("unk_v43_1 ".. tostring(ji.unk_v43_1))
	imgui.Text("unk_v43_2 ".. tostring(ji.unk_v43_2))
	imgui.Text("unk_v43_3 ".. tostring(ji.unk_v43_3))
	imgui.Text("unk_v43_4 ".. tostring(ji.unk_v43_4))
end

function dump_job(j)
	imgui.BeginTooltip()

	--[[for k, v in pairs(df.job_type.attrs[0]) do
		imgui.Text("Test " .. tostring(k) .. " " .. tostring(v))
	end]]--
	
	imgui.Text(df.job_type.attrs[j.job_type].caption)

	--imgui.Text("Type: " .. tostring(j.job_type))
	
	--surgery only apparently
	if j.job_subtype ~= -1 then
		imgui.Text("Subtype: " .. tostring(j.job_subtype))
	end
	
	--imgui.Text("Flags: " .. tostring(j.flags))
	
	imgui.Text("Job flags")
	
	dump_flags(j.flags)
	
	--apparently garbage
	--imgui.Text("unk4: " .. tostring(j.unk4))
	
	--not set for eg beds, both -1
	--imgui.Text("mat_type: " .. tostring(j.mat_type))
	--imgui.Text("mat_index: " .. tostring(j.mat_index))
	
	--always -1
	--imgui.Text("unk5: " .. tostring(j.unk5))
	
	imgui.Text("Material Cat")
	
	dump_flags(j.material_category)
	
	--imgui.Text("material cat: " .. tostring(j.material_category))
	
	--blank
	--imgui.Text("reaction name: " .. tostring(j.reaction_name))
	
	-- -1
	--imgui.Text("unk11: " .. tostring(j.unk11))
	
	imgui.Text("#items: " .. tostring(#j.items))
	imgui.Text("#specific_refs: " .. tostring(#j.specific_refs))
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