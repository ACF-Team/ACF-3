local ACF = ACF

do -- Custom font files
	-- 16 Segments font created by ThorType
	-- Huge thanks to LiddulBOFH to help me get it working
	-- Source: https://www.dafont.com/16-segments.font
	resource.AddFile("resource/fonts/16segments-basic.ttf")
end

do -- Networked notifications
	local Messages = ACF.Utilities.Messages

	util.AddNetworkString("ACF_Notify")
	util.AddNetworkString("ACF_NameAndShame")

	function ACF.Shame(Entity, Message)
		if not ACF.NameAndShame then return end
		local Owner = Entity:CPPIGetOwner()

		if not IsValid(Owner) then return end

		local ShameMsg = Owner:GetName() .. " had " .. tostring(Entity) .. " disabled for " .. Message
		Messages.PrintLog("Error", ShameMsg)

		net.Start("ACF_NameAndShame")
			net.WriteString(ShameMsg)
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

	--- Sends a fetch request to the given url with the given headers.  
	--- For further elaboration, please read this function's definition and SuccessfulRequest.  
	--- To better understand the inputs, please check: https://wiki.facepunch.com/gmod/http.Fetch.
	--- @param Link string The HTTP endpoint to send a fetch request to
	--- @param Headers table Headers to use in the HTTP request
	--- @param OnSuccess fun(Body:string,Data:table)
	--- @param OnFailure fun(Error:string)
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

-- Entity saving and restoring
-- Necessary because some components will update their physics object on update (e.g. ammo crates/scalable guns)
do
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
	--- Saves the physical properties/constraints/etc. of an entity to the "Entities" table.  
	--- Should be used before calling Update functions on ACF entities. Call RestoreEntity after.  
	--- Necessary because some components will update their physics object on update (e.g. ammo crates/scalable guns).
	--- @param Entity table The entity to index
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

		-- If for whatever reason the entity is removed before RestoreEntity is called,
		-- Update the entity table
		Entity:CallOnRemove("ACF_RestoreEntity", function()
			Entities[Entity] = nil
		end)
	end

	--- Sets the properties/constraints/etc of an entity from the "Entities" table.  
	--- Should be used after calling Update functions on ACF entities.
	--- @param Entity table The entity to restore
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

		-- Disables the CallOnRemove callback from earlier
		Entity:RemoveCallOnRemove("ACF_RestoreEntity")
	end
end

