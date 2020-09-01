AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

util.AddNetworkString("ACF_RefillEffect")
util.AddNetworkString("ACF_StopRefillEffect")
util.AddNetworkString("ACF_RequestAmmoData")

-- Local Vars -----------------------------------
local CheckLegal  = ACF_CheckLegal
local ClassLink	  = ACF.GetClassLink
local ClassUnlink = ACF.GetClassUnlink
local Inputs      = ACF.GetInputActions("acf_ammo")
local RefillDist  = ACF.RefillDistance * ACF.RefillDistance
local ActiveCrates = ACF.AmmoCrates
local TimerCreate = timer.Create
local TimerExists = timer.Exists

local function CanRefillCrate(Refill, Crate, Distance)
	if Refill == Crate then return false end
	if not Refill:CanConsume() then return false end
	if Crate.Ammo >= Crate.Capacity then return false end
	if Crate.RoundType == "Refill" then return false end
	if Crate.Disabled then return false end
	if Crate.Damaged then return false end

	return Distance <= RefillDist
end

local function RefillEffect(Entity)
	net.Start("ACF_RefillEffect")
		net.WriteEntity(Entity)
	net.Broadcast()
end

local function StopRefillEffect(Entity)
	net.Start("ACF_StopRefillEffect")
		net.WriteEntity(Entity)
	net.Broadcast()
end

-- Whenever a player requests ammo data, we'll send it to them
net.Receive("ACF_RequestAmmoData", function(_, Player)
	local Entity = net.ReadEntity()

	if IsValid(Entity) and Entity.CrateData then
		net.Start("ACF_RequestAmmoData")
			net.WriteEntity(Entity)
			net.WriteString(Entity.CrateData)
		net.Send(Player)
	end
end)

local function RefillCrates(Refill)
	local Position = Refill:GetPos()

	for Crate in pairs(ActiveCrates) do
		local Distance = Position:DistToSqr(Crate:GetPos())

		if CanRefillCrate(Refill, Crate, Distance) then
			local Supply = math.ceil((50000 / ((Crate.BulletData.ProjMass + Crate.BulletData.PropMass) * 1000)) / Distance ^ 0.5)
			local Transfer = math.min(Supply, Refill.Ammo, Crate.Capacity - Crate.Ammo)

			if hook.Run("ACF_CanRefill", Refill, Crate, Transfer) == false then continue end

			if not next(Refill.SupplyingTo) then
				RefillEffect(Refill)
			end

			if not Refill.SupplyingTo[Crate] then
				Refill.SupplyingTo[Crate] = true

				Crate:CallOnRemove("ACF Refill " .. Refill:EntIndex(), function()
					Refill.SupplyingTo[Crate] = nil
				end)
			end

			Crate:Consume(-Transfer)
			Refill:Consume(Transfer)

			Crate:EmitSound("items/ammo_pickup.wav", 350, 100, 0.5)
			Refill:EmitSound("items/ammo_pickup.wav", 350, 100, 0.5)

		elseif Refill.SupplyingTo[Crate] then
			Refill.SupplyingTo[Crate] = nil

			Crate:RemoveCallOnRemove("ACF Refill " .. Refill:EntIndex())

			if not next(Refill.SupplyingTo) then
				StopRefillEffect(Refill)
			end
		end
	end
end

