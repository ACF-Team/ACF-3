DEFINE_BASECLASS("base_scalable")

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

-- Straight to the rotator; CFW only applies one detour per parent call, so going through the actuator would stop there
CFW.addParentDetour("acf_actuator_rod", "Rotator")

-- One can't exist without the other
function ENT:OnRemove()
	if IsValid(self.Actuator) then
		self.Actuator:Remove()
	end
end

-- Only its actuator may reparent it, and only while resizing it
function ENT:CFW_PreParentedTo()
	if not self.AllowReparent then return false end
end

-- ACF overlay showing just the name; it never changes, so the state is built once
function ENT:GetOverlayState()
	local State = self.OverlayState

	if not State then
		State = ACF.Overlay.State()

		State:Begin()
		State:AddHeader(self.PrintName)
		State:End()

		self.OverlayState = State
	end

	return State
end

function ENT:ACF_UpdateOverlayState() end -- The overlay system only serves entities that define this

-- Hits come off the actuator's health
function ENT:ACF_OnDamage(DmgResult, DmgInfo)
	local Actuator = self.Actuator

	if not IsValid(Actuator) then return DmgResult:GetBlank() end

	return Actuator:ACF_OnDamage(DmgResult, DmgInfo)
end
