local ACF          = ACF
local Classes      = ACF.Classes
local Utilities    = ACF.Utilities
local Notify       = Utilities.Notify
local WireLib      = WireLib
local ActiveCrates = ACF.AmmoCrates
local HookRun      = hook.Run
local Clamp        = math.Clamp
local Floor        = math.floor

-- Missile weapons carry Guidance/Fuze as nested class-instance fields. The menu commit and dupes both
-- deliver them already deserialized under the Weapon field (self:ACF_GetUserVar("Weapon")), so here we
-- just validate that nested instance -- VerifyData clamps sub-params the field-level serializer can't
-- (e.g. FuzeTimer/ArmingDelay, whose ranges are class/weapon-derived, not static field Options, and
-- whose menu default of 0 sits below the class minimum). Legacy flat ClientData (the chosen FQN as a
-- top-level key + flat sub-params) is still honoured as a fallback: rebuild the instance from it.
local function FoldWeaponSubInstance(Weapon, FieldName, BaseFQN, Data)
	local FQN = Data[FieldName]

	if isstring(FQN) then
		local SubClass = Classes.GetTypeByName(FQN)
		local BaseType = Classes.GetTypeByName(BaseFQN)
		if not (SubClass and BaseType and Classes.IsAssignableTo(SubClass, BaseType)) then return end

		local Instance = Classes.Serialization.DeserializePartial(SubClass, Data)
		if Instance.VerifyData then Instance:VerifyData(Weapon) end

		Weapon[FieldName] = Instance
		return
	end

	local Instance = Weapon[FieldName]
	if Instance and Instance.VerifyData then Instance:VerifyData(Weapon) end
end

do -- IO
	WireLib.AddInputAlias("Active", "Load")
	WireLib.AddOutputAlias("Munitions", "Ammo")

	ACF.AddInputAction("acf_ammo", "Load", function(Entity, Value)
		Entity.Load = tobool(Value)

		Entity:UpdateLoading()
	end)

	ACF.AddInputAction("acf_ammo", "Round Select", function(Entity, Value)
		Entity:SetRoundSelect(Value)
	end)
end

-- Box crates use a thin hologram cube; drums use the cylinder shape model.
local function GetAmmoModel(ShapeClass)
	if ShapeClass and ShapeClass.IsDrum then
		return ShapeClass.Model or "models/acf/core/s_ammo_cyl.mdl"
	end

	return "models/holograms/hq_rcube_thin.mdl"
end

-- The ammo round inputs (Projectile/Propellant/Tracer + type-specific like FillerRatio) live
-- on the ammo instance, which reads the weapon via this back-reference. On a menu spawn
-- ClientData carries the inputs flat; copy any present keys onto the instance. Dupes already
-- have them deserialized into the instance (nested under the AmmoType field), so nil keys are
-- skipped to preserve those. Ammo:ServerConvert() then reads everything off the instance.
function ENT:PrepareAmmo(Ammo, Data)
	Ammo.Weapon = self:GetWeapon()

	for _, Field in ipairs(Classes.GetTypeFields(Ammo:GetType())) do
		if Field.Menu and Data[Field.Name] ~= nil then
			Ammo[Field.Name] = Data[Field.Name]
		end
	end
end

-- Shapes with a fixed lattice ignore the hex packing setting
function ENT:IsHexPacked()
	local Shape = self:ACF_GetUserVar("Shape")

	return self:ACF_GetUserVar("HexPacking") and Shape and Shape.CanHexPack or false
end