-- Split this off from the original function,
-- All this does is compare a distance against a table of distances with string indexes for the shortest fitting size
-- It returns the string index of the dimension, or nil if it fails to fit
local function ShortestSize(Size,Spacing,DimTable,ExtraData,IsIrregular)
	local ReturnDimension = nil
	local X = 0
	local Y = 0
	local TestRoundCount = 0
	local BestCount = 0

	--local FullSize = {x = Size.x + Spacing, y = Size.y + Spacing, z = Size.z + Spacing} -- size of the round with the padding
	local ConvLength = Size.x

	for K,_ in pairs(DimTable) do
		if K == "x" then
			X = DimTable["y"]
			Y = DimTable["z"]
		elseif K == "y" then
			X = DimTable["x"]
			Y = DimTable["z"]
		else -- z
			X = DimTable["x"]
			Y = DimTable["y"]
		end

		if not IsIrregular then
			local ModifiedRoundLength = ConvLength + Spacing
			local ModifiedRoundSize = Size.y + Spacing
			if (math.floor(DimTable[K] / ConvLength) == 1) then ModifiedRoundLength = ConvLength end

			local RoundsX = math.floor(DimTable[K] / ModifiedRoundLength)
			local RoundsY = math.floor(X / ModifiedRoundSize)
			local RoundsZ = math.floor(Y / ModifiedRoundSize)

			if ExtraData.MagSize or 0 > 0 then
				TestRoundCount = RoundsX * RoundsY * RoundsZ * ExtraData.MagSize
			else
				TestRoundCount = RoundsX * RoundsY * RoundsZ
			end
		else
			local ModifiedRoundLength = ConvLength + Spacing
			local RoundWidth = Size.y + Spacing
			local RoundHeight = Size.z + Spacing
			-- Doesn't use round spacing for length wise if its just 1, because edge cases are fun
			if (math.floor(DimTable[K] / ConvLength) == 1) then ModifiedRoundLength = ConvLength end

			local RoundsX = math.floor(DimTable[K] / ModifiedRoundLength)
			local RoundsY = math.floor(X / (RoundWidth + Spacing))
			local RoundsZ = math.floor(Y / (RoundHeight + Spacing))

			TestRoundCount = RoundsX * RoundsY * RoundsZ
		end

		if ReturnDimension == nil then
			if TestRoundCount > BestCount then ReturnDimension = K BestCount = TestRoundCount end -- It fits, it sits
		else
			if TestRoundCount > BestCount then ReturnDimension = K BestCount = TestRoundCount end -- It fits, it sits in an even small spot
		end
	end
	return ReturnDimension, BestCount
end

-- BoxSize is just OBBMaxs-OBBMins
-- Removed caliber and round length inputs, uses GunData and BulletData now
-- AddSpacing is just extra spacing (directly reduces storage, but can later make it harder to detonate)
-- AddArmor is literally just extra armor on the ammo crate, but inside (also directly reduces storage)
-- For missiles/bombs, they MUST have ActualLength and ActualWidth (of the model in cm, and in the round table) to use this, otherwise it will fall back to the original calculations
-- Made by LiddulBOFH :)
local function CalcAmmo(BoxSize,GunData,BulletData,AddSpacing,AddArmor)
	local RoundCaliber = GunData.caliber * ACF.AmmoCaseScale or 0
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
	local ConvCaliber = RoundCaliber * 0.3937 -- cm to inches
	local ConvLength = TotalRoundLength * 0.3937
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
		["SA"] = true,
		["SL"] = true,
		["HMG"] = true,
		["GL"] = true,
		["MG"] = true,
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

	if ((GunData.magsize or 0) > 0) and ((GunData.caliber <= 2) or (Force and (not (ExtraData.isRacked or false)))) and (not ForceSkip) then
		MagSize = GunData.magsize
		MagBoxSize = ConvCaliber * math.sqrt(MagSize)
		-- Makes certain automatic ammo stored by boxes
		ConvCaliber = MagBoxSize
		ExtraData.MagSize = MagSize
		ExtraData.isBoxed = true
	end

	if AddArmor then
		local ConvArmor = AddArmor * 0.039 * 2 -- Converting millimeters to inches then multiplying by two since the armor is on both sides
		BoxSize = {
			x = math.max(BoxSize.x-ConvArmor, 0),
			y = math.max(BoxSize.y-ConvArmor, 0),
			z = math.max(BoxSize.z-ConvArmor, 0)
		}
	end

	local D = {["x"] = BoxSize.x, ["y"] = BoxSize.y, ["z"] = BoxSize.z}
	local ShortestFit = ShortestSize({x = ConvLength,y = ConvCaliber,z = ConvCaliber},Spacing,D,ExtraData,false)

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

		local ShortestFit1, ShortestFit2
		local Count1, Count2
		ShortestFit1,Count1 = ShortestSize({x = ConvLength,y = RoundWidth,z = RoundHeight},Spacing,D,ExtraData,true)
		ShortestFit2,Count2 = ShortestSize({x = ConvLength,y = RoundHeight,z = RoundWidth},Spacing,D,ExtraData,true)
		if Count1 > Count2 then ShortestFit = ShortestFit1 ShortestWidth = "x" else ShortestFit = ShortestFit2 ShortestWidth = "y" end

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

