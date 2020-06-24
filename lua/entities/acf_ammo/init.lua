AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("ACF_RefillEffect")
util.AddNetworkString("ACF_StopRefillEffect")
util.AddNetworkString("ACF_UpdateAmmoBox")

-- Local Vars -----------------------------------
local CheckLegal   = ACF_CheckLegal
local ClassLink	   = ACF.GetClassLink
local ClassUnlink  = ACF.GetClassUnlink
local RefillDist   = ACF.RefillDistance * ACF.RefillDistance
local ActiveCrates = ACF.AmmoCrates
local TimerCreate  = timer.Create
local TimerExists  = timer.Exists

local function CanRefillCrate(Crate, Target, Distance)
	if Crate == Target then return false end
	if not Crate.Load then return false end
	if Crate.Damaged then return false end
	if Target.Damaged then return false end
	if Target.RoundType == "Refill" then return false end
	if Target.Ammo >= Target.Capacity then return false end

	return Distance <= RefillDist
end

local function RefillEffect(Entity, Target)
	net.Start("ACF_RefillEffect")
		net.WriteEntity(Entity)
		net.WriteEntity(Target)
	net.Broadcast()
end

local function StopRefillEffect(Entity, Target)
	net.Start("ACF_StopRefillEffect")
		net.WriteEntity(Entity)
		net.WriteEntity(Target)
	net.Broadcast()
end

local function UpdateClientAmmobox(Entity, Data)
	net.Start("ACF_UpdateAmmoBox")
		net.WriteEntity(Entity)
		net.WriteTable(Data)
	net.Broadcast()
end

local function RefillCrates(Entity)
	local Position = Entity:GetPos()

	for Crate in pairs(ActiveCrates) do
		local Distance = Position:DistToSqr(Crate:GetPos())

		if CanRefillCrate(Entity, Crate, Distance) then
			local Supply = math.ceil((50000 / ((Crate.BulletData.ProjMass + Crate.BulletData.PropMass) * 1000)) / Distance ^ 0.5)
			local Transfer = math.min(Supply, Crate.Capacity - Crate.Ammo)

			if not Entity.SupplyingTo[Crate] then
				Entity.SupplyingTo[Crate] = true

				Crate:CallOnRemove("ACF Refill " .. Entity:EntIndex(), function()
					Entity.SupplyingTo[Crate] = nil
				end)

				RefillEffect(Entity, Crate)
			end

			Crate:Consume(-Transfer)
			Entity:Consume(Transfer)

			if not Crate.Load then
				local Enabled = Crate.Inputs.Load.Path and Crate.Inputs.Load.Value or 1

				Crate:TriggerInput("Load", Enabled)
			end

			Crate:EmitSound("items/ammo_pickup.wav", 350, 100, 0.5)
		end
	end

	for Crate in pairs(Entity.SupplyingTo) do
		local Distance = Position:DistToSqr(Crate:GetPos())

		if not CanRefillCrate(Entity, Crate, Distance) then
			Entity.SupplyingTo[Crate] = nil

			Crate:RemoveCallOnRemove("ACF Refill " .. Entity:EntIndex())

			StopRefillEffect(Entity, Crate)
		end
	end
end

-- Split this off from the original function,
-- All this does is compare a distance against a table of distances with string indexes for the shortest fitting size
-- It returns the string index of the dimension, or nil if it fails to fit
local function ShortestSize(Length,DimTable)
	local ReturnDimension = nil

	for K,V in pairs(DimTable) do
		if ReturnDimension == nil then
			if Length <= V then ReturnDimension = K end -- It fits, it sits
		else
			if Length <= V and Length < DimTable[ReturnDimension] then ReturnDimension = K end -- It fits, it sits in an even small spot
		end
	end

	return ReturnDimension
end