do -- Spawn/Update/Remove
	local function UpdateCrateSize(Entity, Data, Class, _, Ammo)
		-- Convert the ammo instance once to get projectile geometry
		local Bullet = Ammo:ServerConvert()

		-- The shape picks the drum layout; nil means this is a plain box crate
		local Shape      = Entity:ACF_GetUserVar("Shape")
		local Layout     = ACF.GetDrumLayout(Shape)
		local HexPacking = Entity:IsHexPacked()

		if Layout then
			local roundSize = ACF.GetRoundProperties(Class, Data, Bullet)
			local minPrimary = Layout.MinPrimary
			local maxPrimary = Layout.GetMaxPrimary(roundSize, ACF.AmmoMaxWidth, HexPacking)
			local maxStacks  = Layout.GetMaxStacks(roundSize, ACF.AmmoMaxLength, HexPacking)

			-- Primary means rounds per ring on a horizontal drum, but rings on a vertical one
			local primary   = Clamp(Floor(tonumber(Data.CrateProjectilesX) or minPrimary), minPrimary, maxPrimary)
			local minStacks = Bullet.TwoPiece and math.min(2, maxStacks) or 1 -- two piece rounds need a charge and a projectile layer
			local numStacks = Clamp(Floor(tonumber(Data.CrateProjectilesZ) or 2), minStacks, maxStacks)

			Data.CrateProjectilesX = primary
			Data.CrateProjectilesZ = numStacks
			Data.CrateProjectilesY = 1
			Data.Size              = Layout.GetDimensions(primary, numStacks, roundSize, HexPacking)

			Entity:SetSize(Data.Size)

			return ACF.GetCrateCapacity(Shape, primary, 1, numStacks, Bullet.TwoPiece)
		elseif Shape.IsCassette then
			-- X is the stacks around the conveyor, Y and Z the conveyor's width and height
			local roundSize        = ACF.GetRoundProperties(Class, Data, Bullet)
			local _, gridY, gridZ  = ACF.GetMaxCounts(roundSize, ACF.AmmoMaxLength, ACF.AmmoMaxWidth, false)
			local stacks           = Floor(tonumber(Data.CrateProjectilesX) or 1)
			local maxX, maxY, maxZ = ACF.GetCassetteMaxCounts(stacks, gridY, gridZ)
			local width            = Clamp(Floor(tonumber(Data.CrateProjectilesY) or 1), 1, maxY)
			local height           = Clamp(Floor(tonumber(Data.CrateProjectilesZ) or 1), 1, maxZ)

			stacks = Clamp(stacks, 1, maxX)

			Data.CrateProjectilesX = stacks
			Data.CrateProjectilesY = width
			Data.CrateProjectilesZ = height
			Data.Size              = ACF.GetCrateDimensions(ACF.GetCassetteGrid(stacks, width, height, Bullet.TwoPiece), roundSize, false)

			Entity:SetSize(Data.Size)

			return ACF.GetCrateCapacity(Shape, stacks, width, height, Bullet.TwoPiece)
		else
			-- Standard box crate logic
			local cx = tonumber(Data.CrateProjectilesX)
			local cy = tonumber(Data.CrateProjectilesY)
			local cz = tonumber(Data.CrateProjectilesZ)

			if not (cx and cy and cz) then
				cx, cy, cz = ACF.GetProjectileCountsFromCrateSize(Data.Size, Class, Data, Bullet, HexPacking)
			end

			cx = math.max(1, Floor(cx or 3))
			cy = math.max(1, Floor(cy or 3))
			cz = math.max(1, Floor(cz or 3))

			-- Clamp counts to maximum allowed dimensions
			local roundSize = ACF.GetRoundProperties(Class, Data, Bullet)
			local maxX, maxY, maxZ = ACF.GetMaxCounts(roundSize, ACF.AmmoMaxLength, ACF.AmmoMaxWidth, HexPacking)

			cx = math.min(cx, maxX)
			cy = math.min(cy, maxY)
			cz = math.min(cz, maxZ)

			if Bullet.TwoPiece then cz = math.max(cz, math.min(2, maxZ)) end

			-- Persist counts on both Data and Entity
			Data.CrateProjectilesX = cx
			Data.CrateProjectilesY = cy
			Data.CrateProjectilesZ = cz

			-- Recompute and apply consistent crate size from final counts
			Data.Size = ACF.GetCrateSizeFromProjectileCounts(cx, cy, cz, Class, Data, Bullet, HexPacking)

			Entity:SetSize(Data.Size)

			return ACF.GetCrateCapacity(Shape, cx, cy, cz, Bullet.TwoPiece)
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
			local ModelInfo   = AmmoType:ResolveModel("Crate", Class, Weapon, BulletData.TwoPiece)
			local RoundModel  = ModelInfo.Model
			local RoundOffset = ModelInfo.Offset
			local Bodygroup   = ModelInfo.Bodygroup
			local NeedsRotation = ModelInfo.NeedsRotation

			-- Get dimensions from weapon's round definition
			local Round = Weapon and Weapon.Round or Class.Round
			local RoundLength, RoundDiameter = ACF.GetModelDimensions(Round)

			if not RoundLength then
				RoundDiameter = Caliber * (BulletData.CaseScale or ACF.GetMaxCaseScale(Class, Weapon)) * 0.1
				RoundLength = BulletData.RoundLength or (BulletData.PropLength + BulletData.ProjLength)
				RoundLength = RoundLength / ACF.InchToCm
				RoundDiameter = RoundDiameter / ACF.InchToCm
			end

			-- Two-piece ammo stores each piece separately, so the rendered shell is half the round's length.
			if BulletData.TwoPiece then RoundLength = RoundLength * 0.5 end

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
			ExtraData.TwoPiece = BulletData.TwoPiece or false

			local ShapeClass = Entity:ACF_GetUserVar("Shape")
			ExtraData.IsCassette = ShapeClass and ShapeClass.IsCassette or false
			ExtraData.HexPacking = Entity:IsHexPacked()

			-- Drum-specific data
			ExtraData.IsDrum = ShapeClass and ShapeClass.IsDrum or false
			if ExtraData.IsDrum then
				ExtraData.DrumShape = Entity.Shape
				ExtraData.DrumPrimary = Entity.CrateProjectilesX
				ExtraData.DrumStacks = Entity.CrateProjectilesZ
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

					net.WriteUInt(ExtraData.Capacity, Entity.CountBits)
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
						net.WriteString(ExtraData.DrumShape)
						net.WriteUInt(ExtraData.DrumPrimary, 8)
						net.WriteUInt(ExtraData.DrumStacks, 8)
					end

					local HasModel = ExtraData.RoundModel ~= nil

					net.WriteBool(HasModel)

					if HasModel then
						net.WriteString(ExtraData.RoundModel)
						net.WriteVector(ExtraData.RoundOffset)
					end

					-- Send rotation flag (true = needs -90 degree rotation for cartridge models)
					net.WriteBool(ExtraData.NeedsRotation)

					net.WriteBool(ExtraData.TwoPiece)
					net.WriteBool(ExtraData.HexPacking)
					net.WriteBool(ExtraData.IsCassette)

					-- Each kind of round top first, with what the round counts window lists it by
					net.WriteUInt(Entity.RoundMixVersion, Entity.MixVersionBits)
					net.WriteUInt(#Entity.RoundKinds - 1, ACF.ProfileBits)

					for _, Kind in ipairs(Entity.RoundKinds) do
						local BulletData = Kind.BulletData

						net.WriteUInt(Kind.Bodygroup, 4)
						net.WriteUInt(Kind.Target, Entity.CountBits)
						net.WriteString(Kind.Name)
						net.WriteString(Kind.Ammo.SpawnIcon or "")
						net.WriteFloat(BulletData.ProjMass)
						net.WriteFloat((BulletData.MuzzleVel or 0) * ACF.Scale)
					end
				end

			if Player then
				net.Send(Player)
			else
				net.Broadcast()
			end
		end
	end

	--- Networks the ammo data at the end of the tick, so several changes in one tick send it once
	function ENT:QueueAmmoData()
		timer.Create("ACF Ammo Data " .. self:EntIndex(), 0, 1, function()
			if IsValid(self) then NetworkAmmoData(self) end
		end)
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
		Entity.BulletData = Ammo:ServerConvert()
		Entity.BulletData.Crate = Entity:EntIndex()

		if Ammo.OnFirst then
			Ammo:OnFirst(Entity)
		end

		HookRun("ACF_OnAmmoFirst", Ammo, Entity)

		Entity.Weapon            = Data.Weapon
		Entity.AmmoType          = Data.AmmoType
		Entity.CrateProjectilesX = Data.CrateProjectilesX
		Entity.CrateProjectilesY = Data.CrateProjectilesY
		Entity.CrateProjectilesZ = Data.CrateProjectilesZ

		-- Short shape name ("Cylinder"), which is what the drum layout registry is keyed on and what
		-- gets networked to the client. The user var itself holds the ContainerShapes class instance.
		local ShapeInst = Entity:ACF_GetUserVar("Shape")
		local ShapeName = ShapeInst and ShapeInst.GetType and Classes.GetTypeName(ShapeInst:GetType())

		Entity.Shape = ShapeName and (string.match(ShapeName, "[^.]+$") or ShapeName) or "Box"

		Entity.Name       = Name or WeaponName .. " " .. Ammo.Name
		Entity.ShortName  = ShortName or WeaponShort .. " " .. (Ammo.ID or "")
		Entity.EntType    = "Ammo Crate"
		Entity.ClassData  = Class
		Entity.Class      = Class.ID
		Entity.WeaponData = Weapon
		Entity.Caliber    = Caliber
		Entity.AmmoStage  = Data.AmmoStage
		Entity.UnitMass   = Entity.BulletData.CartMass

		Entity.WireAmountName = "Ammo"

		Entity:ACF_SetEntityName("ACF " .. (WireName or WeaponName .. " Ammo Crate"))

		-- Capacity can now be zero, and 0 is truthy in Lua, so test the value rather than its presence
		local Percentage = (Entity.Capacity or 0) > 0 and Entity.Amount / Entity.Capacity or 1
		local MagSize    = ACF.GetWeaponValue("MagSize", Caliber, Class, Weapon) or 0

		Entity.Capacity = Rounds
		Entity.MagSize  = MagSize
		Entity:BuildRounds()
		Entity:SetAmount(math.floor(Entity.Capacity * Percentage))
		Entity:SetNWInt("Ammo", Entity.Amount)

		Entity.ExtraData = CalculateExtraData(Entity, Data, Class, Weapon)

		NetworkAmmoData(Entity)

		Entity:UnloadWeapons()

		Entity.ACF.Model = Entity:GetModel()

		Entity:UpdateMass(true)
	end

	--- Unloads the weapons loaded from this crate, so they reload with its current rounds
	function ENT:UnloadWeapons()
		local Unloaded

		for Weapon in pairs(self.Weapons) do
			if Weapon.CurrentCrate == self then
				Unloaded = true

				Weapon:Unload()
			end
		end

		if Unloaded then
			Notify.EntityWarning(self, "Weapons unloaded.", "Crate updated while weapons were loaded with its ammo")
		end
	end

	function ENT:ACF_PreSpawn(_, _, _, ClientData)
		self.ACF             = {}
		self.Weapons         = {}
		self.IsExplosive     = true
		self.RoundSelect     = 0
		self.RoundMixVersion = 0
		self.ProfileKeys     = {} -- Network keys each round profile's last round wrote

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
		ACF.Hints.Set(self, "ammo_no_weapon", true)

		self:TriggerInput("Load", 1)
	end

	function ENT:ACF_PostUpdateEntityData(ClientData)
		self.ACF = self.ACF or {}

		-- Snapshot for unlink-on-change (runtime fields still hold the previous config here).
		local OldWeapon  = self.Weapon
		local OldCaliber = self.Caliber

		-- ClientData carries the ammo round parameters (projectile/propellant/tracer) needed by
		-- Ammo:ServerConvert. Field-level sanitisation already happened in the serializer; legacy/dupe
		-- format conversion happens in the compat patches (see compatibility/acf3/ammo.lua).
		local Data = ClientData

		-- Weapon/ammo come from the deserialized MENU_FIELD instances (the authoritative source -
		-- raw dupe ClientData may carry a serialized {Type, Data} weapon rather than an FQN string).
		local WeaponInst = self:ACF_GetUserVar("Weapon")
		local Ammo       = self:ACF_GetUserVar("AmmoType")
		local Class      = WeaponInst:GetType()

		-- Sync the requested caliber onto the scalable weapon instance, then let it self-validate
		-- (clamps caliber to its CaliberLimits). On dupes ClientData has no flat caliber, so the
		-- instance's deserialized caliber is kept.
		if Class.IsScalable and WeaponInst.Caliber ~= nil then
			WeaponInst.Caliber = Data.Caliber or WeaponInst.Caliber
		end
		if WeaponInst.VerifyData then WeaponInst:VerifyData() end

		-- Fold the menu-selected guidance/fuze onto missile weapons (no-op for guns and for dupes).
		if Classes.GetTypeFieldByName(Class, "Guidance") then
			FoldWeaponSubInstance(WeaponInst, "Guidance", "ACF.Missiles.Guidance", Data)
			FoldWeaponSubInstance(WeaponInst, "Fuze",     "ACF.Missiles.Fuze",     Data)
		end

		self:PrepareAmmo(Ammo, Data)

		-- Derive the flat tool data UpdateCrate consumes from the authoritative instances.
		Data.Weapon   = Classes.GetTypeName(Class)
		Data.AmmoType = Classes.GetTypeName(Ammo:GetType())
		Data.Caliber  = WeaponInst.Caliber or Data.Caliber

		-- Projectile counts / ammo stage also come from the validated field set (dupe ClientData may
		-- omit them - the serializer has already applied the field defaults).
		Data.CrateProjectilesX = self:ACF_GetUserVar("CrateProjectilesX")
		Data.CrateProjectilesY = self:ACF_GetUserVar("CrateProjectilesY")
		Data.CrateProjectilesZ = self:ACF_GetUserVar("CrateProjectilesZ")
		Data.AmmoStage         = self:ACF_GetUserVar("AmmoStage")

		local IsUpdate = self.RoundKinds ~= nil -- Spawning builds them after this

		-- Updating fills the crate with only the round applied, unless the data carries a mix like the copy tool's
		if IsUpdate then
			self:SetRoundsFromData(Data)
		end

		-- Legacy "Weapon" param meant a concrete non-scalable group item (nil for scalables); the
		-- non-scalable weapon instance fills that role now.
		local Weapon = not Class.IsScalable and WeaponInst or nil

		-- Refresh the model from the shape (handles shape changes on update).
		local Model = GetAmmoModel(self:ACF_GetUserVar("Shape"))
		self.ACF.Model = Model
		self:SetScaledModel(Model)

		UpdateCrate(self, Data, Class, Weapon, Ammo)

		-- Persist the clamped projectile counts back into the serialized field set.
		self:ACF_SetUserVar("CrateProjectilesX", Data.CrateProjectilesX)
		self:ACF_SetUserVar("CrateProjectilesY", Data.CrateProjectilesY)
		self:ACF_SetUserVar("CrateProjectilesZ", Data.CrateProjectilesZ)

		-- Autoloaders can only feed from mechanized crates
		if self.Autoloaders and not self:ACF_GetUserVar("Shape").IsMechanized then
			for Autoloader in pairs(self.Autoloaders) do
				Autoloader:Unlink(self)
			end
		end

		-- Unlink weapons that can no longer use this crate (legacy ENT:Update tail).
		if self.Weapons and next(self.Weapons) then
			if Data.Weapon ~= OldWeapon or self.Caliber ~= OldCaliber or self.Unlinkable then
				for W in pairs(self.Weapons) do
					self:Unlink(W)
				end
			else
				local Blacklist = Ammo.Blacklist
				for W in pairs(self.Weapons) do
					if Blacklist[W.Weapon] then
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

		if ACF.IsDestroyed(self) then
			timer.Remove("ACF Crate Cookoff " .. self:EntIndex())

			self:Detonate()
		end

		if self.Weapons then
			for K in pairs(self.Weapons) do
				self:Unlink(K)
			end
		end
	end


	ACF.RegisterLinkSource("acf_ammo", "Weapons")
end