local function UpdateAmmoData(Entity, Data1, Data2, Data3, Data4, Data5, Data6, Data7, Data8, Data9, Data10, Data11, Data12, Data13, Data)
	local GunData = ACF.Weapons.Guns[Data1]
	local Percentage = Entity.Capacity and Entity.Ammo / math.max(Entity.Capacity, 1) or 1

	do -- Sanity checks
		if not GunData then
			Entity:Remove()
			return
		end

		if next(Entity.Weapons) then
			local Unloaded

			for Weapon in pairs(Entity.Weapons) do
				if Weapon.CurrentCrate == Entity then
					Unloaded = true

					Weapon:Unload()
				end
			end

			if Unloaded then
				ACF_SendNotify(Entity.Owner, false, "Crate updated while weapons were loaded with it's ammo. Weapons unloaded.")
			end
		end
	end

	do -- Mass entity mod removal
		local EntMods = Data and Data.EntityMods

		if EntMods and EntMods.mass then
			EntMods.mass = nil
		end
	end

	local RoundData = ACF.RoundTypes[Data2]

	do -- Backwards compatibility
		local AmmoData = Data and Data.Id and ACF.Weapons.Ammo[Data.Id]

		if AmmoData and not (Data11 or Data12 or Data13) then
			local NewPos = Entity:LocalToWorld(AmmoData.Offset)

			Entity:SetPos(NewPos)

			-- Updating the dupe position
			-- TODO: Update constraints on the entity if it gets moved
			if Data.BuildDupeInfo then
				Data.BuildDupeInfo.PosReset = NewPos
			end

			Data11 = AmmoData.Size[1]
			Data12 = AmmoData.Size[2]
			Data13 = AmmoData.Size[3]
		end
	end

	do -- Update RoundData
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
		Entity.RoundData11 = Data11 or Entity.RoundData11 or 24 -- Scale X
		Entity.RoundData12 = Data12 or Entity.RoundData12 or 24 -- Scale Y
		Entity.RoundData13 = Data13 or Entity.RoundData13 or 24 -- Scale Z

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
				StopRefillEffect(Entity)

				Entity.SupplyingTo = nil
			end

			timer.Remove("ACF Refill " .. Entity:EntIndex())
		end
	end

	local Size
	do -- Resizing
		local X = math.Clamp(Entity.RoundData11, 6, 96)
		local Y = math.Clamp(Entity.RoundData12, 6, 96)
		local Z = math.Clamp(Entity.RoundData13, 6, 96)

		Size = Vector(X, Y, Z)

		if Size ~= Entity:GetSize() then
			Entity:SetSize(Size)
		end
	end

	-- CalcAmmo function is just above
	local Rounds, ExtraData = CalcAmmo(Size, GunData, Entity.BulletData, GunData.caliber * 0.039, ACF.AmmoArmor)

	if Rounds ~= -1 then
		Entity.Capacity = Rounds
	else
		--print("Fallback (Rackable munition missing ActualLength/ActualWidth)")

		local Efficiency = 0.1576 * ACF.AmmoMod
		local Volume 	 = math.floor(Entity:GetPhysicsObject():GetVolume()) * Efficiency
		local CapMul 	 = (Volume > 40250) and ((math.log(Volume * 0.00066) / math.log(2) - 4) * 0.15 + 1) or 1

		Entity.Capacity = math.floor(CapMul * Volume * 16.38 / Entity.BulletData.RoundVolume)
	end

	Entity.AmmoMassMax = math.floor((Entity.BulletData.ProjMass + Entity.BulletData.PropMass) * Entity.Capacity)
	Entity.Caliber = GunData.caliber
	Entity.Ammo = math.floor(Entity.Capacity * Percentage)

	Entity:SetNWInt("Ammo", Entity.Ammo)

	WireLib.TriggerOutput(Entity, "Ammo", Entity.Ammo)

	if ExtraData then
		local MGS = 0
		if ((GunData.magsize or 0) > 0) and (ExtraData.isBoxed or false) then MGS = (GunData.magsize or 0) end
		ExtraData.MGS = MGS
		ExtraData.IsRound = not (ExtraData.isBoxed or ExtraData.isTwoPiece or ExtraData.isRacked)

		-- for future use in reloading
		--if (ExtraData.isBoxed or false) then Entity.isBoxed = true end -- Ammunition is boxed
		--if (ExtraData.isTwoPiece or false) then Entity.isTwoPiece = true end -- Ammunition is broken down to two pieces

		ExtraData.Capacity = Entity.Capacity
		ExtraData.Enabled = true
	else
		ExtraData = { Enabled = false }
	end

	Entity.CrateData = util.TableToJSON(ExtraData)

	-- TODO: Figure out a way to not rely on this delay.
	timer.Simple(0.1, function()
		net.Start("ACF_RequestAmmoData")
			net.WriteEntity(Entity)
			net.WriteString(Entity.CrateData)
		net.Broadcast()
	end)

	Entity:SetNWString("WireName", "ACF " .. (Entity.RoundType == "Refill" and "Ammo Refill Crate" or GunData.name .. " Ammo"))

	Entity.RoundData.network(Entity, Entity.BulletData)

	ACF_Activate(Entity, true) -- Makes Crate.ACF table

	Entity.ACF.Model = Entity:GetModel()

	Entity:UpdateMass(true)
	Entity:UpdateOverlay(true)