-- BoxSize is just OBBMaxs-OBBMins
-- Removed caliber and round length inputs, uses GunData and BulletData now
-- AddSpacing is just extra spacing (directly reduces storage, but can later make it harder to detonate)
-- AddArmor is literally just extra armor on the ammo crate, but inside (also directly reduces storage)
-- For missiles/bombs, they MUST have ActualLength and ActualWidth (of the model in cm, and in the round table) to use this, otherwise it will fall back to the original calculations
-- Made by LiddulBOFH :)
local function CalcAmmo(BoxSize,GunData,BulletData,AddSpacing,AddArmor)
	local RoundCaliber = GunData.caliber or 0
	local TotalRoundLength = (BulletData.PropLength or 0) + (BulletData.ProjLength or 0) + (BulletData.Tracer or 0)
	local ExtraData = {}

	-- gives a nice number of rounds per refill box
	if BulletData.Type == "Refill" then return math.ceil((BoxSize.x / 2) * (BoxSize.y / 2) * (BoxSize.z / 2)) end

	-- Filters for missiles, and sets up data
	if (GunData.round.ActualWidth or nil) ~= nil then
		RoundCaliber = GunData.round.ActualWidth
		TotalRoundLength = GunData.round.ActualLength
		ExtraData.isRacked = true
	elseif GunData.ent == "acf_rack" then return -1 end -- Fallback to old capacity
	-- Instantly invalidate garbage rounds
	if RoundCaliber == 0 then return 0 end
	if TotalRoundLength == 0 then return 0 end

	local Rounds = 0
	-- Converting everything to source units
	local ConvCaliber = ( RoundCaliber / 0.75 ) / 2.54 -- cm to u
	local ConvLength = ( TotalRoundLength / 0.75 ) / 2.54 -- cm to u
	local Spacing = math.max(math.abs(AddSpacing) + 0.125,0.125)
	ExtraData.Spacing = Spacing

	local MagSize = 0
	local MagBoxSize = 0
	local Class = GunData.gunclass

	-- This block alters the stored round size, making it more like a container of the rounds
	-- This cuts a little bit of ammo storage out
	-- Anything that may potentially be belt-fed (RACs, ACs despite having the weirdass revolver design) is exempt
	-- Anything with a sensible magazine is forced to use this
	-- Autoloading cannons are exempt because of rounds being inserted into the stored drums

	-- a much needed enmasse comparing function
	-- through some light digging, I couldn't find one, so I made one
	local Force = switch({
		["SAC"] = true,
		["SL"] = true,
		["HMG"] = true,
		["GL"] = true,
		["default"] = false
	},
	Class)

	local ForceSkip = switch({
		["RAC"] = true,
		["AC"] = true,
		["AL"] = true,
		["default"] = false
	},
	Class)

	if ((GunData.magsize or 0) > 0) and ((RoundCaliber <= 2) or (Force and (not (ExtraData.isRacked or false)))) and (not ForceSkip) then
		MagSize = GunData.magsize
		MagBoxSize = ConvCaliber * math.sqrt(MagSize)
		-- Makes certain automatic ammo stored by boxes
		ConvCaliber = MagBoxSize
		ExtraData.MagSize = MagSize
		ExtraData.isBoxed = true
	end

	if AddArmor > 0 then
		local ConvArmor = (AddArmor / 0.75) / 25.4
		-- *2 because armor on both sides
		BoxSize = {
			x = math.max(BoxSize.x-(ConvArmor * 2),0),
			y = math.max(BoxSize.y-(ConvArmor * 2),0),
			z = math.max(BoxSize.z-(ConvArmor * 2),0)
		}
	end

	local D = {["x"] = BoxSize.x, ["y"] = BoxSize.y, ["z"] = BoxSize.z}
	local ShortestFit = ShortestSize(ConvLength,D)

	if ShortestFit ~= nil then -- From here we know the round can sorta fit in the box
		local X = 0
		local Y = 0
		-- Creating the 'plane' to do the basic bitch math with
		if ShortestFit == "x" then
			X = D["y"]
			Y = D["z"]
			ExtraData.LocalAng = Angle(0,0,0)
		elseif ShortestFit == "y" then
			X = D["x"]
			Y = D["z"]
			ExtraData.LocalAng = Angle(0,90,0)
		else -- z
			X = D["x"]
			Y = D["y"]
			ExtraData.LocalAng = Angle(90,90,0)
		end

		local ModifiedRoundLength = ConvLength + Spacing
		local ModifiedRoundSize = ConvCaliber + Spacing
		-- Doesn't use round spacing for length wise if its just 1, because edge cases are fun
		if (math.floor(D[ShortestFit] / ConvLength) == 1) then ModifiedRoundLength = ConvLength end
		-- That basic bitch math
		ExtraData.RoundSize = Vector(ConvLength,ConvCaliber,ConvCaliber)
		local RoundsX = math.floor(D[ShortestFit] / ModifiedRoundLength)
		local RoundsY = math.floor(X / ModifiedRoundSize)
		local RoundsZ = math.floor(Y / ModifiedRoundSize)
		ExtraData.FitPerAxis = Vector(RoundsX,RoundsY,RoundsZ)
		if MagSize > 0 then
			Rounds = RoundsX * RoundsY * RoundsZ * MagSize
		else
			Rounds = RoundsX * RoundsY * RoundsZ
		end
	elseif ShortestFit == nil and ((ConvCaliber >= ((10 / 0.75) / 2.54)) or ((ExtraData.isRacked or false) == true)) and not (ExtraData.isBoxed or false) then
		-- If ShortestFit is nil, that means the round isn't able to fit at all in the box
		-- If its a racked munition that doesn't fit, it will go ahead and try to fit 2-pice
		-- Otherwise, checks if the caliber is over 100mm before trying 2-piece ammunition
		-- It will flatout not do anything if its boxed and not fitting

		-- Not exactly accurate, but cuts the round in two
		ConvLength = ConvLength / 2
		-- Then makes a shape made of the now two pieces of ammunition
		local RoundWidth = ConvCaliber * 2 -- two pieces wide
		local RoundHeight = ConvCaliber -- one piece tall

		ShortestFit = ShortestSize(ConvLength, D)

		-- Retrying the length fit
		if ShortestFit ~= nil then
				local X = 0
				local Y = 0
				-- Creating the 'plane' to do the basic bitch math with
				if ShortestFit == "x" then
					X = D["y"]
					Y = D["z"]
					ExtraData.LocalAng = Angle(0,0,0)
				elseif ShortestFit == "y" then
					X = D["x"]
					Y = D["z"]
					ExtraData.LocalAng = Angle(0,90,0)
				else -- z
					X = D["x"]
					Y = D["y"]
					ExtraData.LocalAng = Angle(90,90,0)
				end

				-- Now we have to check which side will fit the new width of the round, in the shortest space possible
				local D2 = {["x"] = X, ["y"] = Y}
				ShortestWidth = ShortestSize(RoundWidth, D2)

				local FreeSpace = 0
				if ShortestWidth ~= nil then
				if ShortestWidth == "x" then
					FreeSpace = D2["y"]
					ExtraData.LocalAng = ExtraData.LocalAng + Angle(0,0,0)
				else -- y
					FreeSpace = D2["x"]
					ExtraData.LocalAng = ExtraData.LocalAng + Angle(0,0,90)
				end

				local ModifiedRoundLength = ConvLength + Spacing
				-- Doesn't use round spacing for length wise if its just 1, because edge cases are fun
				if (math.floor(D[ShortestFit] / ConvLength) == 1) then ModifiedRoundLength = ConvLength end
				ExtraData.RoundSize = Vector(ConvLength,RoundWidth,RoundHeight)
				local RoundsX = math.floor(D[ShortestFit] / ModifiedRoundLength)
				local RoundsY = math.floor(D2[ShortestWidth] / (RoundWidth + Spacing))
				local RoundsZ = math.floor(FreeSpace / (RoundHeight + Spacing))
				ExtraData.FitPerAxis = Vector(RoundsX,RoundsY,RoundsZ)
				Rounds = RoundsX * RoundsY * RoundsZ
			end
		end
		-- If it still doesn't fit the box, then the box is just too small

		ExtraData.isTwoPiece = true
	end

	return Rounds,ExtraData
