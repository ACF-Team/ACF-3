local ACF = ACF

do -- Networked notifications
	util.AddNetworkString("ACF_Notify")

	function ACF.SendNotify(Player, Success, Message)
		net.Start("ACF_Notify")
			net.WriteBool(Success or false)
			net.WriteString(Message or "")
		net.Send(Player)
	end

	ACF_SendNotify = ACF.SendNotify -- Backwards compatibility
end

do -- HTTP Request
	local NoRequest = true
	local http      = http
	local Queue     = {}
	local Count     = 0

	local function SuccessfulRequest(Code, Body, OnSuccess, OnFailure)
		local Data = Body and util.JSONToTable(Body)
		local Error

		if not Body then
			Error = "No data found on request."
		elseif Code ~= 200 then
			Error = "Request unsuccessful (Code " .. Code .. ")."
		elseif not (Data and next(Data)) then
			Error = "Empty request result."
		end

		if Error then
			ACF.PrintLog("HTTP_Error", Error)

			if OnFailure then
				OnFailure(Error)
			end
		elseif OnSuccess then
			OnSuccess(Body, Data)
		end
	end

	function ACF.StartRequest(Link, OnSuccess, OnFailure, Headers)
		if not isstring(Link) then return end
		if not isfunction(OnSuccess) then OnSuccess = nil end
		if not isfunction(OnFailure) then OnFailure = nil end
		if not istable(Headers) then Headers = nil end

		if NoRequest then
			Count = Count + 1

			Queue[Count] = {
				Link = Link,
				OnSuccess = OnSuccess,
				OnFailure = OnFailure,
				Headers = Headers,
			}

			return
		end

		http.Fetch(
			Link,
			function(Body, _, _, Code)
				SuccessfulRequest(Code, Body, OnSuccess, OnFailure)
			end,
			function(Error)
				ACF.PrintLog("HTTP_Error", Error)

				if OnFailure then
					OnFailure(Error)
				end
			end,
			Headers)
	end

	hook.Add("Initialize", "ACF Allow Requests", function()
		ACF.AddLogType("HTTP_Error", "HTTP", Color(241, 80, 47))

		timer.Simple(0, function()
			NoRequest = nil

			if Count > 0 then
				for _, Request in ipairs(Queue) do
					ACF.StartRequest(
						Request.Link,
						Request.OnSuccess,
						Request.OnFailure,
						Request.Headers
					)
				end
			end

			Count = nil
			Queue = nil
		end)

		hook.Remove("Initialize", "ACF Allow Requests")
	end)
end

