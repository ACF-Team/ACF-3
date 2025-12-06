local ACF          = ACF
local Classes      = ACF.Classes
local Utilities    = ACF.Utilities
local WireIO       = Utilities.WireIO
local WireLib      = WireLib
local Entities     = Classes.Entities
local AmmoTypes    = Classes.AmmoTypes
local Weapons      = Classes.Weapons
local ActiveCrates = ACF.AmmoCrates
local HookRun      = hook.Run
local Clamp        = math.Clamp
local Floor        = math.floor


local Inputs = {
	"Load (If set to a non-zero value, it'll allow weapons to use rounds from this ammo crate.)",
}

local Outputs = {
	"Loading (Whether or not weapons can use rounds from this crate.)",
	"Ammo (Rounds left in this ammo crate.)",
	"Entity (The ammo crate itself.) [ENTITY]",
}

do -- IO
	WireLib.AddInputAlias("Active", "Load")
	WireLib.AddOutputAlias("Munitions", "Ammo")

	ACF.AddInputAction("acf_ammo", "Load", function(Entity, Value)
		Entity.Load = tobool(Value)

		WireLib.TriggerOutput(Entity, "Loading", Entity:CanConsume() and 1 or 0)
	end)
end

do -- Spawn/Update/Remove
	local function VerifyData(Data)
		if not isvector(Data.Size) then
			local X = ACF.CheckNumber(Data.AmmoSizeX or Data.CrateSizeX, 24)
			local Y = ACF.CheckNumber(Data.AmmoSizeY or Data.CrateSizeY, 24)
			local Z = ACF.CheckNumber(Data.AmmoSizeZ or Data.CrateSizeZ, 24)

			Data.Size = Vector(X, Y, Z)
		end

		do
			local Min  = ACF.AmmoMinSize
			local Size = Data.Size

			Size.x = Clamp(Size.x, Min, ACF.AmmoMaxLength)
			Size.y = Clamp(Size.y, Min, ACF.AmmoMaxWidth)
			Size.z = Clamp(Size.z, Min, ACF.AmmoMaxWidth)

			if not isstring(Data.Destiny) then
				Data.Destiny = ACF.FindWeaponrySource(Data.Weapon) or "Weapons"
			end

			local Source = Classes[Data.Destiny]
			local Class  = Classes.GetGroup(Source, Data.Weapon)

			if not Class then
				Class = Weapons.Get("C")

				Data.Destiny = "Weapons"
				Data.Weapon  = "C"
				Data.Caliber = Data.caliber or 50
			elseif Source.IsAlias(Data.Weapon) then
				Data.Weapon = Class.ID
			end

			do
				local Weapon = Source.GetItem(Class.ID, Data.Weapon)

				if Weapon then
					if Class.IsScalable then
						local Bounds  = Class.Caliber
						local Caliber = ACF.CheckNumber(Weapon.Caliber, Bounds.Base)

						Data.Weapon  = Class.ID
						Data.Caliber = Clamp(Caliber, Bounds.Min, Bounds.Max)
					else
						Data.Caliber = ACF.CheckNumber(Weapon.Caliber, 50)
					end
				end
			end

			local Ammo = AmmoTypes.Get(Data.AmmoType)

			if not Ammo or Ammo.Blacklist[Class.ID] then
				Data.AmmoType = Class.DefaultAmmo or "AP"

				Ammo = AmmoTypes.Get(Data.AmmoType)
			end

			if not isnumber(Data.AmmoStage) then
				Data.AmmoStage = 1
			end
			Data.AmmoStage = Clamp(Data.AmmoStage, ACF.AmmoStageMin, ACF.AmmoStageMax)

			do
				Ammo:VerifyData(Data, Class)

				if Class.VerifyData then
					Class.VerifyData(Data, Class, Ammo)
				end

				hook.Run("ACF_OnVerifyData", "acf_ammo", Data, Class, Ammo)
			end
		end
	end

	local function UpdateCrateSize(Entity, Data, Class, _, Ammo)
		-- Convert current tool data once to get projectile geometry
		local Bullet = Ammo:ServerConvert(Data)

		-- Normalize requested projectile counts (accept nil, coerce to integers >= 1)
		local cx = tonumber(Data.CrateProjectilesX)
		local cy = tonumber(Data.CrateProjectilesY)
		local cz = tonumber(Data.CrateProjectilesZ)

		if not (cx and cy and cz) then
			cx, cy, cz = ACF.GetProjectileCountsFromCrateSize(Data.Size, Class, Data, Bullet)
		end

		cx = math.max(1, Floor(cx or 3))
		cy = math.max(1, Floor(cy or 3))
		cz = math.max(1, Floor(cz or 3))

		-- Persist counts on both Data and Entity
		Data.CrateProjectilesX, Data.CrateProjectilesY, Data.CrateProjectilesZ = cx, cy, cz

		-- Recompute and apply consistent crate size from final counts
		Data.Size = ACF.GetCrateSizeFromProjectileCounts(cx, cy, cz, Class, Data, Bullet)
		Entity:SetSize(Data.Size)

		return cx * cy * cz
	end

	local function CalculateExtraData(Entity, Data, Class, Weapon)
		local Rounds = Entity.Capacity
		local ExtraData = {}

		if Rounds > 0 then
			local BulletData = Entity.BulletData
			local Caliber = Entity.Caliber
			local BeltFed = ACF.GetWeaponValue("IsBelted", Caliber, Class, Weapon) or false
			local Round = Weapon and Weapon.Round or Class.Round
			local RoundLength, RoundDiameter, RoundModel, RoundOffset = ACF.GetModelDimensions(Round)

			if not RoundLength then
				RoundDiameter = Caliber * ACF.AmmoCaseScale * 0.1
				RoundLength = BulletData.PropLength + BulletData.ProjLength
				RoundLength = RoundLength / ACF.InchToCm
				RoundDiameter = RoundDiameter / ACF.InchToCm
			end

			Entity.IsBelted = BeltFed
			ExtraData.AmmoStage = Data.AmmoStage or 0
			ExtraData.IsRound = true
			ExtraData.Capacity = Entity.Capacity or 0
			ExtraData.Enabled = true
			ExtraData.RoundSize = Vector(RoundLength, RoundDiameter, RoundDiameter)
			ExtraData.LocalAng = Angle(0, 0, 0)
			ExtraData.Spacing = 0
			ExtraData.MagSize = Entity.MagSize or 0
			ExtraData.IsBelted = BeltFed or false
			ExtraData.RoundModel = RoundModel
			ExtraData.RoundOffset = RoundOffset
		else
			ExtraData = { Enabled = false }
		end

		return ExtraData
	end

	local function NetworkAmmoData(Entity, Player)
		if IsValid(Entity) and Entity.ExtraData then
			net.Start("ACF_RequestAmmoData")
				net.WriteEntity(Entity)

				local ExtraData = Entity.ExtraData
				local Enabled = ExtraData.Enabled
				net.WriteBool(Enabled)

				if Enabled then
					-- Send stored projectile counts for client rendering
					local CountX = Entity.CrateProjectilesX or 3
					local CountY = Entity.CrateProjectilesY or 3
					local CountZ = Entity.CrateProjectilesZ or 3

					net.WriteUInt(ExtraData.Capacity or 0, 25)
					net.WriteBool(ExtraData.IsRound or false)
					net.WriteVector(ExtraData.RoundSize or vector_origin)
					net.WriteAngle(ExtraData.LocalAng or angle_zero)
					net.WriteVector(Vector(CountX, CountY, CountZ)) -- Send stored projectile counts
					net.WriteFloat(ExtraData.Spacing or 0)
					net.WriteUInt(ExtraData.MagSize or 0, 10)
					net.WriteUInt(ExtraData.AmmoStage or 0, 5)
					net.WriteBool(ExtraData.IsBelted or false)

					local HasModel = ExtraData.RoundModel ~= nil

					net.WriteBool(HasModel)

					if HasModel then
						net.WriteString(ExtraData.RoundModel)
						net.WriteVector(ExtraData.RoundOffset)
					end
				end

			if Player then
				net.Send(Player)
			else
				net.Broadcast()
			end
		end
	end

	util.AddNetworkString("ACF_RequestAmmoData")

	net.Receive("ACF_RequestAmmoData", function(_, Player)
		local Entity = net.ReadEntity()

		NetworkAmmoData(Entity, Player)
	end)

	local function UpdateCrate(Entity, Data, Class, Weapon, Ammo)
		local Name, ShortName, WireName = Ammo:GetCrateName()
		local Scalable    = Class.IsScalable
		local Caliber     = Scalable and Data.Caliber or Weapon.Caliber
		local WeaponName  = Scalable and Caliber .. "mm " .. Class.Name or Weapon.Name
		local WeaponShort = Scalable and Caliber .. "mm" .. Class.ID or Weapon.ID
		local Rounds      = UpdateCrateSize(Entity, Data, Class, Weapon, Ammo)
		local OldAmmo     = Entity.RoundData

		if OldAmmo then
			if OldAmmo.OnLast then
				OldAmmo:OnLast(Entity)
			end

			HookRun("ACF_OnAmmoLast", OldAmmo, Entity)
		end

		Entity.RoundData  = Ammo
		Entity.BulletData = Ammo:ServerConvert(Data)
		Entity.BulletData.Crate = Entity:EntIndex()

		if Ammo.OnFirst then
			Ammo:OnFirst(Entity)
		end

		HookRun("ACF_OnAmmoFirst", Ammo, Entity, Data, Class, Weapon)

		Ammo:Network(Entity, Entity.BulletData)

		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name       = Name or WeaponName .. " " .. Ammo.Name
		Entity.ShortName  = ShortName or WeaponShort .. " " .. Ammo.ID
		Entity.EntType    = "Ammo Crate"
		Entity.ClassData  = Class
		Entity.Shape      = "Box"
		Entity.Class      = Class.ID
		Entity.WeaponData = Weapon
		Entity.Caliber    = Caliber
		Entity.AmmoStage  = Data.AmmoStage
		Entity.UnitMass   = Entity.BulletData.CartMass

		WireIO.SetupInputs(Entity, Inputs, Data, Class, Weapon, Ammo)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Weapon, Ammo)

			Entity.WireAmountName = "Ammo"

		Entity:SetNWString("WireName", "ACF " .. (WireName or WeaponName .. " Ammo Crate"))

		local Percentage = Entity.Capacity and Entity.Amount / Entity.Capacity or 1
		local MagSize    = ACF.GetWeaponValue("MagSize", Caliber, Class, Weapon) or 0

		Entity.Capacity = Rounds
		Entity.MagSize  = MagSize
		Entity:SetAmount(math.floor(Entity.Capacity * Percentage))
		Entity:SetNWInt("Ammo", Entity.Amount)

		Entity.ExtraData = CalculateExtraData(Entity, Data, Class, Weapon)

		NetworkAmmoData(Entity)

		if next(Entity.Weapons) then
			local Unloaded

			for K in pairs(Entity.Weapons) do
				if K.CurrentCrate == Entity then
					Unloaded = true

					K:Unload()
				end
			end

			if Unloaded then
				ACF.SendNotify(Entity.Owner, false, "Crate updated while weapons were loaded with its ammo. Weapons unloaded.")
			end
		end

		ACF.Activate(Entity, true)

		Entity.ACF.Model = Entity:GetModel()

		Entity:UpdateMass(true)
	end

	function ACF.MakeAmmo(Player, Pos, Ang, Data)
		if not Player:CheckLimit("_acf_ammo") then return end

		VerifyData(Data)

		local Source = Classes[Data.Destiny]
		local Class  = Classes.GetGroup(Source, Data.Weapon)
		local Weapon = Source.GetItem(Class.ID, Data.Weapon)
		local Ammo   = AmmoTypes.Get(Data.AmmoType)
		local Model  = "models/holograms/hq_rcube_thin.mdl"

		local CanSpawn = HookRun("ACF_PreSpawnEntity", "acf_ammo", Player, Data, Class, Weapon, Ammo)

		if CanSpawn == false then return false end

		local Crate = ents.Create("acf_ammo")

		if not IsValid(Crate) then return end

		Player:AddCleanup("acf_ammo", Crate)
		Player:AddCount("_acf_ammo", Crate)

		Crate.ACF       = Crate.ACF or {}
		Crate.ACF.Model = Model

		Crate:SetMaterial("phoenix_storms/Future_vents")
		Crate:SetScaledModel(Model)
		Crate:SetAngles(Ang)
		Crate:SetPos(Pos)
		Crate:Spawn()

		Crate.IsExplosive = true
		Crate.Weapons     = {}
		Crate.DataStore	  = Entities.GetArguments("acf_ammo")

		UpdateCrate(Crate, Data, Class, Weapon, Ammo)

		if Class.OnSpawn then
			Class.OnSpawn(Crate, Data, Class, Weapon, Ammo)
		end

		HookRun("ACF_OnSpawnEntity", "acf_ammo", Crate, Data, Class, Weapon, Ammo)

		if Data.Offset then
			local Position = Crate:LocalToWorld(Data.Offset)

			ACF.SaveEntity(Crate)

			Crate:SetPos(Position)

			ACF.RestoreEntity(Crate)

			if Data.BuildDupeInfo then
				Data.BuildDupeInfo.PosReset = Position
			end
		end

		Crate:TriggerInput("Load", 1)

		ActiveCrates[Crate] = true

		return Crate
	end

	function ENT:Update(Data)
		VerifyData(Data)

		local Source     = Classes[Data.Destiny]
		local Class      = Classes.GetGroup(Source, Data.Weapon)
		local Weapon     = Source.GetItem(Class.ID, Data.Weapon)
		local Caliber    = Weapon and Weapon.Caliber or Data.Caliber
		local OldClass   = self.ClassData
		local OldWeapon  = self.Weapon
		local OldCaliber = self.Caliber
		local Ammo       = AmmoTypes.Get(Data.AmmoType)
		local Blacklist  = Ammo.Blacklist
		local Extra      = ""

		local CanUpdate, Reason = HookRun("ACF_PreUpdateEntity", "acf_ammo", self, Data, Class, Weapon, Ammo)
		if CanUpdate == false then return CanUpdate, Reason end

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		HookRun("ACF_OnEntityLast", "acf_ammo", self, OldClass)

		ACF.SaveEntity(self)

		UpdateCrate(self, Data, Class, Weapon, Ammo)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, Weapon, Ammo)
		end

		HookRun("ACF_OnUpdateEntity", "acf_ammo", self, Data, Class, Weapon, Ammo)

		if Data.Weapon ~= OldWeapon or Caliber ~= OldCaliber or self.Unlinkable then
			for Entity in pairs(self.Weapons) do
				self:Unlink(Entity)
			end

			Extra = " All weapons have been unlinked."
		else
			local Count = 0
			for Entity in pairs(self.Weapons) do
				if Blacklist[Entity.Class] then
					self:Unlink(Entity)

					Entity:Unload()

					Count = Count + 1
				end
			end

			if Count > 0 then
				Extra = " Unlinked " .. Count .. " weapons from this crate."
			end
		end

		return true, "Crate updated successfully." .. Extra
	end

	function ENT:OnRemove()
		local Class = self.ClassData

		if Class.OnLast then
			Class.OnLast(self, Class)
		end

		HookRun("ACF_OnEntityLast", "acf_ammo", self, Class)

		ActiveCrates[self] = nil

		if self.RoundData and self.RoundData.OnLast then
			self.RoundData:OnLast(self)
		end

		if self.Damaged then
			timer.Remove("ACF Crate Cookoff " .. self:EntIndex())

			self:Detonate()
		end

		for K in pairs(self.Weapons) do
			self:Unlink(K)
		end

		if self.BaseClass.OnRemove then
			self.BaseClass.OnRemove(self)
		end
	end

	function ENT:OnResized(Size)
		local A = ACF.ContainerArmor * ACF.MmToInch
		local ExteriorVolume = Size.x * Size.y * Size.z
		local InteriorVolume = math.max(0, (Size.x - 2 * A) * (Size.y - 2 * A) * (Size.z - 2 * A))

		local Volume = ExteriorVolume - InteriorVolume
		local Mass   = Volume * 0.13

		self.EmptyMass = Mass
	end

	Entities.Register("acf_ammo", ACF.MakeAmmo, "Weapon", "Caliber", "AmmoType", "Size", "AmmoStage", "CrateProjectilesX", "CrateProjectilesY", "CrateProjectilesZ")

	ACF.RegisterLinkSource("acf_ammo", "Weapons")
