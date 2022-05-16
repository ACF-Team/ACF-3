local Network    = ACF.Networking

Network.Sender   = Network.Sender or {}
Network.Receiver = Network.Receiver or {}

local Sender     = Network.Sender
local Receiver   = Network.Receiver
local isstring   = isstring
local isfunction = isfunction

function Network.CreateSender(Name, Function)
	if not isstring(Name) then return end
	if not isfunction(Function) then return end

	Sender[Name] = Function
end

function Network.RemoveSender(Name)
	if not isstring(Name) then return end

	Sender[Name] = nil
end

function Network.CreateReceiver(Name, Function)
	if not isstring(Name) then return end
	if not isfunction(Function) then return end

	Receiver[Name] = Function
end

function Network.RemoveReceiver(Name)
	if not isstring(Name) then return end

	Receiver[Name] = nil
end
