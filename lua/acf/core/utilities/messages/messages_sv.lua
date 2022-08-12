local net      = net
local Messages = ACF.Utilities.Messages


util.AddNetworkString("ACF_Messages")

function Messages.SendChat(Player, Type, ...)
	if not ... then return end

	local Message = istable(...) and ... or { ... }

	net.Start("ACF_Messages")
		net.WriteBool(false)
		net.WriteString(Type or "Normal")
		net.WriteTable(Message)
	if IsValid(Player) then
		net.Send(Player)
	else
		net.Broadcast()
	end
end

function Messages.SendLog(Player, Type, ...)
	if not ... then return end

	local Message = istable(...) and ... or { ... }

	net.Start("ACF_Messages")
		net.WriteBool(true)
		net.WriteString(Type or "Normal")
		net.WriteTable(Message)
	if IsValid(Player) then
		net.Send(Player)
	else
		net.Broadcast()
	end
end

-- Backwards compatibility
ACF.SendMessage = Messages.SendChat