do -- Entity linking
	--[[
	Example structure of EntityLink:
	
	EntityLink = {
		["acf_engine"] = {
			["FuelTanks"] = function(Entity)
				return GetEntityLinks(Entity, "FuelTanks", nil)
			end,
			["Gearboxes"] = function(Entity)
				return GetEntityLinks(Entity, "Gearboxes", nil)
			end
		}
	}

	This example demonstrates that any entity of the acf_engine class has the fields FuelTanks and Gearboxes in its entity table that reference their respective link sources.
	This is done to localize the functions for optimization reasons.
	]]--
	local EntityLink = {}

	--- Returns links to the entry.
	--- @param Entity table The entity to check
	--- @param VarName string The field of the entity that stores link sources (e.g. "Entity.FuelTanks" for engines)
	--- @param SingleEntry boolean | nil Whether the entity supports a single source link or multiple
	--- @return table<table, true> # A table whose keys are the link source entities and whose values are all true
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

	--- Registers that all entities of this class have a field which refers to its link source(s).  
	--- If your entity can link/unlink other entities, you should use this.  
	--- Certain E2/SF functions require this in order to function (e.g. getting linked wheels of a gearbox).  
	--- Example usage: ACF.RegisterLinkSource("acf_engine", "FuelTanks")
	--- @param Class string The name of the class
	--- @param VarName string The field referencing one of the class's link source(s)
	--- @param SingleEntry boolean | nil Whether the entity supports a single source link or multiple
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

	--- Returns all the link source callables for this entity.
	--- @param Class string The name of the class
	--- @return table<string, fun(Entity:table):table> # All the relevant link source callables
	function ACF.GetAllLinkSources(Class)
		if not EntityLink[Class] then return {} end

		local Result = {}

		for K, V in pairs(EntityLink[Class]) do
			Result[K] = V
		end

		return Result
	end

	--- Returns the link source callable of a given class and VarName.
	--- @param Class string The name of the class
	--- @param VarName string The varname for the given class
	--- @return fun(Entity:table):table | nil # The link source callable, or nil if the class doesn't have one
	function ACF.GetLinkSource(Class, VarName)
		if not EntityLink[Class] then return end

		return EntityLink[Class][VarName]
	end

	--- Returns a table of entities linked to the given entity.
	--- @param Entity table The entity to get links from
	--- @return table<table, true> # A table mapping entities to true
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

	--[[
		Example structure of ClassLink:

		ClassLink = {
			["Link"] = {
				["acf_ammo"] = {
					["acf_gun"] = function(Ent1, Ent2) -- Handles linking guns and ammo
				}
			},
			["Unlink"] = {
				["acf_ammo"] = {
					["acf_gun"] = function(Ent1, Ent2) -- Handles unlinking guns and ammo
				}
			}
		}
	]]--
	--- @class LinkFunction
	--- @field Ent1 table The first entity in the link
	--- @field Ent2 table The second entity in the link
	--- @field FromChip boolean If the link is from a chip
	--- @return boolean? Success Whether the link was successful
	--- @return string? Message A message about the link status

	--- @class LinkData
	--- @field Link LinkFunction? The function to handle linking
	--- @field Unlink LinkFunction? The function to handle unlinking
	--- @field Check LinkFunction? The function to check the link status
	--- @field ChipDelay number? The delay associated with the link if done via chip

	--- @type table<string,table<string,LinkData>>
	local ClassLink = { }

	--- Initializes a link in the ClassLink table if it doesn't already exist and returns the result.
	--- The Link is initialized directionally (InitLink(Class1,Class2) != InitLink(Class2,Class1))
	--- @param Class1 string The first class in the link
	--- @param Class2 string The other class in the link
	--- @return LinkData? LinkData The returned link
	function ACF.InitLink(Class1, Class2)
		if not ClassLink[Class1] then ClassLink[Class1] = {} end
		if not ClassLink[Class1][Class2] then ClassLink[Class1][Class2] = {} end
		return ClassLink[Class1][Class2]
	end

	--- Attempts to retrieve link information from Class 1 to Class2, otherwise tries Class 2 to Class1. If link exists in either direction, return nil.
	--- @param Class1 string The first class in the link
	--- @param Class2 string The other class in the link
	--- @return LinkData? LinkData The returned link
	--- @return boolean Reversed Whether you should reverse your entity arguments when calling with entities
	function ACF.GetClassLink(Class1, Class2)
		if ClassLink[Class1] and ClassLink[Class1][Class2] then return ClassLink[Class1][Class2], false end
		if ClassLink[Class2] and ClassLink[Class2][Class1] then return ClassLink[Class2][Class1], true end
		return nil, false
	end

	--- Registers that two classes can be linked, as well as how to handle entities of their class being linked.
	--- @param Class1 string The first class in the link
	--- @param Class2 string The other class in the link
	--- @param Function LinkFunction The linking function defined between an entity of Class1 and an entity of Class2; this should always return a boolean for link status and a string for link message
	function ACF.RegisterClassLink(Class1, Class2, Function)
		local LinkData = ACF.InitLink(Class1, Class2)
		LinkData.Link = Function
	end

	--- Registers that two classes can be unlinked, as well as how to handle entities of their class being unlinked.
	--- @param Class1 string The first class in the link
	--- @param Class2 string The other class in the link
	--- @param Function LinkFunction The unlinking function defined between an entity of Class1 and an entity of Class2
	function ACF.RegisterClassUnlink(Class1, Class2, Function)
		local LinkData = ACF.InitLink(Class1, Class2)
		LinkData.Unlink = Function
	end

	--- Registers a validation check between two classes.
	--- @param Class1 string The first class in the link
	--- @param Class2 string The other class in the link
	--- @param Function LinkFunction The checking function defined between an entity of Class1 and an entity of Class2
	function ACF.RegisterClassCheck(Class1, Class2, Function)
		local LinkData = ACF.InitLink(Class1, Class2)
		LinkData.Check = Function
	end

	--- Registers a chip delay between two classes.
	--- @param Class1 string The first class in the link
	--- @param Class2 string The other class in the link
	--- @param ChipDelay number If the link happens from the chip, then delay it by this amount
	function ACF.RegisterClassDelay(Class1, Class2, ChipDelay)
		local LinkData = ACF.InitLink(Class1, Class2)
		LinkData.ChipDelay = ChipDelay
	end
