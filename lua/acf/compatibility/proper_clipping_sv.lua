local duplicator = duplicator
local hook       = hook
local ACF        = ACF

do -- Triggers an ACF.Activate update whenever a new physical clip is created or removed
	local timer = timer

	local function Update(Entity)
		if Entity._ACF_Physclip_Update then return end

		local EntMods = Entity.EntityMods

		Entity._ACF_Physclip_Update = true
		Entity._ACF_HasMassEntmod   = EntMods and EntMods.mass

		timer.Simple(0, function()
			if not IsValid(Entity) then return end

			Entity._ACF_Physclip_Update = nil

			if not Entity._ACF_HasMassEntmod then
				duplicator.ClearEntityModifier(Entity, "mass")
			else
				Entity._ACF_HasMassEntmod = nil
			end

			ACF.Activate(Entity, true)
		end)
	end

	hook.Add("ProperClippingPhysicsClipped", "ACF", Update)
	hook.Add("ProperClippingPhysicsReset", "ACF", Update)
end

do -- Forces an ACF armored entity to get rid of their mass entity modifier and use the ACF_Armor one instead
	local function UpdateMass(Entity)
		local EntMods = Entity.EntityMods

		if not EntMods then return end

		local Armor = EntMods.ACF_Armor

		if Armor and Armor.Thickness then
			local MassMod = EntMods and EntMods.mass

			if MassMod then
				duplicator.ClearEntityModifier(Entity, "ACF_Armor")
				duplicator.StoreEntityModifier(Entity, "ACF_Armor", { Ductility = Armor.Ductility })
			else
				duplicator.ClearEntityModifier(Entity, "mass")
			end
		end
	end

	hook.Add("ProperClippingClipAdded", "ACF", UpdateMass)
	hook.Add("ProperClippingClipRemoved", "ACF", UpdateMass)
	hook.Add("ProperClippingClipsRemoved", "ACF", UpdateMass)
end