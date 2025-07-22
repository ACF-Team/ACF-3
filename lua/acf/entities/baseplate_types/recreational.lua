local Types     = ACF.Classes.BaseplateTypes
local Baseplate = Types.Register("Recreational")
local EmptyTable = {}

function Baseplate:OnLoaded()
	self.Name		 = "Recreational"
	self.Icon        = "icon16/car_add.png"
	self.Description = "A baseplate designed for non combat use (e.g. cars).\nWeapons and ammo will be disabled. Fuel consumption rate set to 1."
	self.EnforceLooped = function(Baseplate)
		local Contraption = Baseplate:GetContraption()
		if not Contraption then return end

		-- Disable ammo
		for v, _ in pairs(Contraption.Ammo or EmptyTable) do
			if not v.Disabled then ACF.DisableEntity(v, "Recreational Used For Combat", "Recreational Baseplate Used For Combat", 100) end
		end

		-- Recreational baseplates should not refuel others
		for v, _ in pairs(Contraption.Fuels or EmptyTable) do
			v.SupplyFuel = false
		end

		-- Disable weapons
		for v, _ in pairs(Contraption.Guns or EmptyTable) do
			if not v.Disabled then ACF.DisableEntity(v, "Recreational Used For Combat", "Recreational Baseplate Used For Combat", 100) end
		end

		for v, _ in pairs(Contraption.Piledrivers or EmptyTable) do
			if not v.Disabled then ACF.DisableEntity(v, "Recreational Used For Combat", "Recreational Baseplate Used For Combat", 100) end
		end

		for v, _ in pairs(Contraption.Racks or EmptyTable) do
			if not v.Disabled then ACF.DisableEntity(v, "Recreational Used For Combat", "Recreational Baseplate Used For Combat", 100) end
		end
	end
end