end

do -- Entity inputs
	--[[
		Example structure of inputs:

		Inputs = {
			["acf_ammo"] = {
				["Load"] = function(Entity, Value) -- Handles when the "Load" wire input is triggered
			}
		}
	]]--
	local Inputs = {}

	--- Returns the table mapping a class's inputs to a function that handles them.
	--- @param Class string The class to get data from
	--- @return table<string,fun(Entity:table, Value:any)> # A table of input names to functions that handle them
	local function GetClass(Class)
		if not Inputs[Class] then
			Inputs[Class] = {}
		end

		return Inputs[Class]
	end

	--- For a given class, add an input action for when an input is triggered.
	--- @param Class string The class to apply to
	--- @param Name string The wire input to trigger on
	--- @param Action fun(Entity:table, Value:any) The function that gets called when the wire input is triggered
	function ACF.AddInputAction(Class, Name, Action)
		if not Class then return end
		if not Name then return end
		if not isfunction(Action) then return end

		local Data = GetClass(Class)

		Data[Name] = Action
	end

	--- Returns the callback defined previously by ACF.AddInputAction for the given class and wire input name.
	--- @param Class string The class to retrieve from
	--- @param Name string The wire input retrieve from
	--- @return fun(Entity:table, Value:any) | nil # The callback for the given class and wire input name, or nil if the arguments are invalid
	function ACF.GetInputAction(Class, Name)
		if not Class then return end
		if not Name then return end

		local Data = GetClass(Class)

		return Data[Name]
	end

	--- For a given class, returns a table of wire input names mapped to their handlers, defined previously by ACF.AddInputAction.
	--- @param Class string The class to retrieve from
	--- @return table<string,fun(Entity:table,Value:any)> | nil # A table of wire input names mapped to their handlers, or nil if Class is invalid
	function ACF.GetInputActions(Class)
		if not Class then return end

		return GetClass(Class)
	end
end

do -- Extra overlay text
	--[[
		Example structure of Classes:
		
		Classes = {
			["acf_ammo"] = {
				["Kinematic"] = function(Entity), -- Returns text containing muzzle vel, drag coef, etc.
				["Explosive"] = function(Entity) -- Returns text containing explosive mass, blast radius, etc.
			}
		}

		*Note that unlike most examples this isn't actually used anywhere at the time of writing.*
	]]--
	local Classes = {}

	--- Registers a function that provides text for the overlay, with a given Identifier, for a given class.
	--- @param ClassName string Name of the class to register for
	--- @param Identifier string The identitifer to assosciate the function with
	--- @param Function fun(Entity:table):string A function which takes the entity and returns some text for the identifier
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

	--- Removes an overlay callback defined previously by ACF.RegisterOverlayText.
	--- @param ClassName string Name of the class to affect
	--- @param Identifier string The identifier of the function to be removed
	function ACF.RemoveOverlayText(ClassName, Identifier)
		if not isstring(ClassName) then return end
		if Identifier == nil then return end

		local Class = Classes[ClassName]

		if not Class then return end

		Class[Identifier] = nil
	end

	--- Given an entity, returns its overlay text, made by concatenating the overlay functions for its class.
	--- @param Entity table The entity to generate overlay text for
	--- @return string # The overlay text for this entity
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

