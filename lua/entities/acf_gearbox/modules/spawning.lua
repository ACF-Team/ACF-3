local ACF         = ACF
local Contraption = ACF.Contraption
local Utilities   = ACF.Utilities
local Notify      = Utilities.Notify

local Clamp = math.Clamp
local Round = math.Round
local max   = math.max
local abs   = math.abs

local IsEntityValid  = ACF.Optimizations.IsEntityValid
local IsPhysObjValid = ACF.Optimizations.IsPhysObjValid

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

		if Class.CanSetGears and ClientData.GearAmount ~= nil then
			local Requested = ACF.CheckNumber(ClientData.GearAmount, Class.Gears.Max)
			ClientData.GearAmount = Clamp(Round(Requested), max(1, Class.Gears.Min), Class.Gears.Max)
		end

		local MaxGears = Class.CanSetGears and (Class.MaxGear or ClientData.GearAmount or Class.Gears.Max) or Class.Gears.Max
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
				Gear = Round(1 / Gear, 2)
			end

			Gears[I] = Round(Gear, 3)
		end

		for I = MaxGears + 1, #Gears do Gears[I] = nil end

		ClientData.Gears = Gears

		local Final = ACF.CheckNumber(ClientData.FinalDrive)
		if not Final then
			Final = ACF.CheckNumber(ClientData.Gear0, 1)
			ClientData.Gear0 = nil
		end

		if Invert and Final ~= 0 and abs(Final) < 1 then
			Final = Round(1 / Final, 2)
		end

		ClientData.FinalDrive = Round(Final, 3)

		-- Class-specific verification (automatic ShiftPoints/Reverse, CVT MinRPM/MaxRPM).
		if Class.VerifyData then Class.VerifyData(ClientData, Class) end
	end

	local function GetMass(Model, PhysObj, Class, Gearbox, ScaledMass)
		if Gearbox then return ScaledMass end

		local Volume = PhysObj:GetVolume()
		local Factor = Volume / ModelData.GetModelVolume(Model)

		return Round(Class.Mass * Factor)
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

		Entity:ACF_SetEntityName("ACF " .. Entity.Name)

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

	function ENT:UpdateDriverMod()
		local Contraption = self:CFW_GetContraption()
		local Baseplate = Contraption and Contraption.ACF_Baseplate
		local Val = IsEntityValid(Baseplate) and Baseplate.DriverCrewMod or ACF.CrewFallbackCoef
		self.DriverCrewMod = Clamp(Val, ACF.CrewFallbackCoef, 1)
		return self.DriverCrewMod
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
				local Stress = max(WheelPhys:GetStress())
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
		self.DriverCrewMod = ACF.CrewFallbackCoef

		-- Drivers let gearboxes apply full torque to wheels; poll the baseplate's driver crew.
		ACF.AugmentedTimer(function(cfg) self:UpdateDriverMod(cfg) end, function() return IsEntityValid(self) end, nil, {MinTime = 0.1, MaxTime = 0.25})
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