end

do -- Overlay
	function ENT:ACF_UpdateOverlayState(State)
		local Tracer = self.BulletData.Tracer ~= 0 and "-T" or ""
		local AmmoType = self.BulletData.Type .. Tracer

		if next(self.Weapons) then
			if self:CanConsume() then
				State:AddSuccess("Providing Ammo")
			elseif self.Amount ~= 0 then
				State:AddWarning("Idle")
			else
				State:AddError("Empty")
			end
		else
			State:AddError("Not linked to a weapon!")
		end

		local CountX = self.CrateProjectilesX or 1
		local CountY = self.CrateProjectilesY or 1
		local CountZ = self.CrateProjectilesZ or 1

		if AmmoInfo and AmmoInfo ~= "" then
			AmmoInfo = AmmoInfo
		end

		State:AddDivider()
		State:AddSize("Storage (in projectiles)", CountX, CountY, CountZ)
		State:AddKeyValue("Ammo Type", AmmoType)
		State:AddProgressBar("Contents", self.Amount, self.Capacity)

		local Projectile = math.Round(self.BulletData.ProjMass, 2)
		local Cartridge  = math.Round(self.BulletData.CartMass, 2)
		State:AddHeader("Bullet Info", 2)
		State:AddNumber("Cartridge Mass", Cartridge, " kg", 2)
		State:AddNumber("Projectile Mass", Projectile, " kg", 2)

		State:AddHeader("Ammo Info", 2)
		self.RoundData:UpdateCrateOverlay(self.BulletData, State)
		ACF.AddAdditionalOverlays(self, State)
	end
end