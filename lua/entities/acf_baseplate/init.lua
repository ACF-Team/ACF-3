AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

include("shared.lua")

ENT.ACF_UserWeighable             = true
ENT.ACF_KillableButIndestructible = true

-- Might be a good idea to put this somewhere else later
ACF.ActiveBaseplatesTable = ACF.ActiveBaseplatesTable or {}
ACF.ActiveBaseplatesArray = ACF.ActiveBaseplatesArray or {}

-- Lag compensated baseplates are rewound, with everything parented to them, to where a player saw them while that
-- player's predicted bullets are stepped. Off unless an addon firing predicted bullets turns it on (ACF-3 SWEPs does),
-- the engine keeps a position history for every lag compensated entity
ACF.BaseplateLagCompensation = ACF.BaseplateLagCompensation or false

function ACF.SetBaseplateLagCompensation(Enabled)
	ACF.BaseplateLagCompensation = Enabled

	for Baseplate in pairs(ACF.ActiveBaseplatesTable) do
		if IsValid(Baseplate) then Baseplate:SetLagCompensated(Enabled) end
	end
end

include("modules/crew.lua")
include("modules/overlay.lua")
include("modules/repulsion.lua")
include("modules/seats.lua")
include("modules/spawning.lua")
include("modules/state.lua")
include("modules/autoright.lua")