do -- Serverside console log messages
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
end

do -- Clientside message delivery
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
end

do -- Tool data functions
	local ToolData = {}

	do -- Data syncronization
		util.AddNetworkString("ACF_ToolData")

		net.Receive("ACF_ToolData", function(_, Player)
			if not IsValid(Player) then return end

			local Key = net.ReadString()
			local Value = net.ReadType()

			ToolData[Player][Key] = Value

			print("Received", Player, Key, Value, type(Value))
		end)

		hook.Add("PlayerInitialSpawn", "ACF Tool Data", function(Player)
			ToolData[Player] = {}
		end)

		hook.Add("PlayerDisconnected", "ACF Tool Data", function(Player)
			ToolData[Player] = nil
		end)
	end

	do -- Read functions
		function ACF.GetToolData(Player)
			if not IsValid(Player) then return {} end
			if not ToolData[Player] then return {} end

			local Result = {}

			for K, V in pairs(ToolData[Player]) do
				Result[K] = V
			end

			return Result
		end

		function ACF.ReadBool(Player, Key)
			if not IsValid(Player) then return false end
			if not Key then return false end

			local Data = ToolData[Player]

			if not Data then return false end

			return tobool(Data[Key])
		end

		function ACF.ReadNumber(Player, Key)
			if not IsValid(Player) then return 0 end
			if not Key then return 0 end

			local Data = ToolData[Player]

			if not Data then return 0 end
			if not Data[Key] then return 0 end

			return tonumber(Data[Key])
		end

		function ACF.ReadString(Player, Key)
			if not IsValid(Player) then return "" end
			if not Key then return "" end

			local Data = ToolData[Player]

			if not Data then return "" end
			if not Data[Key] then return "" end

			return tostring(Data[Key])
		end
	end
end

do -- Entity saving and restoring
	local Constraints = duplicator.ConstraintType
	local Saved = {}

	function ACF.SaveEntity(Entity)
		if not IsValid(Entity) then return end

		local PhysObj = Entity:GetPhysicsObject()

		Saved[Entity] = {
			Constraints = constraint.GetTable(Entity),
			Gravity = PhysObj:IsGravityEnabled(),
			Motion = PhysObj:IsMotionEnabled(),
		}

		Entity:CallOnRemove("ACF_RestoreEntity", function()
			Saved[Entity] = nil
		end)
	end

	function ACF.RestoreEntity(Entity)
		if not IsValid(Entity) then return end
		if not Saved[Entity] then return end

		local PhysObj = Entity:GetPhysicsObject()
		local EntData = Saved[Entity]

		PhysObj:EnableGravity(EntData.Gravity)
		PhysObj:EnableMotion(EntData.Motion)

		for _, Data in ipairs(EntData.Constraints) do
			local Constraint = Constraints[Data.Type]
			local Args = {}

			for Index, Name in ipairs(Constraint.Args) do
				Args[Index] = Data[Name]
			end

			Constraint.Func(unpack(Args))
		end

		Saved[Entity] = nil

		Entity:RemoveCallOnRemove("ACF_RestoreEntity")
	end
end

do -- Entity linking
	local EntityLink = {}
	local function GetEntityLinks(Entity, VarName, SingleEntry)
		if not Entity[VarName] then return {} end

		if SingleEntry then
			return { [Entity[VarName]] = true }
		end

		local Result = {}

		for K in pairs(Entity[VarName]) do
			Result[K] = true
		end

		return Result
	end

	-- If your entity can link/unlink other entities, you should use this
	function ACF.RegisterLinkSource(Class, VarName, SingleEntry)
		local Data = EntityLink[Class]

		if not Data then
			EntityLink[Class] = {
				[VarName] = function(Entity)
					return GetEntityLinks(Entity, VarName, SingleEntry)
				end
			}
		else
			Data[VarName] = function(Entity)
				return GetEntityLinks(Entity, VarName, SingleEntry)
			end
		end
	end

	function ACF.GetAllLinkSources(Class)
		if not EntityLink[Class] then return {} end

		local Result = {}

		for K, V in pairs(EntityLink[Class]) do
			Result[K] = V
		end

		return Result
	end

	function ACF.GetLinkSource(Class, VarName)
		if not EntityLink[Class] then return end

		return EntityLink[Class][VarName]
	end

	local ClassLink = { Link = {}, Unlink = {} }
	local function RegisterNewLink(Action, Class1, Class2, Function)
		if not isfunction(Function) then return end

		local Target = ClassLink[Action]
		local Data1 = Target[Class1]

		if not Data1 then
			Target[Class1] = {
				[Class2] = function(Ent1, Ent2)
					return Function(Ent1, Ent2)
				end
			}
		else
			Data1[Class2] = function(Ent1, Ent2)
				return Function(Ent1, Ent2)
			end
		end

		if Class1 == Class2 then return end

		local Data2 = Target[Class2]

		if not Data2 then
			Target[Class2] = {
				[Class1] = function(Ent2, Ent1)
					return Function(Ent1, Ent2)
				end
			}
		else
			Data2[Class1] = function(Ent2, Ent1)
				return Function(Ent1, Ent2)
			end
		end
	end

	function ACF.RegisterClassLink(Class1, Class2, Function)
		RegisterNewLink("Link", Class1, Class2, Function)
	end

	function ACF.GetClassLink(Class1, Class2)
		if not ClassLink.Link[Class1] then return end

		return ClassLink.Link[Class1][Class2]
	end

	function ACF.RegisterClassUnlink(Class1, Class2, Function)
		RegisterNewLink("Unlink", Class1, Class2, Function)
	end

	function ACF.GetClassUnlink(Class1, Class2)
		if not ClassLink.Unlink[Class1] then return end

		return ClassLink.Unlink[Class1][Class2]
	end
end

do -- Entity inputs
	local Inputs = {}

	local function GetClass(Class, Add)
		if Add and not Inputs[Class] then
			Inputs[Class] = {}
		end

		return Inputs[Class]
	end

	function ACF.AddInputAction(Class, Name, Action)
		if not Class then return end
		if not Name then return end
		if not isfunction(Action) then return end

		local Data = GetClass(Class, true)

		Data[Name] = Action
	end

	function ACF.GetInputAction(Class, Name)
		if not Class then return end
		if not Name then return end

		local Data = GetClass(Class)

		if not Data then return end

		return Data[Name]
	end

	function ACF.GetInputActions(Class)
		if not Class then return end

		local Data = GetClass(Class)

		if not Data then return end

		local Result = {}

		for K, V in pairs(Data) do
			Result[K] = V
		end

		return Result
	end
end

function ACF_GetHitAngle(HitNormal, HitVector)
	return math.min(math.deg(math.acos(HitNormal:Dot(-HitVector:GetNormalized()))), 89.999)
end