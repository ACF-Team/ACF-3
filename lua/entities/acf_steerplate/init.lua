AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

local ACF         = ACF
local Contraption = ACF.Contraption
local Notify      = ACF.Utilities.Notify
local Clamp       = math.Clamp
local MaxDistance = ACF.LinkDistance * ACF.LinkDistance
local EmptyTable  = {}
local SpeedConv   = 0.09144 -- u/s to km/h (Assumes 1u = 1in)
local LiquidMask  = bit.bor(CONTENTS_WATER, CONTENTS_SLIME)
local MaxSearch   = 4096 -- Most entities the connectivity check will walk through before giving up

-- Steer sockets ----------------------------------
-- Rotation only constraint between a steer plate and a wheel, pivoting on the wheel. The wheel spins freely around
-- the constraint frame's X axis (the twist axis) and is locked on the other two, so the wheel's steering follows the
-- plate's angle. GMod's AdvBallsocket never sets the angles of its phys_ragdollconstraint, which leaves the limits on
-- the world axes at the time of creation. Here the frame is set explicitly, with X along the baseplate's right as
-- steered, and stored relative to the plate so rotated pastes rebuild it the same way.
-- Verified in game: freeing a swing axis (Y or Z) instead, or using limits of exactly 0, makes some wheel models
-- drift several degrees off the steer angle or blow up. The wheel must also be the reference object.
local SocketTolerance = 0.001 -- Degrees, limits of exactly 0 are degenerate

--- Returns the steer socket frame for a baseplate and steer angle, X is the axis the wheels spin around
function ACF.GetSteerSocketFrame(Baseplate, Steer)
	return Baseplate:LocalToWorldAngles(Angle(0, Steer - 90, 0))
end

