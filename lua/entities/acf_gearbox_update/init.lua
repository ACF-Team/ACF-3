DEFINE_BASECLASS("acf_base_simple") -- Required to get the local BaseClass

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local variables ---------------------------------

local ACF       = ACF
local Contraption	= ACF.Contraption
local Utilities = ACF.Utilities
local Clock     = Utilities.Clock
local Clamp     = math.Clamp
local abs       = math.abs
local min       = math.min
local HookRun   = hook.Run

local function CalcWheel(Entity, Link, Wheel, SelfWorld)
	local WheelPhys = Wheel:GetPhysicsObject()
	local VelDiff = WheelPhys:LocalToWorldVector(WheelPhys:GetAngleVelocity()) - SelfWorld
	local BaseRPM = VelDiff:Dot(WheelPhys:LocalToWorldVector(Link.Axis))
	local GearRatio = Entity.GearRatio

	Link.Vel = BaseRPM

	if GearRatio == 0 then return 0 end

	-- Reported BaseRPM is in angle per second and in the wrong direction, so we convert
	return BaseRPM / -6
end

do -- Spawn and Update functions -----------------------
	local Classes   = ACF.Classes
	local WireIO    = Utilities.WireIO
	local Gearboxes = Classes.Gearboxes
	local Entities  = Classes.Entities

	local Inputs = {
		"Gear (Changes the current gear to the given value.)",
		"Gear Up (Attempts to shift up the current gear.)",
		"Gear Down (Attempts to shift down the current gear.)",
	}
	local Outputs = {
		"Current Gear (Returns the gear currently in use.)",
		"Ratio (Returns the current gear ratio, based on the current gear and final drive.)",
		"Entity (The gearbox itself.) [ENTITY]",
		"RPM (The RPM of the gearbox.)",
		"Output Torque (The amount of torque leaving the gearbox.)",
	}

	local function VerifyData(Data)
		if not Data.Gearbox then
			Data.Gearbox = Data.Id or "2Gear-T-S"
		end

		local Class = Classes.GetGroup(Gearboxes, Data.Gearbox)

		if not Class then
			Data.Gearbox = "2Gear-T-S"

			Class = Classes.GetGroup(Gearboxes, "2Gear-T-S")
		end

		do -- Gears table verification
			local Gears = Data.Gears

			if not istable(Gears) then
				Gears = { [0] = 0 }

				Data.Gears = Gears
			else
				Gears[0] = 0
			end

			for I = 1, Class.Gears.Max do
				local Gear = ACF.CheckNumber(Gears[I])

				if not Gear then
					Gear = ACF.CheckNumber(Data["Gear" .. I], I * 0.1)

					Data["Gear" .. I] = nil
				end

				Gears[I] = Clamp(Gear, -10, 10)
			end
		end

		do -- Final drive verification
			local Final = ACF.CheckNumber(Data.FinalDrive)

			if not Final then
				Final = ACF.CheckNumber(Data.Gear0, 1)

				Data.Gear0 = nil
			end

			Data.FinalDrive = Clamp(Final, -10, 10)
		end

		do -- External verifications
			if Class.VerifyData then
				Class.VerifyData(Data, Class)
			end

			HookRun("ACF_VerifyData", "acf_gearbox_update", Data, Class)
		end
	end

	local function UpdateGearbox(Entity, Data, Class, Gearbox)
		local Mass = Gearbox.Mass

		Entity.ACF = Entity.ACF or {}

		Contraption.SetModel(Entity, Gearbox.Model)

		Entity:PhysicsInit(SOLID_VPHYSICS)
		Entity:SetMoveType(MOVETYPE_VPHYSICS)

		-- Storing all the relevant information on the entity for duping
		for _, V in ipairs(Entity.DataStore) do
			Entity[V] = Data[V]
		end

		Entity.Name         = Gearbox.Name
		Entity.ShortName    = Gearbox.ID
		Entity.EntType      = Class.Name
		Entity.ClassData    = Class
		Entity.DefaultSound = Class.Sound
		Entity.SwitchTime   = Gearbox.Switch
		Entity.MaxTorque    = Gearbox.MaxTorque
		Entity.MinGear      = Class.Gears.Min
		Entity.MaxGear      = Class.Gears.Max
		Entity.GearCount    = Entity.MaxGear
		Entity.DualClutch   = Gearbox.DualClutch
		Entity.In           = Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("input")).Pos)
		Entity.OutL         = Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("driveshaftL")).Pos)
		Entity.OutR         = Entity:WorldToLocal(Entity:GetAttachment(Entity:LookupAttachment("driveshaftR")).Pos)
		Entity.HitBoxes     = ACF.GetHitboxes(Gearbox.Model)

		WireIO.SetupInputs(Entity, Inputs, Data, Class, Gearbox)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Gearbox)

		Entity:SetNWString("WireName", "ACF " .. Entity.Name)

		ACF.Activate(Entity, true)

		Contraption.SetMass(Entity, Mass)

		Entity:ChangeGear(1)

		-- ChangeGear doesn't update GearRatio if the gearbox is already in gear 1
		Entity.GearRatio = Entity.Gears[1] * Entity.FinalDrive
	end

	local function CheckRopes(Entity, Target)
		local Ropes = Entity[Target]

		if not next(Ropes) then return end

		for Ent, Link in pairs(Ropes) do
			local OutPos = Entity:LocalToWorld(Link.Output)
			local InPos = Ent.In and Ent:LocalToWorld(Ent.In) or Ent:GetPos()

			-- make sure it is not stretched too far
			if OutPos:Distance(InPos) > Link.RopeLen * 1.5 then
				Entity:Unlink(Ent)
				continue
			end

			-- make sure the angle is not excessive
			local DrvAngle = (OutPos - InPos):GetNormalized():Dot((Entity:GetRight() * Link.Output.y):GetNormalized())

			if DrvAngle < 0.7 then
				Entity:Unlink(Ent)
			end
		end
	end

	-- Some information may still be passed from the menu tool
	-- We don't want to save it on the entity if it's not needed
	local function CleanupData(Class, Gearbox)
		if Class ~= "acf_gearbox_update" then return end

		if not Gearbox.Automatic then
			Gearbox.Reverse = nil
		end

		if not Gearbox.CVT then
			Gearbox.MinRPM = nil
			Gearbox.MaxRPM = nil
		end

		if Gearbox.DualClutch then
			Gearbox:SetBodygroup(1, 1)
		end
	end

	hook.Add("ACF_OnEntitySpawn", "ACF Cleanup Gearbox Data", CleanupData)
	hook.Add("ACF_OnEntityUpdate", "ACF Cleanup Gearbox Data", CleanupData)
	hook.Add("ACF_OnSetupInputs", "ACF Cleanup Gearbox Data", function(Entity, List)
		if Entity:GetClass() ~= "acf_gearbox_update" and Entity:GetClass() ~= "acf_gearbox" then return end

		local Count = #List

		if Entity.DualClutch then
			List[Count + 1] = "Left Clutch (Sets the percentage of power, from 0 to 1, that will not be passed to the left side output.)"
			List[Count + 2] = "Right Clutch (Sets the percentage of power, from 0 to 1, that will not be passed to the right side output.)"
			List[Count + 3] = "Left Brake (Sets the amount of power given to the left side brakes.)"
			List[Count + 4] = "Right Brake (Sets the amount of power given to the right side brakes.)"
		else
			List[Count + 1] = "Clutch (Sets the percentage of power, from 0 to 1, that will not be passed to the output.)"
			List[Count + 2] = "Brake (Sets the amount of power given to the brakes.)"
		end
	end)
	hook.Add("ACF_OnEntityLast", "ACF Cleanup Gearbox Data", function(Class, Gearbox)
		if Class ~= "acf_gearbox_update" and Class ~= "acf_gearbox" then return end

		Gearbox:SetBodygroup(1, 0)
	end)

	-------------------------------------------------------------------------------

	function MakeACF_Gearbox(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class   = Classes.GetGroup(Gearboxes, Data.Gearbox)
		local Gearbox = Gearboxes.GetItem(Class.ID, Data.Gearbox)
		local Limit   = Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return end

		local CanSpawn = HookRun("ACF_PreEntitySpawn", "acf_gearbox_update", Player, Data, Class, Gearbox)

		if CanSpawn == false then return false end

		local Entity = ents.Create("acf_gearbox_update")

		if not IsValid(Entity) then return end

		Entity:SetPlayer(Player)
		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Player:AddCleanup("acf_gearbox_update", Entity)
		Player:AddCount(Limit, Entity)

		Entity.Owner          = Player -- MUST be stored on ent for PP
		Entity.SoundPath      = Class.Sound
		Entity.Engines        = {}
		Entity.Wheels         = {} -- a "Link" has these components: Ent, Side, Axis, Rope, RopeLen, Output, ReqTq, Vel
		Entity.GearboxIn      = {}
		Entity.GearboxOut     = {}
		Entity.TotalReqTq     = 0
		Entity.TorqueOutput   = 0
		Entity.LBrake         = 0
		Entity.RBrake         = 0
		Entity.ChangeFinished = 0
		Entity.InGear         = false
		Entity.Braking        = false
		Entity.LastBrake      = 0
		Entity.LastActive     = 0
		Entity.Clutch		  = 1 -- Clutch just for gearbox and engine connections
		Entity.LClutch        = 1 -- Strictly for dual clutch gearboxes
		Entity.RClutch        = 1 -- Strictly for dual clutch gearboxes
		Entity.Load			  = 0 -- If the gearbox is connected to a load. ( Wheels for example. )
		Entity.DataStore      = Entities.GetArguments("acf_gearbox_update")
		Entity.InputRPM		  = 0
		Entity.OutputRPM	  = 0
		Entity.TorqueInput    = 0
		Entity.TorqueOutput   = 0
		Entity.Inertia		  = 0
		Entity.IsDualClutch   = Gearbox.DualClutch and true or false
		Entity.TotalRatio 	  = 0

		UpdateGearbox(Entity, Data, Class, Gearbox)

		WireLib.TriggerOutput(Entity, "Entity", Entity)

		if Class.OnSpawn then
			Class.OnSpawn(Entity, Data, Class, Gearbox)
		end

		HookRun("ACF_OnEntitySpawn", "acf_gearbox_update", Entity, Data, Class, Gearbox)

		Entity:UpdateOverlay(true)

		do -- Mass entity mod removal
			local EntMods = Data and Data.EntityMods

			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		ACF.CheckLegal(Entity)

		timer.Create("ACF Gearbox Clock " .. Entity:EntIndex(), 3, 0, function()
			if IsValid(Entity) then
				CheckRopes(Entity, "GearboxOut")
				CheckRopes(Entity, "Wheels")
			else
				timer.Remove("ACF Gearbox Clock " .. Entity:EntIndex())
			end
		end)

		return Entity
	end

	Entities.Register("acf_gearbox_update", MakeACF_Gearbox, "Gearbox", "Gears", "FinalDrive", "ShiftPoints", "Reverse", "MinRPM", "MaxRPM")

	ACF.RegisterLinkSource("acf_gearbox_update", "GearboxIn")
	ACF.RegisterLinkSource("acf_gearbox_update", "GearboxOut")
	ACF.RegisterLinkSource("acf_gearbox_update", "Engines")
	ACF.RegisterLinkSource("acf_gearbox_update", "Wheels")

	------------------- Updating ---------------------

	function ENT:Update(Data)
		VerifyData(Data)

		local Class    = Classes.GetGroup(Gearboxes, Data.Gearbox)
		local Gearbox  = Class.Lookup[Data.Gearbox]
		local OldClass = self.ClassData
		local Feedback = ""

		local CanUpdate, Reason = HookRun("ACF_PreEntityUpdate", "acf_gearbox_update", self, Data, Class, Gearbox)
		if CanUpdate == false then return CanUpdate, Reason end

		if OldClass.OnLast then
			OldClass.OnLast(self, OldClass)
		end

		HookRun("ACF_OnEntityLast", "acf_gearbox_update", self, OldClass)

		ACF.SaveEntity(self)

		UpdateGearbox(self, Data, Class, Gearbox)

		ACF.RestoreEntity(self)

		if Class.OnUpdate then
			Class.OnUpdate(self, Data, Class, Gearbox)
		end

		HookRun("ACF_OnEntityUpdate", "acf_gearbox_update", self, Data, Class, Gearbox)

		if next(self.Engines) then
			local Count, Total = 0, 0

			for Engine in pairs(self.Engines) do
				self:Unlink(Engine)

				local Result = self:Link(Engine)

				if not Result then Count = Count + 1 end

				Total = Total + 1
			end

			if Count == Total then
				Feedback = Feedback .. "\nUnlinked all engines due to excessive driveshaft angle."
			elseif Count > 0 then
				local Text = Feedback .. "\nUnlinked %s out of %s engines due to excessive driveshaft angle."

				Feedback = Text:format(Count, Total)
			end
		end

		if next(self.Wheels) then
			local Count, Total = 0, 0

			for Wheel in pairs(self.Wheels) do
				self:Unlink(Wheel)

				local Result = self:Link(Wheel)

				if not Result then Count = Count + 1 end

				Total = Total + 1
			end

			if Count == Total then
				Feedback = Feedback .. "\nUnlinked all wheels due to excessive driveshaft angle."
			elseif Count > 0 then
				local Text = Feedback .. "\nUnlinked %s out of %s wheels due to excessive driveshaft angle."

				Feedback = Text:format(Count, Total)
			end
		end

		if next(self.GearboxIn) or next(self.GearboxOut) then
			local Count, Total = 0, 0

			for Entity in pairs(self.GearboxIn) do
				Entity:Unlink(self)

				local Result = Entity:Link(self)

				if not Result then Count = Count + 1 end

				Total = Total + 1
			end

			for Entity in pairs(self.GearboxOut) do
				self:Unlink(Entity)

				local Result = self:Link(Entity)

				if not Result then Count = Count + 1 end

				Total = Total + 1
			end

			if Count == Total then
				Feedback = Feedback .. "\nUnlinked all gearboxes due to excessive driveshaft angle."
			elseif Count > 0 then
				local Text = Feedback .. "\nUnlinked %s out of %s gearboxes due to excessive driveshaft angle."

				Feedback = Text:format(Count, Total)
			end
		end

		self:UpdateOverlay(true)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		return true, "Gearbox updated successfully!" .. Feedback
	end
end ----------------------------------------------------

do -- Inputs -------------------------------------------
	local function SetCanApplyBrakes(Gearbox)
		local CanApply = Gearbox.LBrake ~= 0 or Gearbox.RBrake ~= 0

		if CanApply ~= Gearbox.Braking then
			Gearbox.Braking = CanApply

			Gearbox:ApplyBrakes()
		end
	end

	ACF.AddInputAction("acf_gearbox_update", "Gear", function(Entity, Value)
		if Entity.Automatic then
			Entity:ChangeDrive(Value)
		else
			Entity:ChangeGear(Value)
		end
	end)

	ACF.AddInputAction("acf_gearbox_update", "Gear Up", function(Entity, Value)
		if not tobool(Value) then return end

		if Entity.Automatic then
			Entity:ChangeDrive(Entity.Drive + 1)
		else
			Entity:ChangeGear(Entity.Gear + 1)
		end
	end)

	ACF.AddInputAction("acf_gearbox_update", "Gear Down", function(Entity, Value)
		if not tobool(Value) then return end

		if Entity.Automatic then
			Entity:ChangeDrive(Entity.Drive - 1)
		else
			Entity:ChangeGear(Entity.Gear - 1)
		end
	end)

	ACF.AddInputAction("acf_gearbox_update", "Clutch", function(Entity, Value)
		Entity.Clutch = Clamp( 1 - Value, 0, 1)
	end)

	ACF.AddInputAction("acf_gearbox_update", "Left Clutch", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.LClutch = Clamp(1 - Value, 0, 1)
	end)

	ACF.AddInputAction("acf_gearbox_update", "Right Clutch", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.RClutch = Clamp(1 - Value, 0, 1)
	end)

	ACF.AddInputAction("acf_gearbox_update", "Brake", function(Entity, Value)
		Entity.LBrake = Clamp(Value, 0, 10000)
		Entity.RBrake = Clamp(Value, 0, 10000)

		SetCanApplyBrakes(Entity)
	end)

	ACF.AddInputAction("acf_gearbox_update", "Left Brake", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.LBrake = Clamp(Value, 0, 10000)

		SetCanApplyBrakes(Entity)
	end)

	ACF.AddInputAction("acf_gearbox_update", "Right Brake", function(Entity, Value)
		if not Entity.DualClutch then return end

		Entity.RBrake = Clamp(Value, 0, 10000)

		SetCanApplyBrakes(Entity)
	end)

	ACF.AddInputAction("acf_gearbox_update", "CVT Ratio", function(Entity, Value)
		if not Entity.CVT then return end

		Entity.CVTRatio = Clamp(Value, 0, 1)
	end)

	ACF.AddInputAction("acf_gearbox_update", "Steer Rate", function(Entity, Value)
		if not Entity.DoubleDiff then return end

		Entity.SteerRate = Clamp(Value, -1, 1)
	end)

	ACF.AddInputAction("acf_gearbox_update", "Hold Gear", function(Entity, Value)
		if not Entity.Automatic then return end

		Entity.Hold = tobool(Value)
	end)

	ACF.AddInputAction("acf_gearbox_update", "Shift Speed Scale", function(Entity, Value)
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
		local InPos = Target.In or Vector()
		local InPosWorld = Target:LocalToWorld(InPos)
		local OutPos, Side

		if Entity:WorldToLocal(InPosWorld).y < 0 then
			OutPos = Entity.OutL
			Side = 0
		else
			OutPos = Entity.OutR
			Side = 1
		end

		local OutPosWorld = Entity:LocalToWorld(OutPos)
		local DrvAngle = (OutPosWorld - InPosWorld):GetNormalized():Dot((Entity:GetRight() * OutPos.y):GetNormalized())

		if DrvAngle < 0.7 then return end

		local Rope

		if Entity.Owner:GetInfoNum("ACF_MobilityRopeLinks", 1) ~= 0 then
			Rope = constraint.CreateKeyframeRope(OutPosWorld, 1, "cable/cable2", nil, Entity, OutPos, 0, Target, InPos, 0)
		end

		local Phys = Target:GetPhysicsObject()
		local Axis = Phys:WorldToLocalVector(Entity:GetRight())

		return {
			Side = Side,
			Axis = Axis,
			Rope = Rope,
			RopeLen = (OutPosWorld - InPosWorld):Length(),
			Output = OutPos,
			ReqTq = 0,
			Vel = 0
		}
	end

	local function LinkWheel(Gearbox, Wheel)
		if Gearbox.Wheels[Wheel] then return false, "This wheel is already linked to this gearbox!" end

		local Link = GenerateLinkTable(Gearbox, Wheel)

		if not Link then return false, "Cannot link due to excessive driveshaft angle!" end

		Link.LastVel   = 0
		Link.AntiSpazz = 0
		Link.IsBraking = false

		Gearbox.Wheels[Wheel] = Link

		Wheel:CallOnRemove("ACF_GearboxUnlink" .. Gearbox:EntIndex(), function()
			if IsValid(Gearbox) then
				Gearbox:Unlink(Wheel)
			end
		end)

		return true, "Wheel linked successfully!"
	end

	local function LinkGearbox(Gearbox, Target)
		if Gearbox.GearboxOut[Target] then return false, "These gearboxes are already linked to each other!" end
		if Target.GearboxIn[Gearbox] then return false, "These gearboxes are already linked to each other!" end
		if CheckLoopedGearbox(Gearbox, Target) then return false, "You cannot link gearboxes in a loop!" end

		local Link = GenerateLinkTable(Gearbox, Target)

		if not Link then return false, "Cannot link due to excessive driveshaft angle!" end

		Gearbox.GearboxOut[Target] = Link
		Target.GearboxIn[Gearbox]  = true

		return true, "Gearbox linked successfully!"
	end

	ACF.RegisterClassLink("acf_gearbox_update", "prop_physics", LinkWheel)
	ACF.RegisterClassLink("acf_gearbox_update", "acf_gearbox_update", LinkGearbox)
	ACF.RegisterClassLink("acf_gearbox_update", "tire", LinkWheel)
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

			return true, "Wheel unlinked successfully!"
		end

		return false, "This wheel is not linked to this gearbox!"
	end

	local function UnlinkGearbox(Gearbox, Target)
		if Gearbox.GearboxOut[Target] or Target.GearboxIn[Gearbox] then
			local Link = Gearbox.GearboxOut[Target]

			if IsValid(Link.Rope) then
				Link.Rope:Remove()
			end

			Gearbox.GearboxOut[Target] = nil
			Target.GearboxIn[Gearbox]  = nil

			return true, "Gearbox unlinked successfully!"
		end

		return false, "That gearboxes are not linked to each other!"
	end

	ACF.RegisterClassUnlink("acf_gearbox_update", "prop_physics", UnlinkWheel)
	ACF.RegisterClassUnlink("acf_gearbox_update", "acf_gearbox_update", UnlinkGearbox)
	ACF.RegisterClassUnlink("acf_gearbox_update", "tire", UnlinkWheel)
end ----------------------------------------------------

do -- Overlay Text -------------------------------------
	local Text = "%s\nCurrent Gear: %s\n\n%s\nFinal Drive: %s\nTorque Rating: %s Nm / %s fl-lb\nTorque Output: %s Nm / %s fl-lb"

	function ENT:UpdateOverlayText()
		local GearsText = self.ClassData.GetGearsText and self.ClassData.GetGearsText(self)
		local Final     = math.Round(self.FinalDrive, 2)
		local Torque    = math.Round(self.MaxTorque * 0.73)
		local Output    = math.Round(self.TorqueOutput * 0.73)

		if not GearsText or GearsText == "" then
			local Gears = self.Gears

			GearsText = ""

			for I = 1, self.MaxGear do
				GearsText = GearsText .. "Gear " .. I .. ": " .. math.Round(Gears[I], 2) .. "\n"
			end
		end

		return Text:format(self.Name, self.Gear, GearsText, Final, self.MaxTorque, Torque, math.floor(self.TorqueOutput), Output)
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

		if self.SoundPath ~= "" then
			Sounds.SendSound(self, self.SoundPath, 70, 100, 0.5)
		end

		WireLib.TriggerOutput(self, "Current Gear", Value)
		WireLib.TriggerOutput(self, "Ratio", self.GearRatio)
	end
end ----------------------------------------------------

do -- Movement -----------------------------------------
	local deg         = math.deg

	local function ActWheel(Link, Wheel, Torque, DeltaTime)
		local Phys = Wheel:GetPhysicsObject()

		if not Phys:IsMotionEnabled() then return end -- skipping entirely if its frozen

		local TorqueAxis = Phys:LocalToWorldVector(Link.Axis)
		Phys:ApplyTorqueCenter(TorqueAxis * Clamp(deg(-Torque * 1.5) * DeltaTime, -500000, 500000)) -- Do tests to see if deltatime drops after 255 seconds.
	end

	local function GetRotationalInertia(Link, Wheel)
		local Phys = Wheel:GetPhysicsObject()

		return (Phys:GetInertia() * Link.Axis):Length()
	end

	function ENT:Calc(InputTorque, DeltaTime)
		if self.Disabled then return 0 end

		local PhysObj 	= Contraption.GetAncestor(self):GetPhysicsObject()
		local SelfWorld = PhysObj:LocalToWorldVector( PhysObj:GetAngleVelocity() )
		local Wheels	= table.Count(self.Wheels)
		local Gearboxes = table.Count(self.GearboxOut)
		local GearRatio = self.GearRatio
		local Clutch 	= self.Clutch
		local LClutch 	= self.LClutch
		local RClutch 	= self.RClutch
		local LTqRatio	= ( 1 + (RClutch - LClutch) ) / Wheels
		local RTqRatio	= ( 1 + (LClutch - RClutch) ) / Wheels

		if self.IsDualClutch and LClutch == RClutch then
			Clutch = LClutch
		end

		if LClutch == 0 and RClutch == 0 then
			LTqRatio = 0
			RTqRatio = 0
		end

		--self.Load = 0
		self.InputRPM = 0
		self.Inertia = 0
		self.TorqueInput = math.Clamp(InputTorque, -self.MaxTorque, self.MaxTorque) * Clutch
		self.TorqueOutput = self.TorqueInput * GearRatio
		self.TotalRatio = math.abs(GearRatio)

		if self.ChangeFinished < Clock.CurTime then
			self.InGear = true
		end

		--[[ Update connected wheels ]]--
		local ChassisTorque = 0
		local AverageWheelRPM = 0
		for Wheel, Link in pairs( self.Wheels ) do
			local DualClutch = Link.Side == 1 and LClutch or RClutch
			local TorqueTransfer = Link.Side == 0 and LTqRatio or RTqRatio

			local WheelTorque = self.TorqueOutput * TorqueTransfer
			local RPM = CalcWheel(self, Link, Wheel, SelfWorld) * DualClutch

			AverageWheelRPM = AverageWheelRPM + RPM
			ChassisTorque = ChassisTorque + WheelTorque
			self.Inertia = self.Inertia + GetRotationalInertia(Link, Wheel)

			ActWheel(Link, Wheel, WheelTorque, DeltaTime)
		end

		if Wheels > 0 then
			AverageWheelRPM = AverageWheelRPM / Wheels
			self.InputRPM = self.InputRPM + AverageWheelRPM * GearRatio
			self.Load = 1 * Clutch
		end

		--[[ Update connected gearboxes ]]--
		local AverageGearboxRPM = 0
		local CombinedRatio = 0
		for Ent, _ in pairs( self.GearboxOut ) do
			local GearboxTorque = self.TorqueOutput / Gearboxes
			local RPM = Ent:Calc( GearboxTorque, DeltaTime )

			AverageGearboxRPM = AverageGearboxRPM + RPM
			CombinedRatio = CombinedRatio + math.abs(Ent.TotalRatio)
			self.InputRPM = self.InputRPM + RPM * GearRatio
			self.Load = math.Clamp(self.Load + Ent.Load,0,1) * Clutch
			self.Inertia = self.Inertia + Ent.Inertia
		end

		if Gearboxes > 0 then
			AverageGearboxRPM = AverageGearboxRPM / Gearboxes
			CombinedRatio = CombinedRatio / Gearboxes
			self.InputRPM = self.InputRPM / Gearboxes
			self.TotalRatio = self.TotalRatio * math.abs(CombinedRatio)
		end

		if GearRatio == 0 then
			self.Load = 0
		end

		if ChassisTorque ~= 0 and IsValid(PhysObj) then
			PhysObj:ApplyTorqueCenter( self:GetRight() * ChassisTorque )
		end

		--[[ Calculate Ratios for CVT ]]--
		if self.CVT and self.Gear == 1 then
			if self.CVTRatio > 0 then
				self.Gears[1] = Clamp(self.CVTRatio, 0.01, 1)
			else
				local AvrgIdle = 0
				local Count = 0
				for Engine in pairs(self.Engines) do
					AvrgIdle = AvrgIdle + Engine.IdleRPM
					Count = Count + 1
				end
				AvrgIdle = ( AvrgIdle / Count )
				local InputRPM = math.max( math.abs(AverageGearboxRPM), math.abs(AverageWheelRPM) )

				local R = self.MinRPM / math.max(AvrgIdle / 2,InputRPM) / math.abs(self.FinalDrive)
				self.Gears[1] = math.Clamp(R, 1, 10)
			end

			self.GearRatio = self.Gears[1] * self.FinalDrive
			WireLib.TriggerOutput(self, "Ratio", self.GearRatio)
		end

		if GearRatio ~= 0 then
			self.Inertia = self.Inertia / math.abs(GearRatio)
		end
		self:UpdateOverlay()
		WireLib.TriggerOutput(self, "RPM", self.InputRPM)
		WireLib.TriggerOutput(self, "Output Torque", self.TorqueOutput)
		return self.InputRPM
	end

end ----------------------------------------------------

do -- Braking ------------------------------------------
	local Contraption = ACF.Contraption

	local function BrakeWheel(Link, Wheel, Brake)
		local Phys      = Wheel:GetPhysicsObject()
		local AntiSpazz = 1

		if not Phys:IsMotionEnabled() then return end -- skipping entirely if its frozen

		if Brake > 100 then
			local Overshot = abs(Link.LastVel - Link.Vel) > abs(Link.LastVel) -- Overshot the brakes last tick?
			local Rate     = Overshot and 0.2 or 0.002 -- If we overshot, cut back agressively, if we didn't, add more brakes slowly

			Link.AntiSpazz = (1 - Rate) * Link.AntiSpazz + (Overshot and 0 or Rate) -- Low pass filter on the antispazz

			AntiSpazz = min(Link.AntiSpazz * 10000 / Brake, 1) -- Anti-spazz relative to brake power
		end

		Link.LastVel = Link.Vel

		Phys:AddAngleVelocity(-Link.Axis * Link.Vel * AntiSpazz * Brake * 0.01)
	end

	function ENT:ApplyBrakes() -- This is just for brakes
		if self.Disabled then return end -- Illegal brakes man
		if not self.Braking then return end -- Kills the whole thing if its not supposed to be running
		if not next(self.Wheels) then return end -- No brakes for the non-wheel users
		if self.LastBrake == Clock.CurTime then return end -- Don't run this twice in a tick
		if not IsValid(Contraption.GetAncestor(self):GetPhysicsObject()) then return end
		local BoxPhys = Contraption.GetAncestor(self):GetPhysicsObject()
		local SelfWorld = BoxPhys:LocalToWorldVector(BoxPhys:GetAngleVelocity())
		local DeltaTime = Clock.DeltaTime

		for Wheel, Link in pairs(self.Wheels) do
			local Brake = Link.Side == 1 and self.LBrake or self.RBrake

			if Brake > 0 then -- regular ol braking
				Link.IsBraking = true
				CalcWheel(self, Link, Wheel, SelfWorld) -- Updating the link velocity
				BrakeWheel(Link, Wheel, Brake, DeltaTime)
			else
				Link.IsBraking = false
			end
		end

		self.LastBrake = Clock.CurTime

		timer.Simple(engine.TickInterval() * 0.9, function()
			if not IsValid(self) then return end

			self:ApplyBrakes()
		end)
	end
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

		--Wire dupe info
		BaseClass.PreEntityCopy(self)
	end

	function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
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

		BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
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

	function ENT:OnRemove()
		local Class = self.ClassData

		if Class.OnLast then
			Class.OnLast(self, Class)
		end

		HookRun("ACF_OnEntityLast", "acf_gearbox_update", self, Class)

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

		timer.Remove("ACF Gearbox Clock " .. self:EntIndex())

		WireLib.Remove(self)
	end
end ----------------------------------------------------
