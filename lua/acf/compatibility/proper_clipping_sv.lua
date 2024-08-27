local hook = hook
local ACF  = ACF

do -- Triggers an ACF.Activate update whenever a new physical clip is created or removed
	local timer = timer

	local function Update(Entity)
		if Entity._ACF_Physclip_Update then return end

		Entity._ACF_Physclip_Update = true

		timer.Simple(0, function()
			if not IsValid(Entity) then return end

			Entity._ACF_Physclip_Update = nil

			ACF.Activate(Entity, true)
		end)
	end

	hook.Add("ProperClippingPhysicsClipped", "ACF", Update)
	hook.Add("ProperClippingPhysicsReset", "ACF", Update)
end

do -- Forces an ACF armored entity to get rid of their mass entity modifier and use the ACF_Armor one instead
	local duplicator = duplicator

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