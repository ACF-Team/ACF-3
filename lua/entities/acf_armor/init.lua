AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

local ACF = ACF
local Contraption	= ACF.Contraption

do -- Spawning and Updating
	local Classes  = ACF.Classes
	local Armors   = Classes.ArmorTypes
	local Entities = Classes.Entities

	local function VerifyData(Data)
		if not isstring(Data.ArmorType) then
			Data.ArmorType = "RHA"
		end

		local Armor = Armors.Get(Data.ArmorType)

		if not Armor then
			Data.ArmorType = RHA

			Armor = Armors.Get("RHA")
		end

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

			Data.Width  = math.Clamp(Data.Width, 0.25, 420)
			Data.Height = math.Clamp(Data.Height, 0.25, 420)

			local MaxPossible = 50000 / (Data.Width * Data.Height * Armor.Density * ACF.gCmToKgIn) * ACF.InchToMm
			local MaxAllowed  = math.min(ACF.MaximumArmor, ACF.GetServerNumber("MaxThickness"))

			Data.Thickness = math.min(Data.Thickness, MaxPossible)
			Data.Size      = Vector(Data.Width, Data.Height, math.Clamp(Data.Thickness, ACF.MinimumArmor, MaxAllowed) * ACF.MmToInch)
		end

		do -- External verifications
			if Armor.VerifyData then
				Armor:VerifyData(Data)
			end

			hook.Run("ACF_VerifyData", "acf_armor", Data, Armor)
		end
	end

	local function UpdatePlate(Entity, Data, Armor)
		Entity.ACF = Entity.ACF or {}

		local Size = Data.Size

		Entity.ArmorClass = Armor
		Entity.Tensile    = Armor.Tensile
		Entity.Density    = Armor.Density

		Entity:SetNW2String("ArmorType", Armor.ID)
		Entity:SetSize(Size)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		ACF.Activate(Entity, true)

		Entity:UpdateMass(true)
	end

	function MakeACF_Armor(Player, Pos, Angle, Data)
		if not Player:CheckLimit("_acf_armor") then return end

		local Plate = ents.Create("acf_armor")

		if not IsValid(Plate) then return end

		VerifyData(Data)

		local Armor = Armors.Get(Data.ArmorType)

		local CanSpawn = hook.Run("ACF_PreEntitySpawn", "acf_armor", Player, Data, Armor)
		if CanSpawn == false then return false end

		Player:AddCount("_acf_armor", Plate)
		Player:AddCleanup("_acf_armor", Plate)

		Plate:SetScaledModel("models/holograms/cube.mdl")
		Plate:SetMaterial("sprops/textures/sprops_metal1")
		Plate:SetPlayer(Player)
		Plate:SetAngles(Angle)
		Plate:SetPos(Pos)
		Plate:Spawn()

		Plate.Owner     = Player -- MUST be stored on ent for PP
		Plate.DataStore = Entities.GetArguments("acf_armor")

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

	Entities.Register("acf_armor", MakeACF_Armor, "Width", "Height", "Thickness", "ArmorType")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		VerifyData(Data)

		local Armor    = Armors.Get(Data.ArmorType)
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
end

do -- ACF Activation and Damage
	local Trace = { Entity = true, StartPos = true, HitPos = true }

	function ENT:ACF_Activate(Recalc)
		local PhysObj = self.ACF.PhysObj
		local Area = PhysObj:GetSurfaceArea() * 6.45
		local Health  = Area / ACF.Threshold * self.Tensile
		local Percent = 1

		if Recalc and self.ACF.Health and self.ACF.MaxHealth then
			Percent = self.ACF.Health / self.ACF.MaxHealth
		end

		self.ACF.Area      = Area
		self.ACF.Armour    = 1
		self.ACF.MaxArmour = 1
		self.ACF.Health    = Health * Percent
		self.ACF.MaxHealth = Health
		self.ACF.Ductility = 0
		self.ACF.Type      = "Prop"
	end

	function ENT:ACF_OnDamage(DmgResult, DmgInfo)
		Trace.Entity   = self
		Trace.StartPos = DmgInfo:GetOrigin()
		Trace.HitPos   = DmgInfo:GetHitPos()

		local Armor  = self:GetArmor(Trace)
		local Area   = DmgResult:GetArea()
		local Pen    = DmgResult:GetPenetration()
		local MaxPen = math.min(Armor, Pen)
		local Forced = DmgResult.Damage
		local Damage = isnumber(Forced) and Forced or MaxPen * Area -- Damage is simply the volume of the hole made
		local HP     = self.ACF.Health

		self.ACF.Health = HP - Damage -- Update health

		--[[
		print("Damage!")
		print("    PenCaliber: " .. math.Round(Bullet.Diameter * 10))
		print("    MaxPen: " .. MaxPen)
		print("    MaxDamage: " .. Pen * Area)
		print("    HP: " .. math.Round(HP, 3))
		print("    Effective Armor: " .. math.Round(Armor))
		print("    Damage: " .. math.Round(Damage, 3))
		print("    pdHP: " .. math.Round(self.ACF.Health, 3))
		print("    Loss: " .. math.Clamp(MaxPen / Pen, 0, 1))
		]]--

		return { -- Damage report
			Loss     = math.Clamp(MaxPen / Pen, 0, 1), -- Energy loss ratio
			Damage   = Damage,
			Overkill = math.max(Pen - MaxPen, 0),
			Kill     = Damage > HP
		}
	end
end

do -- Mass Update
	local TimerCreate = timer.Create
	local TimerExists = timer.Exists

	local function UpdateMass(Entity)
		local Size = Entity.Size
		local Mass = Entity.ArmorClass:GetMass(Size.x * Size.y * Size.z)

		Contraption.SetMass(Entity, Mass)
	end

	function ENT:UpdateMass(Instant)
		if Instant then
			return UpdateMass(self)
		end

		if TimerExists("ACF Mass Buffer" .. self:EntIndex()) then return end

		TimerCreate("ACF Mass Buffer" .. self:EntIndex(), 1, 1, function()
			if not IsValid(self) then return end

			UpdateMass(self)
		end)
	end
end

function ENT:OnRemove()
	local Armor = self.ArmorClass

	if Armor.OnLast then
		Armor.OnLast(self, Armor)
	end

	WireLib.Remove(self)
end