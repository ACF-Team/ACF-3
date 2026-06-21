hook.Add("cfw.contraption.init", "ACF_CFWAmmoContraptionCreated", function(contraption)
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

-- Transfer ammo data when contraptions merge
hook.Add("cfw.contraption.merged", "ACF_CFWAmmoMerge", function(absorbed, into)
	if not absorbed.Ammos then return end

	for ent in pairs(absorbed.Ammos) do
		into.Ammos[ent] = true

		local Stage = ent.AmmoStage
		into.AmmosByStage[Stage] = into.AmmosByStage[Stage] or {}
		into.AmmosByStage[Stage][ent] = true
	end
end)

-- Rebuild ammo indexes when contraptions split
hook.Add("cfw.contraption.split", "ACF_CFWAmmoSplit", function(parent, child)
	child.Ammos = {}
	child.AmmosByStage = {}

	for ent in pairs(child.ents) do
		if ent:GetClass() == "acf_ammo" then
			child.Ammos[ent] = true

			local Stage = ent.AmmoStage
			child.AmmosByStage[Stage] = child.AmmosByStage[Stage] or {}
			child.AmmosByStage[Stage][ent] = true
		end
	end

	-- Rebuild parent's ammo indexes
	parent.Ammos = {}
	parent.AmmosByStage = {}

	for ent in pairs(parent.ents) do
		if ent:GetClass() == "acf_ammo" then
			parent.Ammos[ent] = true

			local Stage = ent.AmmoStage
			parent.AmmosByStage[Stage] = parent.AmmosByStage[Stage] or {}
			parent.AmmosByStage[Stage][ent] = true
		end
	end
end)

