local ACF = ACF
local GlobalFilter = ACF.GlobalFilter
local Messages = ACF.Utilities.Messages
local Message = SERVER and Messages.PrintLog or Messages.PrintChat

local Settings = {
	ServerDataAllowAdmin = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.AllowAdminData == Bool then return end

		ACF.AllowAdminData = Bool

		-- NOTE: This check prevents these messages from appearing only when the client first joins,
		-- as Player will always be nil when initially receiving the server's settings.
		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Admin server data access has been " .. (Bool and "enabled." or "disabled."))
	end,
	RestrictInfo = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.RestrictInfo == Bool then return end

		ACF.RestrictInfo = Bool

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Entity information has been " .. (Bool and "restricted." or "unrestricted."))
	end,
	LegalChecks = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.LegalChecks == Bool then return end

		ACF.LegalChecks = Bool

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Legality checks for ACF entities have been " .. (Bool and "enabled." or "disabled."))
	end,
	NameAndShame = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.NameAndShame == Bool then return end

		ACF.NameAndShame = Bool

		if CLIENT and not IsValid(Player) then return end

		if not ACF.LegalChecks then return end

		Message("Info", "Public shaming for illegal actions has been " .. (Bool and "enabled." or "disabled."))
	end,
	VehicleLegalChecks = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.VehicleLegalChecks == Bool then return end

		ACF.VehicleLegalChecks = Bool

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Legality checks for vehicles have been " .. (Bool and "enabled." or "disabled."))
	end,
	GunsCanFire = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.GunsCanFire == Bool then return end

		ACF.GunsCanFire = Bool

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Gunfire has been " .. (Bool and "enabled." or "disabled."))
	end,
	GunsCanSmoke = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.GunsCanSmoke == Bool then return end

		ACF.GunsCanSmoke = Bool

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Gun sounds and particles have been " .. (Bool and "enabled." or "disabled."))
	end,
	RacksCanFire = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.RacksCanFire == Bool then return end

		ACF.RacksCanFire = Bool

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Missile racks have been " .. (Bool and "enabled." or "disabled."))
	end,
	RequireFuel = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.RequireFuel == Bool then return end

		ACF.RequireFuel = Bool

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Engine fuel requirements have been " .. (Bool and "enabled." or "disabled."))
	end,
	HealthFactor = function(Player, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.HealthFactor == Factor then return end

		local Old = ACF.HealthFactor

		ACF.HealthFactor = Factor
		ACF.Threshold = ACF.Threshold / Old * Factor

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Health multiplier changed to a factor of " .. Factor .. ".")
	end,
	ArmorFactor = function(Player, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.ArmorFactor == Factor then return end

		local Old = ACF.ArmorFactor

		ACF.ArmorFactor = Factor
		ACF.ArmorMod = ACF.ArmorMod / Old * Factor

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Armor multiplier changed to a factor of " .. Factor .. ".")
	end,
	FuelFactor = function(Player, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.FuelFactor == Factor then return end

		local Old = ACF.FuelFactor

		ACF.FuelFactor = Factor
		ACF.FuelRate = ACF.FuelRate / Old * Factor

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Fuel rate multiplier changed to a factor of " .. Factor .. ".")
	end,
	HEPush = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.HEPush == Bool then return end

		ACF.HEPush = Bool

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "HE entity pushing has been " .. (Bool and "enabled." or "disabled."))
	end,
	KEPush = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.KEPush == Bool then return end

		ACF.KEPush = Bool

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Kinetic energy entity pushing has been " .. (Bool and "enabled." or "disabled."))
	end,
	RecoilPush = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.RecoilPush == Bool then return end

		ACF.RecoilPush = Bool

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Recoil entity pushing has been " .. (Bool and "enabled." or "disabled."))
	end,
	AllowFunEnts = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.AllowFunEnts == Bool then return end

		ACF.AllowFunEnts = Bool

		if CLIENT and not IsValid(Player) then return end

		Message("Info", "Fun Entities have been " .. (Bool and "enabled." or "disabled."))
	end,
	AllowProcArmor = function(Player, _, Value)
		local Bool = tobool(Value)

		if ACF.AllowProcArmor == Bool then return end

		ACF.AllowProcArmor = Bool
		GlobalFilter["acf_armor"] = not Bool

		if CLIENT and not IsValid(Player) then return end

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