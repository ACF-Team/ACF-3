util.AddNetworkString("ACF_ChatMessage")

function ACF.SendMessage(Player, Type, ...)
	if not ... then return end

	local Message = istable(...) and ... or { ... }

	net.Start("ACF_ChatMessage")
		net.WriteString(Type or "Normal")
		net.WriteTable(Message)
	if IsValid(Player) then
		net.Send(Player)
	else
		net.Broadcast()
	end
end

local Types = {
	Normal = {
		Prefix = "",
		Color = Color(80, 255, 80)
	},
	Info = {
		Prefix = " - Info",
		Color = Color(0, 233, 255)
	},
	Warning = {
		Prefix = " - Warning",
		Color = Color(255, 160, 0)
	},
	Error = {
		Prefix = " - Error",
		Color = Color(255, 80, 80)
	}
}

function ACF.AddLogType(Name, Prefix, TitleColor)
	if not Name then return end

	Types[Name] = {
		Prefix = Prefix and (" - " .. Prefix) or "",
		Color = TitleColor or Color(80, 255, 80),
	}
end

function ACF.PrintLog(Type, ...)
	if not ... then return end

	local Data = Types[Type] or Types.Normal
	local Prefix = "[ACF" .. Data.Prefix .. "] "
	local Message = istable(...) and ... or { ... }

	Message[#Message + 1] = "\n"

	MsgC(Data.Color, Prefix, color_white, unpack(Message))
end