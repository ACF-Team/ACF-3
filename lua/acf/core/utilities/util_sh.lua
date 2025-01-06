local ACF = ACF

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

	local function UpdateDelta(cfg)
		cfg.DeltaTime = (CurTime() - cfg.LastTime)
		cfg.LastTime = CurTime()
		cfg.Elapsed = cfg.Elapsed + cfg.DeltaTime
	end

	local function InitFields(cfg)
		cfg.DeltaTime = 0
		cfg.Elapsed = 0
		cfg.LastTime = CurTime()
	end

	--- Initializes and runs a random recursive timer
	--- @param loop any
	--- @param depends any
	--- @param finish any
	--- @param cfg any
	function ACF.AugmentedTimer(loop, depends, finish, cfg)
		InitFields(cfg)

		local realLoop
		function realLoop()
			if depends and not depends(cfg) then return end

			UpdateDelta(cfg)
			local left = loop(cfg)
			local rand = cfg.MinTime + (cfg.MaxTime - cfg.MinTime) * math.random()

			--Random step or finishing step, whichever is faster.
			local timeleft = left and math.min(left, rand) or rand
			-- print(timeleft, cfg.Elapsed)
			-- If time left then recurse, otherwise call finish
			if timeleft > 0 then
				timer.Simple(timeleft, realLoop)
			else
				if finish then finish(cfg) end
				return
			end
		end

		if not cfg.Delay then realLoop()
		else timer.Simple(cfg.Delay, realLoop) end
	end

	function ACF.ProgressTimer(ent, loop, finish, cfg)
		ACF.AugmentedTimer(
			function(cfg)
				local eff = loop(cfg)
				cfg.Progress = cfg.Progress + cfg.DeltaTime * eff
				return (cfg.Goal - cfg.Progress) / eff
			end,
			function(cfg)
				return IsValid(ent) and cfg.Progress < cfg.Goal
			end,
			finish,
			cfg
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
		-- If the weapon has a cyclic rate, use it, otherwise calculate the reload time based on the bullet data
		local Cyclic = Override and Override.Cyclic or ACF.GetWeaponValue("Cyclic", Caliber, Class, Weapon)
		if Cyclic then return 60 / Cyclic, false end

		local BaseTime = ACF.BaseReload + (BulletData.CartMass * ACF.MassToTime) + ((BulletData.PropLength + BulletData.ProjLength) * ACF.LengthToTime)
		return BaseTime, true
	end

	--- Calculates the time it takes for a gun to reload its magazine
	--- It is recommended to use Override with an entity which has "MagSize" set to a value to reduce usage
	--- @param Caliber number The caliber of the weapon
	--- @param Class table Weapon class group
	--- @param Weapon table Weapon class item
	--- @param BulletData table Bullet data
	--- @param Override table Override data, either from an entity or a table
	function ACF.CalcReloadTimeMag(Caliber, Class, Weapon, BulletData, Override)
		-- Use the override if possible
		local MagSize = Override and Override.MagSize

		-- If the weapon has a boxed or belted magazine, use the magazine size, otherwise it's manual with one shell.
		if not MagSize then
			local Boxed = ACF.GetWeaponValue("IsBoxed", Caliber, Class, Weapon)
			local Belted = ACF.GetWeaponValue("IsBelted", Caliber, Class, Weapon)
			MagSize = (Boxed or Belted) and ACF.GetWeaponValue("MagSize", Caliber, Class, Weapon) or 1
		end

		-- Note: Currently represents a projectile of the same dimensions with the mass of the entire magazine
		local BaseTime = ACF.BaseReload + (BulletData.CartMass * ACF.MassToTime) * MagSize + ((BulletData.PropLength + BulletData.ProjLength) * ACF.LengthToTime)
		return BaseTime, true
	end

	-- Calculates the reload efficiency between a Crew, one of it's guns and an ammo crate
	function ACF.GetReloadEff(Crew, Gun, Ammo)
		local D1 = Crew:GetPos():Distance(Gun:LocalToWorld(Vector(Gun:OBBMins().x, 0, 0))) -- Breach relative to coordinate center?
		local D2 = Crew:GetPos():Distance(Ammo:GetPos())
		-- print("Dist: ", D1 + D2, ACF.Normalize(D1 + D2, ACF.LoaderWorstDist, ACF.LoaderBestDist))
		return Crew.TotalEff * ACF.Normalize(D1 + D2, ACF.LoaderWorstDist, ACF.LoaderBestDist)
	end
end
