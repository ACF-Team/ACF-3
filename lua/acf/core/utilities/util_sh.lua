local ACF = ACF

local CurTime = CurTime
do -- Ricochet/Penetration materials
	local Materials = {}
	local MatCache = {}
	local Lookup = {}
	local Count = 0

	local function GetMaterial(Path)
		if not Path then return end
		if MatCache[Path] then return MatCache[Path] end

		local Object = Material(Path)

		MatCache[Path] = Object

		return Object
	end

	local function DefaultScale(Caliber)
		return Caliber * 0.1312 -- Default AP decal makes a 76.2mm hole, dividing by 7.62cm
	end

	function ACF.RegisterAmmoDecal(Type, PenPath, RicoPath, ScaleFunc)
		if not Type then return end

		if not Lookup[Type] then
			Count = Count + 1

			Materials[Count] = {
				Penetration = GetMaterial(PenPath),
				Ricochet = GetMaterial(RicoPath),
				Scale = ScaleFunc or DefaultScale,
				Index = Count,
				Type = Type,
			}

			Lookup[Type] = Materials[Count]
		else
			local Data = Lookup[Type]
			Data.Penetration = GetMaterial(PenPath)
			Data.Ricochet = GetMaterial(RicoPath)
			Data.Scale = ScaleFunc or DefaultScale
		end
	end

	function ACF.IsValidAmmoDecal(Key)
		if not Key then return false end
		if Lookup[Key] then return true end
		if Materials[Key] then return true end

		return false
	end

	function ACF.GetAmmoDecalIndex(Type)
		if not Type then return end
		if not Lookup[Type] then return end

		return Lookup[Type].Index
	end

	function ACF.GetAmmoDecalType(Index)
		if not Index then return end
		if not Materials[Index] then return end

		return Materials[Index].Type
	end

	function ACF.GetPenetrationDecal(Key)
		if not Key then return end

		if Lookup[Key] then
			return Lookup[Key].Penetration
		end

		if Materials[Key] then
			return Materials[Key].Penetration
		end
	end

	function ACF.GetRicochetDecal(Key)
		if not Key then return end

		if Lookup[Key] then
			return Lookup[Key].Ricochet
		end

		if Materials[Key] then
			return Materials[Key].Ricochet
		end
	end

	function ACF.GetDecalScale(Key, Caliber)
		if not Key then return end

		if Lookup[Key] then
			return Lookup[Key].Scale(Caliber)
		end

		if Materials[Key] then
			return Materials[Key].Scale(Caliber)
		end
	end
end

