local ACF      = ACF
local Network  = ACF.Networking
local Sender   = Network.Sender
local Receiver = Network.Receiver
local ToJSON   = util.TableToJSON
local ToTable  = util.JSONToTable
local Messages = {}
local IsQueued

local function PrepareQueue(Name)
	if not Messages[Name] then
		Messages[Name] = {}
	end

	return Messages[Name]
end

-- NOTE: Consider the overflow size
local function SendMessages()
	if next(Messages) then
		net.Start("ACF_Networking")
			net.WriteString(ToJSON(Messages))
		net.SendToServer()

		for K in pairs(Messages) do
			Messages[K] = nil
		end
	end

	IsQueued = nil
end

function Network.Send(Name, ...)
	if not Name then return end
	if not Sender[Name] then return end

	local Handler = Sender[Name]
	local Queue   = PrepareQueue(Name)

	Handler(Queue, ...)

	if not IsQueued then
		IsQueued = true

		timer.Simple(0, SendMessages)
	end
end

net.Receive("ACF_Networking", function()
	local Message = ToTable(net.ReadString())

	for Name, Data in pairs(Message) do
		local Handler = Receiver[Name]

		if Handler then
			Handler(Data)
		end
	end
end)