do
	local function FindSockets(Plate, Wheel)
		local Found = {}

		for _, Const in pairs(Plate.Constraints or EmptyTable) do
			if not IsValid(Const) then continue end

			local Data = Const:GetTable()
			local Type = Data.Type

			if Data.ACF_Removed then continue end -- Removal is deferred to the end of the frame
			if Type ~= "ACF_SteerSocket" and Type ~= "AdvBallsocket" then continue end
			if (Data.Ent1 == Plate and Data.Ent2 == Wheel) or (Data.Ent1 == Wheel and Data.Ent2 == Plate) then
				Found[#Found + 1] = Const
			end
		end

		return Found
	end

	--- Removes every steer socket or adv ballsocket between a steer plate and a wheel
	function ACF.RemoveSteerSockets(Plate, Wheel)
		for _, Const in ipairs(FindSockets(Plate, Wheel)) do
			Const.ACF_Removed = true
			Const:Remove()
		end
	end

	--- Returns the steer socket between a steer plate and a wheel, if any
	function ACF.GetSteerSocket(Plate, Wheel)
		for _, Const in ipairs(FindSockets(Plate, Wheel)) do
			if Const.Type == "ACF_SteerSocket" then return Const end
		end
	end

	--- Creates a steer socket between a steer plate and a wheel. Returns the existing one if there is one already.
	--- @param Plate Entity The steer plate
	--- @param Wheel Entity The wheel
	--- @param LocalAng Angle The constraint frame relative to the steer plate, its X axis is the wheel's spin axis
	function ACF.SteerSocket(Plate, Wheel, LocalAng)
		if not IsValid(Plate) or not Plate.IsACFSteerplate then return false end
		if not IsValid(Wheel) or Wheel == Plate then return false end
		if not constraint.CanConstrain(Plate, 0) then return false end
		if not constraint.CanConstrain(Wheel, 0) then return false end

		local Existing = ACF.GetSteerSocket(Plate, Wheel)
		if Existing then return Existing end

		LocalAng = isangle(LocalAng) and Angle(LocalAng:Unpack()) or Angle()

		local Const = ents.Create("phys_ragdollconstraint")
		if not IsValid(Const) then return false end

		-- The pivot must sit on the wheel, even though only rotation is constrained. Anywhere else it fights the
		-- wheel's own suspension constraints and locks the wheel's spin.
		Const:SetPos(Wheel:GetPhysicsObject():LocalToWorld(vector_origin))
		Const:SetAngles(Plate:LocalToWorldAngles(LocalAng))
		Const:SetKeyValue("xmin", -180)
		Const:SetKeyValue("xmax", 180)
		Const:SetKeyValue("ymin", -SocketTolerance)
		Const:SetKeyValue("ymax", SocketTolerance)
		Const:SetKeyValue("zmin", -SocketTolerance)
		Const:SetKeyValue("zmax", SocketTolerance)
		Const:SetKeyValue("spawnflags", 2) -- Rotation only
		Const:SetPhysConstraintObjects(Wheel:GetPhysicsObject(), Plate:GetPhysicsObject())
		Const:Spawn()
		Const:Activate()

		Const:SetTable({
			Type     = "ACF_SteerSocket",
			Ent1     = Plate,
			Ent2     = Wheel,
			Bone1    = 0,
			Bone2    = 0,
			LocalAng = LocalAng,
		})

		constraint.AddConstraintTable(Plate, Const, Wheel)

		return Const
	end

	duplicator.RegisterConstraint("ACF_SteerSocket", ACF.SteerSocket, "Ent1", "Ent2", "LocalAng")
end

-- Connectivity -----------------------------------
--- Whether the wheel can reach the baseplate through constraints or parents, without going through the steer plate
--- or any steer socket. A contraption check isn't enough, since the steer plate itself joins every wheel together.
local function IsConnected(Wheel, Baseplate, Plate)
	local WheelContraption = Wheel:CFW_GetContraption()
	if not WheelContraption or WheelContraption ~= Baseplate:CFW_GetContraption() then return false end

	local Queue   = { Wheel }
	local Visited = { [Wheel] = true, [Plate] = true }
	local Head    = 1

	local function Visit(Other)
		if not IsValid(Other) or Visited[Other] or Other:IsWorld() then return end

		Visited[Other] = true
		Queue[#Queue + 1] = Other
	end

	while Queue[Head] and Head <= MaxSearch do
		local Ent = Queue[Head]
		Head = Head + 1

		if Ent == Baseplate then return true end

		Visit(Ent:GetParent())

		for _, Const in pairs(Ent.Constraints or EmptyTable) do
			if not IsValid(Const) then continue end

			local Data = Const:GetTable()
			local Type = Data.Type

			if Type == "ACF_SteerSocket" or Type == "NoCollide" then continue end

			Visit(Data.Ent1)
			Visit(Data.Ent2)
			Visit(Data.Ent3)
			Visit(Data.Ent4)
		end
	end

	return false
end

--- Finds the AIO controller driving the given baseplate, if any
local function FindController(Baseplate)
	local BaseContraption = Baseplate:CFW_GetContraption()
	local Controllers     = BaseContraption and BaseContraption.entsbyclass and BaseContraption.entsbyclass.acf_controller
	if not Controllers then return end

	for Controller in pairs(Controllers) do
		if IsValid(Controller) and Controller.Baseplate == Baseplate then return Controller end
	end
end

-- Spawning and updating --------------------------
do
	local Behaviors        = ENT.ACF_SteerBehaviors
	local WireInputMethods = ENT.ACF_WireInputMethods
	local AIOInputMethods  = ENT.ACF_AIOInputMethods

	local function IsOneOf(List, Value)
		for _, Entry in ipairs(List) do
			if Entry == Value then return true end
		end

		return false
	end

	-- Invalid strings are dropped, which keeps the current value or falls back to the field's default
	function ENT.ACF_OnVerifyClientData(ClientData)
		for _, Key in ipairs({ "InactiveBehavior", "BrakeBehavior", "WaterBehavior" }) do
			if not IsOneOf(Behaviors, ClientData[Key]) then ClientData[Key] = nil end
		end

		local Method = ClientData.InputMethod
		if not IsOneOf(WireInputMethods, Method) and not IsOneOf(AIOInputMethods, Method) then
			ClientData.InputMethod = nil
		end
	end

	function ENT:ACF_PreSpawn()
		self.ACF = {}

		Contraption.SetModel(self, self.ACF_SteerplateModel)

		-- Linked entities
		self.Baseplate = nil
		self.Wheels    = {}

		-- Steering state
		self.Steer      = 0
		self.InA        = false
		self.InD        = false
		self.InSteer    = 0
		self.InAngle    = Angle()
		self.InActive   = true
		self.InBrake    = false
		self.InWater    = false
		self.HoldInput  = false
		self.Controller = nil
	end

	function ENT:ACF_PostUpdateEntityData()
		local Model = self.ACF_SteerplateModel

		self.ACF.Model = Model
		Contraption.SetModel(self, Model)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		-- The plate is only an angle reference, it never moves and never collides with anything but the world
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)

		local PhysObj = self:GetPhysicsObject()
		if IsValid(PhysObj) then
			PhysObj:EnableMotion(false)
			PhysObj:EnableGravity(false)
		end

		local LiveData = self.ACF_LiveData

		-- Share the linked entities with ACF_LiveData so Serialize reads from them
		LiveData.Wheels = LiveData.Wheels or {}
		self.Wheels     = LiveData.Wheels
		self.Steer      = LiveData.SteerAngle or 0
	end

	function ENT:ACF_OnSpawn()
		-- Drop wheels that are no longer physically connected to the baseplate
		ACF.AugmentedTimer(
			function() self:CheckWheels() end,
			function() return IsValid(self) end,
			nil,
			{ MinTime = 2, MaxTime = 6 }
		)
	end

	function ENT:ACF_PostMenuSpawn()
		ACF.DropToFloor(self)
	end

	-- Dupes come back with their saved steer angle, held until the steering input changes
	function ENT:PostEntityPaste()
		self.HoldInput     = true
		self.HoldSignature = nil
	end

	-- Steer plates are angle references, parenting them or to them would break that
	function ENT:CFW_PreParentedTo(_, NewParent)
		if IsValid(NewParent) then
			Notify.EntityWarning(self, "Cannot parent an ACF steer plate", "Steer plates must stay unparented to steer their wheels.")
			return false
		end
	end

	function ENT:CFW_PreParented()
		Notify.EntityWarning(self, "Cannot parent to an ACF steer plate", "Nothing can be parented to a steer plate.")
		return false
	end
end

-- Links ------------------------------------------
do
	ACF.RegisterClassPreLinkCheck("acf_steerplate", "acf_baseplate", function(This, Baseplate)
		if IsValid(This.Baseplate) then return false, "This steer plate is already linked to a baseplate." end
		if Baseplate:GetPos():DistToSqr(This:GetPos()) > MaxDistance then return false, "This baseplate is too far from the steer plate." end

		return true
	end)

	ACF.RegisterClassLink("acf_steerplate", "acf_baseplate", function(This, Baseplate)
		This.Baseplate = Baseplate
		This.ACF_LiveData.Baseplate = Baseplate
		This.Controller = FindController(Baseplate)

		This:ApplySteer(This:GetTable())
		This:NextThink(CurTime()) -- Unlinked plates think slowly
		This:UpdateOverlay()

		return true, "Steer plate linked successfully."
	end)

	ACF.RegisterClassUnlink("acf_steerplate", "acf_baseplate", function(This, Baseplate)
		if This.Baseplate ~= Baseplate then return false, "This steer plate is not linked to this baseplate." end

		This.Baseplate = nil
		This.ACF_LiveData.Baseplate = nil
		This.Controller = nil

		This:UpdateOverlay()

		return true, "Steer plate unlinked successfully."
	end)

	ACF.RegisterClassPreLinkCheck("acf_steerplate", "prop_physics", function(This, Wheel)
		if not IsValid(This.Baseplate) then return false, "Link this steer plate to a baseplate first." end
		if This.Wheels[Wheel] then return false, "This steer plate is already linked to this wheel." end
		if IsValid(Wheel.ACF_Steerplate) and Wheel.ACF_Steerplate ~= This then return false, "This wheel is already linked to another steer plate." end
		if IsValid(Wheel:GetParent()) then return false, "Cannot use a parented entity as a wheel." end
		if Wheel:GetPos():DistToSqr(This:GetPos()) > MaxDistance then return false, "This wheel is too far from the steer plate." end

		return true
	end)

	ACF.RegisterClassLink("acf_steerplate", "prop_physics", function(This, Wheel)
		local Frame = ACF.GetSteerSocketFrame(This.Baseplate, This.Steer)

		-- Any existing socket between the two is remade, so the frame always comes from the baseplate
		ACF.RemoveSteerSockets(This, Wheel)

		local Socket = ACF.SteerSocket(This, Wheel, This:WorldToLocalAngles(Frame))
		if not Socket then return false, "Couldn't create the steer socket on this wheel." end

		This.Wheels[Wheel] = true
		Wheel.ACF_Steerplate = This

		This:UpdateOverlay()

		return true, "Steer plate linked successfully."
	end)

	ACF.RegisterClassUnlink("acf_steerplate", "prop_physics", function(This, Wheel)
		if not This.Wheels[Wheel] then return false, "This steer plate is not linked to this wheel." end

		ACF.RemoveSteerSockets(This, Wheel)

		This.Wheels[Wheel] = nil
		if Wheel.ACF_Steerplate == This then Wheel.ACF_Steerplate = nil end

		This:UpdateOverlay()

		return true, "Steer plate unlinked successfully."
	end)
end

-- Inputs -----------------------------------------
do
	ACF.AddInputAction("acf_steerplate", "Active", function(Entity, Value) Entity.InActive = Value ~= 0 end)
	ACF.AddInputAction("acf_steerplate", "Brake", function(Entity, Value) Entity.InBrake = Value ~= 0 end)
	ACF.AddInputAction("acf_steerplate", "InWater", function(Entity, Value) Entity.InWater = Value ~= 0 end)
	ACF.AddInputAction("acf_steerplate", "A", function(Entity, Value) Entity.InA = Value ~= 0 end)
	ACF.AddInputAction("acf_steerplate", "D", function(Entity, Value) Entity.InD = Value ~= 0 end)
	ACF.AddInputAction("acf_steerplate", "Steer", function(Entity, Value) Entity.InSteer = Clamp(Value, -1, 1) end)
	ACF.AddInputAction("acf_steerplate", "Angle", function(Entity, Value) Entity.InAngle = Value end)
end

-- Steering ---------------------------------------
do
	local BehaviorRank = { Continue = 0, Neutral = 1, Disable = 2 }

	--- Picks what a condition does. Wire provided conditions read their wire input and disable steering.
	local function Resolve(Current, Behavior, AutoState, WireState)
		local Result

		if Behavior == "Wire" then
			Result = WireState and "Disable" or nil
		elseif AutoState then
			Result = Behavior
		end

		if not Result then return Current end
		if Current and BehaviorRank[Current] >= BehaviorRank[Result] then return Current end

		return Result
	end

	--- Returns the yaw of a world heading relative to the baseplate, positive is left
	local function LocalYaw(Baseplate, WorldAng)
		local Dir = WorldAng:Forward()

		return math.deg(math.atan2(-Dir:Dot(Baseplate:GetRight()), Dir:Dot(Baseplate:GetForward())))
	end

	--- Whether the wire Active input is unwired, which keeps the plate active
	local function IsActiveUnwired(SelfTbl)
		local Input = SelfTbl.Inputs and SelfTbl.Inputs.Active

		return not (Input and IsValid(Input.Src))
	end

	--- Reads the steering inputs from the AIO controller or the wire inputs
	--- @return boolean UsingAIO Whether the controller provided the inputs
	--- @return string Method The effective input method
	--- @return boolean Active, boolean Braking, boolean Left, boolean Right, number Steer, Angle|nil Heading
	local function ReadInputs(Entity, SelfTbl)
		local Method     = Entity:ACF_GetUserVar("InputMethod")
		local Controller = SelfTbl.Controller

		if Entity:ACF_GetUserVar("UseAIOController") and IsValid(Controller) then
			local States   = Controller.ActionStates or EmptyTable
			local Disabled = Controller:GetDisableMobility()
			local Active   = Controller.Active and IsValid(Controller.Driver) and not Disabled
			local Braking  = States.Brake or Disabled or false
			local Left, Right = States.TurnLeft or false, States.TurnRight or false

			if Controller:GetFlipAD() then Left, Right = Right, Left end
			if Method ~= "Aim" then Method = "AD" end

			return true, Method, Active, Braking, Left, Right, 0, Controller.CamAng
		end

		if Method == "Aim" then Method = "AD" end

		local Active = IsActiveUnwired(SelfTbl) or SelfTbl.InActive

		return false, Method, Active, SelfTbl.InBrake, SelfTbl.InA, SelfTbl.InD, SelfTbl.InSteer, SelfTbl.InAngle
	end

	-- Identifies the current steering input, a pasted plate holds its angle until this changes
	local function InputSignature(Method, Left, Right, Steer, Heading)
		if Method == "AD" then return (Left and 1 or 0) + (Right and 2 or 0) end
		if Method == "Steer" then return Steer end

		return Heading and math.Round(Heading.y, 1) or 0
	end

	--- Sets the plate's angle from the baseplate and its current steer angle
	function ENT:ApplySteer(SelfTbl)
		local Baseplate = SelfTbl.Baseplate
		if not IsValid(Baseplate) then return end

		self:SetAngles(Baseplate:LocalToWorldAngles(Angle(0, SelfTbl.Steer, 0)))
	end

	function ENT:ProcessSteering(SelfTbl, DeltaTime)
		local Baseplate = SelfTbl.Baseplate
		local UsingAIO, Method, Active, Braking, Left, Right, Steer, Heading = ReadInputs(self, SelfTbl)

		SelfTbl.UsingAIO = UsingAIO
		SelfTbl.Method   = Method

		-- Steering lock shrinks from the max angle at standstill to the min angle at top speed
		local Speed = Baseplate:GetVelocity():Length() * SpeedConv
		local MaxAngle, MinAngle = self:ACF_GetUserVar("MaxSteerAngle"), self:ACF_GetUserVar("MinSteerAngle")
		local Lock = MaxAngle + (MinAngle - MaxAngle) * Clamp(Speed / self:ACF_GetUserVar("TopSpeed"), 0, 1)

		SelfTbl.Lock = Lock

		-- Conditions, the most restrictive behavior wins
		local InWater = bit.band(util.PointContents(Baseplate:GetPos()), LiquidMask) ~= 0
		local Behavior

		Behavior = Resolve(Behavior, self:ACF_GetUserVar("InactiveBehavior"), not Active, not (IsActiveUnwired(SelfTbl) or SelfTbl.InActive))
		Behavior = Resolve(Behavior, self:ACF_GetUserVar("BrakeBehavior"), Braking, SelfTbl.InBrake)
		Behavior = Resolve(Behavior, self:ACF_GetUserVar("WaterBehavior"), InWater, SelfTbl.InWater)

		-- Pasted plates hold their angle until the steering input changes
		if SelfTbl.HoldInput then
			local Signature = InputSignature(Method, Left, Right, Steer, Heading)

			if SelfTbl.HoldSignature == nil then
				SelfTbl.HoldSignature = Signature
			elseif SelfTbl.HoldSignature ~= Signature then
				SelfTbl.HoldInput = false
			end

			if SelfTbl.HoldInput then Behavior = "Disable" end
		end

		SelfTbl.Behavior = Behavior

		local Current = SelfTbl.Steer
		local Target

		if Behavior == "Disable" then
			Target = Current
		elseif Behavior == "Neutral" then
			Target = 0
		elseif Method == "AD" then
			Target = ((Left and 1 or 0) - (Right and 1 or 0)) * Lock
		elseif Method == "Steer" then
			Target = -Steer * Lock
		else
			Target = Heading and Clamp(LocalYaw(Baseplate, Heading), -Lock, Lock) or 0
		end

		local MaxStep = self:ACF_GetUserVar("TurnRate") * DeltaTime
		local New     = Clamp(Current + Clamp(Target - Current, -MaxStep, MaxStep), -90, 90)

		if New ~= Current then
			SelfTbl.Steer = New
			SelfTbl.ACF_LiveData.SteerAngle = New

			-- Rotating the frozen plate doesn't wake what's constrained to it, parked wheels would ignore the steering
			for Wheel in pairs(SelfTbl.Wheels) do
				if IsValid(Wheel) then
					local PhysObj = Wheel:GetPhysicsObject()
					if IsValid(PhysObj) then PhysObj:Wake() end
				end
			end

			WireLib.TriggerOutput(self, "SteerAngle", New)
		end

		self:ApplySteer(SelfTbl)
	end

	function ENT:Think()
		local SelfTbl = self:GetTable()
		local Now     = CurTime()

		-- Always frozen, no matter what unfroze it
		local PhysObj = self:GetPhysicsObject()
		if IsValid(PhysObj) and PhysObj:IsMotionEnabled() then
			PhysObj:EnableMotion(false)
		end

		if not IsValid(SelfTbl.Baseplate) then
			SelfTbl.LastThink = nil
			self:NextThink(Now + 0.5)
			return true
		end

		local DeltaTime = Now - (SelfTbl.LastThink or Now)
		SelfTbl.LastThink = Now

		self:ProcessSteering(SelfTbl, DeltaTime)

		-- The overlay buffers itself, this only marks it dirty most of the time
		self:UpdateOverlay()

		self:NextThink(Now)
		return true
	end
end

--- Drops wheels that are gone, lost their socket or are no longer physically connected to the baseplate
function ENT:CheckWheels()
	local Baseplate = self.Baseplate

	if not IsValid(Baseplate) then return end

	self.Controller = FindController(Baseplate)

	for Wheel in pairs(self.Wheels) do
		if not IsValid(Wheel) then
			self.Wheels[Wheel] = nil
			continue
		end

		local Reason

		if not ACF.GetSteerSocket(self, Wheel) then
			Reason = "The steer socket on this wheel was removed."
		elseif not IsConnected(Wheel, Baseplate, self) then
			Reason = "This wheel is no longer physically connected to the steer plate's baseplate."
		end

		if Reason then
			self:Unlink(Wheel)

			local Owner = self:CPPIGetOwner()
			if IsValid(Owner) then
				Notify.EntityWarningToPlayer(Wheel, Owner, "A wheel was unlinked from its steer plate", Reason)
			end
		end
	end
end

function ENT:ACF_UpdateOverlayState(State)
	local Baseplate = self.Baseplate
	local Count     = 0

	for Wheel in pairs(self.Wheels) do
		if IsValid(Wheel) then Count = Count + 1 end
	end

	if not IsValid(Baseplate) then
		State:AddError("Not linked to a baseplate")
		State:AddNumber("Linked Wheels", Count)
		return
	end

	State:AddKeyValue("Input Source", self.UsingAIO and "AIO Controller" or "Wire")
	State:AddKeyValue("Input Method", self.Method or self:ACF_GetUserVar("InputMethod"))
	State:AddNumber("Linked Wheels", Count)
	State:AddNumber("Steer Angle", math.Round(self.Steer, 2), "°")
	State:AddNumber("Steer Lock", math.Round(self.Lock or self:ACF_GetUserVar("MaxSteerAngle"), 2), "°")

	if self.HoldInput then
		State:AddLabel("Holding the pasted steer angle until the steering input changes")
	elseif self.Behavior == "Disable" then
		State:AddWarning("Steering disabled")
	elseif self.Behavior == "Neutral" then
		State:AddWarning("Steering to neutral")
	end
end
