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

do -- Data sanitization and compression
	local ents  = ents
	local math  = math
	local table = table
	local util  = util
	local Types = {
		[TYPE_VECTOR] = {
			Compress = function(Value)
				return {
					__t = TYPE_VECTOR,
					math.floor(Value.x * 100),
					math.floor(Value.y * 100),
					math.floor(Value.z * 100),
				}
			end,
			Decompress = function(Value)
				return Vector(
					Value[1] * 0.01,
					Value[2] * 0.01,
					Value[3] * 0.01
				)
			end,
		},
		[TYPE_ENTITY] = {
			Compress = function(Value)
				return {
					__t = TYPE_ENTITY,
					Value:EntIndex(),
				}
			end,
			Decompress = function(Value)
				return ents.GetByIndex(Value[1])
			end,
		},
	}

	local function ProcessRaw(Data, Result, Done)
		local Keys = table.GetKeys(Data)

		Result = Result or {}
		Done   = Done or {}

		for I = 1, #Keys do
			local Key   = Keys[I]
			local Value = Data[Key]

			if istable(Value) and not Value.__t then
				local Copy = Done[Value]

				if not Copy then
					Copy = {}

					ProcessRaw(Value, Copy, Done)
				end

				Value = Copy
			elseif Types[TypeID(Value)] then
				local Functions = Types[TypeID(Value)]

				Value = Functions.Compress(Value)
			end

			Result[Key] = Value
		end

		return Result
	end

	local function ProcessReceived(Data)
		local Keys = table.GetKeys(Data)

		for I = 1, #Keys do
			local Key   = Keys[I]
			local Value = Data[Key]
			if istable(Value) then
				local Type      = Value.__t
				local Functions = Type and Types[Type]

				if Functions then
					Value = Functions.Decompress(Value)
				else
					ProcessReceived(Value)
				end

			end

			Data[Key] = Value
		end

		return Data
	end

	function Network.Compress(Data)
		local Processed = ProcessRaw(Data)
		local Compress  = util.Compress
		local ToJSON    = util.TableToJSON

		return Compress(ToJSON(Processed))
	end

	function Network.Decompress(Data)
		local Decompress = util.Decompress
		local ToTable    = util.JSONToTable
		local Received   = ToTable(Decompress(Data))

		return ProcessReceived(Received)
	end
end