end

do -- Spawn Func --------------------------------
	function MakeACF_Ammo(Player, Pos, Ang, ...)
		if not Player:CheckLimit("_acf_ammo") then return end

		local Crate = ents.Create("acf_ammo")

		if not IsValid(Crate) then return end

		Player:AddCount("_acf_ammo", Crate)
		Player:AddCleanup("acfmenu", Crate)

		Crate:SetPos(Pos)
		Crate:SetAngles(Ang)
		Crate:SetPlayer(Player)
		Crate:SetModel("models/holograms/rcube_thin.mdl")
		Crate:SetMaterial("phoenix_storms/Future_vents")
		Crate:Spawn()

		Crate.IsExplosive   = true
		Crate.Owner			= Player
		Crate.Weapons		= {}
		Crate.Inputs		= WireLib.CreateInputs(Crate, { "Load" })
		Crate.Outputs		= WireLib.CreateOutputs(Crate, { "Entity [ENTITY]", "Ammo", "Loading" })
		Crate.CanUpdate		= true

		UpdateAmmoData(Crate, ...)

		WireLib.TriggerOutput(Crate, "Entity", Crate)

		-- Crates should be ready to load by default
		Crate:TriggerInput("Load", 1)

		ACF.AmmoCrates[Crate] = true

		CheckLegal(Crate)

		return Crate
	end

	list.Set("ACFCvars", "acf_ammo", { "data1", "data2", "data3", "data4", "data5", "data6", "data7", "data8", "data9", "data10", "data11", "data12", "data13" })
	duplicator.RegisterEntityClass("acf_ammo", MakeACF_Ammo, "Pos", "Angle", "RoundId", "RoundType", "RoundPropellant", "RoundProjectile", "RoundData5", "RoundData6", "RoundData7", "RoundData8", "RoundData9", "RoundData10", "RoundData11", "RoundData12", "RoundData13", "Data")
	ACF.RegisterLinkSource("acf_ammo", "Weapons")
end

