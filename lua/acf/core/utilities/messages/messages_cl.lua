local chat     = chat
local table    = table
local Messages = ACF.Utilities.Messages


function Messages.PrintChat(Type, ...)
	if not ... then return end

	local Data    = Messages.GetType(Type)
	local Prefix  = "[ACF" .. Data.Prefix .. "] "
	local Message = istable(...) and ... or { ... }
	local Strings = string.Split(table.concat(Message), " ")

	-- This is needed to properly make sure that localized strings are translated...because nothing is allowed to be easy in this game...
	for Key, String in ipairs(Strings) do
		if string.StartsWith(String, "#") then
			Strings[Key] = language.GetPhrase(String)
		else
			Strings[Key] = String .. " "
		end
	end

	chat.AddText(Data.Color, Prefix, color_white, table.concat(Strings))
end

net.Receive("ACF_Messages", function()
	local IsLog   = net.ReadBool()
	local Type    = net.ReadString()
	local Message = net.ReadTable()

	if IsLog then
		Messages.PrintLog(Type, Message)
	else
		Messages.PrintChat(Type, Message)
	end
end)