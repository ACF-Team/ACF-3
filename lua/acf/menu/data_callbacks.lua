local ACF      = ACF
local Messages = ACF.Utilities.Messages
local Message  = SERVER and Messages.PrintLog or Messages.PrintChat

-- Read __DefinedSettings from globals/etc.
-- Also write ACF.__OnDefinedSetting at this point, since now it's available and we'll want to register it for live updates

function ACF.__OnDefinedSetting(Key, Default, TextWhenChanged, Callback)
	ACF.AddServerDataCallback(Key, "Global Variable Callback", function(Player, _, Value)
		Value = Callback(Key, Value)

		if Value == ACF[Key] then return end

		ACF[Key] = Value

		if CLIENT and not IsValid(Player) then return end

		if TextWhenChanged then
			local Text
			if isbool(Value) then
				Text = TextWhenChanged:format(Value and "enabled" or "disabled")
			else
				Text = TextWhenChanged:format(Value)
			end

			Message("Info", Text)
		end
	end)

	if SERVER then
		ACF.PersistServerData(Key, Default)
	end
end

-- Setup the variables that have already been defined by ACF.DefineSetting (likely by globals.lua)

for _, Setting in pairs(ACF.__DefinedSettings) do
	ACF.__OnDefinedSetting(Setting.Key, Setting.Default, Setting.TextWhenChanged, Setting.Callback)
end