do -- Mobility functions
	local Clamp = math.Clamp

	-- Calculates a position along a catmull-rom spline (as defined on https://www.mvps.org/directx/articles/catmull/)
	function ACF.GetTorque(Points, Pos)
		local Count = #Points

		if Count < 3 then return 0 end

		if Pos <= 0 then
			return Points[1]
		elseif Pos >= 1 then
			return Points[Count]
		end

		local T       = (Pos * (Count - 1)) % 1
		local Current = math.floor(Pos * (Count - 1) + 1)
		local P0      = Points[Clamp(Current - 1, 1, Count - 2)]
		local P1      = Points[Clamp(Current, 1, Count - 1)]
		local P2      = Points[Clamp(Current + 1, 2, Count)]
		local P3      = Points[Clamp(Current + 2, 3, Count)]

		return 0.5 * ((2 * P1) +
			(P2 - P0) * T +
			(2 * P0 - 5 * P1 + 4 * P2 - P3) * T ^ 2 +
			(3 * P1 - P0 - 3 * P2 + P3) * T ^ 3)
	end

	-- Calculates the performance characteristics of an engine, given a torque curve, max torque (in nm), idle, and redline RPM
	function ACF.AddEnginePerformanceData(Class)
		local Curve          = Class.TorqueCurve
		local MaxTq          = Class.Torque
		local Idle           = Class.RPM.Idle
		local Redline        = Class.RPM.Limit
		local PeakTq         = 0
		local PeakPower      = 0
		local PowerTable     = {} -- Power at each point on the curve for use in powerband calc
		local Iterations     = 32 -- Iterations for use in calculating the curve, higher is more accurate
		local PeakTqRPM
		local PeakPowerRPM

		-- Calculate peak torque/Power RPM
		for I = 0, Iterations do
			local RPM   = I / Iterations * Redline
			local Perc = math.Remap(RPM, Idle, Redline, 0, 1)
			local CurTq = ACF.GetTorque(Curve, Perc)
			local Power = MaxTq * CurTq * RPM / 9548.8

			PowerTable[I] = Power

			if Power > PeakPower then
				PeakPower    = Power
				PeakPowerRPM = RPM
			end

			if Clamp(CurTq, 0, 1) > PeakTq then
				PeakTq    = CurTq
				PeakTqRPM = RPM
			end
		end

		-- Find the bounds of the powerband (within 10% of its peak)
		local PowerbandMinRPM
		local PowerbandMaxRPM

		for I = 0, Iterations do
			local PowerFrac = PowerTable[I] / PeakPower
			local RPM       = I / Iterations * Redline

			if PowerFrac > 0.9 and not PowerbandMinRPM then
				PowerbandMinRPM = RPM
			end

			if (PowerbandMinRPM and PowerFrac < 0.9 and not PowerbandMaxRPM) or (I == Iterations and not PowerbandMaxRPM) then
				PowerbandMaxRPM = RPM
			end
		end

		Class.PeakTqRPM    = PeakTqRPM
		Class.PeakPower    = PeakPower
		Class.PeakPowerRPM = math.Round(PeakPowerRPM)
		Class.RPM.PeakMin  = math.Round(PowerbandMinRPM, -1)
		Class.RPM.PeakMax  = math.Round(PowerbandMaxRPM, -1)
	end

	--- Processes the stats of a gearbox into scaled mass and torque formats.
	--- @param BaseMass number The base mass value of the gearbox
	--- @param Scale number The scale value of the gearbox
	--- @param MaxTorque number The maximum torque value of the gearbox
	--- @param GearCount number The number of gears present in the gearbox
	--- @return number # The mass of the gearbox
	--- @return number # The torque value of the gearbox in ft-lb
	--- @return number # The torque rating of the gearbox in N/m
	function ACF.GetGearboxStats(BaseMass, Scale, MaxTorque, GearCount)
		local Mass = math.Round(BaseMass * (Scale ^ ACF.GearboxMassScale))

		-- Torque calculations
		local Torque, TorqueRating = 0, 0

		if MaxTorque and GearCount then
			local TorqueLoss = MaxTorque * (ACF.GearEfficiency ^ GearCount)
			local ScalingCurve = Scale ^ ACF.GearboxTorqueScale
			TorqueRating = math.floor((TorqueLoss * ScalingCurve) / 10) * 10 -- Round to the nearest ten
			Torque = math.Round(TorqueRating * ACF.NmToFtLb)
		end

		return Mass, Torque, TorqueRating
	end
end

do -- Unit conversion
	local Units = {
		{ Unit = "year", Reduction = 1970 },
		{ Unit = "month", Reduction = 1 },
		{ Unit = "day", Reduction = 1 },
		{ Unit = "hour", Reduction = 0 },
		{ Unit = "min", Reduction = 0 },
		{ Unit = "sec", Reduction = 0 },
	}

	local function LocalToUTC()
		return os.time(os.date("!*t", os.time()))
	end

	function ACF.GetTimeLapse(Date)
		if not Date then return end

		local Time = LocalToUTC() - Date
		local DateData = os.date("!*t", Time)

		-- Negative values to os.date will return nil
		-- LocalToUTC() is most likely flawed, will need testing with people from different timezones.
		if Time <= 0 then return "now" end

		for _, Data in ipairs(Units) do
			Time = DateData[Data.Unit] - Data.Reduction

			if Time > 0 then
				return Time .. " " .. Data.Unit .. (Time ~= 1 and "s" or "") .. " ago"
			end
		end
	end

	function ACF.GetProperMass(Kilograms)
		local Unit, Mult = "g", 1000

		if Kilograms >= 1000 then
			Unit, Mult = "t", 0.001
		elseif Kilograms >= 1 then
			Unit, Mult = "kg", 1
		end

		return math.Round(Kilograms * Mult, 2) .. " " .. Unit
	end
end
--[[
-- Pretty much unused, should be moved into the ACF namespace or just removed
function switch(cases, arg)
	local Var = cases[arg]

	if Var ~= nil then return Var end

	return cases.default
end
]]
function ACF.RandomVector(Min, Max)
	local X = math.Rand(Min.x, Max.x)
	local Y = math.Rand(Min.y, Max.y)
	local Z = math.Rand(Min.z, Max.z)

	return Vector(X, Y, Z)
end

do
	--- A class that determines local position and direction, for things like driveshaft/power sources
	function ACF.LocalPlane(LocalPos, LocalDir)
		local Object = {
			Pos = LocalPos or Vector(),
			Dir = LocalDir
		}

		function Object:ApplyTo(Entity)
			return Entity:LocalToWorld(self.Pos), (Entity:GetPos() - Entity:LocalToWorld(self.Dir)):GetNormalized()
		end

		return Object
	end

	--- Determines the combined deviations of the driveshaft between two entities
	--- A return value of zero means that both entities are facing each other perfectly.
	function ACF.DetermineDriveshaftAngle(InputEntity, Input, OutputEntity, Output)
		-- Gearbox -> gearbox connections use Link objects; which contain Source, Origin, and Axis.
		-- Beyond that, everything works like normal; so we can just populate Output/OutputEntity
		-- from the Link object.
		-- TODO: Link object maybe should use LocalPlane instead of creating it each time? This isn't
		-- that hot of a function given it runs infrequently (i think), but it's still a bit of a waste
		if Output == nil then
			local Link = OutputEntity

			Output = ACF.LocalPlane(Link.Origin, Link.OutDirection)
			OutputEntity = Link.Source
		end

		-- For the entity sending power, this is the direction of a "straight" shaft
		local OP, OutputWorldDir = Output:ApplyTo(OutputEntity)
		debugoverlay.Line(OP, OP + (OutputWorldDir * 200), 5, Color(20, 255, 20))

		-- Gearbox -> prop connections mean that Input will be nil, because props don't have a power input
		-- like gearboxes do. So this just switches back to the old way of checking in one direction.
		if Input == nil then
			if InputEntity:GetClass() == "prop_physics" then
				local Degrees = math.deg(math.acos((InputEntity:GetPos() - OP):GetNormalized():Dot(OutputWorldDir)))
				return Degrees
			else
				error("Input == nil AND InputEntity != prop_physics!")
			end
		end

		-- This handles either gearbox -> gearbox or engine -> gearbox, depending on if Output == nil
		-- This will check both directions.

		-- For the entity receiving power, this is the direction of a "straight" shaft
		local IP, InputWorldDir = Input:ApplyTo(InputEntity)
		debugoverlay.Line(IP, IP + (InputWorldDir * 200), 5, Color(255, 20, 20))

		-- For the entity sending power, the deviation between the shaft and what it considers "straight"
		local OutToIn = math.deg(math.acos((OP - IP):GetNormalized():Dot(InputWorldDir)))

		-- For the entity receiving power, the deviation between the shaft and what it considers "straight"
		local InToOut = math.deg(math.acos((IP - OP):GetNormalized():Dot(OutputWorldDir)))

		-- The max of the deviations
		return math.max(OutToIn, InToOut)
	end

	function ACF.IsDriveshaftAngleExcessive(InputEntity, Input, OutputEntity, Output)
		local Determined = ACF.DetermineDriveshaftAngle(InputEntity, Input, OutputEntity, Output)
		return Determined > ACF.MaxDriveshaftAngle, Determined
	end
end

do
	-- Checks the parent chain of an entity.
	-- Basically; given Entity, confirms that all inbetween entities are a class whitelisted in InbetweenEntities,
	-- and the final ancestor is a class whitelisted in EndIn.
	function ACF.CheckParentChain(Entity, InbetweenEntities, EndIn)
		local Parent = Entity
		local NoInbetween = false
		for _ = 1, 1000 do
			local TestParent = Parent:GetParent()
			if not IsValid(TestParent) then
				break
			end
			if NoInbetween then return false end

			Parent = TestParent
			local Class = TestParent:GetClass()
			if not (InbetweenEntities == Class or InbetweenEntities[Class]) then
				-- The next check MUST be the end
				NoInbetween = true
			end
		end

		-- Parent is now the master parent
		local Class = Parent:GetClass()
		return Class == EndIn or EndIn[Class] or false
	end
end

do -- ACF.GetHitAngle
	-- This includes workarounds for traces starting and/or ending inside an object
	-- Whenever a trace ends inside an object the hitNormal will be 0,0,0
	-- If the trace also starts inside the normal (direction) will be 1,0,0 and the fraction 0

	-- Whenever a trace starts inside an object, a ray-mesh intersection will be used to calculate the real hitNormal
	-- Additionally, the trace.Normal is unreliable and rayNormal (bullet.Flight) will be used instead
	local v0       = Vector()
	local toDegree = math.deg
	local acos     = math.acos
	local abs      = math.abs
	local clamp    = math.Clamp
	local sqrt     = math.sqrt
	local theta    = 0.001

	local function raySphere(rayOrigin, rayDir, sphereOrigin, radius)
		local a = 2 * rayDir:LengthSqr()
		local b = 2 * rayDir:Dot(rayOrigin - sphereOrigin)
		local c = sphereOrigin:LengthSqr() + rayOrigin:LengthSqr() - 2 * sphereOrigin:Dot(rayOrigin) - radius^2

		local bac4 = b^2 - (2 * a * c)

		if bac4 >= theta and b < theta then

			local enter  = rayOrigin + ((-sqrt(bac4) - b) / a) * rayDir
			--local exit   =  rayOrigin + ((sqrt(bac4) - b) / a) * rayDir
			local normal = (enter - sphereOrigin):GetNormalized()

			return normal
		end

		return rayDir
	end

	local function rayMesh(ent, rayOrigin, rayDir)
		local mesh        = ent:GetPhysicsObject():GetMeshConvexes()
		local minDistance = math.huge
		local minNormal   = -rayDir

		-- Translate the ray to the local space of the mesh
		local rayOrigin = ent:WorldToLocal(rayOrigin)
		local rayDir    = ent:WorldToLocalAngles(rayDir:Angle()):Forward()

		for _, hull in ipairs(mesh) do
			local hc = #hull

			for i = 1, hc, 3 do
				local p1, p2, p3   = hull[i].pos, hull[i + 1].pos, hull[i + 2].pos
				local edge1, edge2 = p2 - p1, p3 - p1

				-- check if surfaceNormal is facing towards the ray
				local surfaceNormal = edge2:GetNormalized():Cross(edge1:GetNormalized())

				if rayDir:Dot(surfaceNormal) > 0.001 then continue end

				-- check if ray passes through triangle
				local h = rayDir:Cross(edge2)
				local a = edge1:Dot(h)
				local f = 1 / a
				local s = rayOrigin - p1
				local u = f * s:Dot(h)

				if u < 0 or u > 1 then continue end

				local q = s:Cross(edge1)
				local v = f * rayDir:Dot(q)

				if v < 0 or u + v > 1 then continue end

				-- length of the ray from rayOrigin to the point of intersection
				local length = f * edge2:Dot(q)

				if length > 0.0001 and length < minDistance then
					minDistance = length
					minNormal   = surfaceNormal
				end
			end
		end

		return ent:LocalToWorldAngles(minNormal:Angle()):Forward()
	end

	local function rayIntersect(ent, rayOrigin, rayDir)
		local mesh = ent:GetPhysicsObject():GetMesh()

		if mesh then return rayMesh(ent, rayOrigin, rayDir) end
		if not mesh then return raySphere(rayOrigin, rayDir, ent:GetPos(), abs(ent:GetCollisionBounds().x)) end -- Spherical collisions
	end

	function ACF.GetHitAngle(trace, rayNormal)
		local hitNormal = trace.HitNormal
		local rayNormal = rayNormal:GetNormalized()

		if trace.Hit and hitNormal == v0 and trace.Entity ~= game.GetWorld() then
			local rayOrigin = trace.HitPos - rayNormal * 5000

			hitNormal = rayIntersect(trace.Entity, rayOrigin, rayNormal)
		end

		return toDegree(acos(clamp(-rayNormal:Dot(hitNormal), -1, 1)))
	end
end

do -- Native type verification functions
	--- Returns the numerical representation of a value or a default of this type
	--- @param Value number The input to be converted to a number
	--- @param Default number The default value if the input canno tbe made into a number
	--- @return number # The numerical result
	function ACF.CheckNumber(Value, Default)
		if not Value then return Default end

		return tonumber(Value) or Default
	end

	--- Returns the string representation of a value or a default of this type
	--- @param Value string The input to be converted to a string
	--- @param Default string The default value if the input cannot be made into a string
	--- @return string # The string result
	function ACF.CheckString(Value, Default)
		if Value == nil then return Default end

		return tostring(Value) or Default
	end

	--- Returns the entity representation of a value or a default of this type
	--- @param Value Entity The input to be converted to an entity
	--- @param Default Entity The default value if the input cannot be made into an entity
	--- @return Entity # The entity result
	function ACF.CheckEntity(Value, Default)
		if Value == nil then return Default end

		return IsValid(Value) and Value or Default
	end
end

do -- Hitbox storing and retrieval functions
	ACF.Hitboxes = ACF.Hitboxes or {}

	local Hitboxes = ACF.Hitboxes

	local function IsValidModel(Model)
		if not isstring(Model) then return false end

		return not IsUselessModel(Model)
	end

	local function GetModelTable(Model)
		local Result = Hitboxes[Model]

		if not Result then
			Result = {}

			Hitboxes[Model] = Result
		end

		return Result
	end

	local function AddHitbox(Model, Name, Data)
		local Table = GetModelTable(Model)

		Table[Name] = {
			Pos       = Vector(Data.Pos),
			Scale     = Vector(Data.Scale),
			Angle     = Angle(Data.Angle),
			Sensitive = tobool(Data.Sensitive),
		}
	end

	local function GetProperScale(Scale)
		if not Scale then return 1 end
		if isnumber(Scale) then return Scale end

		return Vector(Scale)
	end

	local function GetCopy(Hitbox, Scale)
		if not Hitbox then return end

		return {
			Pos       = Vector(Hitbox.Pos) * Scale,
			Scale     = Vector(Hitbox.Scale) * Scale,
			Angle     = Angle(Hitbox.Angle),
			Sensitive = tobool(Hitbox.Sensitive),
		}
	end

	function ACF.AddHitbox(Model, Name, Data)
		if not IsValidModel(Model) then return end
		if not isstring(Name) then return end
		if not istable(Data) then return end

		AddHitbox(Model, Name, Data)
	end

	function ACF.AddHitboxes(Model, Data)
		if not IsValidModel(Model) then return end
		if not istable(Data) then return end

		for Name, Hitbox in pairs(Data) do
			if not isstring(Name) then continue end

			AddHitbox(Model, Name, Hitbox)
		end
	end

	function ACF.RemoveHitbox(Model, Name)
		if not IsValidModel(Model) then return end
		if not isstring(Name) then return end

		local Table = Hitboxes[Model]

		if not Table then return end

		Table[Name] = nil
	end

	function ACF.RemoveHitboxes(Model)
		if not IsValidModel(Model) then return end

		local Table = Hitboxes[Model]

		if not Table then return end

		for K in pairs(Table) do
			Table[K] = nil
		end

		Hitboxes[Model] = nil
	end

	function ACF.GetHitbox(Model, Name, Scale)
		if not IsValidModel(Model) then return end
		if not isstring(Name) then return end

		local Table = Hitboxes[Model]

		if Table then
			Scale = GetProperScale(Scale)

			return GetCopy(Table[Name], Scale)
		end
	end

	function ACF.GetHitboxes(Model, Scale)
		if not IsValidModel(Model) then return end

		local Table = Hitboxes[Model]

		if Table then
			local Result = {}

			Scale = GetProperScale(Scale)

			for Name, Data in pairs(Table) do
				Result[Name] = GetCopy(Data, Scale)
			end

			return Result
		end
	end
end

do -- Attachment storage
	local IsUseless = IsUselessModel
	local EntMeta   = FindMetaTable("Entity")
	local GetAttach = EntMeta.GetAttachment
	local GetAll    = EntMeta.GetAttachments
	local Lookup    = EntMeta.LookupAttachment
	local Models    = {}

	local function GetModelData(Model, NoCreate)
		local Table = Models[Model]

		if not (Table or NoCreate) then
			Table = {}

			Models[Model] = Table
		end

		return Table
	end

	local function SaveAttachments(Model, Attachments, Clear)
		if IsUseless(Model) then return end

		local Data  = GetModelData(Model)
		local Count = Clear and 0 or #Data

		if Clear then
			for K in pairs(Data) do Data[K] = nil end
		end

		for I, Attach in ipairs(Attachments) do
			local Index = Count + I
			local Name  = ACF.CheckString(Attach.Name, "Unnamed" .. Index)

			Data[Index] = {
				Index = Index,
				Name  = Name,
				Pos   = Attach.Pos or Vector(),
				Ang   = Attach.Ang or Angle(),
				Bone  = Attach.Bone,
			}
		end

		if not next(Data) then
			Models[Model] = nil
		end
	end

	local function GetAttachData(Entity)
		local Model = Entity:GetModel()

		if not Model or IsUseless(Model) then return end

		local Data  = Entity.AttachData

		if not Data or Data.Model ~= Model then
			local Attachments = GetModelData(Model)

			Data = {
				Model = Model,
			}

			if next(Attachments) then
				Data.Attachments  = Attachments
				Entity.AttachData = Data
			end
		end

		return Data.Attachments
	end

	-------------------------------------------------------------------

	function ACF.AddCustomAttachment(Model, Name, Pos, Ang, Bone)
		if not isstring(Model) then return end

		SaveAttachments(Model, {{
			Name = Name,
			Pos  = Pos,
			Ang  = Ang,
			Bone = Bone,
		}})
	end

	function ACF.AddCustomAttachments(Model, Attachments)
		if not isstring(Model) then return end
		if not istable(Attachments) then return end

		SaveAttachments(Model, Attachments)
	end

	function ACF.SetCustomAttachment(Model, Name, Pos, Ang, Bone)
		if not isstring(Model) then return end

		SaveAttachments(Model, {{
			Name = Name,
			Pos  = Pos,
			Ang  = Ang,
			Bone = Bone,
		}}, true)
	end

	function ACF.SetCustomAttachments(Model, Attachments)
		if not isstring(Model) then return end
		if not istable(Attachments) then return end

		SaveAttachments(Model, Attachments, true)
	end

	function ACF.RemoveCustomAttachment(Model, Index)
		if not isstring(Model) then return end

		local Data = GetModelData(Model, true)

		if not Data then return end

		table.remove(Data, Index)

		if not next(Data) then
			Models[Model] = nil
		end
	end

	function ACF.RemoveCustomAttachments(Model)
		if not isstring(Model) then return end

		local Data = GetModelData(Model, true)

		if not Data then return end

		for K in pairs(Data) do
			Data[K] = nil
		end

		Models[Model] = nil
	end

	function EntMeta:GetAttachment(Index, ...)
		local Data = GetAttachData(self)

		if not Data then
			return GetAttach(self, Index, ...)
		end

		local Attachment = Data[Index]

		if not Attachment then return end

		local Pos = Attachment.Pos

		if self.Scale then
			Pos = Pos * self.Scale
		end

		return {
			Pos = self:LocalToWorld(Pos),
			Ang = self:LocalToWorldAngles(Attachment.Ang),
		}
	end

	function EntMeta:GetAttachments(...)
		local Data = GetAttachData(self)

		if not Data then
			return GetAll(self, ...)
		end

		local Result = {}

		for Index, Info in ipairs(Data) do
			Result[Index] = {
				id   = Index,
				name = Info.Name,
			}
		end

		return Result
	end

	function EntMeta:LookupAttachment(Name, ...)
		local Data = GetAttachData(self)

		if not Data then
			return Lookup(self, Name, ...)
		end

		for Index, Info in ipairs(Data) do
			if Info.Name == Name then
				return Index
			end
		end

		return 0
	end
end

do -- File creation
	function ACF.FolderExists(Path, Create)
		if not isstring(Path) then return end

		local Exists = file.Exists(Path, "DATA")

		if not Exists and Create then
			file.CreateDir(Path)

			return true
		end

		return Exists
	end

	function ACF.SaveToJSON(Path, Name, Table, GoodFormat)
		if not isstring(Path) then return end
		if not isstring(Name) then return end
		if not istable(Table) then return end

		ACF.FolderExists(Path, true) -- Creating the folder if it doesn't exist

		local FullPath = Path .. "/" .. Name

		file.Write(FullPath, util.TableToJSON(Table, GoodFormat))
	end

	function ACF.LoadFromFile(Path, Name)
		if not isstring(Path) then return end
		if not isstring(Name) then return end

		local FullPath = Path .. "/" .. Name

		if not file.Exists(FullPath, "DATA") then return end

		return util.JSONToTable(file.Read(FullPath, "DATA"))
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
		for v in pairs(LUT) do
			if not IsValid(v) then continue end -- Skip invalids
			Sum = Sum + Weighter(v, ...)
			Count = Count + 1
		end
		return Sum, Count
	end

	--- Normalizes a value from [inMin,inMax] to [0,1]
	--- Values outside the input range are clamped to the output range
	--- @param Value number The value to normalize
	--- @param InMin number The minimum value of the input range
	--- @param InMax number The maximum value of the input range
	--- @return number # The normalized value
	function ACF.Normalize(Value, InMin, InMax)
		return math.Clamp((Value - InMin) / (InMax - InMin), 0, 1)
	end

	--- Maps a value from [inMin,inMax] to [outMin,outMax] using a transformation that maps [0,1] to [0,1]
	--- Values outside the input range are clamped to the output range
	--- @param Value number The value to remap
	--- @param InMin number The minimum value of the input range
	--- @param InMax number The maximum value of the input range
	--- @param OutMin number The minimum value of the output range
	--- @param OutMax number The maximum value of the output range
	--- @param Transform function(value:number):number
	--- @return number # The remapped value
	function ACF.RemapAdv(Value, InMin, InMax, OutMin, OutMax, Transform)
		return OutMin + (Transform(ACF.Normalize(Value, InMin, InMax)) * (OutMax - OutMin))
	end

	local function UpdateDelta(Config)
		local CT = CurTime()
		Config.DeltaTime = (CT - Config.LastTime)
		Config.LastTime = CT
		Config.Elapsed = Config.Elapsed + Config.DeltaTime
	end

	local function InitFields(Config)
		Config.DeltaTime = 0
		Config.Elapsed = 0
		Config.LastTime = CurTime()
	end

	--- Similar to a mix of timer.create and timer.simple but with random steps.
	--- Every iteration it asks Loop to return the amount of time left. It will walk a random step or the time left, whichever is faster.
	--- Its principal use case is in dynamic reloading where the time until a loader Finishes loading changes during loading and must be checked at random.
	--- @param Loop function A function that returns the time left until the next iteration
	--- @param Depends function A function that returns whether the timer should continue
	--- @param Finish function A function that is called when the timer Finishes
	--- @param Config table A table with the fields: MinTime, MaxTime, Delay
	function ACF.AugmentedTimer(Loop, Depends, Finish, Config)
		InitFields(Config)

		local RealLoop
		local Cancelled = false
		local Finished  = false
		function RealLoop()
			if Cancelled then return end
			if Depends and not Depends(Config) then return end

			UpdateDelta(Config)
			local left = Loop(Config)
			local rand = Config.MinTime + (Config.MaxTime - Config.MinTime) * math.random()

			--Random step or Finishing step, whichever is faster.
			local timeleft = left and math.min(left, rand) or rand
			-- If time left then recurse, otherwise call Finish
			if timeleft > 0.001 then
				timer.Simple(timeleft, RealLoop)
			else
				if Finish and not Finished then Finished = true Finish(Config) end
				return
			end
		end

		if not Config.Delay then RealLoop()
		else timer.Simple(Config.Delay, RealLoop) end

		local ProxyObject = {}
		function ProxyObject:Cancel(RunFinisher)
			Cancelled = true
			if RunFinisher and Finish and not Finished then
				Finished = true
				Finish(Config)
			end
		end
		return ProxyObject
	end

	--- Wrapper for augmented timers, keeps a record of a "progress" and a "goal".
	--- Progress increases at the rate determined by Loop, until it reaches "goal"
	--- @param Ent any The entity to attach the timer to (checks its validity)
	--- @param Loop any	A function that returns the efficiency of the process
	--- @param Finish any A function that is called when the timer Finishes
	--- @param Config any A table with the fields: MinTime, MaxTime, Delay, Goal, Progress
	function ACF.ProgressTimer(Ent, Loop, Finish, Config)
		return ACF.AugmentedTimer(
			function(Config)
				local eff = Loop(Config)
				Config.Progress = Config.Progress + Config.DeltaTime * eff
				return (Config.Goal - Config.Progress) / eff
			end,
			function(Config)
				return IsValid(Ent) and Config.Progress < Config.Goal
			end,
			Finish,
			Config
		)
	end

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

	--- Recursively searches a table for an entry given keys, initializing layers with {} if they don't exist
	--- @param Tbl table -- The table to search
	--- @param ... any -- The keys to search for
	--- @return any -- The value at the given keys
	function ACF.GetTableSafe(Tbl, ...)
		if not Tbl then return end

		local keys = { ... }
		local value = Tbl

		for _, key in ipairs(keys) do
			if not value[key] then value[key] = {} end
			value = value[key]
		end

		return value
	end

	--- Returns the length and bulletdata of the longest bullet in any crate a gun has ever seen.
	--- @param Gun any The gun
	--- @return integer LongestLength The length of the longest bullet
	--- @return table? LongestBullet The bullet data of the longest bullet
	function ACF.FindLongestBullet(Gun)
		local LongestLength = 0
		local LongestBullet = nil
		for Crate in pairs(Gun.Crates) do
			local BulletData = Crate.BulletData
			local Length = BulletData.PropLength + BulletData.ProjLength
			if Length > LongestLength then
				LongestLength = Length
				LongestBullet = BulletData
			end
		end

		return LongestLength, LongestBullet
	end
end

do -- Reload related
	--- Calculates the time it takes for a gun to reload
	--- It is recommended to use Override with an entity which has "Cyclic" set to a value to reduce usage
	--- @param Caliber number The caliber of the weapon
	--- @param Class table Weapon class group
	--- @param Weapon table Weapon class item
	--- @param BulletData table Bullet data
	--- @param Override table Override data, either from an entity or a table
	function ACF.CalcReloadTime(Caliber, Class, Weapon, BulletData, Override)
		if BulletData.Type == "Refill" then return 1, false end -- None of the later calculations make sense if this is a refill

		-- If the weapon has a cyclic rate, use it, otherwise calculate the reload time based on the bullet data
		local Cyclic = Override and Override.Cyclic or ACF.GetWeaponValue("Cyclic", Caliber, Class, Weapon)
		if Cyclic then return 60 / Cyclic, false end

		-- Reload mod scales the final reload value and represents the ease of manipulating the weapon's ammunition
		local ReloadMod = ACF.GetWeaponValue("ReloadMod", Caliber, Class, Weapon) or 1

		local BaseTime = ACF.BaseReload + (BulletData.CartMass * ACF.MassToTime) + ((BulletData.PropLength + BulletData.ProjLength) * ACF.LengthToTime)
		return math.Clamp(BaseTime * ReloadMod, 0, 60), true -- Clamped to a maximum of 60 seconds of ideal loading
	end

	--- Calculates the time it takes for a gun to reload its magazine
	--- It is recommended to use Override with an entity which has "MagSize" set to a value to reduce usage
	--- @param Caliber number The caliber of the weapon
	--- @param Class table Weapon class group
	--- @param Weapon table Weapon class item
	--- @param BulletData table Bullet data
	--- @param Override table Override data, either from an entity or a table
	function ACF.CalcReloadTimeMag(Caliber, Class, Weapon, BulletData, Override)
		if BulletData.Type == "Refill" then return 1, false end -- None of the later calculations make sense if this is a refill

		-- Use the override if possible
		local MagSizeOverride = Override and Override.MagSize

		-- Reload mod scales the final reload value and represents the ease of manipulating the weapon's ammunition
		local ReloadMod = ACF.GetWeaponValue("ReloadMod", Caliber, Class, Weapon) or 1

		-- If the weapon has a boxed or belted magazine, use the magazine size, otherwise it's manual with one shell.
		local DefaultMagSize = ACF.GetWeaponValue("MagSize", Caliber, Class, Weapon) or 1

		-- Use the largest of the default mag size or the current mag size (beltfeds), or the default if neither is specified...
		local MagSize = math.max(MagSizeOverride or DefaultMagSize, DefaultMagSize)

		-- Note: Currently represents a projectile of the same dimensions with the mass of the entire magazine
		local BaseTime = ACF.BaseReload + (BulletData.CartMass * ACF.MassToTime) * MagSize + ((BulletData.PropLength + BulletData.ProjLength) * ACF.LengthToTime)
		return math.Clamp(BaseTime * ReloadMod, 0, 60), true -- Clamped to a maximum of 60 seconds of ideal loading
	end

	local ModelToPlayerStart = {
		["models/chairs_playerstart/jeeppose.mdl"] = "playerstart_chairs_jeep",
		["models/chairs_playerstart/airboatpose.mdl"] = "playerstart_chairs_airboat",
		["models/chairs_playerstart/sitposealt.mdl"] = "playerstart_chairs_seated",
		["models/chairs_playerstart/podpose.mdl"] = "playerstart_chairs_podpose",
		["models/chairs_playerstart/sitpose.mdl"] = "playerstart_chairs_seated_alt",
		["models/chairs_playerstart/standingpose.mdl"] = "playerstart_chairs_standing",
		["models/chairs_playerstart/pronepose.mdl"] = "playerstart_chairs_prone"
	}

	--- Generates a lua seat for a given entity
	--- @param Entity any The entity to attach the seat to
	--- @param Player any The owner of the entity
	--- @param Pos any The position of the seat
	--- @param Angle any The angle of the seat
	--- @param Model any The model of the seat
	--- @return unknown Pod The generated seat
	function ACF.GenerateLuaSeat(Entity, Player, Pos, Angle, Model)
		if not Player:CheckLimit("vehicles") then return end

		local Pod = ents.Create("prop_vehicle_prisoner_pod")
		Player:AddCount("vehicles", Pod)
		if IsValid(Pod) and IsValid(Player) then
			Pod:SetAngles(Angle)
			Pod:SetModel(Model)
			Pod:SetPos(Pos)
			Pod:Spawn()
			Pod:SetParent(Entity)

			-- MARCH: Fixes player-start animations
			-- I don't like how this works but it's the best way I can think of right now
			local PlayerStartName = ModelToPlayerStart[Model]
			if PlayerStartName then
				local PlayerStartInfo = list.GetForEdit("Vehicles")[PlayerStartName]
				if PlayerStartInfo then
					Pod:SetVehicleClass(PlayerStartName)
					if PlayerStartInfo.Members then
						table.Merge(Pod, PlayerStartInfo.Members)
					end
				end
			end

			Pod.Owner = Player
			Pod:CPPISetOwner(Player)

			return Pod
		else
			return nil
		end
	end

	timer.Simple(1, function()
		if WireLib then
			if not ACF.WirelibDetour_GetClosestRealVehicle then
				ACF.WirelibDetour_GetClosestRealVehicle = WireLib.GetClosestRealVehicle
			end
			local ACF_WirelibDetour_GetClosestRealVehicle = ACF.WirelibDetour_GetClosestRealVehicle
			function WireLib.GetClosestRealVehicle(Vehicle, Position, Notify)
				if IsValid(Vehicle) and Vehicle.ACF and Vehicle.ACF_GetSeatProxy then
					local Pod = Vehicle:ACF_GetSeatProxy()
					if IsValid(Pod) then return Pod end
				end

				return ACF_WirelibDetour_GetClosestRealVehicle(Vehicle, Position, Notify)
			end
		end
	end)

	--- Configures a lua seat after it has been created.
	--- Whenever the seat is created, this should be called after.
	--- @param Pod any The seat to configure
	--- @param Player any The owner of the seat
	function ACF.ConfigureLuaSeat(Entity, Pod, Player)
		-- Just to be safe...
		Pod.Owner = Player
		Pod:CPPISetOwner(Player)

		Pod:SetKeyValue("vehiclescript", "scripts/vehicles/prisoner_pod.txt")    	-- I don't know what this does, but for good measure...
		Pod:SetKeyValue("limitview", 0)                                            -- Let the player look around

		Pod.Vehicle = Entity
		Pod.ACF = Pod.ACF or {}
		Pod.ACF.LuaGeneratedSeat = true

		if not IsValid(Pod) then return end

		Pod:SetParent(Entity)

		Pod:SetNoDraw(true)
		Pod:SetNotSolid(true)
		-- MARCH: In Advanced Duplicator 2, pasting runs v.PostEntityPaste (if it exists), and then afterwards will call
		-- v:SetNotSolid(v.SolidMod). For whatever reason, that is false when the seat gets duped. So this just tricks
		-- the duplicator to make it not-solid. source: advdupe2/lua/advdupe2/sv_clipboard.lua
		Pod.SolidMod = true

		Pod.ACF_InvisibleToBallistics = true
		Pod.ACF_InvisibleToTrace = true
	end
end

do
	--- Sets up a table to track G forces
	--- Use with ACF.UpdateGForceTracker to update the G force tracker.
	--- @param pos? Vector The initial position
	--- @param vel? Vector The initial velocity
	--- @param accel? Vector The initial acceleration
	--- @return nil
	function ACF.SetupGForceTracker(pos, vel, accel)
		return {
			Pos = pos or vector_origin,
			Vel = vel or vector_origin,
			Acc = accel or vector_origin,
			LastPos = pos or vector_origin,
			LastVel = vel or vector_origin,
			LastAcc = accel or vector_origin,
			LastTime = CurTime()
		}
	end

	--- Returns the G force given the current position and the time since the last update.
	--- @param tbl table The table storing the G force tracker data
	--- @param newPos Vector The new position to update the tracker with
	--- @param dt? number The delta time since the last update (defaults to time since last update)
	--- @return number, number The G force experienced and the delta time since the last update
	function ACF.UpdateGForceTracker(tbl, newPos, dt)
		if not tbl then return end

		local LastTime = tbl.LastTime or CurTime()
		local DeltaTime = dt or (CurTime() - LastTime)

		tbl.Pos = newPos or tbl.Pos
		tbl.Vel = (tbl.Pos - tbl.LastPos) / DeltaTime
		tbl.Acc = (tbl.Vel - tbl.LastVel) / DeltaTime

		tbl.LastPos = tbl.Pos
		tbl.LastVel = tbl.Vel
		tbl.LastAcc = tbl.Acc
		tbl.LastTime = LastTime + DeltaTime
		return tbl.Acc:Length() / -ACF.Gravity.z, DeltaTime -- Since gravity is a vector...
	end
end

-- Helper function to perform pairs() over one or two tables (note this doesn't take into account duplicate keys)
function ACF.DuplexPairs(Table1, Table2)
	local Switched = false

	local function Enumerator(_, K)
		local V

		if Switched then
			K, V = next(Table2, K)
			return K, V
		else
			K, V = next(Table1, K)
			if K == nil and Table2 ~= nil then
				Switched = true
				return next(Table2, nil)
			else
				return K, V
			end
		end
	end

	return Enumerator, nil, nil
end