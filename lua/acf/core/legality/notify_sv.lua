-- Serverside notification of the owner when one of their entities is restricted
local ACF         = ACF
local Legality    = ACF.Legality
local Diagnostics = ACF.Diagnostics
local Notify      = ACF.Utilities.Notify

local NOTIFY_COOLDOWN = 10 -- Seconds before the same violation notifies its owner again

--- Tells the owner about a new violation after its cooldown and delay, and shames the entity if the restriction asks.
--- @param Entity entity
--- @param Id string A registered restriction id
function Legality.NotifyOwner(Entity, Id)
	local EntTbl   = Entity:GetTable()
	local Notified = EntTbl.ACF_ViolationNotified or {}
	local Now      = CurTime()

	EntTbl.ACF_ViolationNotified = Notified

	if Notified[Id] and Now - Notified[Id] < NOTIFY_COOLDOWN then return end

	Notified[Id] = Now

	local Def = Legality.Checks[Id]
	if Def.Silent then return end

	timer.Simple(Def.NotifyDelay or 0, function()
		if not IsValid(Entity) then return end

		local Violation = Entity.ACF_Violations and Entity.ACF_Violations[Id]
		if not Violation then return end -- Fixed during the delay

		if Def.Shame then ACF.Shame(Entity, Def.Shame) end

		local Owner = Entity:CPPIGetOwner()
		if not IsValid(Owner) or not tobool(Owner:GetInfo("acf_legalhints")) then return end

		local Title, Detail = Diagnostics.Describe(Id, Violation.Data)
		local Text = Diagnostics.Get(Id)

		Notify.EntityDisabledToPlayer(Entity, Owner, Detail ~= "" and Detail or Title, Text.Ponder, Text.Wiki, Id)
	end)
end
