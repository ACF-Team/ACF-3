local Classes = ACF.Classes
local Racks   = Classes.Racks
local Entries = Classes.GetOrCreateEntries(Racks)

function Racks.Register(ID, Data)
	local Class = Classes.AddSimple(ID, Entries, Data)

	if not Class.EntType then -- TODO: Replace with flag CanDelayMotor
		Class.EntType = "Rack"
	end

	if not Class.LimitConVar then
		Class.LimitConVar = {
			Name   = "_acf_rack",
			Amount = 12,
			Text   = "Maximum amount of ACF Racks a player can create."
		}
	end

	if not Class.BreechConfigs then
		Class.BreechConfigs = {
			Locations = {
				{Name = "Rear", LPos = Vector(-1, 0, 0), LAng = Angle(0, 0, 0), Direction = 1},
				{Name = "Front", LPos = Vector(1, 0, 0), LAng = Angle(180, 0, 0), Direction = -1},
			}
		}
	end

	if Data.MountPoints then
		Class.MagSize = table.Count(Data.MountPoints)
	end

	Classes.AddSboxLimit(Class.LimitConVar)

	return Class
end

Classes.AddSimpleFunctions(Racks, Entries)