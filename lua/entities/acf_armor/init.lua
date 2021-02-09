AddCSLuaFile("shared.lua")

include("shared.lua")

do -- Spawning and Updating
	local function VerifyData(Data)
		if not isnumber(Data.Width) then
			Data.Width = ACF.CheckNumber(Data.PlateSizeX, 24)
		end

		if not isnumber(Data.Height) then
			Data.Height = ACF.CheckNumber(Data.PlateSizeY, 24)
		end

		if not isnumber(Data.Thickness) then
			Data.Thickness = ACF.CheckNumber(Data.PlateSizeZ, 5)
		end

		do -- Clamping values
			Data.Width = math.Clamp(Data.Width, 0.25, 420)
			Data.Height = math.Clamp(Data.Height, 0.25, 420)
			Data.Thickness = math.Clamp(Data.Thickness, 5, 1000)
		end

		Data.Size = Vector(Data.Width, Data.Height, Data.Thickness * 0.03937)

		hook.Run("ACF_VerifyData", "acf_armor", Data)
	end

	local function UpdatePlate(Entity, Data)
		Entity.IsACFEntity = false -- Hack to make sure nothing goes wrong

		Entity:SetSize(Data.Size)

		Entity.IsACFEntity = true

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end
	end

	function MakeACF_Armor(Player, Pos, Angle, Data)
		if not Player:CheckLimit("props") then return end

		local Plate = ents.Create("acf_armor")

		if not IsValid(Plate) then return end

		VerifyData(Data)

		Player:AddCount("props", Plate)
		Player:AddCleanup("props", Plate)

		Plate:SetModel("models/holograms/cube.mdl")
		Plate:SetMaterial("sprops/textures/sprops_metal1")
		Plate:SetPlayer(Player)
		Plate:SetAngles(Angle)
		Plate:SetPos(Pos)
		Plate:Spawn()

		Plate.Owner     = Player -- MUST be stored on ent for PP
		Plate.DataStore = ACF.GetEntityArguments("acf_armor")

		UpdatePlate(Plate, Data)

		hook.Run("ACF_OnEntitySpawn", "acf_armor", Plate, Data)

		do -- Mass entity mod removal
			local EntMods = Data.EntityMods

			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		return Plate
	end

	ACF.RegisterEntityClass("acf_armor", MakeACF_Armor, "Width", "Height", "Thickness")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		VerifyData(Data)

		ACF.SaveEntity(self)

		UpdatePlate(self, Data)

		ACF.RestoreEntity(self)

		hook.Run("ACF_OnEntityUpdate", "acf_armor", self, Data)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Armor plate updated successfully!"
	end

	function ENT:OnResized(Size)
		local Volume = Size.x * Size.y * Size.z
		local Mass   = Volume * 0.13 -- Kg of steel per inch

		self:GetPhysicsObject():SetMass(Mass)
	end
end

do -- ACF Activation and Damage
	function ENT:ACF_Activate(Recalc) -- TODO: Remove this
		local PhysObj = self.ACF.PhysObj
		local Volume  = PhysObj:GetVolume()

		if not self.ACF.Area then
			self.ACF.Area = PhysObj:GetVolume() * 6.45 -- NOTE: Shouldn't this just be Area = PhysObj:GetSurfaceArea()??
		end

		local Health  = Volume
		local Percent = 1

		if Recalc and self.ACF.Health and self.ACF.MaxHealth then
			Percent = self.ACF.Health / self.ACF.MaxHealth
		end

		self.ACF.Armour    = 1
		self.ACF.MaxArmour = 1
		self.ACF.Health    = Health * Percent
		self.ACF.MaxHealth = Health
		self.ACF.Ductility = 0
		self.ACF.Type      = "Prop"
	end

	function ENT:ACF_OnDamage(Bullet, Trace)
		local Entity = Trace.Entity
		local Armor  = Entity:GetArmor(Trace)
		local Energy = Bullet.Energy
		local FrArea = Bullet.PenArea
		local Pen    = (Energy.Penetration / FrArea) * ACF.KEtoRHA -- RHA Penetration

		local MaxPen = math.min(Armor, Pen)

		local Damage = MaxPen * FrArea -- Damage is simply the volume of the hole made
		local HP     = self.ACF.Health

		self.ACF.Health = HP - Damage -- Update health

		print("Damage!")
		print("    PenCaliber: " .. math.Round(math.sqrt(FrArea / 3.14159) * 20))
		print("    MaxPen: " .. MaxPen)
		print("    MaxDamage: " .. Pen * FrArea)
		print("    HP: " .. math.Round(HP, 3))
		print("    Effective Armor: " .. math.Round(Armor))
		print("    Damage: " .. math.Round(Damage, 3))
		print("    pdHP: " .. math.Round(self.ACF.Health, 3))
		print("    Loss: " .. math.Clamp(MaxPen / Pen, 0, 1))

		return { -- Damage report
			Loss = math.Clamp(MaxPen / Pen, 0, 1), -- Energy loss ratio
			Damage = Damage,
			Overkill = math.max(Pen - MaxPen, 0),
			Kill = Damage > HP
		}
	end
end
