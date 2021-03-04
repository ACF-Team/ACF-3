AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

do -- Spawning and Updating
	local Armors = ACF.Classes.ArmorTypes

	local function VerifyData(Data)
		do -- Verifying dimension values
			if not isnumber(Data.Width) then
				Data.Width = ACF.CheckNumber(Data.PlateSizeX, 24)
			end

			if not isnumber(Data.Height) then
				Data.Height = ACF.CheckNumber(Data.PlateSizeY, 24)
			end

			if not isnumber(Data.Thickness) then
				Data.Thickness = ACF.CheckNumber(Data.PlateSizeZ, 5)
			end

			Data.Width     = math.Clamp(Data.Width, 0.25, 420)
			Data.Height    = math.Clamp(Data.Height, 0.25, 420)
			Data.Thickness = math.Clamp(Data.Thickness, 5, 1000)
			Data.Size      = Vector(Data.Width, Data.Height, Data.Thickness * 0.03937)
		end

		if not isstring(Data.ArmorType) then
			Data.ArmorType = "RHA"
		end

		local Armor = Armors[Data.ArmorType]

		if not Armor then
			Data.ArmorType = RHA

			Armor = Armors.RHA
		end

		do -- External verifications
			if Armor.VerifyData then
				Armor:VerifyData(Data)
			end

			hook.Run("ACF_VerifyData", "acf_armor", Data, Armor)
		end
	end

	local function UpdatePlate(Entity, Data, Armor)
		Entity.ArmorClass = Armor
		Entity.Tensile    = Armor.Tensile
		Entity.Density    = Armor.Density

		Entity:SetNW2String("ArmorType", Armor.ID)
		Entity:SetSize(Data.Size)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end
	end

	function MakeACF_Armor(Player, Pos, Angle, Data)
		if not Player:CheckLimit("_acf_armor") then return end

		local Plate = ents.Create("acf_armor")

		if not IsValid(Plate) then return end

		VerifyData(Data)

		local Armor = Armors[Data.ArmorType]

		Player:AddCount("_acf_armor", Plate)
		Player:AddCleanup("_acf_armor", Plate)

		Plate:SetModel("models/holograms/cube.mdl")
		Plate:SetMaterial("sprops/textures/sprops_metal1")
		Plate:SetPlayer(Player)
		Plate:SetAngles(Angle)
		Plate:SetPos(Pos)
		Plate:Spawn()

		Plate.Owner     = Player -- MUST be stored on ent for PP
		Plate.DataStore = ACF.GetEntityArguments("acf_armor")

		UpdatePlate(Plate, Data, Armor)

		if Armor.OnSpawn then
			Armor:OnSpawn(Plate, Data)
		end

		hook.Run("ACF_OnEntitySpawn", "acf_armor", Plate, Data, Armor)

		do -- Mass entity mod removal
			local EntMods = Data.EntityMods

			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		return Plate
	end

	ACF.RegisterEntityClass("acf_armor", MakeACF_Armor, "Width", "Height", "Thickness", "ArmorType")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		VerifyData(Data)

		local Armor    = Armors[Data.ArmorType]
		local OldArmor = self.ArmorClass

		if OldArmor.OnLast then
			OldArmor:OnLast(self)
		end

		hook.Run("ACF_OnEntityLast", "acf_armor", self, OldClass)

		ACF.SaveEntity(self)

		UpdatePlate(self, Data, Armor)

		ACF.RestoreEntity(self)

		if Armor.OnUpdate then
			Armor:OnUpdate(Plate, Data)
		end

		hook.Run("ACF_OnEntityUpdate", "acf_armor", self, Data, Armor)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Armor plate updated successfully!"
	end

	function ENT:OnResized(Size)
		local Volume = Size.x * Size.y * Size.z
		local Mass   = self.ArmorClass:GetMass(Volume)

		self:GetPhysicsObject():SetMass(Mass)
	end
end

do -- ACF Activation and Damage
	function ENT:ACF_Activate(Recalc) -- TODO: Remove this
		local PhysObj = self.ACF.PhysObj
		local Volume  = PhysObj:GetVolume()

		if not self.ACF.Area then
			self.ACF.Area = PhysObj:GetVolume() * 6.45
		end

		local Health  = Volume / ACF.Threshold * self.Tensile
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

function ENT:OnRemove()
	local Armor = self.ArmorClass

	if Armor.OnLast then
		Armor.OnLast(self, Armor)
	end

	WireLib.Remove(self)
end
