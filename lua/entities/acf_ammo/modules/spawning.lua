local ACF          = ACF
local Classes      = ACF.Classes
local Utilities    = ACF.Utilities
local Notify       = Utilities.Notify
local WireLib      = WireLib
local AmmoTypes    = Classes.AmmoTypes
local Weapons      = Classes.Weapons
local ActiveCrates = ACF.AmmoCrates
local HookRun      = hook.Run
local Clamp        = math.Clamp
local Floor        = math.floor

do -- IO
	WireLib.AddInputAlias("Active", "Load")
	WireLib.AddOutputAlias("Munitions", "Ammo")

	ACF.AddInputAction("acf_ammo", "Load", function(Entity, Value)
		Entity.Load = tobool(Value)

		WireLib.TriggerOutput(Entity, "Loading", Entity:CanConsume() and 1 or 0)
	end)
end

-- Box crates use a thin hologram cube; drums use the cylinder shape model.
local function GetAmmoModel(ShapeClass)
	if ShapeClass and ShapeClass.IsDrum then
		return ShapeClass.Model or "models/acf/core/s_fuel_cyl.mdl"
	end

	return "models/holograms/hq_rcube_thin.mdl"
end

do -- Spawn/Update/Remove
	-- Validates/normalises the raw client/dupe data (replaces the legacy VerifyData). Resolves the
	-- weapon group + ammo type from the still-legacy grouped classes, and translates AmmoShape into
	-- the inherited container Shape field.
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
			local Class = Classes.GetGroup(Source, Data.Weapon)

			-- Compatibility layer for pre-scalable guns
			if not Class then
				local Compat = ACF.Compatibility[Data.Destiny]
				local AliasData = Compat and Compat.CheckGroupItem and Compat.CheckGroupItem(Data.Weapon)

				if AliasData then
					Data.Weapon = AliasData.ID
					Data.Caliber = AliasData.Caliber or Data.Caliber

					Class = Classes.GetGroup(Source, Data.Weapon)
				end
			end

			-- No class exists!
			if not Class then
				Class = Weapons.Get("C")
				Data.Destiny = "Weapons"
				Data.Weapon  = "C"
				Data.Caliber = Data.caliber or 50
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
				Data.AmmoType = Class.DefaultAmmo or "ACF.Ammunition.AP"

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

		-- Check if this is an ammo drum (cylinder shape)
		local ShapeClass = Entity:ACF_GetUserVar("Shape")
		local IsDrum     = ShapeClass and ShapeClass.IsDrum

		if IsDrum then
			local roundSize = ACF.GetRoundProperties(Class, Data, Bullet)
			local minRounds = ACF.GetMinRoundsPerRing()
			local maxRounds = ACF.GetMaxRoundsPerRing(roundSize, ACF.AmmoMaxWidth)
			local maxLayers = ACF.GetMaxDrumLayers(roundSize, ACF.AmmoMaxLength)

			local roundsPerRing = Clamp(Floor(tonumber(Data.CrateProjectilesX) or minRounds), minRounds, maxRounds)
			local numLayers     = Clamp(Floor(tonumber(Data.CrateProjectilesZ) or 2), 1, maxLayers)

			Data.CrateProjectilesX = roundsPerRing
			Data.CrateProjectilesZ = numLayers
			Data.CrateProjectilesY = 1
			Data.Size              = ACF.GetDrumDimensions(roundsPerRing, numLayers, roundSize)

			Entity:SetSize(Data.Size)

			return roundsPerRing * numLayers
		else
			-- Standard box crate logic
			local cx = tonumber(Data.CrateProjectilesX)
			local cy = tonumber(Data.CrateProjectilesY)
			local cz = tonumber(Data.CrateProjectilesZ)

			if not (cx and cy and cz) then
				cx, cy, cz = ACF.GetProjectileCountsFromCrateSize(Data.Size, Class, Data, Bullet)
			end

			cx = math.max(1, Floor(cx or 3))
			cy = math.max(1, Floor(cy or 3))
			cz = math.max(1, Floor(cz or 3))

			-- Clamp counts to maximum allowed dimensions
			local roundSize = ACF.GetRoundProperties(Class, Data, Bullet)
			local maxX, maxY, maxZ = ACF.GetMaxCounts(roundSize, ACF.AmmoMaxLength, ACF.AmmoMaxWidth, cy, cz)

			cx = math.min(cx, maxX)
			cy = math.min(cy, maxY)
			cz = math.min(cz, maxZ)

			-- Persist counts on both Data and Entity
			Data.CrateProjectilesX = cx
			Data.CrateProjectilesY = cy
			Data.CrateProjectilesZ = cz

			-- Recompute and apply consistent crate size from final counts
			Data.Size = ACF.GetCrateSizeFromProjectileCounts(cx, cy, cz, Class, Data, Bullet)

			Entity:SetSize(Data.Size)

			return cx * cy * cz
		end
	end

	local function CalculateExtraData(Entity, Data, Class, Weapon)
		local Rounds = Entity.Capacity
		local ExtraData = {}

		if Rounds > 0 then
			local BulletData = Entity.BulletData
			local Caliber = Entity.Caliber
			local BeltFed = ACF.GetWeaponValue("IsBelted", Caliber, Class, Weapon) or false
			local AmmoType = Entity.RoundData

			-- Get model info from ammo type's unified resolver
			local ModelInfo   = AmmoType:ResolveModel("Crate", Class, Weapon)
			local RoundModel  = ModelInfo.Model
			local RoundOffset = ModelInfo.Offset
			local Bodygroup   = ModelInfo.Bodygroup
			local NeedsRotation = ModelInfo.NeedsRotation

			-- Get dimensions from weapon's round definition
			local Round = Weapon and Weapon.Round or Class.Round
			local RoundLength, RoundDiameter = ACF.GetModelDimensions(Round)

			if not RoundLength then
				RoundDiameter = Caliber * ACF.AmmoCaseScale * 0.1
				RoundLength = BulletData.PropLength + BulletData.ProjLength
				RoundLength = RoundLength / ACF.InchToCm
				RoundDiameter = RoundDiameter / ACF.InchToCm
			end

			Entity.IsBelted = BeltFed
			ExtraData.AmmoStage = Data.AmmoStage
			ExtraData.IsRound = true
			ExtraData.Capacity = Entity.Capacity
			ExtraData.Enabled = true
			ExtraData.RoundSize = Vector(RoundLength, RoundDiameter, RoundDiameter)
			ExtraData.LocalAng = Angle(0, 0, 0)
			ExtraData.Spacing = 0
			ExtraData.MagSize = Entity.MagSize
			ExtraData.IsBelted = BeltFed
			ExtraData.RoundModel = RoundModel
			ExtraData.RoundOffset = RoundOffset
			ExtraData.Bodygroup = Bodygroup
			ExtraData.NeedsRotation = NeedsRotation

			-- Drum-specific data
			local ShapeClass = Entity:ACF_GetUserVar("Shape")
			ExtraData.IsDrum = ShapeClass and ShapeClass.IsDrum or false
			if ExtraData.IsDrum then
				ExtraData.RoundsPerRing = Entity.CrateProjectilesX
				ExtraData.DrumLayers = Entity.CrateProjectilesZ
			end
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
					-- These are validated at spawn time, no fallbacks needed
					local CountX = Entity.CrateProjectilesX
					local CountY = Entity.CrateProjectilesY
					local CountZ = Entity.CrateProjectilesZ

					net.WriteUInt(ExtraData.Capacity, 25)
					net.WriteBool(ExtraData.IsRound)
					net.WriteVector(ExtraData.RoundSize)
					net.WriteAngle(ExtraData.LocalAng)
					net.WriteVector(Vector(CountX, CountY, CountZ))
					net.WriteFloat(ExtraData.Spacing)
					net.WriteUInt(ExtraData.MagSize, 10)
					net.WriteUInt(ExtraData.AmmoStage, 5)
					net.WriteBool(ExtraData.IsBelted)
					net.WriteUInt(ExtraData.Bodygroup, 4) -- Bodygroup index (0-15)

					-- Send drum-specific data
					local IsDrum = ExtraData.IsDrum
					net.WriteBool(IsDrum)

					if IsDrum then
						net.WriteUInt(ExtraData.RoundsPerRing, 8)
						net.WriteUInt(ExtraData.DrumLayers, 8)
					end

					local HasModel = ExtraData.RoundModel ~= nil

					net.WriteBool(HasModel)

					if HasModel then
						net.WriteString(ExtraData.RoundModel)
						net.WriteVector(ExtraData.RoundOffset)
					end

					-- Send rotation flag (true = needs -90 degree rotation for cartridge models)
					net.WriteBool(ExtraData.NeedsRotation)
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

		-- Runtime fields the rest of the entity / other modules read (legacy copied these via DataStore).
		Entity.Weapon            = Data.Weapon
		Entity.AmmoType          = Data.AmmoType
		Entity.CrateProjectilesX = Data.CrateProjectilesX
		Entity.CrateProjectilesY = Data.CrateProjectilesY
		Entity.CrateProjectilesZ = Data.CrateProjectilesZ

		Entity.Name       = Name or WeaponName .. " " .. Ammo.Name
		Entity.ShortName  = ShortName or WeaponShort .. " " .. Ammo.ID
		Entity.EntType    = "Ammo Crate"
		Entity.ClassData  = Class
		Entity.Class      = Class.ID
		Entity.WeaponData = Weapon
		Entity.Caliber    = Caliber
		Entity.AmmoStage  = Data.AmmoStage
		Entity.UnitMass   = Entity.BulletData.CartMass

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

		if Entity.Weapons and next(Entity.Weapons) then
			local Unloaded

			for K in pairs(Entity.Weapons) do
				if K.CurrentCrate == Entity then
					Unloaded = true

					K:Unload()
				end
			end

			if Unloaded then
				Notify.EntityWarning(Entity, "Weapons unloaded.", "Crate updated while weapons were loaded with its ammo")
			end
		end

		Entity.ACF.Model = Entity:GetModel()

		Entity:UpdateMass(true)
	end

	-- Lifecycle: validation (runs for menu spawns and dupe pastes)
	function ENT.ACF_OnVerifyClientData(ClientData)
		VerifyData(ClientData)
	end

	function ENT:ACF_PreSpawn(_, _, _, ClientData)
		self.ACF         = {}
		self.Weapons     = {}
		self.IsExplosive = true

		local ShapeClass = Classes.GetTypeByName(ClientData.Shape)
		local Model      = GetAmmoModel(ShapeClass)

		self.ACF.Model = Model
		self:SetMaterial("phoenix_storms/Future_vents")
		self:SetScaledModel(Model)
	end

	function ENT:ACF_OnSpawn()
		ActiveCrates[self] = true
	end

	function ENT:ACF_PostSpawn()
		self:TriggerInput("Load", 1)
	end

	function ENT:ACF_PostUpdateEntityData(ClientData)
		self.ACF = self.ACF or {}

		-- Snapshot for unlink-on-change (runtime fields still hold the previous config here).
		local OldWeapon  = self.Weapon
		local OldCaliber = self.Caliber

		-- ClientData has been fully validated by ACF_OnVerifyClientData (it also carries the ammo
		-- round parameters - projectile/propellant/tracer - needed by Ammo:ServerConvert, which a
		-- dupe's serialized field set would not).
		local Data   = ClientData
		local Source = Classes[Data.Destiny]
		local Class  = Classes.GetGroup(Source, Data.Weapon)
		local Weapon = Source.GetItem(Class.ID, Data.Weapon)
		local Ammo   = AmmoTypes.Get(Data.AmmoType)

		-- Refresh the model from the shape (handles shape changes on update).
		local Model = GetAmmoModel(self:ACF_GetUserVar("Shape"))
		self.ACF.Model = Model
		self:SetScaledModel(Model)

		UpdateCrate(self, Data, Class, Weapon, Ammo)

		-- Persist the clamped projectile counts back into the serialized field set.
		self:ACF_SetUserVar("CrateProjectilesX", Data.CrateProjectilesX)
		self:ACF_SetUserVar("CrateProjectilesY", Data.CrateProjectilesY)
		self:ACF_SetUserVar("CrateProjectilesZ", Data.CrateProjectilesZ)

		-- Unlink weapons that can no longer use this crate (legacy ENT:Update tail).
		if self.Weapons and next(self.Weapons) then
			if Data.Weapon ~= OldWeapon or self.Caliber ~= OldCaliber or self.Unlinkable then
				for W in pairs(self.Weapons) do
					self:Unlink(W)
				end
			else
				local Blacklist = Ammo.Blacklist
				for W in pairs(self.Weapons) do
					if Blacklist[W.Class] then
						self:Unlink(W)
						W:Unload()
					end
				end
			end
		end
	end

	-- Remove-only teardown. Captured by AutoRegisterV2 as OrigOnRemove; the generated OnRemove still
	-- runs ACF_OnEntityLast + WireLib cleanup around this.
	function ENT:OnRemove(IsFullUpdate)
		if IsFullUpdate then return end

		local Class = self.ClassData

		if Class and Class.OnLast then
			Class.OnLast(self, Class)
		end

		ActiveCrates[self] = nil

		if self.RoundData and self.RoundData.OnLast then
			self.RoundData:OnLast(self)
		end

		if self.Damaged then
			timer.Remove("ACF Crate Cookoff " .. self:EntIndex())

			self:Detonate()
		end

		if self.Weapons then
			for K in pairs(self.Weapons) do
				self:Unlink(K)
			end
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

		local CountX = self.CrateProjectilesX
		local CountY = self.CrateProjectilesY
		local CountZ = self.CrateProjectilesZ

		State:AddDivider()
		State:AddSize("Storage (in projectiles)", CountX, CountY, CountZ)
		State:AddKeyValue("Ammo Type", AmmoType)
		State:AddProgressBar("Contents", self.Amount, self.Capacity)

		local BulletData = self.BulletData
		local Projectile = math.Round(BulletData.ProjMass, 2)
		local Cartridge  = math.Round(BulletData.CartMass, 2)
		State:AddHeader("Bullet Info", 2)

		local Caliber = math.Round(BulletData.Caliber * 10, 2)
		local Length  = math.Round(BulletData.ProjLength + BulletData.PropLength, 2)
		if self.IsMissileAmmo then
			local Class    	= Classes.GetGroup(Classes.Missiles, BulletData.Id)
			local Weapon    = Class and Class.Lookup[BulletData.Id]
			local Round 	= Weapon and Weapon.Round
			Length = Round.ActualLength * ACF.InchToCm
		end
		State:AddKeyValue("Shell dimensions", Caliber .. "mm x " .. Length .. "cm")

		local IdealReloadTime = math.Round(ACF.CalcReloadTime(Caliber, self.ClassData, self.Weapon, self.BulletData, self.Override), 2)
		local IdealMagReloadTime = math.Round(ACF.CalcReloadTimeMag(self.Caliber, self.ClassData, self.Weapon, self.BulletData, {MagSize = self.Amount}), 2)
		State:AddKeyValue("Ideal Reload Time", IdealReloadTime .. " s")
		State:AddKeyValue("Ideal Mag Reload Time", IdealMagReloadTime .. " s")

		State:AddNumber("Cartridge Mass", Cartridge, " kg", 2)
		State:AddNumber("Projectile Mass", Projectile, " kg", 2)

		State:AddHeader("Ammo Info", 2)
		self.RoundData:UpdateCrateOverlay(self.BulletData, State)
		ACF.AddAdditionalOverlays(self, State)
	end
end
