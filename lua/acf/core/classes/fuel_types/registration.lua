local Classes = ACF.Classes
Classes.FuelTypes = Classes.FuelTypes or {}

local Types = Classes.FuelTypes

-- Fuel types were migrated to the new DefineClass system (ACF.FuelTypes.*). This file keeps the
-- legacy read API (Get/GetList/GetEntries/GetStored) alive for older consumers (the engine menu,
-- starfall, etc.) by sourcing it from the new class tree. The class tables themselves serve as the
-- "entry" objects since they already carry ID/Name/Density and the optional display functions.
local BASE = "ACF.FuelTypes.FuelType"

local function GetMap()
	local Map = {}

	for _, Class in ipairs(Classes.GetSubtypes(BASE)) do
		if Class.ID then Map[Class.ID] = Class end
	end

	return Map
end

function Types.GetStored()
	return GetMap()
end

function Types.GetEntries()
	return GetMap()
end

function Types.Get(ID)
	if not ID then return end

	return GetMap()[ID]
end

function Types.GetList()
	local Result = {}

	for _, Class in pairs(GetMap()) do
		Result[#Result + 1] = Class
	end

	return Result
end
