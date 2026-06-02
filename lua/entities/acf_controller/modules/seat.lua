local RecacheBindOutput = ENT.RecacheBindOutput
local RecacheBindState  = ENT.RecacheBindState

local function Init(Entity)
	Entity.Seat = nil  -- The single seat
end

-- https://wiki.facepunch.com/gmod/Enums/IN
local KEY_WIRE_BINDINGS = {
	{ IN_FORWARD,   "W" },
	{ IN_MOVELEFT,  "A" },
	{ IN_BACK,      "S" },
	{ IN_MOVERIGHT, "D" },
	{ IN_ATTACK,    "Mouse1" },
	{ IN_ATTACK2,   "Mouse2" },
	{ IN_RELOAD,    "R" },
	{ IN_JUMP,      "Space" },
	{ IN_SPEED,     "Shift" },
	{ IN_ZOOM,      "Zoom" },
	{ IN_WALK,      "Alt" },
	{ IN_DUCK,      "Duck" },
}

local IN_ENUM_TO_WIRE_OUTPUT = {}
for _, Binding in ipairs(KEY_WIRE_BINDINGS) do
	IN_ENUM_TO_WIRE_OUTPUT[Binding[1]] = Binding[2]
	ACF.RegisterControllerOutput(Binding[2])
end

ACF.RegisterControllerOutput("Active")
ACF.RegisterControllerOutput("Driver (The player driving the vehicle.) [ENTITY]")

-- Handle a player entering or exiting the vehicle
local function OnActiveChanged(Controller, Ply, Active)
	local SelfTbl = Controller:GetTable()

	-- Reset all key states and outputs when getting in or out of the vehicle
	Controller.KeyStates = {}
	for Key, Output in pairs(IN_ENUM_TO_WIRE_OUTPUT) do
		RecacheBindOutput(Controller, SelfTbl, Output, 0)
		RecacheBindState(SelfTbl, Key, false)
	end

	RecacheBindOutput(Controller, SelfTbl, "Driver", Ply)
	RecacheBindOutput(Controller, SelfTbl, "Active", Active and 1 or 0)

	Controller.FOV = Controller.FOV or 90
	Ply:SetFOV(Active and Controller.FOV or 0, 0, nil)

	Controller.Active = Active
	Controller.Driver = Active and Ply or NULL
	if Active then Controller:AnalyzeCams() end -- Recalculate filter for the cameras

	for Turret in pairs(Controller.Turrets) do
		if IsValid(Turret) then Turret:TriggerInput("Active", Active) end
	end

	for Engine in pairs(Controller.Engines) do
		if IsValid(Engine) then Engine:TriggerInput("Active", Active) end
	end

	if IsValid(Controller.Gearbox) then Controller.Gearbox:TriggerInput("Gear", Active and 1 or 0) end

	for Gearbox in pairs(Controller.GearboxEnds) do
		if IsValid(Gearbox) then Gearbox:TriggerInput("Gear", Active and 1 or 0) end
	end

	for Gearbox in pairs(Controller.GearboxIntermediates) do
		if IsValid(Gearbox) then Gearbox:TriggerInput("Gear", Active and 1 or 0) end
	end

	-- Let the player know the controller is active or not
	net.Start("ACF_Controller_Active")
	net.WriteUInt(Controller:EntIndex(), MAX_EDICT_BITS)
	net.WriteBool(Active)
	net.Send(Ply)

	-- Network the camera filter to the player
	net.Start("ACF_Controller_CamInfo")
	net.WriteTable(Controller.Filter or {})
	net.Send(Ply)
end

local function OnKeyChanged(Controller, Key, Down)
	local Output = IN_ENUM_TO_WIRE_OUTPUT[Key]
	local SelfTbl = Controller:GetTable()
	if Output ~= nil then
		RecacheBindOutput(Controller, SelfTbl, Output, Down and 1 or 0)
		RecacheBindState(SelfTbl, Key, Down)
	end

	Controller:ToggleTurretLocks(SelfTbl, Key, Down)
end

