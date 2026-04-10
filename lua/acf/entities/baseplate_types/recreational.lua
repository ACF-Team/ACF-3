ACF.Class("ACF.Baseplates.RecreationalBaseplate", "ACF.Baseplates.BaseplateType", function()
	CLASS.Name		    = "Recreational"
	CLASS.Icon          = "icon16/car_add.png"
	CLASS.Description   = "A baseplate designed for non combat use (e.g. cars).\nWeapons and ammo will be removed. Fuel consumption rate set to 1."

	function CLASS:EnforceLooped(Baseplate)
		local Contraption = Baseplate:GetContraption()
		if not Contraption then return end

		local Owner = Baseplate:CPPIGetOwner()

		-- Kill ammo
		for v, _ in pairs(Contraption.Ammo or EmptyTable) do
			if IsValid(Owner) then Notify.WarningToPlayer(Owner, "Baseplate removed", "A recreational baseplate was used for combat.") end
			if IsValid(v) then
				Contraption.Ammo[v] = nil
				v:Remove()
			end
		end

		-- Kill weapons
		for v, _ in pairs(Contraption.Guns or EmptyTable) do
			if IsValid(Owner) then Notify.WarningToPlayer(Owner, "Baseplate removed", "A recreational baseplate was used for combat.") end
			if IsValid(v) then
				Contraption.Guns[v] = nil
				v:Remove()
			end
		end

		for v, _ in pairs(Contraption.Piledrivers or EmptyTable) do
			if IsValid(Owner) then Notify.WarningToPlayer(Owner, "Baseplate removed", "A recreational baseplate was used for combat.") end
			if IsValid(v) then
				Contraption.Piledrivers[v] = nil
				v:Remove()
			end
		end

		for v, _ in pairs(Contraption.Racks or EmptyTable) do
			if IsValid(Owner) then Notify.WarningToPlayer(Owner, "Baseplate removed", "A recreational baseplate was used for combat.") end
			if IsValid(v) then
				Contraption.Racks[v] = nil
				v:Remove()
			end
		end
	end

	function CLASS:PhysicsCollide(Entity, Data)
		if not Entity:ACF_GetUserVar("ExplodeOnCollisions") then return end

		self:PhysicsCollideExplosion(Entity, Data)
	end
end)