end

local function UpdateAmmoData(Entity, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10)
	local GunData = ACF.Weapons.Guns[Data1]

	if not GunData then
		Entity:Remove()
		return
	end

	if Entity.Weapons and next(Entity.Weapons) then
		local Unloaded

		for Weapon in pairs(Entity.Weapons) do
			if Weapon.CurrentCrate == Entity then
				Unloaded = true

				Weapon:Unload()
			end
		end

		if Unloaded then
			ACF_SendNotify(Entity:CPPIGetOwner(), false, "Crate updated while weapons were loaded with it's ammo. Weapons unloaded.")
		end
	end

	local GunClass = ACF.Classes.GunClass[GunData.gunclass]
	local RoundData = ACF.RoundTypes[Data2]

	--Data 1 to 4 are should always be Round ID, Round Type, Propellant lenght, Projectile lenght
	Entity.RoundId = Data1 --Weapon this round loads into, ie 140mmC, 105mmH ...
	Entity.RoundType = RoundData and Data2 or "AP" --Type of round, IE AP, HE, HEAT ...
	Entity.RoundPropellant = Data3 --Length of propellant
	Entity.RoundProjectile = Data4 --Length of the projectile
	Entity.RoundData5 = Data5 or 0
	Entity.RoundData6 = Data6 or 0
	Entity.RoundData7 = Data7 or 0
	Entity.RoundData8 = Data8 or 0
	Entity.RoundData9 = Data9 or 0
	Entity.RoundData10 = Data10 or 0

	Entity.Name = (Entity.RoundType ~= "Refill" and (Data1 .. " ") or "") .. Entity.RoundType
	Entity.ShortName = Data1
	Entity.EntType = Entity.RoundType
	Entity.RoundData = RoundData or ACF.RoundTypes.AP

	local PlayerData = {
		Id = Entity.RoundId,
		Type = Entity.RoundType,
		PropLength = Entity.RoundPropellant,
		ProjLength = Entity.RoundProjectile,
		Data5 = Entity.RoundData5,
		Data6 = Entity.RoundData6,
		Data7 = Entity.RoundData7,
		Data8 = Entity.RoundData8,
		Data9 = Entity.RoundData9,
		Data10 = Entity.RoundData10
	}

	Entity.BulletData = Entity.RoundData.convert(Entity, PlayerData)
	Entity.BulletData.Crate = Entity:EntIndex()

	if Entity.RoundType == "Refill" then
		Entity.SupplyingTo = Entity.SupplyingTo or {}

		TimerCreate("ACF Refill " .. Entity:EntIndex(), 1, 0, function()
			if not IsValid(Entity) then return end

			RefillCrates(Entity)
		end)
	else
		if Entity.SupplyingTo then
			for Crate in pairs(Entity.SupplyingTo) do
				StopRefillEffect(Entity, Crate)
			end

			Entity.SupplyingTo = nil
		end

		timer.Remove("ACF Refill " .. Entity:EntIndex())
	end

	local Efficiency = 0.1576 * ACF.AmmoMod
	local Volume = math.floor(Entity:GetPhysicsObject():GetVolume())
	--local MassMod = Entity.BulletData.MassMod or 1

	Entity.Volume = Volume * Efficiency
	--Entity.Capacity = math.floor(CapMul * Entity.Volume * 16.38 / Entity.BulletData.RoundVolume)
	-- CalcAmmo function is just above
	local BoundingBox = Entity:OBBMaxs() - Entity:OBBMins()

	local Rounds,ExtraData = CalcAmmo(BoundingBox, GunData, Entity.BulletData, 0, 0)
	if Rounds ~= -1 then
		Entity.Capacity = Rounds
	else
		print("Fallback (Rackable munition missing ActualLength/ActualWidth)")
		local CapMul = (Volume > 40250) and ((math.log(Volume * 0.00066) / math.log(2) - 4) * 0.15 + 1) or 1
		Entity.Capacity = math.floor(CapMul * Entity.Volume * 16.38 / Entity.BulletData.RoundVolume)
	end

	--*0.0625 for 25% @ 4x8x8, 0.025 10%, 0.0375 15%, 0.05 20% --0.23 karb edit for cannon rof 2. changed to start from 2x3x4 instead of 2x4x4
	Entity.RoFMul = (Volume > 27000) and (1 - (math.log(Volume * 0.00066) / math.log(2) - 4) * 0.2) or 1

	Entity.AmmoMassMax = math.floor((Entity.BulletData.ProjMass + Entity.BulletData.PropMass) * Entity.Capacity)
	Entity.Caliber = GunData.caliber
	Entity.Spread = GunClass.spread * ACF.GunInaccuracyScale
	if ExtraData ~= nil then
		local MGS = 0
		if ((GunData.magsize or 0) > 0) and (ExtraData.isBoxed or false) then MGS = (GunData.magsize or 0) end
		ExtraData.MGS = MGS
		ExtraData.IsRound = not ((ExtraData.isBoxed or false) or (ExtraData.isTwoPiece or false) or (ExtraData.isRacked or false))
		Entity.ExtraData = ExtraData

		-- for future use in reloading
		--if (ExtraData.isBoxed or false) then Entity.isBoxed = true end -- Ammunition is boxed
		--if (ExtraData.isTwoPiece or false) then Entity.isTwoPiece = true end -- Ammunition is broken down to two pieces

		local NWTable = {}
		table.Merge(NWTable,ExtraData)
		NWTable.Capacity = Entity.Capacity
		timer.Simple(0.1,function()
			UpdateClientAmmobox(Entity,NWTable)
		end)
	end
	Entity:SetNWString("WireName", "ACF " .. (Entity.RoundType == "Refill" and "Ammo Refill Crate" or GunData.name .. " Ammo"))

	Entity.RoundData.network(Entity, Entity.BulletData)
