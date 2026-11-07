-- Damage condition of ACF entities, kept apart from legality restrictions
local ACF = ACF

--- @param Entity entity
--- @param EntTbl table|nil The entity's table, for hot paths that already have it
--- @return boolean # Whether the entity has been reduced to zero health
function ACF.IsDestroyed(Entity, EntTbl)
	local EntACF = (EntTbl or Entity:GetTable()).ACF

	return EntACF ~= nil and EntACF.Health ~= nil and EntACF.Health <= 0
end

--- @param Entity entity
--- @param EntTbl table|nil The entity's table, for hot paths that already have it
--- @return boolean # Whether the entity is neither destroyed nor restricted
function ACF.IsOperational(Entity, EntTbl)
	EntTbl = EntTbl or Entity:GetTable()

	return not ACF.IsDestroyed(Entity, EntTbl) and not EntTbl.Disabled
end

--- Runs the ACF_OnEntityDestroyed or ACF_OnEntityRestored hook if health crossed zero, never ENT:Enable or ENT:Disable.
--- @param Entity entity
function ACF.RefreshCondition(Entity)
	if not IsValid(Entity) then return end

	local EntTbl    = Entity:GetTable()
	local Destroyed = ACF.IsDestroyed(Entity)

	if Destroyed == (EntTbl.ACF_Destroyed == true) then return end

	EntTbl.ACF_Destroyed = Destroyed or nil

	hook.Run(Destroyed and "ACF_OnEntityDestroyed" or "ACF_OnEntityRestored", Entity)

	if EntTbl.UpdateOverlay then Entity:UpdateOverlay(true) end
end
