hook.Add("cfw.contraption.init", "ACF_CFWFuelContraptionCreated", function(contraption)
	contraption.Fuels = {}
end)

hook.Add("cfw.contraption.removed", "ACF_CFWFuelContraptionRemoved", function(contraption)
	contraption.Fuels = nil
end)

hook.Add("cfw.contraption.entityAdded", "ACF_CFWFuelIndex", function(contraption, ent)
	if ent:GetClass() ~= "acf_fueltank" then return end

	contraption.Fuels[ent] = true
end)

hook.Add("cfw.contraption.entityRemoved", "ACF_CFWFuelUnIndex", function(contraption, ent)
	if ent:GetClass() ~= "acf_fueltank" then return end
	if not contraption.Fuels then return end
	contraption.Fuels[ent] = nil
end)

-- Transfer fuel data when contraptions merge
hook.Add("cfw.contraption.merged", "ACF_CFWFuelMerge", function(absorbed, into)
	if not absorbed.Fuels then return end

	for ent in pairs(absorbed.Fuels) do
		into.Fuels[ent] = true
	end
end)

-- Rebuild fuel indexes when contraptions split
hook.Add("cfw.contraption.split", "ACF_CFWFuelSplit", function(parent, child)
	child.Fuels = {}

	for ent in pairs(child.ents) do
		if ent:GetClass() == "acf_fueltank" then
			child.Fuels[ent] = true
		end
	end

	parent.Fuels = {}

	for ent in pairs(parent.ents) do
		if ent:GetClass() == "acf_fueltank" then
			parent.Fuels[ent] = true
		end
	end
end)