hook.Add("cfw.contraption.created", "ACF_CFWAmmoContraptionCreated", function(contraption)
	contraption.Ammos = {}
	contraption.AmmosByStage = {}
end)

hook.Add("cfw.contraption.removed", "ACF_CFWAmmoContraptionRemoved", function(contraption)
	contraption.Ammos = nil
	contraption.AmmosByStage = nil
end)

hook.Add("cfw.contraption.entityAdded", "ACF_CFWAmmoIndex", function(contraption, ent)
	if ent:GetClass() ~= "acf_ammo" then return end

	contraption.Ammos[ent] = true

	local Stage = ent.AmmoStage
	contraption.AmmosByStage[Stage] = contraption.AmmosByStage[Stage] or {}
	contraption.AmmosByStage[Stage][ent] = true
end)

hook.Add("cfw.contraption.entityRemoved", "ACF_CFWAmmoUnIndex", function(contraption, ent)
	if ent:GetClass() ~= "acf_ammo" then return end
	if not contraption.Ammos then return end
	contraption.Ammos[ent] = nil

	local Stage = ent.AmmoStage
	if contraption.AmmosByStage[Stage] then
		contraption.AmmosByStage[Stage][ent] = nil
	end
end)