do	-- Seat alias system
	local SeatModel = {
		[1] = {
			model	= "models/chairs_playerstart/sitpose.mdl",
			pos		= Vector(0, -19.6, 20),
			ang		= Angle(0, 90, 0)
		},
		[2] = {
			model	= "models/chairs_playerstart/jeeppose.mdl",
			pos		= Vector(0, -39.5, 5),
			ang		= Angle(0, 90, 0)
		},
		[3] = {
			model	= "models/chairs_playerstart/airboatpose.mdl",
			pos		= Vector(0, -35.4, 9.3),
			ang		= Angle(0, 90, 0)
		},
		[4] = {
			model	= "models/chairs_playerstart/podpose.mdl",
			pos		= Vector(0, 5, 6),
			ang		= Angle(0, 90, 0)
		},
	}

	-- Because garry's mod wouldn't even be a game without annoying fucking workarounds
	-- HL2 vehicles MOVE the fucking normally static "vehicle_feet_passenger0" so we have to do something totally different
	local PosOverride = {
		["models/airboat.mdl"] = function(Vic)
			local SeatPos, SeatAng = Vic:GetPassengerSeatPoint(0)

			return Vic:WorldToLocal(SeatPos) - Vector(0.1, -24, -25.5), Vic:WorldToLocalAngles(SeatAng), true
		end,
		["models/vehicle.mdl"] = function(Vic)
			local SeatPos, SeatAng = Vic:GetPassengerSeatPoint(0)

			return Vic:WorldToLocal(SeatPos), Vic:WorldToLocalAngles(SeatAng), false
		end,
		["models/buggy.mdl"] = function(Vic)
			local SeatPos, SeatAng = Vic:GetPassengerSeatPoint(0)

			return Vic:WorldToLocal(SeatPos), Vic:WorldToLocalAngles(SeatAng), false
		end,
		["models/vehicles/prisoner_pod_inner.mdl"] = function(Vic)
			local SeatPos, SeatAng = Vic:GetPassengerSeatPoint(0)

			return Vic:WorldToLocal(SeatPos) - Vector(5, 0, 6), Vic:WorldToLocalAngles(SeatAng) + Angle(0, -90, 0), true
		end,
		["models/vehicles/driver_pod.mdl"] = function(Vic)
			local SeatPos, SeatAng = Vic:GetPassengerSeatPoint(0)

			return Vic:WorldToLocal(SeatPos) - Vector(5, 0, 6), Vic:WorldToLocalAngles(SeatAng) + Angle(0, -90, 0), true
		end,
		["models/chairs_playerstart/pronepose.mdl"] = function(Vic)
			local SeatPos, SeatAng = Vic:GetPassengerSeatPoint(0)

			return Vic:WorldToLocal(SeatPos) - Vector(0, 42, -5), Vic:WorldToLocalAngles(SeatAng) + Angle(0, 0, -85), true
		end,
		["models/lubprops/seat/raceseat2.mdl"] = function(Vic)
			local SeatPos, SeatAng = Vic:GetPassengerSeatPoint(0)

			-- Close enough, I hate this seat in particular because of the weird offset everything *just has to have*
			return Vic:WorldToLocal(SeatPos) + Vector(0, 24, -6), Vic:WorldToLocalAngles(SeatAng) + Angle(20, -90, 22.5), true
		end,
	}

	local ClassList = {
		["prop_vehicle_jeep"] = function(Ply) return Ply:LookupSequence("drive_jeep") end,
		["prop_vehicle_airboat"] = function(Ply) return Ply:LookupSequence("drive_airboat") end,
		["prop_vehicle_prisoner_pod"] = function(Ply, Vic)
			-- Using the same shitty hack that whoever wrote however long ago in garrysmod/gamemodes/base/gamemode/animations.lua #171

			if Vic:GetModel() == "models/vehicles/prisoner_pod_inner.mdl" then
				return Ply:LookupSequence("drive_pd")
			else
				return Ply:LookupSequence("sit_rollercoaster")
			end
		end,
	}

	local Hitboxes	= {
		[1] = {
			["head"] = {
				pos	= Vector(0, -18, 46),
				ang	= Angle(0, 0, -10),
				min	= Vector(-4, -6, -6),
				max	= Vector(4, 6, 6)
			},
			["chest"] = {
				pos	= Vector(0, -22, 30),
				ang	= Angle(0, 0, 0),
				min	= Vector(-8, -5.5, -12),
				max	= Vector(8, 6, 12)
			},
		},
		[2] = {
			["head"] = {
				pos	= Vector(0, -34, 38),
				ang	= Angle(0, 0, 0),
				min	= Vector(-4, -6, -6),
				max	= Vector(4, 6, 6)
			},
			["chest"] = {
				pos	= Vector(0, -32, 20),
				ang	= Angle(0, 0, 15),
				min	= Vector(-8, -5.5, -12),
				max	= Vector(8, 6, 12)
			},
		},
		[3] = {
			["head"] = {
				pos	= Vector(0, -31, 39),
				ang	= Angle(0, 0, 0),
				min	= Vector(-4, -6, -6),
				max	= Vector(4, 6, 6)
			},
			["chest"] = {
				pos	= Vector(0, -33, 22),
				ang	= Angle(0, 0, 10),
				min	= Vector(-8, -5.5, -12),
				max	= Vector(8, 6, 12)
			},
		},
		[4] = {
			["head"] = {
				pos	= Vector(0, -3, 73),
				ang	= Angle(0, 0, 20),
				min	= Vector(-4, -6, -6),
				max	= Vector(4, 6, 6)
			},
			["chest"] = {
				pos	= Vector(0, -0.5, 54),
				ang	= Angle(0, 0, 0),
				min	= Vector(-8, -5.5, -12),
				max	= Vector(8, 6, 12)
			},
		}
	}

	local ArmorHitboxes = {
		[1] = {
			["helmet"] = {
				parent	= "head",
				min	= Vector(-4.5, -6.5, 3),
				max	= Vector(4.5, 6.5, 6.5)
			},
			["vest"] = {
				parent	= "chest",
				min	= Vector(-7.5, -6, -11),
				max	= Vector(7.5, 6.5, 11)
			},
		},
		[2] = {
			["helmet"] = {
				parent	= "head",
				min	= Vector(-4.5, -6.5, 3),
				max	= Vector(4.5, 6.5, 6.5)
			},
			["vest"] = {
				parent	= "chest",
				min	= Vector(-7.5, -6, -11),
				max	= Vector(7.5, 6.5, 11)
			},
		},
		[3] = {
			["helmet"] = {
				parent	= "head",
				min	= Vector(-4.5, -6.5, 3),
				max	= Vector(4.5, 6.5, 6.5)
			},
			["vest"] = {
				parent	= "chest",
				min	= Vector(-7.5, -6, -11),
				max	= Vector(7.5, 6.5, 11)
			},
		},
		[4] = {
			["helmet"] = {
				parent	= "head",
				min	= Vector(-4.5, -6.5, 3),
				max	= Vector(4.5, 6.5, 6.5)
			},
			["vest"] = {
				parent	= "chest",
				min	= Vector(-7.5, -6, -11),
				max	= Vector(7.5, 6.5, 11)
			},
		}
	}

	local function RoundVector(Vec, Dec)
		return Vector(math.Round(Vec.x, Dec), math.Round(Vec.y, Dec), math.Round(Vec.z, Dec))
	end

	local function RoundAngle(Ang, Dec)
		return Angle(math.Round(Ang.p, Dec), math.Round(Ang.y, Dec), math.Round(Ang.r, Dec))
	end

	function ACF.PrepareAlias(Vehicle, Ply)
		if not IsValid(Vehicle) then return end
		if not IsValid(Ply) then return end
		if Vehicle._Alias ~= nil then return end
		local Alias	= {}

		-- Since this list is not always available in the same state, we'll need to get it over and over
		local VT = list.Get("Vehicles")

		-- Every playermodel is a little different, so this has to be done on a per-player basis
		local SeqList = {
			[Ply:LookupSequence("sit_rollercoaster")] = 1,
			[Ply:LookupSequence("sit")] = 1, -- basically the same as sit_rollercoaster? Seems to only be used for PHX Car Seat 1
			[Ply:LookupSequence("drive_jeep")] = 2,
			[Ply:LookupSequence("drive_airboat")] = 3,
			[Ply:LookupSequence("drive_pd")] = 4,
		}

		local Seq = -1

		if VT[Vehicle.VehicleName] then
			local VTD = VT[Vehicle.VehicleName]

			if VTD.Members and VTD.Members.HandleAnimation and isfunction(VTD.Members.HandleAnimation) then
				Seq = VTD.Members.HandleAnimation(Vehicle, Ply)
			else
				local Class = Vehicle:GetClass()

				if ClassList[Class] then
					Seq = ClassList[Class](Ply, Vehicle)
				end
			end
		else
			if Vehicle.HandleAnimation and isfunction(Vehicle.HandleAnimation) then
				Seq = Vehicle:HandleAnimation(Ply)

				if not SeqList[Seq] then
					Seq = -1
				end
			else
				local Class = Vehicle:GetClass()

				if ClassList[Class] then
					Seq = ClassList[Class](Ply, Vehicle)
				end
			end
		end

		local Pose = (Seq ~= -1) and SeqList[Seq] or 1
		Alias.Pose	= Pose
		local AliasInfo = SeatModel[Pose]
		Alias.Model = AliasInfo.model
		local Pos	= AliasInfo.pos
		local Ang	= AliasInfo.ang

		local AttachmentPos	= Vector()
		local AttachmentAng	= Angle()
		local Override	= false

		if PosOverride[Vehicle:GetModel()] then
			AttachmentPos, AttachmentAng, Override = PosOverride[Vehicle:GetModel()](Vehicle)
		else
			local Attachment = Vehicle:LookupAttachment("vehicle_feet_passenger0")
			if Attachment > 0 then
				local AttachmentInfo = Vehicle:GetAttachment(Attachment)

				AttachmentPos = Vehicle:WorldToLocal(AttachmentInfo.Pos)
				AttachmentAng = Vehicle:WorldToLocalAngles(AttachmentInfo.Ang)
			end
		end

		if Override then
			Alias.Pos	= RoundVector(AttachmentPos, 2)
			Alias.Ang	= RoundAngle(AttachmentAng, 2)
		else
			Alias.Pos	= RoundVector(AttachmentPos - Pos, 2)
			Alias.Ang	= RoundAngle(AttachmentAng - Ang, 2)
		end

		Alias.Hitboxes	= Hitboxes[Pose]
		Alias.ArmorHitboxes	= ArmorHitboxes[Pose]
		Alias.SeatModel	= Vehicle:GetModel()

		Vehicle._Alias = Alias
	end

	function ACF.ApplyAlias(Vehicle, Ply)
		ACF.PrepareAlias(Vehicle, Ply)

		MakeACF_SeatAlias(Vehicle)
	end
