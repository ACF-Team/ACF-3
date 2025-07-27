local Types     = ACF.Classes.BaseplateTypes
local Baseplate = Types.Register("Recreational")
local EmptyTable = {}

function Baseplate:OnLoaded()
	self.Name		 = "Recreational"
	self.Icon        = "icon16/car_add.png"
	self.Description = "A baseplate designed for non combat use (e.g. cars).\nWeapons and ammo will be removed. Fuel consumption rate set to 1."
	self.EnforceLooped = function(Baseplate)
		local Contraption = Baseplate:GetContraption()
		if not Contraption then return end

		local Owner = Baseplate:CPPIGetOwner()

		-- Kill ammo
		for v, _ in pairs(Contraption.Ammo or EmptyTable) do
			if IsValid(Owner) then ACF.SendNotify(Owner, false, "Recreational Baseplate Used For Combat") end
			if IsValid(v) then
				Contraption.Ammo[v] = nil
				v:Remove()
			end
		end

		-- Kill weapons
		for v, _ in pairs(Contraption.Guns or EmptyTable) do
			if IsValid(Owner) then ACF.SendNotify(Owner, false, "Recreational Baseplate Used For Combat") end
			if IsValid(v) then
				Contraption.Guns[v] = nil
				v:Remove()
			end
		end

		for v, _ in pairs(Contraption.Piledrivers or EmptyTable) do
			if IsValid(Owner) then ACF.SendNotify(Owner, false, "Recreational Baseplate Used For Combat") end
			if IsValid(v) then
				Contraption.Piledrivers[v] = nil
				v:Remove()
			end
		end

		for v, _ in pairs(Contraption.Racks or EmptyTable) do
			if IsValid(Owner) then ACF.SendNotify(Owner, false, "Recreational Baseplate Used For Combat") end
			if IsValid(v) then
				Contraption.Racks[v] = nil
				v:Remove()
			end
		end
	end
end