end

do -- Spawn Func --------------------------------
	function MakeACF_Ammo(Player, Pos, Ang, Id, ...)
		if not Player:CheckLimit("_acf_ammo") then return end

		local CrateData = ACF.Weapons.Ammo[Id]

		if not CrateData then return end

		local Crate = ents.Create("acf_ammo")

		if not IsValid(Crate) then return end

		Player:AddCount("_acf_ammo", Crate)
		Player:AddCleanup("acfmenu", Crate)

		Crate:SetPos(Pos)
		Crate:SetAngles(Ang)
		Crate:SetPlayer(Player)
		Crate:SetModel(CrateData.model)
		Crate:Spawn()

		Crate:PhysicsInit(SOLID_VPHYSICS)
		Crate:SetMoveType(MOVETYPE_VPHYSICS)

		UpdateAmmoData(Crate, ...)

		Crate.IsExplosive   = true
		Crate.Ammo			= Crate.Capacity
		Crate.EmptyMass		= math.floor(CrateData.weight)
		Crate.Id			= Id
		Crate.Owner			= Player
		Crate.Size			= Size
		Crate.Weapons		= {}
		Crate.Inputs		= WireLib.CreateInputs(Crate, { "Load" })
		Crate.Outputs		= WireLib.CreateOutputs(Crate, { "Entity [ENTITY]", "Ammo", "Loading"})
		Crate.CanUpdate		= true
		Crate.HitBoxes 		= {
					Main = {
						Pos = Crate:OBBCenter(),
						Scale = (Crate:OBBMaxs() - Crate:OBBMins()) - Vector(0.5, 0.5, 0.5),
					}
				}

		WireLib.TriggerOutput(Crate, "Entity", Crate)
		WireLib.TriggerOutput(Crate, "Ammo", Crate.Ammo)

		-- Crates should be ready to load by default
		Crate:TriggerInput("Load", 1)
		Crate:SetNWInt("Ammo",Crate.Ammo)

		ACF.AmmoCrates[Crate] = true

		local Mass = Crate.EmptyMass + Crate.AmmoMassMax
		local Phys = Crate:GetPhysicsObject()
		if IsValid(Phys) then
			Phys:SetMass(Mass)
		end

		ACF_Activate(Crate) -- Makes Crate.ACF table

		Crate.ACF.Model 	= ACF.Weapons.Ammo[Id].model
		Crate.ACF.LegalMass = math.floor(Mass)

		CheckLegal(Crate)
		Crate:UpdateOverlay(true)

		return Crate
	end

	list.Set("ACFCvars", "acf_ammo", {"id", "data1", "data2", "data3", "data4", "data5", "data6", "data7", "data8", "data9", "data10"})
	duplicator.RegisterEntityClass("acf_ammo", MakeACF_Ammo, "Pos", "Angle", "Id", "RoundId", "RoundType", "RoundPropellant", "RoundProjectile", "RoundData5", "RoundData6", "RoundData7", "RoundData8", "RoundData9", "RoundData10")
	ACF.RegisterLinkSource("acf_ammo", "Weapons")
