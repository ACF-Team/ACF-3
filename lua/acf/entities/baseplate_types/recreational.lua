local Notify     = ACF.Utilities.Notify
local EmptyTable = {}

ACF.Classes.DefineClass("ACF.Baseplates.Recreational", "ACF.Baseplates.BaseplateType", function()
	CLASS.Name        = "Recreational"
	CLASS.Icon        = "icon16/car_add.png"
	CLASS.Description = "A baseplate designed for non combat use (e.g. cars).\nWeapons and ammo will be removed. Fuel consumption rate set to 1."

	MENU_FIELD("Boolean", "ExplodeOnCollisions", {Default = false})

	function CLASS.CreateMenu(SubMenu, NestedData, PushData)
		local Opts = ACF.Classes.GetTypeFieldByName(CLASS, "ExplodeOnCollisions").Options
		local Box  = SubMenu:AddCheckBox("Explode on Collisions")
		local Init = NestedData.ExplodeOnCollisions
		if Init == nil then Init = Opts.Default or false end
		Box:SetValue(Init)
		function Box:OnChange(Value)
			NestedData.ExplodeOnCollisions = Value
			PushData()
		end
	end

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

	function CLASS:PhysicsCollide(Entity, Data)
		if not self.ExplodeOnCollisions then return end
		BASE.BP_PhysicsCollideExplosion(Entity, Data)
	end
end)