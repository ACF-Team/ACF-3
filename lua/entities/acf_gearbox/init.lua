AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local variables ---------------------------------

local ACF         	 = ACF
local Contraption 	 = ACF.Contraption
local Mobility    	 = ACF.Mobility
local MobilityObj 	 = Mobility.Objects
local Utilities   	 = ACF.Utilities
local Clock       	 = Utilities.Clock
local Notify      	 = Utilities.Notify
local Clamp       	 = math.Clamp
local abs         	 = math.abs
local min         	 = math.min
local max         	 = math.max
local MaxDistance 	 = ACF.MobilityLinkDistance * ACF.MobilityLinkDistance

local ENTITY         = FindMetaTable("Entity")
local VECTOR         = FindMetaTable("Vector")
local PHYSOBJ        = FindMetaTable("PhysObj")

local IsEntityValid  = ACF.Optimizations.IsEntityValid
local IsPhysObjValid = ACF.Optimizations.IsPhysObjValid

local ENT_ApplyBrakes

local function CalcWheel(Entity, Link, Wheel, SelfWorld)
	local EntityTable = ENTITY.GetTable(Entity)

	local WheelPhys   = ENTITY.GetPhysicsObject(Wheel)
	local VelDiff     = PHYSOBJ.LocalToWorldVector(WheelPhys, PHYSOBJ.GetAngleVelocity(WheelPhys))
	VECTOR.Sub(VelDiff, SelfWorld)

	local BaseRPM     = VECTOR.Dot(VelDiff, PHYSOBJ.LocalToWorldVector(WheelPhys, Link.Axis))
	local GearRatio   = EntityTable.GearRatio
	Link.Vel = BaseRPM

	if GearRatio == 0 then return 0 end

	-- Reported BaseRPM is in angle per second and in the wrong direction, so we convert and add the gear ratio
	return BaseRPM * GearRatio / -6
end