do -- Metamethods -------------------------------
	do -- Inputs/Outputs/Linking ----------------
		WireLib.AddInputAlias("Active", "Load")
		WireLib.AddOutputAlias("Munitions", "Ammo")

		ACF.AddInputAction("acf_ammo", "Load", function(Entity, Value)
			Entity.Load = tobool(Value)

			WireLib.TriggerOutput(Entity, "Loading", Entity:CanConsume() and 1 or 0)
		end)

		function ENT:TriggerInput(Name, Value)
			if self.Disabled then return end -- Ignore input if disabled

			local Action = Inputs[Name]

			if Action then
				Action(self, Value)

				self:UpdateOverlay()
			end
		end

		function ENT:Link(Target)
			if not IsValid(Target) then return false, "Attempted to link an invalid entity." end
			if self == Target then return false, "Can't link a crate to itself." end

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
		local Text = "%s\n\nSize: %sx%sx%s\n\nContents: %s ( %s / %s )%s%s"
		local BulletText = "\nCartridge Mass: %s kg\nProjectile Mass: %s kg\nPropellant Mass: %s kg"

		local function Overlay(Ent)
			if Ent.Disabled then
				Ent:SetOverlayText("Disabled: " .. Ent.DisableReason .. "\n" .. Ent.DisableDescription)
			else
				local Tracer = Ent.BulletData.Tracer ~= 0 and "-T" or ""
				local X, Y, Z = Ent:GetSize():Unpack()
				local AmmoInfo = Ent.RoundData.cratetxt and Ent.RoundData.cratetxt(Ent.BulletData)
				local BulletInfo = ""
				local Status

				if next(Ent.Weapons) or Ent.BulletData.Type == "Refill" then
					Status = Ent:CanConsume() and "Providing Ammo" or (Ent.Ammo ~= 0 and "Idle" or "Empty")
				else
					Status = "Not linked to a weapon!"
				end

				X = math.Round(X, 2)
				Y = math.Round(Y, 2)
				Z = math.Round(Z, 2)

				if Ent.BulletData.Type ~= "Refill" then
					local ProjectileMass = math.Round(Ent.BulletData.ProjMass, 2)
					local PropellantMass = math.Round(Ent.BulletData.PropMass, 2)
					local CartridgeMass = math.Round(Ent.BulletData.CartMass, 2)

					BulletInfo = BulletText:format(CartridgeMass, ProjectileMass, PropellantMass)
				end

				if AmmoInfo and AmmoInfo ~= "" then
					AmmoInfo = "\n\n" .. AmmoInfo
				end

				Ent:SetOverlayText(Text:format(Status, X, Y, Z, Ent.BulletData.Type .. Tracer, Ent.Ammo, Ent.Capacity, BulletInfo, AmmoInfo))
			end
		end

		function ENT:UpdateOverlay(Instant)
			if Instant then
				return Overlay(self)
			end

			if TimerExists("ACF Overlay Buffer" .. self:EntIndex()) then -- This entity has been updated too recently
				self.OverlayBuffer = true -- Mark it to update when buffer time has expired
			else
				TimerCreate("ACF Overlay Buffer" .. self:EntIndex(), 1, 1, function()
					if IsValid(self) and self.OverlayBuffer then
						self.OverlayBuffer = nil

						Overlay(self)
					end
				end)

				Overlay(self)
			end
		end
	end

	do -- Legal Checks --------------------------
		function ENT:Enable()
			WireLib.TriggerOutput(self, "Loading", self:CanConsume() and 1 or 0)

			self:UpdateOverlay(true)
			self:UpdateMass(true)
		end

		function ENT:Disable()
			WireLib.TriggerOutput(self, "Loading", 0)

			self:UpdateOverlay(true)
			self:UpdateMass(true)
		end
	end

	do -- Consuming ammo, updating mass --------
		function ENT:CanConsume()
			if self.Disabled then return false end
			if not self.Load then return false end
			if self.Damaged then return false end

			return self.Ammo > 0
		end

		function ENT:Consume(Num)
			self.Ammo = math.Clamp(self.Ammo - (Num or 1), 0, self.Capacity)

			self:UpdateOverlay()
			self:UpdateMass()

			WireLib.TriggerOutput(self, "Ammo", self.Ammo)
			WireLib.TriggerOutput(self, "Loading", self:CanConsume() and 1 or 0)

			if TimerExists("ACF Network Ammo " .. self:EntIndex()) then return end

			TimerCreate("ACF Network Ammo " .. self:EntIndex(), 1, 1, function()
				if not IsValid(self) then return end

				self:SetNWInt("Ammo", self.Ammo)
			end)
		end

		local function UpdateMass(Ent)
			Ent.ACF.LegalMass = math.floor(Ent.EmptyMass + (Ent.AmmoMassMax * (Ent.Ammo / math.max(Ent.Capacity, 0))))

			local Phys = Ent:GetPhysicsObject()

			if IsValid(Phys) then
				Phys:SetMass(Ent.ACF.LegalMass)
			end
		end

		function ENT:UpdateMass(Instant)
			if Instant then
				return UpdateMass(self)
			end

			if TimerExists("ACF Mass Buffer" .. self:EntIndex()) then return end

			TimerCreate("ACF Mass Buffer" .. self:EntIndex(), 5, 1, function()
				if not IsValid(self) then return end

				UpdateMass(self)
			end)
		end
	end

	do -- Misc ----------------------------------
		local function CookoffCrate(Entity)
			if Entity.Ammo <= 1 or Entity.Damaged < ACF.CurTime then -- Detonate when time is up or crate is out of ammo
				Entity:Detonate()
			elseif Entity.BulletData.Type ~= "Refill" and Entity.RoundData then -- Spew bullets out everywhere
				local VolumeRoll = math.Rand(0, 150) > Entity.BulletData.RoundVolume ^ 0.5
				local AmmoRoll = math.Rand(0, 1) < Entity.Ammo / math.max(Entity.Capacity, 1)

				if VolumeRoll and AmmoRoll then
					local Speed = ACF_MuzzleVelocity(Entity.BulletData.PropMass, Entity.BulletData.ProjMass / 2)

					Entity:EmitSound("ambient/explosions/explode_4.wav", 350, math.max(255 - Entity.BulletData.PropMass * 100,60))

					Entity.BulletData.Pos = Entity:LocalToWorld(Entity:OBBCenter() + VectorRand() * (Entity:OBBMaxs() - Entity:OBBMins()) / 2)
					Entity.BulletData.Flight = VectorRand():GetNormalized() * Speed * 39.37 + ACF_GetAncestor(Entity):GetVelocity()
					Entity.BulletData.Owner = Entity.Inflictor or Entity.Owner
					Entity.BulletData.Gun = Entity
					Entity.BulletData.Crate = Entity:EntIndex()

					Entity.RoundData.create(Entity, Entity.BulletData)

					Entity:Consume()
				end
			end
		end

		function ENT:ACF_Activate(Recalc)
			local PhysObj = self.ACF.PhysObj

			if not self.ACF.Area then
				self.ACF.Area = PhysObj:GetSurfaceArea() * 6.45
			end

			local Volume = PhysObj:GetVolume()

			local Armour = ACF.AmmoArmor
			local Health = Volume / ACF.Threshold --Setting the threshold of the prop Area gone
			local Percent = 1

			if Recalc and self.ACF.Health and self.ACF.MaxHealth then
				Percent = self.ACF.Health / self.ACF.MaxHealth
			end

			self.ACF.Health = Health * Percent
			self.ACF.MaxHealth = Health
			self.ACF.Armour = Armour * (0.5 + Percent / 2)
			self.ACF.MaxArmour = Armour
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

				if self.Ammo > 0 then
					self:Detonate()
				end

				return HitRes
			end

			-- Cookoff chance
			if self.Damaged then return HitRes end -- Already cooking off

			local Ratio = (HitRes.Damage / self.BulletData.RoundVolume) ^ 0.2

			if (Ratio * self.Capacity / self.Ammo) > math.Rand(0, 1) then
				self.Inflictor = Inflictor
				self.Damaged = ACF.CurTime + (5 - Ratio * 3)

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
			if ArgsTable[5] == "Refill" then return false, "Refill ammo type is only avaliable for new crates!" end -- Argtable[5] is the round type. If it's refill it shouldn't be loaded into guns, so we refuse to change to it

			-- Argtable[4] is the weapon ID the new ammo loads into
			if ArgsTable[4] ~= self.RoundId then
				for Gun in pairs(self.Weapons) do
					self:Unlink(Gun)
				end

				Message = "New ammo type loaded, crate unlinked."
			else -- ammotype wasn't changed, but let's check if new roundtype is blacklisted
				local Blacklist = ACF.AmmoBlacklist[ArgsTable[5]]

				for Gun in pairs(self.Weapons) do
					if table.HasValue(Blacklist, Gun.Class) then
						self:Unlink(Gun)

						Gun:Unload()

						Message = "New round type cannot be used with linked gun, crate unlinked and gun unloaded."
					end
				end
			end

			UpdateAmmoData(self, unpack(ArgsTable, 4))

			return true, Message
		end

		function ENT:OnResized()
			local Size = self:GetSize()

			do -- Calculate new empty mass
				local A = ACF.AmmoArmor * 0.039 -- Millimeters to inches
				local ExteriorVolume = Size[1] * Size[2] * Size[3]
				local InteriorVolume = (Size[1] - A) * (Size[2] - A) * (Size[3] - A) -- Math degree

				local Volume = ExteriorVolume - InteriorVolume
				local Mass   = Volume * 0.13 -- Kg of steel per inch

				self.EmptyMass = Mass
			end

			self.HitBoxes = {
				Main = {
					Pos = self:OBBCenter(),
					Scale = Size,
				}
			}

			-- TODO: Remove as soon as racks are improved, this is only being readded because of them
			local PhysObj = self:GetPhysicsObject()

			if IsValid(PhysObj) then
				self.Volume = PhysObj:GetVolume() * 0.1576 * ACF.AmmoMod
			end

			self:UpdateOverlay()
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
