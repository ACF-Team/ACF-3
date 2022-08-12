local Messages = ACF.Utilities.Messages
local Green    = Color(80, 255, 80)
local Types    = {
	Normal = {
		Prefix = "",
		Color  = Green
	},
	Info = {
		Prefix = " - Info",
		Color  = Color(0, 233, 255)
	},
	Warning = {
		Prefix = " - Warning",
		Color  = Color(255, 160, 0)
	},
	Error = {
		Prefix = " - Error",
		Color  = Color(255, 80, 80)
	}
}


function Messages.AddType(Name, Prefix, TitleColor)
	if not isstring(Name) then return end

	Types[Name] = {
		Prefix = Prefix and (" - " .. Prefix) or "",
		Color = TitleColor or Green,
	}
end

function Messages.GetType(Name)
	if not isstring(Name) then return end

	return Types[Name] or Types.Normal
end

function Messages.PrintLog(Type, ...)
	if not ... then return end

	local Data    = Messages.GetType(Type)
	local Prefix  = "[ACF" .. Data.Prefix .. "] "
	local Message = istable(...) and ... or { ... }

	Message[#Message + 1] = "\n"

	MsgC(Data.Color, Prefix, color_white, unpack(Message))
end

-- Backwards compatibility
ACF.AddMessageType = Messages.AddType
ACF.AddLogType     = Messages.AddType
ACF.PrintLog       = Messages.PrintLog
