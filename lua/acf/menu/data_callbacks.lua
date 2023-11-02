local ACF = ACF
local GlobalFilter = ACF.GlobalFilter
local Messages = ACF.Utilities.Messages
local Message = SERVER and Messages.PrintLog or Messages.PrintChat

local Settings = {
	ServerDataAllowAdmin = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.AllowAdminData == Bool then return end

		ACF.AllowAdminData = Bool

		Message("Info", "Admin server data access has been " .. (Bool and "enabled." or "disabled."))
	end,
	RestrictInfo = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.RestrictInfo == Bool then return end

		ACF.RestrictInfo = Bool

		Message("Info", "Entity information has been " .. (Bool and "restricted." or "unrestricted."))
	end,
	LegalChecks = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.LegalChecks == Bool then return end

		ACF.LegalChecks = Bool

		Message("Info", "Legality checks have been " .. (Bool and "enabled." or "disabled."))
	end,
	GunsCanFire = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.GunsCanFire == Bool then return end

		ACF.GunsCanFire = Bool

		Message("Info", "Gunfire has been " .. (Bool and "enabled." or "disabled."))
	end,
	GunsCanSmoke = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.GunsCanSmoke == Bool then return end

		ACF.GunsCanSmoke = Bool

		Message("Info", "Gun sounds and particles have been " .. (Bool and "enabled." or "disabled."))
	end,
	RacksCanFire = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.RacksCanFire == Bool then return end

		ACF.RacksCanFire = Bool

		Message("Info", "Missile racks have been " .. (Bool and "enabled." or "disabled."))
	end,
	RequireFuel = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.RequireFuel == Bool then return end

		ACF.RequireFuel = Bool

		Message("Info", "Engine fuel requirements have been " .. (Bool and "enabled." or "disabled."))
	end,
	HealthFactor = function(_, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.HealthFactor == Factor then return end

		local Old = ACF.HealthFactor

		ACF.HealthFactor = Factor
		ACF.Threshold = ACF.Threshold / Old * Factor

		Message("Info", "Health multiplier changed to a factor of " .. Factor .. ".")
	end,
	ArmorFactor = function(_, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.ArmorFactor == Factor then return end

		local Old = ACF.ArmorFactor

		ACF.ArmorFactor = Factor
		ACF.ArmorMod = ACF.ArmorMod / Old * Factor

		Message("Info", "Armor multiplier changed to a factor of " .. Factor .. ".")
	end,
	FuelFactor = function(_, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.FuelFactor == Factor then return end

		local Old = ACF.FuelFactor

		ACF.FuelFactor = Factor
		ACF.FuelRate = ACF.FuelRate / Old * Factor

		Message("Info", "Fuel rate multiplier changed to a factor of " .. Factor .. ".")
	end,
	HEPush = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.HEPush == Bool then return end

		ACF.HEPush = Bool

		Message("Info", "HE entity pushing has been " .. (Bool and "enabled." or "disabled."))
	end,
	KEPush = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.KEPush == Bool then return end

		ACF.KEPush = Bool

		Message("Info", "Kinetic energy entity pushing has been " .. (Bool and "enabled." or "disabled."))
	end,
	RecoilPush = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.RecoilPush == Bool then return end

		ACF.RecoilPush = Bool

		Message("Info", "Recoil entity pushing has been " .. (Bool and "enabled." or "disabled."))
	end,
	AllowFunEnts = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.AllowFunEnts == Bool then return end

		ACF.AllowFunEnts = Bool

		Message("Info", "Fun Entities have been " .. (Bool and "enabled." or "disabled."))
	end,
	AllowProcArmor = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.AllowProcArmor == Bool then return end

		ACF.AllowProcArmor = Bool
		GlobalFilter["acf_armor"] = not Bool

		Message("Info", "Procedural armor has been " .. (Bool and "enabled." or "disabled."))
	end,
	WorkshopContent = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.WorkshopContent == Bool then return end

		ACF.WorkshopContent = Bool

		if CLIENT then return end

		Message("Info", "Workshop content download has been " .. (Bool and "enabled." or "disabled."))
	end,
	WorkshopExtras = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.WorkshopExtras == Bool then return end

		ACF.WorkshopExtras = Bool

		if CLIENT then return end

		Message("Info", "Extra Workshop content download has been " .. (Bool and "enabled." or "disabled."))
	end,
}

for Key, Function in pairs(Settings) do
	ACF.AddServerDataCallback(Key, "Global Variable Callback", Function)
end