end

do -- Special squishy functions
	local BoneList = {
		head = {boneName = "ValveBiped.Bip01_Head1", group = "head", min = Vector(-6, -6, -6), max = Vector(8, 4, 6)},

		chest = {boneName = "ValveBiped.Bip01_Spine", group = "chest", min = Vector(-6, -4, -9), max = Vector(18, 10, 9)},

		lthigh = {boneName = "ValveBiped.Bip01_L_Thigh", group = "limb", min = Vector(0, -4, -4), max = Vector(18, 4, 4)},
		lcalf = {boneName = "ValveBiped.Bip01_L_Calf", group = "limb", min = Vector(0, -4, -4), max = Vector(18, 4, 4)},

		rthigh = {boneName = "ValveBiped.Bip01_R_Thigh", group = "limb", min = Vector(0, -3, -3), max = Vector(18, 3, 3)},
		rcalf = {boneName = "ValveBiped.Bip01_R_Calf", group = "limb", min = Vector(0, -3, -3), max = Vector(18, 3, 3)},
	}

	local ArmorHitboxes = { -- only applied if the entity has armor greater than 0
		helmet = {boneName = "ValveBiped.Bip01_Head1", group = "helmet", min = Vector(4.5, -6.5, -6.5), max = Vector(8.5, 4.5, 6.5)},
		vest = {boneName = "ValveBiped.Bip01_Spine", group = "vest", min = Vector(-5, -5, -8), max = Vector(17, 11, 8)},
	}

	-- The goal of this is to provide a much sturdier way to get the part of a player that got hit with a bullet
	-- This will ignore any bone manipulation too
	function ACF.GetBestSquishyHitBox(Entity, RayStart, RayDir)
		local CheckList = {}
		local Bones     = {}

		for k, v in pairs(BoneList) do
			CheckList[k] = v
		end

		if Entity:IsPlayer() and Entity:Armor() > 0 then
			for k, v in pairs(ArmorHitboxes) do
				CheckList[k] = v
			end
		end

		--if true then return "none" end

		for k, v in pairs(CheckList) do
			local bone = Entity:LookupBone(v.boneName)
			if bone then Bones[k] = bone end
		end

		if table.IsEmpty(Bones) then return "none" end

		local HitBones = {}

		if Entity:IsPlayer() and Entity:InVehicle() and IsValid(Entity:GetVehicle().Alias) then
			local Vehicle = Entity:GetVehicle()
			local Alias = Vehicle.Alias
			local AliasInfo = Vehicle._Alias
			local LocalRay = Alias:WorldToLocal(RayStart)
			local LocalRayDir = Alias:WorldToLocal(RayDir + Alias:GetPos())

			for k, v in pairs(AliasInfo.Hitboxes) do
				local HitPos = util.IntersectRayWithOBB(LocalRay, LocalRayDir * 64, v.pos, v.ang, v.min, v.max)

				--debugoverlay.Text(Alias:LocalToWorld(v.pos),k,10,false)
				--debugoverlay.BoxAngles(Alias:LocalToWorld(v.pos), v.min, v.max, Alias:LocalToWorldAngles(v.ang), 10, Color(255, 0, 0, 50))

				if HitPos ~= nil then
					HitBones[k] = HitPos
				end
			end

			if Entity:Armor() > 0 then
				for k, v in pairs(AliasInfo.ArmorHitboxes) do
					local parentBox = AliasInfo.Hitboxes[v.parent]

					local HitPos = util.IntersectRayWithOBB(LocalRay, LocalRayDir * 64, parentBox.pos, parentBox.ang, v.min, v.max)

					--debugoverlay.Text(Alias:LocalToWorld(parentBox.pos),k,10,false)
					--debugoverlay.BoxAngles(Alias:LocalToWorld(parentBox.pos), v.min, v.max, Alias:LocalToWorldAngles(parentBox.ang), 10, Color(0, 0, 255, 50))

					if HitPos ~= nil then
						HitBones[k] = HitPos
					end
				end
			end

			if table.IsEmpty(HitBones) then
				local nearest, nearestdist = "none", 16384

				for k, v in pairs(AliasInfo.Hitboxes) do
					local DistToLine = util.DistanceToLine(LocalRay, LocalRay + LocalRayDir * 64, Alias:LocalToWorld(v.pos))

					if DistToLine < nearestdist then
						nearest = k
						nearestdist = DistToLine
					end
				end

				return CheckList[nearest].group
			end
		else
			for k, v in pairs(Bones) do
				local BoneData = CheckList[k]
				local BonePos, BoneAng = Entity:GetBonePosition(v)

				local HitPos = util.IntersectRayWithOBB(RayStart, RayDir * 64, BonePos, BoneAng, BoneData.min, BoneData.max)

				--debugoverlay.Text(BonePos,k,5,false)
				--debugoverlay.BoxAngles(BonePos, BoneData.min, BoneData.max, BoneAng, 5, Color(255, 0, 0, 50))

				if HitPos ~= nil then
					HitBones[k] = HitPos
				end
			end

			if table.IsEmpty(HitBones) then
				local nearest, nearestdist = "none", 16384

				for k, v in pairs(Bones) do
					local BonePos = Entity:GetBonePosition(v)

					local DistToLine = util.DistanceToLine(RayStart, RayStart + RayDir * 64, BonePos)

					if DistToLine < nearestdist then
						nearest = k
						nearestdist = DistToLine
					end
				end

				return CheckList[nearest].group
			end
		end

		if table.Count(HitBones) == 1 then return CheckList[next(HitBones)].group end -- Single box got hit, just return that

		local BestChoice = next(HitBones)
		local BestDist = HitBones[BestChoice]:DistToSqr(RayStart)

		for k, _ in pairs(HitBones) do
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

		DmgResult:SetThickness(Mass * 0.075 * 0.18) -- skull is around 7-8mm on average for humans, but this gets thicker with bigger creatures; further modified by bone density compared to steel

		HitRes = DmgResult:Compute()
		Damage = Damage + HitRes.Damage * 10

		if HitRes.Overkill > 0 then -- Went through skull
			DmgResult:SetThickness(0.001) -- squishy squishy brain matter, no resistance

			HitRes = DmgResult:Compute()
			Damage = Damage + (HitRes.Damage * 50 * math.max(1, HitRes.Overkill * 0.25)) -- yuge damage, yo brains just got scrambled by a BOOLET
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

		DmgResult:SetThickness(Size * 0.2) -- the SKIN and SKELETON, just some generic trashy "armor"

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

