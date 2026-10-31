local RecacheBindOutput = ENT.RecacheBindOutput
local RecacheBindState  = ENT.RecacheBindState

local function Init(Entity)
	Entity.Seat = nil  -- The single seat
end

local IN_ENUM_TO_WIRE_OUTPUT = {}
for _, Binding in ipairs(ACF.ControllerKeyBindings) do
	IN_ENUM_TO_WIRE_OUTPUT[Binding[1]] = Binding[2]
end

-- Handle a player entering or exiting the vehicle
local function OnActiveChanged(Controller, Ply, Active)
	local SelfTbl = Controller:GetTable()

	-- Reset all key states and outputs when getting in or out of the vehicle
	Controller.KeyStates = {}
	Controller.ActionStates = {}
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
		if IsValid(Turret) then Turret:TriggerInput("Active", Active and not Controller.TurretLocked) end
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

	if Active then
		Controller:FLIR_OnEnter(Ply)
	else
		Controller:FLIR_OnExit(Ply)
	end
end

local function OnKeyChanged(Controller, Key, Down)
	local Output = IN_ENUM_TO_WIRE_OUTPUT[Key]
	local SelfTbl = Controller:GetTable()
	if Output ~= nil then
		RecacheBindOutput(Controller, SelfTbl, Output, Down and 1 or 0)
		RecacheBindState(SelfTbl, Key, Down)
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

	-- PlayerButtonDown/Up don't fire client side in singleplayer, so forward them to binds_sh.lua there
	local function ForwardButton(Ply, Key, Down)
		if not IsValid(Controller) or not IsValid(Target) then return end
		if Ply ~= Controller.Driver then return end
		if not game.SinglePlayer() then return end

		net.Start("ACF_Controller_Button")
		net.WriteUInt(Key, 8)
		net.WriteBool(Down)
		net.Send(Ply)
	end

	hook.Add("PlayerButtonDown", "ACFControllerSeatButtonDown" .. Controller:EntIndex(), function(Ply, Key)
		ForwardButton(Ply, Key, true)
	end)

	hook.Add("PlayerButtonUp", "ACFControllerSeatButtonUp" .. Controller:EntIndex(), function(Ply, Key)
		ForwardButton(Ply, Key, false)
	end)

	-- Remove the hooks when the controller is removed
	Controller:CallOnRemove("ACFRemoveController", function(Ent)
		hook.Remove("PlayerEnteredVehicle", "ACFControllerSeatEnter" .. Ent:EntIndex())
		hook.Remove("PlayerLeaveVehicle", "ACFControllerSeatExit" .. Ent:EntIndex())
		hook.Remove("KeyPress", "ACFControllerSeatKeyPress" .. Ent:EntIndex())
		hook.Remove("KeyRelease", "ACFControllerSeatKeyRelease" .. Ent:EntIndex())
		hook.Remove("PlayerButtonDown", "ACFControllerSeatButtonDown" .. Ent:EntIndex())
		hook.Remove("PlayerButtonUp", "ACFControllerSeatButtonUp" .. Ent:EntIndex())
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
