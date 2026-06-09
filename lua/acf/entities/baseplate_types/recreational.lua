local Notify     = ACF.Utilities.Notify
local EmptyTable = {}

ACF.Classes.DefineClass("ACF.Baseplates.Recreational", "ACF.Baseplates.BaseplateType", function()
	CLASS.Name        = "Recreational"
	CLASS.Icon        = "icon16/car_add.png"
	CLASS.Description = "A baseplate designed for non combat use (e.g. cars).\nWeapons and ammo will be removed. Fuel consumption rate set to 1."

	function CLASS.EnforceLooped(Baseplate)
		local Contraption = Baseplate:CFW_GetContraption()
		if not Contraption then return end

		local Owner = Baseplate:CPPIGetOwner()

		for v in pairs(Contraption.Ammo or EmptyTable) do
			if IsValid(Owner) then Notify.WarningToPlayer(Owner, "Baseplate removed", "A recreational baseplate was used for combat.") end
			if IsValid(v) then
				Contraption.Ammo[v] = nil
				v:Remove()
			end
		end

		for v in pairs(Contraption.Guns or EmptyTable) do
			if IsValid(Owner) then Notify.WarningToPlayer(Owner, "Baseplate removed", "A recreational baseplate was used for combat.") end
			if IsValid(v) then
				Contraption.Guns[v] = nil
				v:Remove()
			end
		end

		for v in pairs(Contraption.Piledrivers or EmptyTable) do
			if IsValid(Owner) then Notify.WarningToPlayer(Owner, "Baseplate removed", "A recreational baseplate was used for combat.") end
			if IsValid(v) then
				Contraption.Piledrivers[v] = nil
				v:Remove()
			end
		end

		for v in pairs(Contraption.Racks or EmptyTable) do
			if IsValid(Owner) then Notify.WarningToPlayer(Owner, "Baseplate removed", "A recreational baseplate was used for combat.") end
			if IsValid(v) then
				Contraption.Racks[v] = nil
				v:Remove()
			end
		end
	end

	function CLASS:PhysicsCollide(Data)
		if not self:ACF_GetUserVar("ExplodeOnCollisions") then return end
		BASE.BP_PhysicsCollideExplosion(self, Data)
	end
end)