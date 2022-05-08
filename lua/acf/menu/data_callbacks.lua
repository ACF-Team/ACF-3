local ACF = ACF
local Message = SERVER and ACF.PrintLog or ACF.PrintToChat

local Names = {
	[1] = "Sandbox",
	[2] = "Classic",
	[3] = "Competitive"
}

local Settings = {
	Gamemode = function(_, _, Value)
		local Mode = math.Clamp(math.floor(tonumber(Value) or 2), 1, 3)

		if Mode == ACF.Gamemode then return end

		ACF.Gamemode = Mode

		Message("Info", "ACF Gamemode has been changed to " .. Names[Mode])
	end,
	ServerDataAllowAdmin = function(_, _, Value)
		ACF.AllowAdminData = tobool(Value)
	end,
	RestrictInfo = function(_, _, Value)
		ACF.RestrictInfo = tobool(Value)
	end,
	GunsCanFire = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.GunsCanFire == Bool then return end

		ACF.GunsCanFire = Bool

		Message("Info", "ACF Gunfire has been " .. (Bool and "enabled." or "disabled."))
	end,
	GunsCanSmoke = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.GunsCanSmoke == Bool then return end

		ACF.GunsCanSmoke = Bool

		Message("Info", "ACF Gun sound and particles have been " .. (Bool and "enabled." or "disabled."))
	end,
	RacksCanFire = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.RacksCanFire == Bool then return end

		ACF.RacksCanFire = Bool

		Message("Info", "ACF Missile Racks have been " .. (Bool and "enabled." or "disabled."))
	end,
	HealthFactor = function(_, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.HealthFactor == Factor then return end

		local Old = ACF.HealthFactor

		ACF.HealthFactor = Factor
		ACF.Threshold = ACF.Threshold / Old * Factor

		Message("Info", "ACF Health Mod changed to a factor of " .. Factor)
	end,
	ArmorFactor = function(_, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.ArmorFactor == Factor then return end

		local Old = ACF.ArmorFactor

		ACF.ArmorFactor = Factor
		ACF.ArmorMod = ACF.ArmorMod / Old * Factor

		Message("Info", "ACF Armor Mod changed to a factor of " .. Factor)
	end,
	FuelFactor = function(_, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.FuelFactor == Factor then return end

		local Old = ACF.FuelFactor

		ACF.FuelFactor = Factor
		ACF.FuelRate = ACF.FuelRate / Old * Factor

		Message("Info", "ACF Fuel Rate changed to a factor of " .. Factor)
	end,
	CompFuelFactor = function(_, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.CompFuelFactor == Factor then return end

		local Old = ACF.CompFuelFactor

		ACF.CompFuelFactor = Factor
		ACF.CompFuelRate = ACF.CompFuelRate / Old * Factor

		Message("Info", "ACF Competitive Fuel Rate changed to a factor of " .. Factor)
	end,
	HEPush = function(_, _, Value)
		ACF.HEPush = tobool(Value)
	end,
	KEPush = function(_, _, Value)
		ACF.KEPush = tobool(Value)
	end,
	RecoilPush = function(_, _, Value)
		ACF.RecoilPush = tobool(Value)
	end,
	AllowFunEnts = function(_, _, Value)
		ACF.AllowFunEnts = tobool(Value)
	end,
	WorkshopContent = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.WorkshopContent == Bool then return end

		ACF.WorkshopContent = Bool

		if CLIENT then return end

		Message("Info", "ACF Workshop Content download has been " .. (Bool and "enabled." or "disabled."))
	end,
	WorkshopExtras = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.WorkshopExtras == Bool then return end

		ACF.WorkshopExtras = Bool

		if CLIENT then return end

		Message("Info", "ACF Extra Workshop Content download has been " .. (Bool and "enabled." or "disabled."))
	end,
}

for Key, Function in pairs(Settings) do
	ACF.AddServerDataCallback(Key, "Global Variable Callback", Function)
end

do -- Volume setting callback
	local Realm = SERVER and "Server" or "Client"
	local Callback = ACF["Add" .. Realm .. "DataCallback"]

	Callback("Volume", "Volume Variable Callback", function(_, _, Value)
		ACF.Volume = math.Clamp(tonumber(Value) or 1, 0, 1)
	end)
end
