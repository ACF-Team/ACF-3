local ACF           = ACF
local Classes       = ACF.Classes
local Serialization = Classes.Serialization

do -- MARK: Updating
	local function CoerceUserVar(Entity, Name, Value)
		local Field = Classes.GetTypeFieldByName(Entity.ACF_ClassDef, Name)

		Entity:ACF_SetUserVar(Name, Serialization.CoerceField(Field, Value))
	end

	--- The menu and dupes send the mix with the rest of the data, so the deserializer already applied it.
	--- Updates without one (chips, code) fill the crate with only the round they set, as before
	function ENT:SetRoundsFromData(Data)
		if Data.Rounds ~= nil then return end

		CoerceUserVar(self, "Rounds", {})
		CoerceUserVar(self, "RoundCounts", {})
	end
end
