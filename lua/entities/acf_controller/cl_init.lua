DEFINE_BASECLASS("acf_base_simple")

include("shared.lua")

-- Boilerplate
function ENT:Initialize(...)
	BaseClass.Initialize(self, ...)
end

function ENT:Draw(...)
	BaseClass.Draw(self, ...)
end

-- Note: Since this file is sent to each client, locals are unique to each player...
-- This is similar to doing entity.value or self.value, but for the client itself.
local State = {
	MyController = nil,
	MyFilter = nil,
}

local ActivationCallbacks = {}
local function RegisterClientModule(OnActivated)
	if OnActivated then ActivationCallbacks[#ActivationCallbacks + 1] = OnActivated end
end

RegisterClientModule(include("modules_cl/overlay.lua")(State))
RegisterClientModule(include("modules_cl/camera.lua")(State))
RegisterClientModule(include("modules_cl/hud.lua")(State))

-- Maintain a record of links to the entity from the server
net.Receive("ACF_Controller_Links", function()
	local EntIndex1 = net.ReadUInt(MAX_EDICT_BITS)
	local EntIndex2 = net.ReadUInt(MAX_EDICT_BITS)
	local Linked = net.ReadBool()

	local Ent = Entity(EntIndex1)
	Ent.Targets = Ent.Targets or {}

	if Ent.Targets == nil then return end
	if Linked then Ent.Targets[EntIndex2] = true else Ent.Targets[EntIndex2] = nil end
end)

-- Keep a record of the controller we are currently in, from the server
net.Receive("ACF_Controller_Active", function()
	local EntIndex = net.ReadUInt(MAX_EDICT_BITS)
	local Activated = net.ReadBool()

	local Ent = Entity(EntIndex)
	if not IsValid(Ent) then return end

	State.MyController = Activated and Ent or nil
	if Activated then
		for _, OnActivated in ipairs(ActivationCallbacks) do OnActivated(LocalPlayer()) end
	end
end)