do -- Spawn and Update functions -----------------------
	local Classes = ACF.Classes

	-- Gearbox classes are identified by FQN; derive the legacy short id (e.g. "Manual-T") by stripping
	-- the namespace prefix.
	local function ShortName(Class)
		local Name = Classes.GetTypeName(Class):gsub("^ACF%.Gearboxes%.", "")
		return Name
	end

	-- Assembles the menu's flat Gear1..N / FinalDrive (Gear0) keys into the serialized Gears array,
	-- applying the optional legacy-ratio conversion. The class' own VerifyData (automatic shift points,
	-- CVT min/max RPM) runs afterwards. Runs on raw client/dupe data before serialization.
	function ENT.ACF_OnVerifyClientData(ClientData)
		local ID = ClientData.Gearbox
		if istable(ID) then ID = ID.Type end

		local Class = Classes.GetSubtypeByName("ACF.Gearboxes.BaseGearbox", ID)
			or Classes.GetTypeByName("ACF.Gearboxes.2Gear-T")

		local MaxGears = Class.CanSetGears and (Class.MaxGear or ClientData.GearAmount or Class.Gears.Max) or Class.Gears.Max
		local ToLegacy = tobool(ClientData.GearboxConvertRatio)
		ClientData.GearboxConvertRatio = false -- one-shot; don't reconvert on dupes

		-- Pre-scalable gearboxes stored inverted ratios; the compat patch flags those dupes here since the
		-- V2 classes no longer carry InvertGearRatios. One-shot (not a declared field).
		local Invert = Class.InvertGearRatios or ClientData.InvertGearRatios
		ClientData.InvertGearRatios = nil

		local Gears = istable(ClientData.Gears) and ClientData.Gears or {}

		for I = 1, MaxGears do
			local Gear = ACF.CheckNumber(Gears[I])

			if not Gear then
				Gear = ACF.CheckNumber(ClientData["Gear" .. I], I * 0.1)
				ClientData["Gear" .. I] = nil
			end

			-- Invert pre-scalable gear ratios (compat only; never set on V2 gearboxes).
			if Invert and Gear ~= 0 and abs(Gear) < 1 then
				Gear = math.Round(1 / Gear, 2)
			end

			Gears[I] = ACF.ConvertGearRatio(Gear, ToLegacy)
		end

		for I = MaxGears + 1, #Gears do Gears[I] = nil end

		ClientData.Gears = Gears

		local Final = ACF.CheckNumber(ClientData.FinalDrive)
		if not Final then
			Final = ACF.CheckNumber(ClientData.Gear0, 1)
			ClientData.Gear0 = nil
		end

		if Invert and Final ~= 0 and abs(Final) < 1 then
			Final = math.Round(1 / Final, 2)
		end

		ClientData.FinalDrive = ACF.ConvertGearRatio(Final, ToLegacy)

		-- Class-specific verification (automatic ShiftPoints/Reverse, CVT MinRPM/MaxRPM).
		if Class.VerifyData then Class.VerifyData(ClientData, Class) end
	end

	local function GetMass(Model, PhysObj, Class, Gearbox, ScaledMass)
		if Gearbox then return ScaledMass end

		local Volume = PhysObj:GetVolume()
		local Factor = Volume / ModelData.GetModelVolume(Model)

		return math.Round(Class.Mass * Factor)
	end

	local vector_forward = Vector(1, 0, 0)
	local vector_left    = Vector(0, -1, 0)
	local vector_right   = Vector(0, 1, 0)

	local function UpdateGearbox(Entity, Gearbox)
		local Class         = Classes.GetBaseClass(Gearbox:GetType()) -- the group (for EntType/ClassData)
		local CanDualClutch = Gearbox.CanDualClutch
		local Scale         = Entity:ACF_GetUserVar("GearboxScale") or 1
		local MaxGear       = Gearbox.CanSetGears and (Gearbox.MaxGear or Entity:ACF_GetUserVar("GearAmount")) or Gearbox.Gears.Max
		local ScaledMass, _, TorqueRating = ACF.GetGearboxStats(Gearbox.Mass, Scale, Gearbox.MaxTorque, MaxGear)

		Entity.ACF = Entity.ACF or {}

		Entity:SetScaledModel(Gearbox.Model)
		Entity:SetScale(Scale)

		-- Reconstruct the runtime gear/shift tables from the serialized 1-based arrays, carrying the legacy
		-- [0] sentinel slots. The gearbox class' OnSpawn/OnUpdate may extend these (e.g. automatic appends
		-- the reverse gear at GearCount).
		local Gears  = { [0] = 0 }
		local Shifts = { [0] = -1 }

		for I, V in ipairs(Entity:ACF_GetUserVar("Gears") or {}) do Gears[I] = V end
		for I, V in ipairs(Entity:ACF_GetUserVar("ShiftPoints") or {}) do Shifts[I] = V end

		Entity.Gears              = Gears
		Entity.ShiftPoints        = Shifts
		Entity.FinalDrive         = Entity:ACF_GetUserVar("FinalDrive")
		Entity.Reverse            = Entity:ACF_GetUserVar("Reverse")
		Entity.MinRPM             = Entity:ACF_GetUserVar("MinRPM")
		Entity.MaxRPM             = Entity:ACF_GetUserVar("MaxRPM")
		Entity.GearboxScale       = Scale
		Entity.GearAmount         = MaxGear
		Entity.GearboxLegacyRatio = Entity:ACF_GetUserVar("GearboxLegacyRatio")

		Entity.Name         = Gearbox.Name
		Entity.ShortName    = ShortName(Gearbox:GetType())

		local SplitID       = string.Split(Entity.ShortName, "-")
		Entity.Shape        = SplitID[#SplitID]

		Entity.EntType      = Class and Class.Name or Gearbox.Name
		Entity.ClassData    = Class
		Entity.DefaultSound = Gearbox.Sound
		Entity.SoundPath    = Entity.SoundPath or Gearbox.Sound
		Entity.SwitchTime   = Gearbox.Switch
		Entity.MaxTorque    = TorqueRating
		Entity.MinGear      = Gearbox.Gears.Min
		Entity.MaxGear      = MaxGear
		Entity.GearCount    = Entity.MaxGear
		Entity.ScaleMult    = Scale
		Entity.DualClutch   = CanDualClutch and Entity:ACF_GetUserVar("DualClutch") or Gearbox.DualClutch
		Entity.In           = ACF.LocalPlane(Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("input")).Pos), Entity.Shape == "T" and -vector_forward or vector_right)
		Entity.OutL         = ACF.LocalPlane(Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("driveshaftL")).Pos), Entity.Shape == "ST" and vector_left or vector_right)
		Entity.OutR         = ACF.LocalPlane(Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("driveshaftR")).Pos), vector_left)
		Entity.HitBoxes     = ACF.GetHitboxes(Gearbox.Model, Scale)

		if CanDualClutch and Entity.DualClutch then
			Entity.Name = Entity.Name .. ", Dual Clutch"
		end

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)

		ACF.Activate(Entity, true)

		local PhysObj = Entity.ACF.PhysObj

		if IsPhysObjValid(PhysObj) then
			local Mass = GetMass(Gearbox.Model, PhysObj, Class, Gearbox, ScaledMass)

			Contraption.SetMass(Entity, Mass)
		end

		Entity:ChangeGear(1)

		-- ChangeGear doesn't update GearRatio if the gearbox is already in gear 1
		Entity.GearRatio = Entity.Gears[1] * Entity.FinalDrive
	end

	local function CheckRopes(Entity, Target)
		local NiceName = Target == "Wheels" and "Prop" or "Gearbox"
		local Ropes = Entity[Target]

		if not next(Ropes) then return end

		local Contraption = Entity:CFW_GetContraption()
		local IsAircraft  = Contraption and Contraption:ACF_IsAircraft()

		for Ent, Link in pairs(Ropes) do
			local OutPos = Entity:LocalToWorld(Link:GetOrigin())
			local InPos = Ent.In and Ent:LocalToWorld(Ent.In.Pos) or Ent:GetPos()

			-- make sure it is not stretched too far
			if OutPos:Distance(InPos) > Link.RopeLen * 1.5 then
				Entity:Unlink(Ent)
				Notify.EntityWarning(Ent, "Gearbox to " .. NiceName .. " connection broken", "Excessive distance!")
				continue
			end

			if ACF.IsDriveshaftAngleExcessive(Ent, Ent.In, Link) then
				Entity:Unlink(Ent)
				Notify.EntityWarning(Ent, "Gearbox to " .. NiceName .. " connection broken", "Excessive driveshaft angle!")
				continue
			end

			if IsAircraft then
				local WheelPhys = Ent:GetPhysicsObject()
				-- We check the physical stress of the BoxPhys.
				-- If the stress is greater than half the mass of the BoxPhys,
				-- we break the link connection and return.
				-- This prevents aircraft baseplates from being used on grounded
				-- vehicles.
				local Stress = math.max(WheelPhys:GetStress())
				if Stress > 15 then
					Entity:Unlink(Ent)
					Notify.EntityWarning(Ent, "Gearbox to " .. NiceName .. " connection broken", "Excess stress on linked props!\n(aircraft baseplates cannot have wheel-like gearbox connections)")
					continue
				end
			end
		end
	end

	function ENT:ACF_SetupWireIO(Inputs, Outputs)
		local Gearbox = self:GetGearbox()

		if Gearbox then
			if Gearbox.SetupInputs  then Gearbox.SetupInputs(self, Inputs) end
			if Gearbox.SetupOutputs then Gearbox.SetupOutputs(self, Outputs) end
		end

		if self.DualClutch then
			Inputs[#Inputs + 1] = "Left Clutch (Sets the percentage of power, from 0 to 1, that will not be passed to the left side output.)"
			Inputs[#Inputs + 1] = "Right Clutch (Sets the percentage of power, from 0 to 1, that will not be passed to the right side output.)"
			Inputs[#Inputs + 1] = "Left Brake (Sets the amount of power given to the left side brakes.)"
			Inputs[#Inputs + 1] = "Right Brake (Sets the amount of power given to the right side brakes.)"
		else
			Inputs[#Inputs + 1] = "Clutch (Sets the percentage of power, from 0 to 1, that will not be passed to the output.)"
			Inputs[#Inputs + 1] = "Brake (Sets the amount of power given to the brakes.)"
		end
	end

	-- Type-specific runtime cleanup (was the "Cleanup Gearbox Data" ACF_On*Entity hooks). Runs after the
	-- gearbox class' OnSpawn/OnUpdate has set the Automatic/CVT flags.
	local function CleanupData(Entity)
		if not Entity.Automatic then Entity.Reverse = nil end
		if not Entity.CVT then Entity.MinRPM = nil; Entity.MaxRPM = nil end

		Entity:SetBodygroup(1, Entity.DualClutch and 1 or 0)
	end

	-------------------------------------------------------------------------------

	-- Spawn-only init (runs before Entity:Spawn(), so the model is ready for physics).
	function ENT:ACF_PreSpawn(_, _, _, ClientData)
		self.ACF            = {}
		self.Engines        = {}
		self.Wheels         = {} -- a "Link" has these components: Ent, Side, Axis, Rope, RopeLen, Output, ReqTq, Vel
		self.Effectors      = {}
		self.GearboxIn      = {}
		self.GearboxOut     = {}
		self.TotalReqTq     = 0
		self.TorqueOutput   = 0
		self.LBrake         = 0
		self.RBrake         = 0
		self.ChangeFinished = 0
		self.InGear         = false
		self.Braking        = false
		self.LastBrake      = 0
		self.LastActive     = 0
		self.LClutch        = 1
		self.RClutch        = 1

		-- ClientData isn't verified yet here; resolve defensively for the pre-spawn model. On dupes the
		-- Gearbox field arrives nested ({Type,Data}) and falls through to the default - PostUpdate fixes it.
		local ID = ClientData.Gearbox
		if istable(ID) then ID = ID.Type end

		local Gearbox = Classes.GetSubtypeByName("ACF.Gearboxes.BaseGearbox", ID)
			or Classes.GetTypeByName("ACF.Gearboxes.2Gear-T")

		self:SetScaledModel(Gearbox.Model)

		duplicator.ClearEntityModifier(self, "mass")
	end

	function ENT.ACF_CheckSpawnLimit(Player)
		return Player:CheckLimit("_acf_gearbox")
	end

	-- Runs before each reconfigure (and is fired by the framework before deserialize, while the OLD
	-- gearbox config is still live), letting the previous gearbox class tear down its runtime state.
	function ENT:ACF_OnEntityLast()
		local Gearbox = self:GetGearbox()
		if Gearbox and Gearbox.OnLast then Gearbox.OnLast(self) end
	end

	function ENT:ACF_PostUpdateEntityData()
		local Gearbox = self:GetGearbox()

		UpdateGearbox(self, Gearbox)

		-- Gearbox class init (automatic/CVT set up shift/drive state). OnSpawn == OnUpdate for these.
		local Init = Gearbox.OnUpdate or Gearbox.OnSpawn
		if Init then Init(self) end

		CleanupData(self)

		-- A reconfigure can invalidate existing links (no-op on a fresh spawn).
		if next(self.Engines) then
			for Engine in pairs(self.Engines) do self:Unlink(Engine) self:Link(Engine) end
		end

		if next(self.Wheels) then
			for Wheel in pairs(self.Wheels) do self:Unlink(Wheel) self:Link(Wheel) end
		end

		if next(self.GearboxIn) then
			for Box in pairs(self.GearboxIn) do Box:Unlink(self) Box:Link(self) end
		end

		if next(self.GearboxOut) then
			for Box in pairs(self.GearboxOut) do self:Unlink(Box) self:Link(Box) end
		end
	end

	function ENT:ACF_PostSpawn()
		timer.Create("ACF Gearbox Clock " .. self:EntIndex(), 3, 0, function()
			if IsEntityValid(self) then
				CheckRopes(self, "GearboxOut")
				CheckRopes(self, "Wheels")
			else
				timer.Remove("ACF Gearbox Clock " .. self:EntIndex())
			end
		end)
	end

	ACF.RegisterLinkSource("acf_gearbox", "GearboxIn")
	ACF.RegisterLinkSource("acf_gearbox", "GearboxOut")
	ACF.RegisterLinkSource("acf_gearbox", "Engines")
	ACF.RegisterLinkSource("acf_gearbox", "Wheels")
end ----------------------------------------------------

do -- Inputs -------------------------------------------
	local function SetCanApplyBrakes(Gearbox)
		local CanApply = Gearbox.LBrake ~= 0 or Gearbox.RBrake ~= 0

		if CanApply ~= Gearbox.Braking then
			Gearbox.Braking = CanApply

			ENT_ApplyBrakes(Gearbox)
		end
	end

	ACF.AddInputAction("acf_gearbox", "Gear", function(Entity, Value)
		if Entity.Automatic then
			Entity:ChangeDrive(Value)
		else
			Entity:ChangeGear(Value)
		end
	end)

	ACF.AddInputAction("acf_gearbox", "Gear Up", function(Entity, Value)
		if not tobool(Value) then return end

		if Entity.Automatic then
			Entity:ChangeDrive(Entity.Drive + 1)
		else
			Entity:ChangeGear(Entity.Gear + 1)
		end
	end)

	ACF.AddInputAction("acf_gearbox", "Gear Down", function(Entity, Value)
		if not tobool(Value) then return end

		if Entity.Automatic then
			Entity:ChangeDrive(Entity.Drive - 1)
		else
			Entity:ChangeGear(Entity.Gear - 1)
		end
	end)

	ACF.AddInputAction("acf_gearbox", "Clutch", function(Entity, Value)
		Entity.LClutch = Clamp(1 - Value, 0, 1)
		Entity.RClutch = Clamp(1 - Value, 0, 1)
	end)

	ACF.AddInputAction("acf_gearbox", "Left Clutch", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.LClutch = Clamp(1 - Value, 0, 1)
	end)

	ACF.AddInputAction("acf_gearbox", "Right Clutch", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.RClutch = Clamp(1 - Value, 0, 1)
	end)

	ACF.AddInputAction("acf_gearbox", "Brake", function(Entity, Value)
		Entity.LBrake = Clamp(Value, 0, 10000)
		Entity.RBrake = Clamp(Value, 0, 10000)

		SetCanApplyBrakes(Entity)
	end)

	ACF.AddInputAction("acf_gearbox", "Left Brake", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.LBrake = Clamp(Value, 0, 10000)

		SetCanApplyBrakes(Entity)
	end)

	ACF.AddInputAction("acf_gearbox", "Right Brake", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.RBrake = Clamp(Value, 0, 10000)

		SetCanApplyBrakes(Entity)
	end)

	ACF.AddInputAction("acf_gearbox", "CVT Ratio", function(Entity, Value)
		if not Entity.CVT then return end

		if Entity.GearboxLegacyRatio and Value ~= 0 then Value = 1 / Value end
		Entity.CVTRatio = Value ~= 0 and Clamp(Value, ACF.MinCVTRatio, ACF.MaxCVTRatio) or Value
	end)

	ACF.AddInputAction("acf_gearbox", "Steer Rate", function(Entity, Value)
		if not Entity.DoubleDiff then return end

		Entity.SteerRate = Clamp(Value, -1, 1)
	end)

	ACF.AddInputAction("acf_gearbox", "Hold Gear", function(Entity, Value)
		if not Entity.Automatic then return end

		Entity.Hold = tobool(Value)
	end)

	ACF.AddInputAction("acf_gearbox", "Shift Speed Scale", function(Entity, Value)
		if not Entity.Automatic then return end

		Entity.ShiftScale = Clamp(Value, 0.1, 1.5)
	end)
end ----------------------------------------------------

do -- Linking ------------------------------------------
	local function CheckLoopedGearbox(This, Target)
		local Queued = { [Target] = true }
		local Checked = {}
		local Entity

		while next(Queued) do
			Entity = next(Queued)

			if Entity == This then
				return true
			end

			Checked[Entity] = true
			Queued[Entity]  = nil

			for Gearbox in pairs(Entity.GearboxOut) do
				if not Checked[Gearbox] then
					Queued[Gearbox] = true
				end
			end
		end

		return false
	end

	local function GenerateLinkTable(Entity, Target)
		local InPos = Target.In and Target.In.Pos or Vector()
		local InPosWorld = Target:LocalToWorld(InPos)
		local OutPos, Side

		local Plane
		if Entity:WorldToLocal(InPosWorld).y < 0 then
			Plane = Entity.OutL
			OutPos = Entity.OutL.Pos
			Side = 0
		else
			Plane = Entity.OutR
			OutPos = Entity.OutR.Pos
			Side = 1
		end

		local OutPosWorld = Entity:LocalToWorld(OutPos)
		local Excessive, Angle = ACF.IsDriveshaftAngleExcessive(Target, Target.In, Entity, Plane)
		if Excessive then return nil, Angle end

		local Link	= MobilityObj.Link(Entity, Target)

		Link:SetOrigin(OutPos)
		Link:SetTargetPos(InPos)
		Link:SetAxis(Target.In and Plane.Dir or Target:GetPhysicsObject():WorldToLocalVector(Entity:GetRight()))
		Link.OutDirection = Plane.Dir
		Link.Side = Side
		Link.RopeLen = (OutPosWorld - InPosWorld):Length()

		return Link, Angle
	end

	local function LinkWheel(Gearbox, Wheel)
		if Gearbox.Wheels[Wheel] then return false, "This wheel is already linked to this gearbox!" end
		if Gearbox:GetPos():DistToSqr(Wheel:GetPos()) > MaxDistance then return false, "This wheel is too far away from this gearbox!" end

		local Link, DriveshaftAngle = GenerateLinkTable(Gearbox, Wheel)

		if not Link then return false, "Cannot link due to excessive driveshaft angle! (" .. math.Round(DriveshaftAngle) .. " deg)" end

		Link.LastVel   = 0
		Link.AntiSpazz = 0
		Link.IsBraking = false

		Gearbox.Wheels[Wheel] = Link
		if not Wheel.ACF_Gearboxes then Wheel.ACF_Gearboxes = {} end
		Wheel.ACF_Gearboxes[Gearbox] = Link

		Wheel:CallOnRemove("ACF_GearboxUnlink" .. Gearbox:EntIndex(), function()
			if IsEntityValid(Gearbox) then
				Gearbox:Unlink(Wheel)
			end
		end)

		Gearbox:InvalidateClientInfo()

		return true, "Wheel linked successfully!"
	end

	local function LinkGearbox(Gearbox, Target)
		if Gearbox.GearboxOut[Target] then return false, "These gearboxes are already linked to each other!" end
		if Target.GearboxIn[Gearbox] then return false, "These gearboxes are already linked to each other!" end
		if Gearbox:GetPos():DistToSqr(Target:GetPos()) > MaxDistance then return false, "These gearboxes are too far away from each other!" end
		if CheckLoopedGearbox(Gearbox, Target) then return false, "You cannot link gearboxes in a loop!" end

		local Link, DriveshaftAngle = GenerateLinkTable(Gearbox, Target)

		if not Link then return false, "Cannot link due to excessive driveshaft angle! (" .. math.Round(DriveshaftAngle) .. " deg)" end

		Gearbox.GearboxOut[Target] = Link
		Target.GearboxIn[Gearbox]  = true

		Gearbox:InvalidateClientInfo()

		return true, "Gearbox linked successfully!"
	end

	ACF.RegisterClassLink("acf_gearbox", "prop_physics", LinkWheel)
	ACF.RegisterClassLink("acf_gearbox", "acf_gearbox", LinkGearbox)
	ACF.RegisterClassLink("acf_gearbox", "tire", LinkWheel)
end ----------------------------------------------------

do -- Unlinking ----------------------------------------
	local function UnlinkWheel(Gearbox, Wheel)
		if Gearbox.Wheels[Wheel] then
			local Link = Gearbox.Wheels[Wheel]

			if IsValid(Link.Rope) then
				Link.Rope:Remove()
			end

			Gearbox.Wheels[Wheel] = nil

			Wheel:RemoveCallOnRemove("ACF_GearboxUnlink" .. Gearbox:EntIndex())

			Gearbox:InvalidateClientInfo()

			return true, "Wheel unlinked successfully!"
		end

		if Wheel.ACF_Gearboxes and Wheel.ACF_Gearboxes[Gearbox] then
			Wheel.ACF_Gearboxes[Gearbox] = nil
		end

		return false, "This wheel is not linked to this gearbox!"
	end

	local function UnlinkGearbox(Gearbox, Target)
		local GearboxToTarget = Gearbox.GearboxOut[Target] or Target.GearboxIn[Gearbox]
		local TargetToGearbox = Target.GearboxOut[Gearbox] or Gearbox.GearboxIn[Target]

		if GearboxToTarget or TargetToGearbox then
			local Link = Gearbox.GearboxOut[Target] or Target.GearboxOut[Gearbox]

			if IsValid(Link.Rope) then
				Link.Rope:Remove()
			end

			Gearbox.GearboxIn[Target]  = nil
			Gearbox.GearboxOut[Target] = nil
			Target.GearboxIn[Gearbox]  = nil
			Target.GearboxOut[Gearbox] = nil

			Gearbox:InvalidateClientInfo()

			return true, "Gearbox unlinked successfully!"
		end

		return false, "These gearboxes are not linked to each other!"
	end

	ACF.RegisterClassUnlink("acf_gearbox", "prop_physics", UnlinkWheel)
	ACF.RegisterClassUnlink("acf_gearbox", "acf_gearbox", UnlinkGearbox)
	ACF.RegisterClassUnlink("acf_gearbox", "tire", UnlinkWheel)
end ----------------------------------------------------

do -- Overlay Text -------------------------------------
	function ENT:ACF_UpdateOverlayState(State)
		local Final     = ACF.ConvertGearRatio(self.FinalDrive, self.GearboxLegacyRatio)
		local Torque    = math.Round(self.MaxTorque * ACF.TorqueMult * ACF.NmToFtLb)
		local Output    = math.Round(self.TorqueOutput * ACF.TorqueMult * ACF.NmToFtLb)

		if not GearsText or GearsText == "" then
			local Gears = self.Gears

			GearsText = ""

			for I = 1, self.MaxGear do
				local Ratio = ACF.ConvertGearRatio(Gears[I], self.GearboxLegacyRatio)
				GearsText = GearsText .. "Gear " .. I .. ": " .. Ratio .. "\n"
			end
		end

		local RatioFormat = self.GearboxLegacyRatio and "Driven/Driver (Legacy)" or "Driver/Driven (Realistic)"
		State:AddNumber("Scale", self.ScaleMult)
		State:AddNumber("Current Gear", self.Gear)
		State:AddDivider()
		if self.ClassData.WriteGearOverlay then
			self.ClassData.WriteGearOverlay(self, State)
		else
			local Gears = self.Gears

			for I = 1, self.MaxGear do
				local Ratio = ACF.ConvertGearRatio(Gears[I], self.GearboxLegacyRatio)
				State:AddGearRatio("Gear " .. I, Ratio, "", self.GearboxLegacyRatio)
			end
		end
		State:AddDivider()
		State:AddNumber("Final Drive", Final)
		State:AddKeyValue("Ratio", RatioFormat)
		State:AddKeyValue("Torque Rating", ("%s Nm / %s ft-lb"):format(math.Round(self.MaxTorque * ACF.TorqueMult), Torque))
		State:AddKeyValue("Torque Output", ("%s Nm / %s ft-lb"):format(math.floor(self.TorqueOutput * ACF.TorqueMult), Output))
	end
end ----------------------------------------------------

do -- Gear Shifting ------------------------------------
	local Sounds = Utilities.Sounds

	-- Handles gearing for automatic gearboxes. 0 = Neutral, 1 = Drive, 2 = Reverse
	function ENT:ChangeDrive(Value)
		Value = Clamp(math.floor(Value), 0, 2)

		if self.Drive == Value then return end

		self.Drive = Value

		self:ChangeGear(Value == 2 and self.GearCount or Value)
	end

	function ENT:ChangeGear(Value)
		Value = Clamp(math.floor(Value), self.MinGear, self.GearCount)

		if self.Gear == Value then return end

		self.Gear           = Value
		self.InGear         = false
		self.GearRatio      = self.Gears[Value] * self.FinalDrive
		self.ChangeFinished = Clock.CurTime + self.SwitchTime

		local SoundPath  = self.SoundPath

		if SoundPath ~= "" then
			local Pitch = self.SoundPitch and Clamp(self.SoundPitch * 100, 0, 255) or 100
			local Volume = self.SoundVolume or 0.5

			Sounds.SendSound(self, SoundPath, 70, Pitch, Volume)
		end

		WireLib.TriggerOutput(self, "Current Gear", Value)

		local Ratio = ACF.ConvertGearRatio(self.GearRatio, self.GearboxLegacyRatio)
		WireLib.TriggerOutput(self, "Ratio", Ratio)
	end
end ----------------------------------------------------

do -- Movement -----------------------------------------
	local deg         = math.deg

	function ENT:Calc(InputRPM, InputInertia)
		local SelfTbl = self:GetTable()
		if SelfTbl.Disabled then return 0 end
		if SelfTbl.LastActive == Clock.CurTime then return SelfTbl.TorqueOutput end

		if SelfTbl.ChangeFinished < Clock.CurTime then
			SelfTbl.InGear = true
		end

		local BoxPhys = self:GetAncestor():GetPhysicsObject()
		local SelfWorld = BoxPhys:LocalToWorldVector(BoxPhys:GetAngleVelocity())
		local Gear = SelfTbl.Gear

		if SelfTbl.CVT and Gear == 1 then
			local Gears = SelfTbl.Gears

			if SelfTbl.CVTRatio > 0 then
				Gears[1] = SelfTbl.CVTRatio
			else
				local MinRPM  = SelfTbl.MinRPM
				Gears[1] = 1 / Clamp((InputRPM - MinRPM) / (SelfTbl.MaxRPM - MinRPM), 0.05, 1)
			end

			local GearRatio = Gears[1] * SelfTbl.FinalDrive
			SelfTbl.GearRatio = GearRatio

			if SelfTbl.LastRatio ~= GearRatio then
				SelfTbl.LastRatio = GearRatio
				local Ratio = ACF.ConvertGearRatio(GearRatio, SelfTbl.GearboxLegacyRatio)
				WireLib.TriggerOutput(self, "Ratio", Ratio)
			end
		end

		if SelfTbl.Automatic and SelfTbl.Drive == 1 and SelfTbl.InGear then
			local PhysVel = BoxPhys:GetVelocity():Length()

			if not SelfTbl.Hold and Gear ~= SelfTbl.MaxGear and PhysVel > (SelfTbl.ShiftPoints[Gear] * SelfTbl.ShiftScale) then
				self:ChangeGear(Gear + 1)
			elseif PhysVel < (SelfTbl.ShiftPoints[Gear - 1] * SelfTbl.ShiftScale) then
				self:ChangeGear(Gear - 1)
			end
		end

		local TorqueOutput = 0
		local TotalReqTq = 0
		local LClutch = SelfTbl.LClutch
		local RClutch = SelfTbl.RClutch
		local GearRatio = SelfTbl.GearRatio

		if GearRatio == 0 then return 0 end

		for Ent, Link in pairs(SelfTbl.GearboxOut) do
			local Clutch = Link.Side == 0 and LClutch or RClutch

			Link.ReqTq = 0

			if not Ent.Disabled then
				local Inertia = 0

				if GearRatio ~= 0 then
					Inertia = InputInertia * GearRatio
				end

				Link.ReqTq = abs(Ent:Calc(InputRPM / GearRatio, Inertia) / GearRatio) * Clutch
				TotalReqTq = TotalReqTq + abs(Link.ReqTq)
			end
		end

		local DoubleDiff = SelfTbl.DoubleDiff
		local SteerRate  = SelfTbl.SteerRate

		for Wheel, Link in pairs(SelfTbl.Wheels) do
			Link.ReqTq = 0

			if GearRatio ~= 0 then
				local RPM = CalcWheel(self, Link, Wheel, SelfWorld)
				local Clutch = Link.Side == 0 and LClutch or RClutch
				local OnRPM = ((InputRPM > 0 and RPM < InputRPM) or (InputRPM < 0 and RPM > InputRPM))

				if Clutch > 0 and OnRPM then
					local Multiplier = 1

					if DoubleDiff and SteerRate ~= 0 then
						local Rate = SteerRate * 2

						-- this actually controls the RPM of the wheels, so the steering rate is correct
						if Link.Side == 0 then
							Multiplier = min(0, Rate) + 1
						else
							Multiplier = -max(0, Rate) + 1
						end
					end

					if abs(InputRPM * Multiplier) > abs(RPM) then -- removing this check causes the wheels to constantly invert their rotation
						Link.ReqTq = (InputRPM * Multiplier - RPM) * InputInertia * Clutch
						TotalReqTq = TotalReqTq + abs(Link.ReqTq)
					end
				end
			end
		end

		for Effector, Link in pairs(SelfTbl.Effectors) do
			local Clutch = Link.Side == 0 and LClutch or RClutch

			Link.ReqTq = 0

			if not Effector.Disabled then
				local Inertia = 0

				if GearRatio ~= 0 then
					Inertia = InputInertia * GearRatio
				end

				Link.ReqTq = abs(Effector:Calc(InputRPM / GearRatio, Inertia) / GearRatio) * Clutch
				TotalReqTq = TotalReqTq + abs(Link.ReqTq)
			end
		end

		SelfTbl.TotalReqTq = TotalReqTq
		TorqueOutput = min(TotalReqTq, SelfTbl.MaxTorque)
		SelfTbl.TorqueOutput = TorqueOutput

		self:UpdateOverlay()

		return TorqueOutput
	end

	function ENT:Act(Torque, DeltaTime, MassRatio, FlyRPM)
		local SelfTbl = ENTITY.GetTable(self)
		if SelfTbl.Disabled then return end

		if Torque == 0 then
			SelfTbl.LastActive = Clock.CurTime
			return
		end

		local Loss = Clamp(((1 - 0.4) / 0.5) * ((SelfTbl.ACF.Health / SelfTbl.ACF.MaxHealth) - 1) + 1, 0.4, 1) -- Internal torque loss from damage
		local Slop = SelfTbl.Automatic and 0.9 or 1 -- Internal torque loss from inefficiency
		local ReactTq = 0
		-- Calculate the ratio of total requested torque versus what's available, and then multiply it by the current gear ratio
		local AvailTq = 0
		local GearRatio = SelfTbl.GearRatio

		if Torque ~= 0 and GearRatio ~= 0 then
			AvailTq = min(abs(Torque) / SelfTbl.TotalReqTq, 1) * GearRatio * -(-Torque / abs(Torque)) * Loss * Slop
		end

		for Ent, Link in pairs(SelfTbl.GearboxOut) do
			Link:TransferGearbox(Ent, Link.ReqTq * AvailTq, DeltaTime, MassRatio, FlyRPM)
			--Ent:Act(Link.ReqTq * AvailTq, DeltaTime, MassRatio)
		end

		local Braking = SelfTbl.Braking

		for Ent, Link in pairs(SelfTbl.Wheels) do
			-- If the gearbox is braking, always
			if not Braking or not Link.IsBraking then
				local WheelTorque = Link.ReqTq * AvailTq
				ReactTq = ReactTq + WheelTorque

				Link:TransferWheel(Ent, WheelTorque, DeltaTime)
				--ActWheel(Link, Ent, WheelTorque, DeltaTime)
			end
		end

		if ReactTq ~= 0 then
			local BoxPhys = ENTITY.GetPhysicsObject(ENTITY.GetAncestor(self))

			if IsPhysObjValid(BoxPhys) then
				local RightDir = ENTITY.GetRight(self)
				VECTOR.Mul(RightDir, Clamp(2 * deg(ReactTq * MassRatio) * DeltaTime, -500000, 500000))
				PHYSOBJ.ApplyTorqueCenter(BoxPhys, RightDir)
			end
		end

		for Effector, Link in pairs(SelfTbl.Effectors) do
			Link:TransferEffector(Effector, Link.ReqTq * AvailTq, DeltaTime, MassRatio, FlyRPM)
		end

		SelfTbl.LastActive = Clock.CurTime
	end
end ----------------------------------------------------

do -- Braking ------------------------------------------
	local function BrakeWheel(Link, Wheel, Brake)
		local Phys      = ENTITY.GetPhysicsObject(Wheel)
		local AntiSpazz = 1

		if not PHYSOBJ.IsMotionEnabled(Phys) then return end -- skipping entirely if its frozen

		if Brake > 100 then
			local Overshot = abs(Link.LastVel - Link.Vel) > abs(Link.LastVel) -- Overshot the brakes last tick?
			local Rate     = Overshot and 0.2 or 0.002 -- If we overshot, cut back agressively, if we didn't, add more brakes slowly

			Link.AntiSpazz = (1 - Rate) * Link.AntiSpazz + (Overshot and 0 or Rate) -- Low pass filter on the antispazz

			AntiSpazz = min(Link.AntiSpazz * 10000 / Brake, 1) -- Anti-spazz relative to brake power
		end

		Link.LastVel = Link.Vel

		-- creates negative copy, then performs in-place multiplication to not create as much garbage
		local AngleVelocity = -Link.Axis
		VECTOR.Mul(AngleVelocity, Link.Vel)
		VECTOR.Mul(AngleVelocity, AntiSpazz)
		VECTOR.Mul(AngleVelocity, Brake)
		VECTOR.Mul(AngleVelocity, 0.01)

		PHYSOBJ.AddAngleVelocity(Phys, AngleVelocity)
	end

	function ENT_ApplyBrakes(self) -- This is just for brakes
		local SelfTbl = ENTITY.GetTable(self)

		if SelfTbl.Disabled then return end -- Illegal brakes man
		if not SelfTbl.Braking then return end -- Kills the whole thing if its not supposed to be running
		if not next(SelfTbl.Wheels) then return end -- No brakes for the non-wheel users
		if SelfTbl.LastBrake == Clock.CurTime then return end -- Don't run this twice in a tick

		local BoxPhys = ENTITY.GetPhysicsObject(ENTITY.GetAncestor(self))
		if not IsPhysObjValid(BoxPhys) then return end -- Fixes an issue I had where deleting a contraption while driving it threw an error

		local SelfWorld = PHYSOBJ.LocalToWorldVector(BoxPhys, PHYSOBJ.GetAngleVelocity(BoxPhys))
		local DeltaTime = Clock.DeltaTime

		for Wheel, Link in pairs(SelfTbl.Wheels) do
			local Brake = Link.Side == 0 and SelfTbl.LBrake or SelfTbl.RBrake

			if Brake > 0 then -- regular ol braking
				Link.IsBraking = true
				CalcWheel(self, Link, Wheel, SelfWorld) -- Updating the link velocity
				BrakeWheel(Link, Wheel, Brake, DeltaTime)
			else
				Link.IsBraking = false
			end
		end

		SelfTbl.LastBrake = Clock.CurTime

		timer.Simple(DeltaTime, function()
			if not IsEntityValid(self) then return end

			ENT_ApplyBrakes(self)
		end)
	end
	ENT.ApplyBrakes = ENT_ApplyBrakes
end ----------------------------------------------------

do -- Duplicator Support -------------------------------
	function ENT:PreEntityCopy()
		if next(self.Wheels) then
			local Wheels = {}

			for Ent in pairs(self.Wheels) do
				Wheels[#Wheels + 1] = Ent:EntIndex()
			end

			duplicator.StoreEntityModifier(self, "ACFWheels", Wheels)
		end

		if next(self.GearboxOut) then
			local Entities = {}

			for Ent in pairs(self.GearboxOut) do
				Entities[#Entities + 1] = Ent:EntIndex()
			end

			duplicator.StoreEntityModifier(self, "ACFGearboxes", Entities)
		end

		if next(self.Effectors) then
			local Entities = {}

			for Ent in pairs(self.Effectors) do
				Entities[#Entities + 1] = Ent:EntIndex()
			end

			duplicator.StoreEntityModifier(self, "ACFEffectors", Entities)
		end

		-- AutoRegisterV2 wraps this as the original PreEntityCopy and handles the wire/base dupe info.
	end

	function ENT:PostEntityPaste(_, Ent, CreatedEntities)
		local EntMods = Ent.EntityMods

		-- Backwards compatibility
		if EntMods.WheelLink then
			local Entities = EntMods.WheelLink.entities

			for _, EntID in ipairs(Entities) do
				self:Link(CreatedEntities[EntID])
			end

			EntMods.WheelLink = nil
		end

		if EntMods.ACFWheels then
			for _, EntID in ipairs(EntMods.ACFWheels) do
				self:Link(CreatedEntities[EntID])
			end

			EntMods.ACFWheels = nil
		end

		if EntMods.ACFGearboxes then
			for _, EntID in ipairs(EntMods.ACFGearboxes) do
				self:Link(CreatedEntities[EntID])
			end

			EntMods.ACFGearboxes = nil
		end

		if EntMods.ACFEffectors then
			for _, EntID in ipairs(EntMods.ACFEffectors) do
				self:Link(CreatedEntities[EntID])
			end

			EntMods.ACFEffectors = nil
		end

		-- AutoRegisterV2 wraps this as the original PostEntityPaste and handles the wire/base dupe info.
	end
end ----------------------------------------------------

do	-- NET SURFER 2.0
	util.AddNetworkString("ACF_RequestGearboxInfo")
	util.AddNetworkString("ACF_InvalidateGearboxInfo")

	function ENT:InvalidateClientInfo()
		net.Start("ACF_InvalidateGearboxInfo")
			net.WriteEntity(self)
		net.Broadcast()
	end

	net.Receive("ACF_RequestGearboxInfo", function(_, Ply)
		local Entity = net.ReadEntity()

		if IsEntityValid(Entity) then
			local Inputs = {}
			local OutputL = {}
			local OutputR = {}
			local In = Entity.In.Pos
			local OutL = Entity.OutL.Pos
			local OutR = Entity.OutR.Pos

			local SingleTargets, CoupleTargets =
				{ Entity.GearboxIn, Entity.Engines },
				{ Entity.GearboxOut, Entity.Wheels, Entity.Effectors }

			for _, Singles in ipairs(SingleTargets) do
				if next(Singles) then
					for E in pairs(Singles) do
						Inputs[#Inputs + 1] = E:EntIndex()
					end
				end
			end

			for _, Couples in ipairs(CoupleTargets) do
				if next(Couples) then
					for E, L in pairs(Couples) do
						if L.Side == 0 then
							OutputL[#OutputL + 1] = E:EntIndex()
						else
							OutputR[#OutputR + 1] = E:EntIndex()
						end
					end
				end
			end

			net.Start("ACF_RequestGearboxInfo")
				net.WriteEntity(Entity)

				net.WriteVector(In)
				net.WriteVector(OutL)
				net.WriteVector(OutR)

				net.WriteUInt(#Inputs, 6)
				net.WriteUInt(#OutputL, 6)
				net.WriteUInt(#OutputR, 6)

				if next(Inputs) then
					for _, E in ipairs(Inputs) do
						net.WriteUInt(E, MAX_EDICT_BITS)
					end
				end

				if next(OutputL) then
					for _, E in ipairs(OutputL) do
						net.WriteUInt(E, MAX_EDICT_BITS)
					end
				end

				if next(OutputR) then
					for _, E in ipairs(OutputR) do
						net.WriteUInt(E, MAX_EDICT_BITS)
					end
				end
			net.Send(Ply)
		end
	end)
end

do -- Miscellaneous ------------------------------------
	function ENT:Enable()
		if self.Automatic then
			self:ChangeDrive(self.OldGear)
		else
			self:ChangeGear(self.OldGear)
		end

		self.OldGear = nil

		self:UpdateOverlay()
	end

	function ENT:Disable()
		self.OldGear = self.Automatic and self.Drive or self.Gear

		if self.Automatic then
			self:ChangeDrive(0)
		else
			self:ChangeGear(0)
		end

		self:UpdateOverlay()
	end

	-- Prevent people from changing bodygroup
	function ENT:CanProperty(_, Property)
		return Property ~= "bodygroups"
	end

	-- Remove-only teardown. Captured by AutoRegisterV2 as OrigOnRemove; the generated OnRemove runs
	-- ACF_OnEntityLast (which fires the gearbox class' OnLast) + WireLib cleanup around this.
	function ENT:OnRemove(IsFullUpdate)
		if IsFullUpdate then return end

		for Engine in pairs(self.Engines) do
			self:Unlink(Engine)
		end

		for Wheel in pairs(self.Wheels) do
			self:Unlink(Wheel)
		end

		for Gearbox in pairs(self.GearboxIn) do
			Gearbox:Unlink(self)
		end

		for Gearbox in pairs(self.GearboxOut) do
			self:Unlink(Gearbox)
		end

		for Effector in pairs(self.Effectors) do
			self:Unlink(Effector)
		end

		timer.Remove("ACF Gearbox Clock " .. self:EntIndex())
	end
end ----------------------------------------------------
