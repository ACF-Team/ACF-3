local ACF = ACF

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

		print("ACF Gamemode has been changed to " .. Names[Mode])
	end,
	ServerDataAllowAdmin = function(_, _, Value)
		local Bool = tobool(Value)

		ACF.AllowAdminData = Bool
	end,
	GunfireEnabled = function(_, _, Value)
		local Bool = tobool(Value)

		if ACF.GunfireEnabled == Bool then return end

		ACF.GunfireEnabled = Bool

		print("ACF Gunfire has been " .. (Bool and "enabled." or "disabled."))
	end,
	HealthFactor = function(_, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.HealthFactor == Factor then return end

		local Old = ACF.HealthFactor

		ACF.HealthFactor = Factor
		ACF.Threshold = ACF.Threshold / Old * Factor

		print("ACF Health Mod changed to a factor of " .. Factor)
	end,
	ArmorFactor = function(_, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.ArmorFactor == Factor then return end

		local Old = ACF.ArmorFactor

		ACF.ArmorFactor = Factor
		ACF.ArmorMod = ACF.ArmorMod / Old * Factor

		print("ACF Armor Mod changed to a factor of " .. Factor)
	end,
	FuelFactor = function(_, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.FuelFactor == Factor then return end

		local Old = ACF.FuelFactor

		ACF.FuelFactor = Factor
		ACF.FuelRate = ACF.FuelRate / Old * Factor

		print("ACF Fuel Rate changed to a factor of " .. Factor)
	end,
	CompFuelFactor = function(_, _, Value)
		local Factor = math.Clamp(math.Round(tonumber(Value) or 1, 2), 0.01, 2)

		if ACF.CompFuelFactor == Factor then return end

		local Old = ACF.CompFuelFactor

		ACF.CompFuelFactor = Factor
		ACF.CompFuelRate = ACF.CompFuelRate / Old * Factor

		print("ACF Competitive Fuel Rate changed to a factor of " .. Factor)
	end,
	AllowFunEnts = function(_, _, Value)
		local Bool = tobool(Value)

		ACF.AllowFunEnts = Bool
	end,
}

for Key, Function in pairs(Settings) do
	ACF.AddServerDataCallback(Key, "Global Variable Callback", Function)
end
