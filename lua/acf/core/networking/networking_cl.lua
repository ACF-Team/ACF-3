local ACF        = ACF
local Network    = ACF.Networking
local Sender     = Network.Sender
local Receiver   = Network.Receiver
local ToJSON     = util.TableToJSON
local ToTable    = util.JSONToTable
local Compress   = util.Compress
local Decompress = util.Decompress
local Messages   = {}
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
		local Compressed = Compress(ToJSON(Messages))

		net.Start("ACF_Networking")
			net.WriteUInt(#Compressed, 16)
			net.WriteData(Compressed)
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

net.Receive("ACF_Networking", function(Bits)
	local Bytes   = net.ReadUInt(16)
	local String  = Decompress(net.ReadData(Bytes))
	local Message = ToTable(String)

	if not Message then
		local Error = "ACF Networking: Failed to parse message. Report this to the ACF Team.\nMessage size: %sB\nTotal size: %sB\nMessage: %s"
		local Total = Bits * 0.125 -- Bits to bytes
		local JSON  = String ~= "" and String or "Empty, possible overflow."

		ErrorNoHalt(Error:format(Bytes, Total, JSON))

		return
	end

	for Name, Data in pairs(Message) do
		local Handler = Receiver[Name]

		if Handler then
			Handler(Data)
		end
	end
end)
