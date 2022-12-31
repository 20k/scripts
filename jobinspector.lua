--@ module = true

imgui = dfhack.imgui

function dump_flags(f)
	local test = f

	for k,v in pairs(f) do
		if v then
			imgui.Text("Flag: " .. tostring(k))
		end
	end
end

function dump_job(j)
	imgui.BeginTooltip()

	--[[for k, v in pairs(df.job_type.attrs[0]) do
		imgui.Text("Test " .. tostring(k) .. " " .. tostring(v))
	end]]--
	
	imgui.Text(df.job_type.attrs[j.job_type].caption)

	--imgui.Text("Type: " .. tostring(j.job_type))
	
	--surgery only apparently
	if j.job_subtype ~= -1
		imgui.Text("Subtype: " .. tostring(j.job_subtype))
	end
	
	--imgui.Text("Flags: " .. tostring(j.flags))
	
	dump_flags(j.flags)
	
	--apparently garbage
	--imgui.Text("unk4: " .. tostring(j.unk4))
	
	--not set for eg beds, both -1
	--imgui.Text("mat_type: " .. tostring(j.mat_type))
	--imgui.Text("mat_index: " .. tostring(j.mat_index))
	
	--always -1
	--imgui.Text("unk5: " .. tostring(j.unk5))
	
	dump_flags(j.material_category)
	
	--imgui.Text("material cat: " .. tostring(j.material_category))
	
	--blank
	--imgui.Text("reaction name: " .. tostring(j.reaction_name))
	
	-- -1
	--imgui.Text("unk11: " .. tostring(j.unk11))
	
	imgui.Text("#items: " .. tostring(#j.items))
	imgui.Text("#specific_refs: " .. tostring(#j.specific_refs))
	imgui.Text("#general_refs: " .. tostring(#j.general_refs))
	imgui.Text("#job_items: " .. tostring(#j.job_items))
	
	imgui.EndTooltip()
end

function inspect_workshop(workshop)
	local jobs = workshop.jobs
	
	for _,v in ipairs(jobs) do
		dump_job(v)
	end
end