do -- Bulletdata related
	--- Checks the two bullet datas are equal
	--- TODO: Probably find a better way to do this via the ammo classes...
	--- @param Data1 any -- The first bullet data
	--- @param Data2 any -- The second bullet data
	--- @return boolean -- Whether the two bullet datas are equal
	function ACF.BulletEquality(Data1, Data2)
		if not Data1 then return false end
		if not Data2 then return false end

		-- Only check fields all rounds share...
		-- Note: We are trying to fail as early as possible so check constraints from most to least common
		if Data1.Type ~= Data2.Type then return false end
		if Data1.Caliber ~= Data2.Caliber then return false end
		if Data1.Diameter ~= Data2.Diameter then return false end
		if Data1.ProjArea ~= Data2.ProjArea then return false end
		if Data1.PropArea ~= Data2.PropArea then return false end
		if Data1.Efficiency ~= Data2.Efficiency then return false end

		return true
	end
end

do -- Crew related
	--- Computes the weighted sum of a LUT (often representing links) using a weighting function.
	--- @param LUT any -- The lookup table to sum
	--- @param Weighter function -- The function to compute the weight of each entry
	--- @param ... unknown -- Additional arguments to pass to the weighter
	--- @return integer -- The weighted sum of the LUT
	--- @return integer -- The count of entries in the LUT
	function ACF.WeightedLinkSum(LUT, Weighter, ...)
		if not LUT then return 0, 0 end

		local Sum = 0
		local Count = 0
		for v, _ in pairs(LUT) do
			if not IsValid(v) then continue end -- Skip invalids
			Sum = Sum + Weighter(v, ...)
			Count = Count + 1
		end
		return Sum, Count
	end

	--- Normalizes a value from [inMin,inMax] to [0,1]
	--- Values outside the input range are clamped to the output range
	--- @param value number The value to normalize
	--- @param inMin number The minimum value of the input range
	--- @param inMax number The maximum value of the input range
	--- @return number # The normalized value
	function ACF.Normalize(value, inMin, inMax)
		return math.Clamp((value - inMin) / (inMax - inMin), 0, 1)
	end

	--- Assuming every item in "array" is in [0,1] (e.g. crew efficiencies)...
	--- This property holds: sum(array) * Falloff(#array, Limit) < Limit
	--- @param count number The number of items in the array
	--- @param limit number The asymptotic limit to stay under
	--- @return number # The asymptotic falloff multiplier
	function ACF.AsymptoticFalloff(count, limit)
		return limit / (count + limit - 1)
	end

	--- Maps a value from [inMin,inMax] to [outMin,outMax] using a transformation that maps [0,1] to [0,1]
	--- Values outside the input range are clamped to the output range
	--- @param value number The value to remap
	--- @param inMin number The minimum value of the input range
	--- @param inMax number The maximum value of the input range
	--- @param outMin number The minimum value of the output range
	--- @param outMax number The maximum value of the output range
	--- @param transform function(value:number):number
	--- @return number # The remapped value
	function ACF.RemapAdv(value, inMin, inMax, outMin, outMax, transform)
		return outMin + (transform(ACF.Normalize(value, inMin, inMax)) * (outMax - outMin))
	end
end

do -- Entity property system
	local Utilities   = ACF.Utilities
	local Clock = Utilities.Clock

	function ACF.RandomizedDependentTimer(loop, depends, minTime, maxTime, delay)
		local realLoop
		local lastTime = Clock.CurTime
		function realLoop()
			if not depends() then return end

			loop(lastTime)
			lastTime = Clock.CurTime
			timer.Simple(math.random(minTime, maxTime), realLoop)
		end

		if not delay then
		   realLoop()
		else
			timer.Simple(delay, realLoop)
		end
	end
end