local function OnButtonChanged(Controller, Button, Down)
	if not IsFirstTimePredicted() then return end
	if Button == MOUSE_MIDDLE and Down and IsValid(Controller.TurretComputer) then
		-- Reset computer lase
		if Controller.Driver:KeyDown( IN_DUCK ) then
			Controller.Additive = vector_origin
			Controller.LaseDist = 0
			Controller.LasePitch = 0
			Controller.Drop = 0
			Controller.TravelTime = 0
			return
		end

		-- Otherwise log metrics on lase, and use these later
		Controller.TurretComputer.Inputs.Position.Value = Controller.HitPos
		Controller.TurretComputer:TriggerInput("Calculate Superelevation", 1)

		local Diff = (Controller.Primary:GetPos() - Controller.HitPos)
		Controller.LasePitch = math.deg(math.asin(Diff.z / Diff:Length()))
		Controller.LaseDist = Diff:Length()
	end
end

local function OnLinkedSeat(Controller, Target)
	hook.Add("PlayerEnteredVehicle", "ACFControllerSeatEnter" .. Controller:EntIndex(), function(Ply, Veh)
		if Veh == Target then OnActiveChanged(Controller, Ply, true) end
	end)

	hook.Add("PlayerLeaveVehicle", "ACFControllerSeatExit" .. Controller:EntIndex(), function(Ply, Veh)
		if Veh == Target then OnActiveChanged(Controller, Ply, false) end
	end)

	hook.Add("KeyPress", "ACFControllerSeatKeyPress" .. Controller:EntIndex(), function(Ply, Key)
		if not IsValid(Controller) or not IsValid(Target) then return end
		if Ply ~= Controller.Driver then return end
		OnKeyChanged(Controller, Key, true)
	end)

	hook.Add("KeyRelease", "ACFControllerSeatKeyRelease" .. Controller:EntIndex(), function(Ply, Key)
		if not IsValid(Controller) or not IsValid(Target) then return end
		if Ply ~= Controller.Driver then return end
		OnKeyChanged(Controller, Key, false)
	end)

	hook.Add("PlayerButtonDown", "ACFControllerSeatButtonDown" .. Controller:EntIndex(), function(Ply, Key)
		if not IsValid(Controller) or not IsValid(Target) then return end
		if Ply ~= Controller.Driver then return end
		OnButtonChanged(Controller, Key, true)
	end)

	hook.Add("PlayerButtonUp", "ACFControllerSeatButtonUp" .. Controller:EntIndex(), function(Ply, Key)
		if not IsValid(Controller) or not IsValid(Target) then return end
		if Ply ~= Controller.Driver then return end
		OnButtonChanged(Controller, Key, false)
	end)

	-- Remove the hooks when the controller is removed
	Controller:CallOnRemove("ACFRemoveController", function(Ent)
		hook.Remove("PlayerEnteredVehicle", "ACFControllerSeatEnter" .. Ent:EntIndex())
		hook.Remove("PlayerLeaveVehicle", "ACFControllerSeatExit" .. Ent:EntIndex())
		hook.Remove("KeyPress", "ACFControllerSeatKeyPress" .. Ent:EntIndex())
		hook.Remove("KeyRelease", "ACFControllerSeatKeyRelease" .. Ent:EntIndex())
	end)
end

local function OnUnlinkedSeat(Controller)
	-- Remove the hooks when the seat is unlinked
	hook.Remove("PlayerEnteredVehicle", "ACFControllerSeatEnter" .. Controller:EntIndex())
	hook.Remove("PlayerLeaveVehicle", "ACFControllerSeatExit" .. Controller:EntIndex())
	hook.Remove("KeyPress", "ACFControllerSeatKeyPress" .. Controller:EntIndex())
	hook.Remove("KeyRelease", "ACFControllerSeatKeyRelease" .. Controller:EntIndex())
end

ACF.RegisterControllerLink("prop_vehicle_prisoner_pod", {
	Field = "Seat",
	Single = true,
	OnLinked = function(Controller, Target) OnLinkedSeat(Controller, Target) end,
	OnUnlinked = function(Controller, _) OnUnlinkedSeat(Controller) end,
})

return Init