do -- Entity saving and restoring
	local ConstraintTypes = duplicator.ConstraintType
	local Entities = {}

	local function ResetCollisions(Entity)
		if not IsValid(Entity) then return end

		local PhysObj = Entity:GetPhysicsObject()

		if not IsValid(PhysObj) then return end

		PhysObj:EnableCollisions(true)
	end

	local function ClearHydraulic(Constraint)
		local ID = Constraint.MyCrtl

		if not ID then return end

		local Controller = ents.GetByIndex(ID)

		if not IsValid(Controller) then return end

		local Rope = Controller.Rope

		Controller:DontDeleteOnRemove(Constraint)
		Constraint:DontDeleteOnRemove(Controller)

		if IsValid(Rope) then
			Controller:DontDeleteOnRemove(Rope)
			Rope:DontDeleteOnRemove(Constraint)
		end
	end

	-- Similar to constraint.RemoveAll
	local function ClearConstraints(Entity)
		local Constraints = Entity.Constraints

		if not Constraints then return end

		for Index, Constraint in pairs(Constraints) do
			if IsValid(Constraint) then
				ResetCollisions(Constraint.Ent1)
				ResetCollisions(Constraint.Ent2)

				if Constraint.Type == "WireHydraulic" then
					ClearHydraulic(Constraint)
				end

				Constraint:Remove()
			end

			Constraints[Index] = nil
		end

		Entity:IsConstrained()
	end

	local function GetFactory(Name)
		if not Name then return end

		return ConstraintTypes[Name]
	end

	local function RestoreHydraulic(ID, Constraint, Rope)
		local Controller = ents.GetByIndex(ID)

		if not IsValid(Controller) then return end

		Constraint.MyCrtl = Controller:EntIndex()
		Controller.MyId   = Controller:EntIndex()

		Controller:SetConstraint(Constraint)
		Controller:DeleteOnRemove(Constraint)

		if IsValid(Rope) then
			Controller:SetRope(Rope)
			Controller:DeleteOnRemove(Rope)
		end

		Controller:SetLength(Controller.TargetLength)
		Controller:TriggerInput("Constant", Controller.current_constant)
		Controller:TriggerInput("Damping", Controller.current_damping)

		Constraint:DeleteOnRemove(Controller)
	end

	local function RestoreConstraint(Data)
		local Type    = Data.Type
		local Factory = GetFactory(Type)

		if not Factory then return end

		local ID   = Data.MyCrtl
		local Args = {}

		if ID then Data.MyCrtl = nil end

		for Index, Name in ipairs(Factory.Args) do
			Args[Index] = Data[Name]
		end

		local Constraint, Rope = Factory.Func(unpack(Args))

		if Type == "WireHydraulic" then
			RestoreHydraulic(ID, Constraint, Rope)
		end
	end

	------------------------------------------------------------------------

	function ACF.SaveEntity(Entity)
		if not IsValid(Entity) then return end

		local PhysObj = Entity:GetPhysicsObject()

		if not IsValid(PhysObj) then return end

		Entities[Entity] = {
			Constraints = constraint.GetTable(Entity),
			Gravity = PhysObj:IsGravityEnabled(),
			Motion = PhysObj:IsMotionEnabled(),
			Contents = PhysObj:GetContents(),
			Material = PhysObj:GetMaterial(),
		}

		ClearConstraints(Entity)

		Entity:CallOnRemove("ACF_RestoreEntity", function()
			Entities[Entity] = nil
		end)
	end

	function ACF.RestoreEntity(Entity)
		if not IsValid(Entity) then return end
		if not Entities[Entity] then return end

		local PhysObj = Entity:GetPhysicsObject()
		local EntData = Entities[Entity]

		PhysObj:EnableGravity(EntData.Gravity)
		PhysObj:EnableMotion(EntData.Motion)
		PhysObj:SetContents(EntData.Contents)
		PhysObj:SetMaterial(EntData.Material)

		for _, Data in ipairs(EntData.Constraints) do
			RestoreConstraint(Data)
		end

		Entities[Entity] = nil

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

	function ACF.GetLinkedEntities(Entity)
		if not IsValid(Entity) then return {} end

		local Links = EntityLink[Entity:GetClass()]

		if not Links then return {} end

		local Result = {}

		for _, Function in pairs(Links) do
			for Ent in pairs(Function(Entity)) do
				Result[Ent] = true
			end
		end

		return Result
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

	local function GetClass(Class)
		if not Inputs[Class] then
			Inputs[Class] = {}
		end

		return Inputs[Class]
	end

	function ACF.AddInputAction(Class, Name, Action)
		if not Class then return end
		if not Name then return end
		if not isfunction(Action) then return end

		local Data = GetClass(Class)

		Data[Name] = Action
	end

	function ACF.GetInputAction(Class, Name)
		if not Class then return end
		if not Name then return end

		local Data = GetClass(Class)

		return Data[Name]
	end

	function ACF.GetInputActions(Class)
		if not Class then return end

		return GetClass(Class)
	end
end

do -- Extra overlay text
	local Classes = {}

	function ACF.RegisterOverlayText(ClassName, Identifier, Function)
		if not isstring(ClassName) then return end
		if Identifier == nil then return end
		if not isfunction(Function) then return end

		local Class = Classes[ClassName]

		if not Class then
			Classes[ClassName] = {
				[Identifier] = Function
			}
		else
			Class[Identifier] = Function
		end
	end

	function ACF.RemoveOverlayText(ClassName, Identifier)
		if not isstring(ClassName) then return end
		if Identifier == nil then return end

		local Class = Classes[ClassName]

		if not Class then return end

		Class[Identifier] = nil
	end

	function ACF.GetOverlayText(Entity)
		local Class = Classes[Entity:GetClass()]

		if not Class then return "" end

		local Result = ""

		for _, Function in pairs(Class) do
			local Text = Function(Entity)

			if Text and Text ~= "" then
				Result = Result .. "\n\n" .. Text
			end
		end

		return Result
	end
end