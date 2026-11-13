-- Serverside build hint state, shown as warnings in the entity's overlay
local ACF         = ACF
local Hints       = ACF.Hints
local Diagnostics = ACF.Diagnostics

--- Shows or clears a hint.
--- @param Entity entity
--- @param Id string A registered hint id
--- @param Active boolean Whether the hint currently applies
--- @param Data table|nil Per-hint data, read by the detail
function Hints.Set(Entity, Id, Active, Data)
	local Def = Diagnostics.Get(Id)
	if not Def or Def.Type ~= "Warning" then error("Unknown build hint '" .. tostring(Id) .. "'") end
	if Hints.Requirements[Id] then error("'" .. Id .. "' is a requirement, set it with ENT:SetRequirement") end

	local EntTbl   = Entity:GetTable()
	local Current  = EntTbl.ACF_Hints or {}
	local Existing = Current[Id]

	if Active then
		Data = Data or {}

		if Existing and ACF.SameData(Existing, Data) then return end

		Current[Id] = Data
	else
		if not Existing then return end

		Current[Id] = nil
	end

	EntTbl.ACF_Hints = Current

	if EntTbl.UpdateOverlay then Entity:UpdateOverlay() end
end

--- Adds the active hints to an entity's overlay.
--- @param Entity entity
--- @param State table The overlay state being built
function Hints.AddOverlayLines(Entity, State)
	Diagnostics.AddOverlayLines(State, "Warning", Entity.ACF_Hints)
end
