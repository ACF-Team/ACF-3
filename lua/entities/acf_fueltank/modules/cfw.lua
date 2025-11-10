hook.Add("cfw.contraption.created", "ACF_CFWFuelContraptionCreated", function(contraption)
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