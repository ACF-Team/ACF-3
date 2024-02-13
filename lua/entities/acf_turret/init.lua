AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Local Vars

local ACF			= ACF

local Contraption	= ACF.Contraption
local Classes		= ACF.Classes
local Utilities		= ACF.Utilities
local Sounds		= Utilities.Sounds
local Clock			= Utilities.Clock
local HookRun		= hook.Run
local TimerSimple	= timer.Simple

local MaxLinkDistance = ACF.LinkDistance ^ 2
local UnlinkSound = "physics/metal/metal_box_impact_bullet%s.wav"

do	-- Spawn and Update funcs
	local WireIO	= Utilities.WireIO
	local Entities	= Classes.Entities
	local Turrets	= Classes.Turrets

	Contraption.AddParentDetour("acf_turret", "Rotator")

	local Inputs	= {
		"Active (Enables movement of the turret.)",
		"Angle (Global angle for the turret to attempt to aim at.) [ANGLE]",
		"Vector (Position for the turret to attempt to aim at.) [VECTOR]"
	}

	local Outputs	= {
		"Mass (Current amount of mass loaded onto the turret.)",
		"Degrees (The number of degrees from center.)",
		"Entity (The turret drive.) [ENTITY]"
	}

	local function VerifyData(Data)
		if not Data.Turret then Data.Turret = Data.ID end

		local Class = Classes.GetGroup(Turrets, Data.Turret)

		if not Class then
			Class = Turrets.Get("1-Turret")

			Data.Destiny		= "Turrets"
			Data.Turret			= "Turret-H"
		end

		local Turret = Turrets.GetItem(Class.ID, Data.Turret)

		if Turret then
			Data.Size		= Turret.Size
		end

		local Bounds	= Turret.Size
		local Size		= ACF.CheckNumber(Data.RingSize, Bounds.Base)

		Data.RingSize	= math.Clamp(Size, Bounds.Min, Bounds.Max)
	end

	------------------

	local function GetMass(Turret,Data)
		return math.Round(math.max(Turret.Mass * (Data.RingSize / Turret.Size.Base),5) ^ 1.5, 1)
	end

	local function UpdateTurret(Entity, Data, Class, Turret)
		local Model		= Turret.Model
		local Size		= Data.RingSize

		if (Size < 12) and (Data.Turret == "Turret-H") then
			Model	= Turret.ModelSmall
		end

		Entity:SetScaledModel(Model)

		local RingHeight = Class.GetRingHeight({Type = Data.Turret, Ratio = Turret.Size.Ratio}, Size)

		if Data.Turret == "Turret-H" then
			Entity:SetSize(Vector(Size,Size,RingHeight))
		else
			Entity:SetScale(Size / 20)
		end

		Entity.ACF.Model	= Model
		Entity.Name			= math.Round(Size,2) .. "\" " .. Turret.Name
		Entity.ShortName	= math.Round(Size,2) .. "\" " .. Turret.ID
		Entity.EntType		= Class.Name
		Entity.ClassData	= Class
		Entity.Class		= Class.ID
		Entity.Turret		= Data.Turret
		Entity.ID			= Turret.ID

		Entity.TurretData	= {
			Teeth		= Class.GetTeethCount(Turret,Size),
			RingSize	= Size,
			RingHeight	= RingHeight,
			TotalMass	= 0,
			LocalCoM	= Vector(),
			Tilt		= 1,
			TurretClass	= Data.Turret
		}

		-- Type-specific functions that differ between horizontal and vertical turret components
		Entity.SlewFuncs	= Turret.SlewFuncs

		Entity.DesiredAngle	= Entity.DesiredAngle or Angle(0,0,0)
		Entity.CurrentAngle	= Entity.CurrentAngle or 0

		-- This is TRUE whenever the last used angle input is Elevation/Bearing
		-- Otherwise this is FALSE and will attempt to rotate to the Angle input
		Entity.Manual		= true
		Entity.UseVector	= false
		Entity.DesiredVector = Vector()
		Entity.DesiredDeg	= 0

		-- Any turrets that happen to get parented to this one, either directly or indirectly
		-- Mass calculation will stop at this, and instead read whatever that turret has calculated
		Entity.SubTurrets		= {}

		-- Anything else deemed dynamic when it comes to mass (e.g. ammo, racks, fuel (for whatever reason))
		Entity.DynamicEntities	= {}

		-- Three different mass types to track, all checked differently
		--[[
			Static is updated only when parenting is updated, or a mass change function is called, and after a delay (not indefinite)
			Dynamic is from any entities deemed able to change mass at will (ammo, racks, fuel)
			SubTurret is from any turret components parented to this one, and will simply used whatever was calculated already
		]]
		Entity.StaticMass		= 0
		Entity.StaticCoM		= Vector()
		Entity.DynamicMass		= 0
		Entity.DynamicCoM		= Vector()
		Entity.SubTurretMass	= 0
		Entity.SubTurretCoM		= Vector()

		Entity.Active			= false
		Entity.SlewRate			= 0 -- Rotation rate
		Entity.Stabilized		= false
		Entity.StabilizeAmount	= 0
		Entity.LastRotatorAngle	= Entity.Rotator:GetAngles()

		Entity.MaxSlewRate		= 0
		Entity.SlewAccel		= 0

		Entity.MinDeg			= Data.MinDeg
		Entity.MaxDeg			= Data.MaxDeg
		Entity.HasArc			= not ((Data.MinDeg == -180) and (Data.MaxDeg == 180))

		Entity.MotorMaxSpeed	= 1
		Entity.MotorGearRatio	= 1
		Entity.EffortScale		= 1

		if Entity.SoundPlaying == true then
			Sounds.SendAdjustableSound(Entity,true)
		end
		Entity.SoundPlaying		= false
		Entity.SoundPath		= Entity.HandGear.Sound

		local SizePerc = (Size - Turret.Size.Min) / (Turret.Size.Max - Turret.Size.Min)
		Entity.ScaledArmor		= (Turret.Armor.Min * (1 - SizePerc)) + (Turret.Armor.Max * SizePerc)

		WireIO.SetupInputs(Entity, Inputs, Data, Class, Turret)
		WireIO.SetupOutputs(Entity, Outputs, Data, Class, Turret)

		Entity:SetNWString("WireName","ACF " .. Entity.Name)
		Entity:SetNWString("Class", Entity.Class)

		WireLib.TriggerOutput(Entity, "Entity", Entity)
		WireLib.TriggerOutput(Entity, "Mass", 0)

		for _,v in ipairs(Entity.DataStore) do
			Entity[v] = Data[v]
		end

		ACF.Activate(Entity, true)

		Entity.DamageScale		= math.max((Entity.ACF.Health / (Entity.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)

		local Mass = GetMass(Turret,Data)

		Contraption.SetMass(Entity, Mass)
	end

	------------------

	util.AddNetworkString("ACF_RequestTurretInfo")

	net.Receive("ACF_RequestTurretInfo",function(_, Player)
		local Entity = net.ReadEntity()

		if IsValid(Entity) then
			local CoM = Entity.TurretData.LocalCoM
			local Data = {
				LocalCoM	= Vector(math.Round(CoM.x,1),math.Round(CoM.y,1),math.Round(CoM.z,1)),
				Mass		= math.Round(Entity.TurretData.TotalMass,1),
				MinDeg		= Entity.MinDeg,
				MaxDeg		= Entity.MaxDeg,
				CoMDist		= math.Round(CoM:Length2D(),2),
				Type		= Entity.Turret
			}

			local DataString = util.TableToJSON(Data)

			net.Start("ACF_RequestTurretInfo")
				net.WriteEntity(Entity)
				net.WriteEntity(Entity.Rotator)
				net.WriteString(DataString)
			net.Send(Player)
		end
	end)

	------------------

	function MakeACF_Turret(Player, Pos, Angle, Data)
		VerifyData(Data)

		local Class = Classes.GetGroup(Turrets, Data.Turret)
		local Limit	= Class.LimitConVar.Name

		if not Player:CheckLimit(Limit) then return false end

		local Turret	= Turrets.GetItem(Class.ID, Data.Turret)

		local CanSpawn	= HookRun("ACF_PreEntitySpawn", "acf_turret", Player, Data, Class, Turret)

		if CanSpawn == false then return false end

		local Entity = ents.Create("acf_turret")

		if not IsValid(Entity) then return end

		local Rotator = ents.Create("acf_turret_rotator") -- Integral to the turret working, if this does not spawn then stop everything
		if not IsValid(Rotator) then
			Entity:Remove()
			error(Entity .. " did not have a valid rotator spawn with it, cancelling operation")
			return
		end

		Player:AddCleanup(Class.Cleanup, Entity)
		Player:AddCount(Limit, Entity)

		local Model	= Turret.Model
		if (Data.RingSize < 12) and (Data.Turret == "Turret-H") then
			Model	= Turret.ModelSmall
		end

		Entity.ACF				= {}

		Contraption.SetModel(Entity, Model)

		Entity:SetPlayer(Player)
		Entity:SetAngles(Angle)
		Entity:SetPos(Pos)
		Entity:Spawn()

		Entity.Owner			= Player
		Entity.DataStore		= Entities.GetArguments("acf_turret")
		Entity.MassCheckDelay 	= 0
		Entity.CoMCheckDelay	= 0
		Entity.ScaledArmor		= 0
		Entity.HandGear			= Class.HandGear
		Entity.Disconnect		= false

		Entity:SetNWEntity("ACF.Rotator", Rotator)

		Rotator:SetPos(Entity:GetPos())
		Rotator:SetAngles(Entity:GetAngles())
		Rotator:SetParent(Entity)
		Rotator:Spawn()
		Rotator:SetRenderMode(RENDERMODE_NONE)
		Rotator:DrawShadow(false)

		Entity.Rotator			= Rotator
		Rotator.Turret			= Entity

		UpdateTurret(Entity, Data, Class, Turret)

		Entity:UpdateOverlay(true)

		HookRun("ACF_OnEntitySpawn", "acf_turret", Entity, Data, Class, Turret)

		ACF.CheckLegal(Entity)

		return Entity
	end

	Entities.Register("acf_turret", MakeACF_Turret, "Turret", "RingSize", "MinDeg", "MaxDeg")

	function ENT:Update(Data)
		VerifyData(Data)

		if self.Turret ~= Data.Turret then return false, "Turret type is mismatched!\n(" .. self.Turret .. " > " .. Data.Turret .. ")" end

		local Class 	= Classes.GetGroup(Turrets, Data.Turret)
		local Turret	= Turrets.GetItem(Class.ID, Data.Turret)
		local OldClass	= self.ClassData

		local CanUpdate, Reason	= HookRun("ACF_PreEntityUpdate", "acf_turret", self, Data, Class, Turret)

		if CanUpdate == false then return CanUpdate, Reason end

		self.Active		= false
		self.SlewRate	= 0

		HookRun("ACF_OnEntityLast", "acf_turret", self, OldClass)

		ACF.SaveEntity(self)

		UpdateTurret(self, Data, Class, Turret)

		ACF.RestoreEntity(self)

		HookRun("ACF_OnEntityUpdate", "acf_turret", self, Data, Class, Motor)

		self:UpdateOverlay(true)

		net.Start("ACF_UpdateEntity")
			net.WriteEntity(self)
		net.Broadcast()

		self:UpdateTurretMass()

		return true, "Turret updated successfully!"
	end

	function ENT:OnRemove()
		if IsValid(self.Rotator) then
			self.Rotator:Remove()
		end
	end

	------------------

	-- Entity types that can have a different mass from time to time
	-- Need to hook into SetMass specifically for these so it can do a simple update for the turret
	local DynamicMassTypes = {
		acf_ammo		= true,
		acf_rack		= true,
		acf_fueltank	= true
	}

	local function GetFilteredChildren(Entity, Pass, FilterClass) -- Specialized for this use case, this will stop at any subturrets found, but still include them
		local List = Pass or {}

		if Entity.Rotator then Entity = Entity.Rotator end

		for _, V in pairs(Entity:GetChildren()) do
			if not IsValid(V) or List[V] then continue end

			local Parent = V:GetParent()
			if Parent == NULL then continue end -- somehow this shit is still a problem

			List[V] = V

			if V:GetClass() == FilterClass then continue end

			GetFilteredChildren(V, List, FilterClass)
		end

		return List
	end

	local function Proxy_ACF_OnParent(self, _, _)
		if (not IsValid(self.ACF_TurretAncestor)) or (not Contraption.HasAncestor(self,self.ACF_TurretAncestor)) then self.ACF_OnParented = nil self.ACF_TurretAncestor = nil return end

		self.ACF_TurretAncestor:UpdateTurretMass(false)
	end

	local function Proxy_ACF_OnMassChange(self)
		if (not IsValid(self.ACF_TurretAncestor)) or (not Contraption.HasAncestor(self,self.ACF_TurretAncestor)) then self.ACF_OnMassChange = nil self.ACF_TurretAncestor = nil return end

		self.ACF_TurretAncestor:UpdateTurretMass(false)
	end

	local function ParentLink(Turret, Entity, Connect)
		if Connect then
			Entity.ACF_OnParented		= Proxy_ACF_OnParent
			Entity.ACF_OnMassChange		= Proxy_ACF_OnMassChange
			Entity.ACF_TurretAncestor	= Turret
		else
			Entity.ACF_OnParented		= nil
			Entity.ACF_OnMassChange		= nil
			Entity.ACF_TurretAncestor	= nil
		end
	end

	local function BuildWatchlist(Entity) -- Potentially hot and heavy, should only be triggered after a (maximum) delay to catch large changes and not every single new entity
		if not IsValid(Entity) then return end

		local PhysObj = Entity.ACF.PhysObj
		if not IsValid(PhysObj) then return end

		local Mass = 0
		local CoM = Vector()
		local AddCoM = {}

		Entity.DynamicEntities	= {}
		Entity.SubTurrets		= {}

		local ChildList = GetFilteredChildren(Entity,{},"acf_turret")

		for k in pairs(ChildList) do
			local Class = k:GetClass()

			k.ACF_TurretAncestor = nil
			if Class == "acf_turret" then
				Entity.SubTurrets[k] = true

				k.ACF_TurretAncestor = Entity
			elseif DynamicMassTypes[Class] then
				Entity.DynamicEntities[k] = true

				ParentLink(Entity,k,true)
			else
				if not IsValid(k) then continue end
				ParentLink(Entity,k,true)

				if Class == "acf_turret_motor" then k:ValidatePlacement() end

				local PO = k:GetPhysicsObject()
				if not IsValid(PO) then continue end

				Mass = Mass + PO:GetMass()
				AddCoM[k] = PO
			end
		end

		Entity.StaticMass = Mass

		local Rotator = Entity.Rotator
		for Ent, PhysObj in pairs(AddCoM) do
			local Shift = Rotator:WorldToLocal(Ent:LocalToWorld(PhysObj:GetMassCenter())) * (PhysObj:GetMass() / Mass)
			CoM = CoM + Shift
		end

		Entity.StaticCoM = CoM
	end

	local function GetDynamicMass(Entity) -- Returns mass center (local to rotator) and amount from all "dynamic" entities, should be triggered after a resettable delay (only delayable by so long) in order to reduce spammed calls
		if not IsValid(Entity) then return end

		if next(Entity.DynamicEntities) == nil then return Vector(), 0 end -- Early stop if empty

		local Mass = 0
		local CoM = Vector()
		local AddCoM = {}

		for k in pairs(Entity.DynamicEntities) do
			if not IsValid(k) then continue end
			local PO = k:GetPhysicsObject()
			if not IsValid(PO) then continue end

			Mass = Mass + PO:GetMass()
			AddCoM[k] = PO
		end

		Entity.DynamicMass = Mass

		local Rotator = Entity.Rotator
		for Ent,PhysObj in pairs(AddCoM) do
			local Shift = Rotator:WorldToLocal(Ent:LocalToWorld(PhysObj:GetMassCenter())) * (PhysObj:GetMass() / Mass)
			CoM = CoM + Shift
		end

		Entity.DynamicCoM = CoM

		return CoM, Mass
	end

	local function GetSubTurretMass(Entity) -- Returns mass center (local to rotator) and amount from all subturrets
		if not IsValid(Entity) then return end

		if next(Entity.SubTurrets) == nil then return Vector(), 0 end

		local Mass = 0
		local CoM = Vector()
		local AddCoM = {}

		for k in pairs(Entity.SubTurrets) do
			if not IsValid(k) then continue end

			Mass = Mass + k:GetTotalMass() + k.ACF.Mass
			AddCoM[k] = true
		end

		Entity.SubTurretMass = Mass

		local Rotator = Entity.Rotator
		for Turret in pairs(AddCoM) do
			local Shift = Rotator:WorldToLocal(Turret.Rotator:LocalToWorld(Turret:GetTurretMassCenter())) * (Turret.TurretData.TotalMass / Mass)
			CoM = CoM + Shift
		end

		Entity.SubTurretCoM = CoM

		return CoM, Mass
	end

	function ENT:UpdateTurretSlew()
		local SlewInput 	= self.HandGear
		local Stabilized	= false
		local StabilizeAmount	= 0
		local SoundPath		= SlewInput.Sound
		local MaxDistance 	= (((self.TurretData.RingSize / 2) * 1.2) + 12) ^ 2

		if IsValid(self.Motor) and self.Motor:GetPos():DistToSqr(self:GetPos()) > MaxDistance then
			local USound = UnlinkSound:format(math.random(1, 3))

			Sounds.SendSound(self, USound, 70, 100, 1)
			Sounds.SendSound(self.Motor, USound, 70, 100, 1)
			self:Unlink(self.Motor)

			-- No sense checking for this separately since it can't function without the motor anyway
			-- Using separate link distance as gyros can be parented to other things
			if IsValid(self.Gyro) and self.Gyro:GetPos():DistToSqr(self:GetPos()) > MaxLinkDistance then
				Sounds.SendSound(self, USound, 70, 100, 1)
				Sounds.SendSound(self.Gyro, USound, 70, 100, 1)
				self:Unlink(self.Gyro)
			end
		end

		if IsValid(self.Motor) and self.Motor:IsActive() then
			SlewInput	= self.Motor:GetInfo()
			Stabilized	= IsValid(self.Gyro) and self.Gyro:IsActive()
			if Stabilized then StabilizeAmount = self.Gyro:GetInfo() end

			SoundPath	= self.Motor.SoundPath
		end

		-- Scale for being off-axis, further affects friction
		local Tilt = 1
		if self.Turret == "Turret-V" then
			Tilt = math.max(1 - self:GetRight():Dot(Vector(0,0,1)),0)
		else
			Tilt = math.max(self:GetUp():Dot(Vector(0,0,1)),0)
		end

		self.TurretData.Tilt = Tilt

		local SlewData		= self.ClassData.CalcSpeed(self.TurretData,SlewInput)

		-- Allowing vertical turret drives to have a small amount of stabilization, but only if they aren't powered and the mass is well balanced
		-- Think about certain turrets in WW2 where the gun was vertically aimed by the gunner with his shoulder
		-- Only going to allow at most 25% so it's always better to motorize the drive and link a gyro to it
		-- Also limited to 125mm distance from center of drive, where it will be strongest at the center
		if (self.ID == "Turret-V") and ((self.TurretData.LocalCoM:Length2DSqr() * ACF.InchToMm) < (125 ^ 2)) and not IsValid(self.Motor) then
			Stabilized = true
			StabilizeAmount = (1 - ((self.TurretData.LocalCoM:Length2DSqr() * ACF.InchToMm) / (125 ^ 2))) * 0.25
		end

		self.MotorMaxSpeed		= SlewData.MotorMaxSpeed or 1 -- Both this and MotorGearRatio are used for sound calculations
		self.MotorGearRatio		= SlewData.MotorGearRatio or 1
		self.SoundPath			= SoundPath

		self.MaxSlewRate		= SlewData.MaxSlewRate
		self.SlewAccel			= SlewData.SlewAccel
		self.EffortScale		= SlewData.EffortScale or 1 -- Sound scaling
		self.Stabilized			= Stabilized
		self.StabilizeAmount	= StabilizeAmount
	end

	function ENT:GetTotalMass() -- Sum of all of the mass mounted on the turret, plus the turret component itself
		if not IsValid(self) then return 0 end
		local PhysObj = self:GetPhysicsObject()
		if not IsValid(PhysObj) then return 0 end

		self.TurretData.TotalMass = self.StaticMass + self.DynamicMass + self.SubTurretMass

		WireLib.TriggerOutput(self, "Mass", self.TurretData.TotalMass)

		return self.TurretData.TotalMass
	end

	function ENT:GetTurretMassCenter() -- Returns a local vector of the center of all of the mass on the turret component, from the rotator
		local PhysObj = self:GetPhysicsObject()
		if not IsValid(PhysObj) then return Vector() end

		local MassTotal = self:GetTotalMass() + self.ACF.Mass

		self.TurretData.LocalCoM = (PhysObj:GetMassCenter() * (self.ACF.Mass / MassTotal)) + (self.StaticCoM * (self.StaticMass / MassTotal)) + (self.DynamicCoM * (self.DynamicMass / MassTotal)) + (self.SubTurretCoM * (self.SubTurretMass / MassTotal))

		self:UpdateOverlay()
		return self.TurretData.LocalCoM
	end

	function ENT:CheckCoM(Force)
		if (Force == false) and (Clock.CurTime < self.CoMCheckDelay) then return end
		self.CoMCheckDelay = Clock.CurTime + 2 + math.Rand(1,2)

		GetDynamicMass(self)
		GetSubTurretMass(self)

		self:GetTotalMass()
		self:GetTurretMassCenter()

		self:UpdateTurretSlew()
		self:UpdateOverlay()
	end

	function ENT:UpdateTurretMass(Force) -- Will call the other parts above, this should be triggered after a parent (safe to call multiple times e.g. on dupe paste, as it has an internal delay to prevent spamming)
		if (Force == false) and (Clock.CurTime < self.MassCheckDelay) then return end

		self.MassCheckDelay = Clock.CurTime + 2 + math.Rand(1,2)

		TimerSimple(Force and 0 or 3,function()
			if not IsValid(self) then return end

			if IsValid(self.ACF_TurretAncestor) then
				self.ACF_TurretAncestor:UpdateTurretMass(true)
			end

			BuildWatchlist(self)
			self:CheckCoM(Force)

			self:UpdateOverlay()
		end)
	end
end

do -- Overlay
	function ENT:UpdateOverlayText()
		local SlewMax = math.Round(self.MaxSlewRate * self.DamageScale, 2)
		local SlewAccel = math.Round(self.SlewAccel * self.DamageScale, 4)
		local TotalMass = math.Round(self.TurretData.TotalMass, 1)

		local Text = "Max " .. SlewMax .. " deg/s\nAccel: " .. SlewAccel .. " deg/s^2\nTeeth: " .. self.TurretData.Teeth .. "t\nCurrent Mass: " .. TotalMass .. "kg"

		if self.HasArc then Text = Text .. "\nArc: " .. self.MinDeg .. "/" .. self.MaxDeg end

		if IsValid(self.Motor) then Text = Text .. "\nMotor: " .. tostring(self.Motor) end

		if IsValid(self.Gyro) then Text = Text .. "\nGyro: " .. tostring(self.Gyro) end

		if self.Stabilized and IsValid(self.Gyro) and IsValid(self.Motor) then
			Text = Text .. "\n\nMotor stabilized at " .. math.Round(self.StabilizeAmount * 100,1) .. "%"
		elseif self.Stabilized then
			Text = Text .. "\n\nNaturally stabilized at " .. math.Round(self.StabilizeAmount * 100,1) .. "%"
		end

		return Text
	end
end

do -- Metamethods
	do	-- Links
		ACF.RegisterLinkSource("acf_turret", "Motors")
		ACF.RegisterLinkSource("acf_turret", "Gyros")

		-- Motor links

		ACF.RegisterClassLink("acf_turret","acf_turret_motor",function(This,Motor)
			if IsValid(This.Motor) then return false, "This turret already has a motor linked!" end
			if IsValid(Motor.Turret) and (Motor.Turret ~= This) then return false, "This motor is already linked to different turret!" end
			if IsValid(Motor.Turret) and (Motor.Turret == This) then return false, "This motor is already linked to this turret!" end
			if This:GetPos():DistToSqr(Motor:GetPos()) > ((((This.TurretData.RingSize / 2) * 1.2) + 12) ^ 2) then return false, "This motor is too far from the turret!" end

			This.Motor		= Motor
			Motor.Turret	= This

			Motor:ValidatePlacement()
			This:UpdateTurretSlew()

			This:UpdateOverlay(true)
			Motor:UpdateOverlay(true)

			return true, "Motor linked successfully."
		end)

		ACF.RegisterClassUnlink("acf_turret", "acf_turret_motor", function(This, Motor)
			if not IsValid(This.Motor) then return false, "This turret doesn't have a motor linked!" end
			if not IsValid(Motor.Turret) then return false, "This motor isn't linked to a turret!" end
			if This.Motor ~= Motor then return false, "This turret isn't linked to this motor!" end

			This.Motor		= nil
			Motor.Turret	= nil

			Motor:ValidatePlacement()
			This:UpdateTurretSlew()

			This:UpdateOverlay(true)
			Motor:UpdateOverlay(true)

			return true, "Motor unlinked successfully."
		end)

		-- Gyro links

		ACF.RegisterClassLink("acf_turret","acf_turret_gyro",function(This,Gyro)
			if IsValid(This.Gyro) then return false, "This turret already has a gyro linked!" end
			if Gyro.IsDual then
				if IsValid(Gyro[This.ID]) then return false, "This gyro is already linked to this type of turret!" end
				if This:GetPos():DistToSqr(Gyro:GetPos()) > MaxLinkDistance then return false, "This gyro is too far from the turret!" end

				Gyro[This.ID]	= This
			else
				if IsValid(Gyro.Turret) and (Gyro.Turret ~= This) then return false, "This gyro is already linked to a turret!" end
				if This:GetPos():DistToSqr(Gyro:GetPos()) > MaxLinkDistance then return false, "This gyro is too far from the turret!" end

				Gyro.Turret		= This
			end

			This.Gyro	= Gyro

			This:UpdateTurretSlew()

			This:UpdateOverlay(true)
			Gyro:UpdateOverlay(true)

			return true, "Gyro linked successfully."
		end)

		ACF.RegisterClassUnlink("acf_turret", "acf_turret_gyro", function(This, Gyro)
			if not IsValid(This.Gyro) then return false, "This turret doesn't have a gyro linked!" end

			if Gyro.IsDual then
				if not IsValid(Gyro[This.ID]) then return false, "This gyro isn't linked to this type of turret!" end
				if This ~= Gyro[This.ID] then return false, "This turret isn't linked to this gyro!" end

				Gyro[This.ID]	= nil
			else
				if not IsValid(Gyro.Turret) then return false, "This gyro isn't linked to a turret!" end
				if This.Gyro ~= Gyro then return false, "This turret isn't linked to this gyro!" end

				Gyro.Turret		= nil
			end

			This.Gyro	= nil

			This:UpdateTurretSlew()

			This:UpdateOverlay(true)
			Gyro:UpdateOverlay(true)

			return true, "Gyro unlinked successfully."
		end)
	end

	do	-- Dupe Support
		function ENT:PreEntityCopy()
			if self.Motor then
				duplicator.StoreEntityModifier(self, "ACFMotor", {self.Motor:EntIndex()})
			end

			if self.Gyro then
				duplicator.StoreEntityModifier(self, "ACFGyro", {self.Gyro:EntIndex()})
			end

			-- Gyros!

			-- Wire dupe info
			self.BaseClass.PreEntityCopy(self)
		end

		function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
			local EntMods = Ent.EntityMods

			if EntMods.ACFMotor then
				self:Link(CreatedEntities[EntMods.ACFMotor[1]])

				EntMods.ACFMotor = nil
			end

			if EntMods.ACFGyro then
				self:Link(CreatedEntities[EntMods.ACFGyro[1]])

				EntMods.ACFGyro = nil
			end

			self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
		end
	end

	do	-- Think
		function ENT:SetSoundState(State)
			if State ~= self.SoundPlaying then
				if State == true then
					Sounds.CreateAdjustableSound(self,self.SoundPath,0,0)
					self.CurrentSound = self.SoundPath
				else
					Sounds.SendAdjustableSound(self,true)
				end
			end

			self.SoundPlaying = State
		end

		function ENT:InputDirection(Direction)
			if self.Disabled then return end

			self.Manual		= true
			self.UseVector	= false

			if isnumber(Direction) then
				self.DesiredDeg = math.NormalizeAngle(Direction)
				return
			end

			self.Manual		= false

			if isangle(Direction) then
				Direction:Normalize()
				self.DesiredAngle = Direction

				return
			end
			if isvector(Direction) then
				self.UseVector = true
				self.DesiredVector = Direction

				return
			end
		end

		function ENT:Think() -- The meat and POE-TAE-TOES of the turret working
			if self.Disabled then
				self:SetSoundState(false)
				self:NextThink(Clock.CurTime + 0.1)

				return true
			end

			self:CheckCoM(false)
			local Tick		= Clock.DeltaTime
			local Rotator	= self.Rotator
			if not IsValid(Rotator) then self:Remove() return end

			local Scale		= self.DamageScale * Tick

			local SlewMax		= self.MaxSlewRate * Scale
			local SlewAccel		= self.SlewAccel * Scale
			local MaxImpulse	= math.min(SlewMax, SlewAccel)

			local AngleChange	= self.CurrentAngle

			-- Something or another has caused the turret to be unable to rotate, so don't waste the extra processing time
			if MaxImpulse == 0 then
				self.LastRotatorAngle	= Rotator:GetAngles()

				if self.SoundPlaying == true then
					self:SetSoundState(false)
				end

				self:NextThink(Clock.CurTime + 0.1)
				return true
			end

			if self.UseVector and (self.Manual == false) then self.DesiredAngle = (self.DesiredVector - Rotator:GetPos()):GetNormalized():Angle() end

			local StabAmt	= math.Clamp(self.SlewFuncs.GetStab(self), -SlewMax, SlewMax)

			local TargetBearing	= math.Round(self.SlewFuncs.GetTargetBearing(self,StabAmt),8)

			local sign			= TargetBearing < 0 and -1 or 1
			local Dist			= math.abs(TargetBearing)
			local FinalAccel	= math.Clamp(TargetBearing, -MaxImpulse, MaxImpulse)
			local BrakingDist	= self.SlewRate ^ 2 / math.abs(FinalAccel) / 2

			if self.Active then
				self.SlewRate = math.Clamp(self.SlewRate + (math.abs(FinalAccel) * ((Dist + (self.SlewRate * 2 * -sign)) >= BrakingDist and sign or -sign)), -SlewMax, SlewMax)

				if self.SlewRate ~= 0 and (Dist <= math.abs(FinalAccel)) and (self.SlewRate <= FinalAccel) then
					self.SlewRate = 0
					self.CurrentAngle = self.CurrentAngle + TargetBearing / 2
				end
			elseif not self.Active and self.SlewRate ~= 0 then
				self.SlewRate = self.SlewRate - (math.min(SlewAccel, math.abs(self.SlewRate)) * (self.SlewRate >= 0 and 1 or -1))
			end

			self.CurrentAngle = self.CurrentAngle + math.Clamp(self.SlewRate + StabAmt,-SlewMax,SlewMax)

			if self.HasArc then
				self.CurrentAngle = math.Clamp(self.CurrentAngle,-self.MaxDeg,-self.MinDeg)
			end

			self.CurrentAngle = math.NormalizeAngle(self.CurrentAngle)

			WireLib.TriggerOutput(self, "Degrees", -self.CurrentAngle)

			self.SlewFuncs.SetRotatorAngle(self)

			local MotorSpeed = math.Clamp(math.abs(self.CurrentAngle - AngleChange),0,SlewMax) / Tick

			local MotorSpeedPerc = MotorSpeed / self.MotorMaxSpeed
			if MotorSpeedPerc > 0.1 and (self.SoundPlaying == false) then
				self:SetSoundState(true)
			elseif MotorSpeedPerc <= 0.1 and (self.SoundPlaying == true) then
				self:SetSoundState(false)
			end

			if self.SoundPlaying == true then
				if self.SoundPath ~= (self.CurrentSound or "") then -- should only get set off if the motor is enabled/disabled while the sound is playing
					self:SetSoundState(false)
				else
					Sounds.SendAdjustableSound(self,false, 70 + math.ceil(MotorSpeedPerc * 30), 0.1 + (self.EffortScale * 0.9))
				end
			end

			self.LastRotatorAngle	= Rotator:GetAngles()

			self:NextThink(Clock.CurTime)
			return true
		end
	end

	do	-- Input/Outputs/Eventually linking
		ACF.AddInputAction("acf_turret", "Active", function(Entity,Value)
			if Entity.Disabled then return end

			Entity.Active = tobool(Value)
		end)

		ACF.AddInputAction("acf_turret", "Angle", function(Entity,Value)
			local Ang = isangle(Value) and Value or Angle(0,0,0)

			Entity:InputDirection(Ang)
		end)

		ACF.AddInputAction("acf_turret", "Vector", function(Entity,Value)
			local Pos = isvector(Value) and Value or Vector(0,0,0)

			Entity:InputDirection(Pos)
		end)

		ACF.AddInputAction("acf_turret", "Bearing", function(Entity,Value) -- Only on horizontal drives
			if not isnumber(Value) then return end

			Entity:InputDirection(Value)
		end)

		ACF.AddInputAction("acf_turret", "Elevation", function(Entity,Value) -- Only on vertical drives
			if not isnumber(Value) then return end

			Entity:InputDirection(Value)
		end)
	end

	do	-- Activation and Damage handling

		function ENT:Enable()
			self:UpdateOverlay()
		end

		function ENT:Disable()
			self.Active 	= false
			self.SlewRate	= 0
			self:UpdateOverlay()
		end

		------------------

		function ENT:ACF_Activate(Recalc)
			local PhysObj	= self.ACF.PhysObj
			local Area		= PhysObj:GetSurfaceArea() * 6.45
			local Armour	= self.ScaledArmor
			local Health	= (Area / ACF.Threshold) * 5
			local Percent	= 1

			if Recalc and self.ACF.Health and self.ACF.MaxHealth then
				Percent = self.ACF.Health / self.ACF.MaxHealth
			end

			self.ACF.Area		= Area
			self.ACF.Health		= Health * Percent
			self.ACF.MaxHealth	= Health
			self.ACF.Armour		= Armour * Percent
			self.ACF.MaxArmour	= Armour
			self.ACF.Type		= "Prop"
		end

		function ENT:ACF_OnDamage(DmgResult, DmgInfo)
			local Health = self.ACF.Health
			local HitRes = DmgResult:Compute()

			if DmgInfo.Attacker and IsValid(DmgInfo.Attacker) then
				local Attacker = DmgInfo.Attacker

				if ((Attacker:GetClass() == "acf_ammo") or (Attacker:GetClass() == "acf_fueltank")) and (Attacker.Exploding == true and (HitRes.Damage >= self.ACF.Health) and (self.Disconnect == false)) then
					self.Disconnect	= true

					self:SetParent(nil)
					local PO = self:GetPhysicsObject()
					if IsValid(PO) then
						PO:EnableMotion(true)
						local Mass = PO:GetMass()

						PO:ApplyForceOffset((self:GetPos() - Attacker:GetPos()):GetNormalized() * Mass * (Mass / (Mass + self.TurretData.TotalMass)),self:GetPos() + VectorRand(-self.RingSize / 2,self.RingSize / 2))
					end

					TimerSimple(7.5,function()
						if not IsValid(self) then return end
						self:Remove()
					end)
				end
			end

			HitRes.Kill = false

			local NewHealth = math.max(0,Health - HitRes.Damage)

			self.ACF.Health = NewHealth
			self.ACF.Armour = self.ACF.MaxArmour * (NewHealth / self.ACF.MaxHealth)

			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)
			self:UpdateOverlay()

			return HitRes
		end

		function ENT:ACF_OnRepaired() -- Normally has OldArmor, OldHealth, Armor, and Health passed
			self.DamageScale = math.max((self.ACF.Health / (self.ACF.MaxHealth * 0.75)) - 0.25 / 0.75,0)

			self.ACF.Armour = self.ACF.MaxArmour * (self.ACF.Health / self.ACF.MaxHealth)

			self:UpdateOverlay()
		end

		function ENT:ACF_OnParented(Entity, _) -- Potentially called many times a second, so we won't force mass to update
			if Entity:GetClass() == "acf_turret_rotator" then return end

			self:UpdateTurretMass(false)

			-- Should only be called when parenting, checks the position of the motor relative to the ring
			-- Shooouuld be using ACF_OnParented as it was made with this in mind, but turret entities will overwrite it with the above function to ensure everything is captured
			if Entity:GetClass() == "acf_turret_motor" then Entity:ValidatePlacement() end
			if IsValid(self.Motor) then self.Motor:ValidatePlacement() end
		end

		function ENT:OnRemove()
			-- TODO: Destroy sound when that gets added

			if IsValid(self.Motor) then
				self.Motor:ValidatePlacement()
				self:Unlink(self.Motor)
			end

			if IsValid(self.Gyro) then self:Unlink(Gyro) end

			WireLib.Remove(self)
		end
	end
end