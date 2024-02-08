local ACF = ACF

do -- Networked notifications
	util.AddNetworkString("ACF_Notify")
	util.AddNetworkString("ACF_NameAndShame")

	function ACF.Shame(Entity, Message)
		if not ACF.NameAndShame then return end
		local Owner = Entity:CPPIGetOwner()

		if not IsValid(Owner) then return end

		MsgN("ACF Legal: " .. Owner:GetName() .. " had " .. tostring(Entity) .. " disabled for " .. Message)

		net.Start("ACF_NameAndShame")
			net.WriteString("ACF Legal: " .. Owner:GetName() .. " had " .. tostring(Entity) .. " disabled for " .. Message)
		net.Broadcast()
	end

	function ACF.SendNotify(Player, Success, Message)
		net.Start("ACF_Notify")
			net.WriteBool(Success or false)
			net.WriteString(Message or "")
		net.Send(Player)
	end
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

do -- Special squishy functions
	local BoneList = {
		head = {boneName = "ValveBiped.Bip01_Head1",group = "head",min = Vector(-6,-6,-4),max = Vector(8,4,4)},

		spine = {boneName = "ValveBiped.Bip01_Spine",group = "chest",min = Vector(-6,-4,-9),max = Vector(18,10,9)},

		lthigh = {boneName = "ValveBiped.Bip01_L_Thigh",group = "limb",min = Vector(0,-4,-4),max = Vector(18,4,4)},
		lcalf = {boneName = "ValveBiped.Bip01_L_Calf",group = "limb",min = Vector(0,-4,-4),max = Vector(18,4,4)},

		rthigh = {boneName = "ValveBiped.Bip01_R_Thigh",group = "limb",min = Vector(0,-3,-3),max = Vector(18,3,3)},
		rcalf = {boneName = "ValveBiped.Bip01_R_Calf",group = "limb",min = Vector(0,-3,-3),max = Vector(18,3,3)},
	}

	local ArmorHitboxes = { -- only applied if the entity has armor greater than 0
		helmet = {boneName = "ValveBiped.Bip01_Head1",group = "helmet",min = Vector(4.5,-6.5,-4.5),max = Vector(8.5,4.5,4.5)},
		vest = {boneName = "ValveBiped.Bip01_Spine",group = "vest",min = Vector(-5,-5,-8),max = Vector(17,11,8)},
	}

	-- The goal of this is to provide a much sturdier way to get the part of a player that got hit with a bullet
	-- This will ignore any bone manipulation too
	function ACF.GetBestSquishyHitBox(Entity, RayStart, RayDir)
		local CheckList = {}
		local Bones     = {}

		for k,v in pairs(BoneList) do
			CheckList[k] = v
		end

		if Entity:IsPlayer() and Entity:Armor() > 0 then
			for k,v in pairs(ArmorHitboxes) do
				CheckList[k] = v
			end
		end

		--if true then return "none" end

		for k,v in pairs(CheckList) do
			local bone = Entity:LookupBone(v.boneName)
			if bone then Bones[k] = bone end
		end

		if table.IsEmpty(Bones) then return "none" end

		local HitBones = {}

		for k,v in pairs(Bones) do
			local BoneData = CheckList[k]
			local BonePos,BoneAng = Entity:GetBonePosition(v)

			local HitPos = util.IntersectRayWithOBB(RayStart, RayDir * 64, BonePos, BoneAng, BoneData.min, BoneData.max)
			if HitPos ~= nil then
				HitBones[k] = HitPos
			end
		end

		if table.IsEmpty(HitBones) then return "none" end -- No boxes got hit, so return the default
		if table.Count(HitBones) == 1 then return CheckList[next(HitBones)].group end -- Single box got hit, just return that

		local BestChoice = next(HitBones)
		local BestDist = HitBones[BestChoice]:DistToSqr(RayStart)

		for k,_ in pairs(HitBones) do
			if BestChoice == k then continue end
			local BoxPosDist = HitBones[k]:DistToSqr(RayStart)
			if BoxPosDist < BestDist then BestChoice = k BestDist = BoxPosDist end
		end

		return CheckList[BestChoice].group
	end

	ACF.SquishyFuncs = ACF.SquishyFuncs or {}

	function ACF.SquishyFuncs.DamageHelmet(Entity, HitRes, DmgResult)
		DmgResult:SetThickness(12.5) -- helmet armor, sorta just shot in the dark for thickness
		HitRes = DmgResult:Compute()

		if HitRes.Overkill > 0 then -- Went through helmet
			return ACF.SquishyFuncs.DamageHead(Entity, HitRes, DmgResult)
		end

		return 0, HitRes
	end

	function ACF.SquishyFuncs.DamageHead(Entity, HitRes, DmgResult)
		local Mass   = Entity:GetPhysicsObject():GetMass() or 100
		local Damage = 0

		DmgResult:SetThickness(Mass * 0.075) -- skull is around 7-8mm on average for humans, but this gets thicker with bigger creatures

		HitRes = DmgResult:Compute()
		Damage = Damage + HitRes.Damage * 10

		if HitRes.Overkill > 0 then -- Went through skull
			DmgResult:SetThickness(0.01) -- squishy squishy brain matter, no resistance

			HitRes = DmgResult:Compute()
			Damage = Damage + (HitRes.Damage * 50 * math.max(1,HitRes.Overkill * 0.25)) -- yuge damage, yo brains just got scrambled by a BOOLET
		end

		return Damage, HitRes
	end

	function ACF.SquishyFuncs.DamageVest(Entity, HitRes, DmgResult)
		DmgResult:SetThickness(15) -- Vest armor, also a shot in the dark for thickness

		HitRes = DmgResult:Compute()

		if HitRes.Overkill > 0 then -- Went through vest
			return ACF.SquishyFuncs.DamageChest(Entity, HitRes, DmgResult)
		end

		return 0, HitRes
	end

	function ACF.SquishyFuncs.DamageChest(Entity, HitRes, DmgResult)
		local Size   = Entity:BoundingRadius()
		local Damage = 0

		DmgResult:SetThickness(Size * 0.25 * 0.02) -- the SKIN and SKELETON, just some generic trashy "armor"

		HitRes = DmgResult:Compute()
		Damage = Damage + HitRes.Damage * 10

		if HitRes.Overkill > 0 then -- Went through body surface
			DmgResult:SetThickness(0.05) -- fleshy organs, ain't much here

			HitRes = DmgResult:Compute()
			Damage = Damage + (HitRes.Damage * 25 * math.max(1, HitRes.Overkill * 0.2)) -- some decent damage, vital organs got hurt for sure
		end

		return Damage, HitRes
	end
end