-- Shared base of warnings and errors, which both diagnose a problem to the player the same way
local ACF    = ACF
local Diagnostics = ACF.Diagnostics or {}
ACF.Diagnostics   = Diagnostics

local All = {}

-- Warning: a problem that is only shown, raised and cleared with ACF.Hints.Set by the code that detects it.
-- Error: a problem that disables the entity, raised through ACF.Legality or shown by the entity's own overlay.
-- Overlay is the overlay state method that adds a line of that type.
local Types = {
	Warning = {Overlay = "AddWarning", Defs = {}, Order = {}},
	Error   = {Overlay = "AddError", Defs = {}, Order = {}},
}

--- The overlay state method that adds a line of the type.
--- @param Type string "Warning" or "Error"
--- @return string
function Diagnostics.GetOverlayMethod(Type)
	return Types[Type].Overlay
end

--- The ids of one type of diagnostic in registration order, the list is live and must not be modified.
--- @param Type string "Warning" or "Error"
--- @return table
function Diagnostics.GetIds(Type)
	return Types[Type].Order
end

--- Registers a diagnostic, ids are unique across every type.
--- Fields: Title, Detail (string or function of the diagnostic data), Help (how to fix it, shown on hover), Ponder, Wiki.
--- Restriction behaviour is registered with ACF.Legality.RegisterRestriction instead.
--- @param Type string "Warning" or "Error"
--- @param Id string Unique identifier
--- @param Data table The definition
--- @return table|nil # The registered definition
function Diagnostics.Register(Type, Id, Data)
	local Registry = Types[Type]

	if not Registry then
		ErrorNoHalt("Unknown diagnostic type '" .. tostring(Type) .. "'\n")
		return
	end

	local Other = All[Id]

	if Other and Other.Type ~= Type then
		ErrorNoHalt("Diagnostic '" .. Id .. "' is already registered as a " .. Other.Type .. "\n")
		return
	end

	Data.Id   = Id
	Data.Type = Type

	if not Registry.Defs[Id] then Registry.Order[#Registry.Order + 1] = Id end

	Registry.Defs[Id] = Data
	All[Id]           = Data

	return Data
end

--- @param Id string
--- @return table|nil # The definition of a warning or error
function Diagnostics.Get(Id)
	return All[Id]
end

--- @param Id string
--- @return table|nil # The definition if it has help text
function Diagnostics.GetHelp(Id)
	local Def = All[Id]

	return Def and Def.Help and Def or nil
end

--- Builds the player facing title and detail of a diagnostic, data can override them with its own Title and Detail.
--- @param Id string
--- @param Data table|nil Per-diagnostic data
--- @return string, string # Title and detail
function Diagnostics.Describe(Id, Data)
	local Def    = All[Id]
	local Title  = Data and Data.Title or Def and Def.Title or Id
	local Detail = Data and Data.Detail or Def and Def.Detail or ""

	if isfunction(Detail) then Detail = Detail(Data or {}) end

	return Title, Detail
end
