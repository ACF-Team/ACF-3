local chat     = chat
local table    = table
local Messages = ACF.Utilities.Messages


function Messages.PrintChat(Type, ...)
	if not ... then return end

	local Data    = Messages.GetType(Type)
	local Prefix  = "[ACF" .. Data.Prefix .. "] "
	local Message = istable(...) and ... or { ... }

	chat.AddText(Data.Color, Prefix, color_white, table.concat(Message))
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

-- Backwards compatibility
ACF.PrintToChat = Messages.PrintChat