end

do -- Metamethods -------------------------------
	do -- Inputs/Outputs/Linking ----------------
		WireLib.AddInputAlias("Active", "Load")
		WireLib.AddOutputAlias("Munitions", "Ammo")

		function ENT:TriggerInput(Name, Value)
			if self.Disabled then return end -- Ignore input if disabled

			if Name == "Load" then
				self.Load = self.Ammo ~= 0 and tobool(Value)

				WireLib.TriggerOutput(self, "Loading", self.Load and 1 or 0)
			end


			self:UpdateOverlay()
		end

		function ENT:Link(Target)
			if not IsValid(Target) then return false, "Attempted to link an invalid entity." end
			if self == Target then return false, "Can't link a crate to itself." end
			if table.HasValue(ACF.AmmoBlacklist[self.BulletData.Type], Target.Class) then return false, "The ammo type in this crate cannot be used for this weapon." end

			local Function = ClassLink(self:GetClass(), Target:GetClass())

			if Function then
				return Function(self, Target)
			end

			return false, "Crates can't be linked to '" .. Target:GetClass() .. "'."
		end

		function ENT:Unlink(Target)
			if not IsValid(Target) then return false, "Attempted to unlink an invalid entity." end
			if self == Target then return false, "Can't unlink a crate from itself." end

			local Function = ClassUnlink(self:GetClass(), Target:GetClass())

			if Function then
				return Function(self, Target)
			end

			return false, "Crates can't be unlinked from '" .. Target:GetClass() .. "'."
		end
	end

	do -- Overlay -------------------------------
		local function Overlay(Ent)
			if Ent.Disabled then
				Ent:SetOverlayText("Disabled: " .. Ent.DisableReason .. "\n" .. Ent.DisableDescription)
			else
				local Tracer = Ent.BulletData.Tracer ~= 0 and "-T" or ""
				local Text = "%s\n\nContents: %s ( %s / %s ) %s"
				local AmmoData = ""
				local Status

				if next(Ent.Weapons) or Ent.BulletData.Type == "Refill" then
					Status = Ent.Load and "Providing Ammo" or (Ent.Ammo ~= 0 and "Idle" or "Empty")
				else
					Status = "Not linked to a weapon!"
				end

				if Ent.RoundData.cratetxt then
					AmmoData = "\n" .. Ent.RoundData.cratetxt(Ent.BulletData)
				end

				Ent:SetOverlayText(string.format(Text, Status, Ent.BulletData.Type .. Tracer, Ent.Ammo, Ent.Capacity, AmmoData))
				Ent:SetNWInt("Ammo", Ent.Ammo)
			end
		end

		function ENT:UpdateOverlay(Instant)
			if Instant then
				Overlay(self)
				return
			end

			if not TimerExists("ACF Overlay Buffer" .. self:EntIndex()) then
				TimerCreate("ACF Overlay Buffer" .. self:EntIndex(), 1, 1, function()
					if IsValid(self) then
						Overlay(self)
					end
				end)
			end
		end
	end

	do -- Legal Checks --------------------------
		function ENT:Enable()
			if self.Inputs.Load.Path then
				self.Load = tobool(self.Inputs.Load.Value)
			else
				self.Load = true
			end

			self:UpdateOverlay(true)
			self:UpdateMass()
		end

		function ENT:Disable()
			self.Load = false

			self:UpdateOverlay(true)
			self:UpdateMass()
		end
	end

	do -- Consuming ammo, updating mass --------
		function ENT:Consume(Num)
			self.Ammo = self.Ammo - (Num or 1)

			self:UpdateOverlay()
			self:UpdateMass()

			if self.Ammo == 0 then
				self:TriggerInput("Load", 0)
			end

			WireLib.TriggerOutput(self, "Ammo", self.Ammo)
		end

		function ENT:UpdateMass()
			if TimerExists("ACF Mass Buffer" .. self:EntIndex()) then return end

			TimerCreate("ACF Mass Buffer" .. self:EntIndex(), 5, 1, function()
				if IsValid(self) then
					self.ACF.LegalMass = math.floor(self.EmptyMass + (self.AmmoMassMax * (self.Ammo / math.max(self.Capacity, 0))))

					local Phys = self:GetPhysicsObject()

					if IsValid(Phys) then
						Phys:SetMass(self.ACF.LegalMass)
					end
				end
			end)
		end
	end

	do -- Misc ----------------------------------
		local function CookoffCrate(Entity)
			if Entity.Ammo <= 1 or Entity.Damaged < CurTime() then -- Detonate when time is up or crate is out of ammo
				Entity:Detonate()
			elseif Entity.BulletData.Type ~= "Refill" and Entity.RoundData then -- Spew bullets out everywhere
				local VolumeRoll = math.Rand(0, 150) > Entity.BulletData.RoundVolume ^ 0.5
				local AmmoRoll = math.Rand(0, 1) < Entity.Ammo / math.max(Entity.Capacity, 1)

				if VolumeRoll and AmmoRoll then
					local Speed = ACF_MuzzleVelocity(Entity.BulletData.PropMass, Entity.BulletData.ProjMass / 2, Entity.Caliber)

					Entity:EmitSound("ambient/explosions/explode_4.wav", 350, math.max(255 - Entity.BulletData.PropMass * 100,60))

					Entity.BulletData.Pos = Entity:LocalToWorld(Entity:OBBCenter() + VectorRand() * (Entity:OBBMaxs() - Entity:OBBMins()) / 2)
					Entity.BulletData.Flight = (VectorRand()):GetNormalized() * Speed * 39.37 + Entity:GetVelocity()
					Entity.BulletData.Owner = Entity.Inflictor or Entity.Owner
					Entity.BulletData.Gun = Entity
					Entity.BulletData.Crate = Entity:EntIndex()

					Entity.RoundData.create(Entity, Entity.BulletData)

					Entity:Consume()
				end
			end
		end

		function ENT:ACF_Activate(Recalc)
			local PhysObj   = self.ACF.PhysObj
			local EmptyMass = math.max(self.EmptyMass, PhysObj:GetMass() - self.AmmoMassMax)

			if not self.ACF.Area then
				self.ACF.Area = PhysObj:GetSurfaceArea() * 6.45
			end

			if not self.ACF.Volume then
				self.ACF.Volume = PhysObj:GetVolume() * 16.38
			end

			local Armour = EmptyMass * 1000 / self.ACF.Area / 0.78 --So we get the equivalent thickness of that prop in mm if all it's weight was a steel plate
			local Health = self.ACF.Volume / ACF.Threshold --Setting the threshold of the prop Area gone
			local Percent = 1

			if Recalc and self.ACF.Health and self.ACF.MaxHealth then
				Percent = self.ACF.Health / self.ACF.MaxHealth
			end

			self.ACF.Health = Health * Percent
			self.ACF.MaxHealth = Health
			self.ACF.Armour = Armour * (0.5 + Percent / 2)
			self.ACF.MaxArmour = Armour
			self.ACF.Type = nil
			self.ACF.Mass = self.Mass
			self.ACF.Density = (PhysObj:GetMass() * 1000) / self.ACF.Volume
			self.ACF.Type = "Prop"
		end

		function ENT:ACF_OnDamage(Entity, Energy, FrArea, Ang, Inflictor, _, Type)
			local Mul = (Type == "HEAT" and ACF.HEATMulAmmo) or 1 --Heat penetrators deal bonus damage to ammo
			local HitRes = ACF.PropDamage(Entity, Energy, FrArea * Mul, Ang, Inflictor) --Calling the standard damage prop function

			if self.Exploding or not self.IsExplosive then return HitRes end

			if HitRes.Kill then
				if hook.Run("ACF_AmmoExplode", self, self.BulletData) == false then return HitRes end

				self.Exploding = true

				if IsValid(Inflictor) and Inflictor:IsPlayer() then
					self.Inflictor = Inflictor
				end

				if self.Ammo > 1 then
					self:Detonate()

					return HitRes
				else
					ACF_HEKill(self, VectorRand())
				end
			end


			-- Cookoff chance
			if self.Damaged then return HitRes end -- Already cooking off

			local Ratio = (HitRes.Damage / self.BulletData.RoundVolume) ^ 0.2

			if (Ratio * self.Capacity / self.Ammo) > math.Rand(0, 1) then
				self.Inflictor = Inflictor
				self.Damaged = CurTime() + (5 - Ratio * 3)

				local Interval = 0.01 + self.BulletData.RoundVolume ^ 0.5 / 100

				TimerCreate("ACF Crate Cookoff " .. self:EntIndex(), Interval, 0, function()
					if not IsValid(self) then return end

					CookoffCrate(self)
				end)
			end

			return HitRes
		end

		function ENT:Update(ArgsTable)
			-- That table is the player data, as sorted in the ACFCvars above, with player who shot,
			-- and pos and angle of the tool trace inserted at the start
			local Message = "Ammo crate updated successfully!"

			if ArgsTable[1] ~= self.Owner then return false, "You don't own that ammo crate!" end -- Argtable[1] is the player that shot the tool
			if ArgsTable[6] == "Refill" then return false, "Refill ammo type is only avaliable for new crates!" end -- Argtable[6] is the round type. If it's refill it shouldn't be loaded into guns, so we refuse to change to it

			-- Argtable[5] is the weapon ID the new ammo loads into
			if ArgsTable[5] ~= self.RoundId then
				for Gun in pairs(self.Weapons) do
					self:Unlink(Gun)
				end

				Message = "New ammo type loaded, crate unlinked."
			else -- ammotype wasn't changed, but let's check if new roundtype is blacklisted
				local Blacklist = ACF.AmmoBlacklist[ArgsTable[6]]

				for Gun in pairs(self.Weapons) do
					if table.HasValue(Blacklist, Gun.Class) then
						self:Unlink(Gun)
						Gun:Unload()

						Message = "New round type cannot be used with linked gun, crate unlinked and gun unloaded."
					end
				end
			end

			local AmmoPercent = self.Ammo / math.max(self.Capacity, 1)

			UpdateAmmoData(self, unpack(ArgsTable, 5, 14))

			self.Ammo = math.floor(self.Capacity * AmmoPercent)

			self:UpdateMass()
			self:UpdateOverlay(true)

			return true, Message
		end

		function ENT:Detonate()
			timer.Remove("ACF Crate Cookoff " .. self:EntIndex()) -- Prevent multiple explosions
			self.Damaged = nil -- Prevent multiple explosions

			local Pos		 = self:LocalToWorld(self:OBBCenter() + VectorRand() * (self:OBBMaxs() - self:OBBMins()) / 2)
			local Filler     = self.RoundType == "Refill" and 0.001 or self.BulletData.FillerMass or 0
			local Propellant = self.RoundType == "Refill" and 0.001 or self.BulletData.PropMass or 0

			local ExplosiveMass = (Filler + Propellant * (ACF.PBase / ACF.HEPower)) * self.Ammo
			local FragMass		= self.BulletData.ProjMass or ExplosiveMass * 0.5

			ACF_KillChildProps(self, Pos, ExplosiveMass)
			ACF_HE(Pos, ExplosiveMass, FragMass, self.Inflictor, {self}, self)

			local Effect = EffectData()
				Effect:SetOrigin(Pos)
				Effect:SetNormal(Vector(0, 0, -1))
				Effect:SetScale(math.max(ExplosiveMass ^ 0.33 * 8 * 39.37, 1))
				Effect:SetRadius(0)

			util.Effect("ACF_Explosion", Effect)

			constraint.RemoveAll(self)
			self:Remove()
		end

		function ENT:OnRemove()
			ActiveCrates[self] = nil

			if self.SupplyingTo then
				for Crate in pairs(self.SupplyingTo) do
					Crate:RemoveCallOnRemove("ACF Refill " .. self:EntIndex())

					self.SupplyingTo[Crate] = nil
				end
			end

			if self.Damaged then -- Detonate immediately if cooking off
				self:Detonate()
			end

			for K in pairs(self.Weapons) do -- Unlink weapons
				self:Unlink(K)
			end

			timer.Remove("ACF Refill " .. self:EntIndex())
			timer.Remove("ACF Crate Cookoff " .. self:EntIndex())

			WireLib.Remove(self)
		end
	end
end
