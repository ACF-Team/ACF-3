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

		local function TranslateData(String)
			return unpack(string.Explode(":", String))
		end

		net.Receive("ACF_ToolData", function(_, Player)
			if not IsValid(Player) then return end

			local Key, Value = TranslateData(net.ReadString())

			ToolData[Player][Key] = Value

			print("Received", Player, Key, Value)
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

function ACF_GetHitAngle(HitNormal, HitVector)
	return math.min(math.deg(math.acos(HitNormal:Dot(-HitVector:GetNormalized()))), 89.999)
end