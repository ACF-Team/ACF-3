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

do -- Trace functions
	local TraceLine = util.TraceLine

	function ACF.Trace(TraceData)
		local T = TraceLine(TraceData)

		if T.HitNonWorld and ACF.CheckClips(T.Entity, T.HitPos) then
			TraceData.filter[#TraceData.filter + 1] = T.Entity

			return ACF.Trace(TraceData)
		end

		return T
	end

	-- Generates a copy of and uses it's own filter instead of using the existing one
	function ACF.TraceF(TraceData)
		local Original = TraceData.filter
		local Filter = {}

		if istable(Original) then
			for K, V in pairs(Original) do Filter[K] = V end -- Quick copy
		elseif isentity(Original) then
			Filter[1] = Original
		else
			Filter = Original
		end

		TraceData.filter = Filter -- Temporarily replace filter

		local T = ACF.Trace(TraceData)

		TraceData.filter = Original -- Restore filter

		return T, Filter
	end
end

-- Pretty much unused, should be moved into the ACF namespace or just removed
function switch(cases, arg)
	local Var = cases[arg]

	if Var ~= nil then return Var end

	return cases.default
end

function ACF.RandomVector(Min, Max)
	local X = math.Rand(Min.x, Max.x)
	local Y = math.Rand(Min.y, Max.y)
	local Z = math.Rand(Min.z, Max.z)

	return Vector(X, Y, Z)
end

function ACF_GetHitAngle(HitNormal, HitVector)
	local Ang = math.deg(math.acos(HitNormal:Dot(-HitVector:GetNormalized()))) -- Can output nan sometimes on extremely small angles

	if Ang ~= Ang then -- nan is the only value that does not equal itself
		return 0 -- return 0 instead of nan
	else
		return Ang
	end
end

do -- Native type verification functions
	function ACF.CheckNumber(Value, Default)
		if not Value then return Default end

		return tonumber(Value) or Default
	end

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

do -- Model convex mesh and volume
	ACF.ModelInfo = ACF.ModelInfo or {}

	local Models = ACF.ModelInfo

	local function CreateEntity(Model)
		local Entity = SERVER and ents.Create("base_anim") or ents.CreateClientProp(Model)

		Entity:SetModel(Model)
		Entity:PhysicsInit(SOLID_VPHYSICS)

		return Entity
	end

	local function GetModelData(Model)
		if not isstring(Model) then return end
		if IsUselessModel(Model) then return end

		local Data = Models[Model]

		if Data then return Data end

		local Entity   = CreateEntity(Model)
		local PhysObj  = Entity:GetPhysicsObject()
		local Min, Max = PhysObj:GetAABB()

		Data = {
			Mesh   = PhysObj:GetMeshConvexes(),
			Volume = PhysObj:GetVolume(),
			Center = (Max + Min) * 0.5,
			Size   = Max - Min,
			Min    = Min,
			Max    = Max,
		}

		Models[Model] = Data

		Entity:Remove()

		return Data
	end

	local function IsValidScale(Scale)
		if not Scale then return false end
		if isnumber(Scale) then return true end

		return isvector(Scale)
	end

	local function ScaleMesh(Mesh, Scale)
		for I, Hull in ipairs(Mesh) do
			for J, Vertex in ipairs(Hull) do
				Mesh[I][J] = Vertex.pos * Scale
			end
		end
	end

	-- TODO: Optimize this in a way that doesn't imply creating an entity
	local function GetMeshVolume(Mesh)
		local Entity = CreateEntity("models/props_junk/PopCan01a.mdl")
		Entity:PhysicsInitMultiConvex(Mesh)

		local PhysObj = Entity:GetPhysicsObject()
		local Volume  = PhysObj:GetVolume()

		Entity:Remove()

		return Volume
	end

	-------------------------------------------------------------------

	function ACF.GetModelMesh(Model, Scale)
		local Data = GetModelData(Model)

		if not Data then return end

		local Mesh = table.Copy(Data.Mesh)

		if IsValidScale(Scale) then ScaleMesh(Mesh, Scale) end

		return Mesh
	end

	function ACF.GetModelCenter(Model, Scale)
		local Data = GetModelData(Model)

		if not Data then return end

		if not IsValidScale(Scale) then
			return Data.Center
		end

		return Data.Center * Scale
	end

	function ACF.GetModelVolume(Model, Scale)
		local Data = GetModelData(Model)

		if not Data then return end
		if not IsValidScale(Scale) then
			return Data.Volume
		end

		local Mesh = table.Copy(Data.Mesh)

		ScaleMesh(Mesh, Scale)

		return GetMeshVolume(Mesh)
	end

	function ACF.GetModelSize(Model, Scale)
		local Data = GetModelData(Model)

		if not Data then return end
		if not IsValidScale(Scale) then
			return Vector(Data.Size)
		end

		return Data.Size * Scale
	end
end

do -- Attachment storage
	local IsUseless = IsUselessModel
	local EntTable = FindMetaTable("Entity")
	local Models = {}

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
		if not Entity.AttachData then
			Entity.AttachData = GetModelData(Entity:GetModel(), true)
		end

		return Entity.AttachData
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

	EntTable.LegacySetModel = EntTable.LegacySetModel or EntTable.SetModel
	EntTable.LegacyGetAttachment = EntTable.LegacyGetAttachment or EntTable.GetAttachment
	EntTable.LegacyGetAttachments = EntTable.LegacyGetAttachments or EntTable.GetAttachments
	EntTable.LegacyLookupAttachment = EntTable.LegacyLookupAttachment or EntTable.LookupAttachment

	function EntTable:SetModel(Path, ...)
		self:LegacySetModel(Path, ...)

		self.AttachData = GetModelData(Path, true)
	end

	function EntTable:GetAttachment(Index, ...)
		local Data = GetAttachData(self)

		if not Data then
			return self:LegacyGetAttachment(Index, ...)
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

	function EntTable:GetAttachments(...)
		local Data = GetAttachData(self)

		if not Data then
			return self:LegacyGetAttachments(...)
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

	function EntTable:LookupAttachment(Name, ...)
		local Data = GetAttachData(self)

		if not Data then
			return self:LegacyLookupAttachment(Name, ...)
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

do -- Ballistic functions
	-- changes here will be automatically reflected in the armor properties tool
	function ACF_CalcArmor(Area, Ductility, Mass)
		return (Mass * 1000 / Area / 0.78) / (1 + Ductility) ^ 0.5 * ACF.ArmorMod
	end

	function ACF_MuzzleVelocity(Propellant, Mass)
		local PEnergy = ACF.PBase * ((1 + Propellant) ^ ACF.PScale - 1)
		local Speed = ((PEnergy * 2000 / Mass) ^ ACF.MVScale)
		local Final = Speed -- - Speed * math.Clamp(Speed/2000,0,0.5)

		return Final
	end

	function ACF_Kinetic(Speed, Mass, LimitVel)
		LimitVel = LimitVel or 99999
		Speed    = Speed / 39.37

		local Energy = {
			Kinetic = (Mass * (Speed ^ 2)) / 2000, --Energy in KiloJoules
			Momentum = Speed * Mass,
			Penetration = true
		}
		local KE = (Mass * (Speed ^ ACF.KinFudgeFactor)) / 2000 + Energy.Momentum

		Energy.Penetration = math.max(KE - (math.max(Speed - LimitVel, 0) ^ 2) / (LimitVel * 5) * (KE / 200) ^ 0.95, KE * 0.1)
		--Energy.Penetration = math.max( KE - (math.max(Speed-LimitVel,0)^2)/(LimitVel*5) * (KE/200)^0.95 , KE*0.1 )
		--Energy.Penetration = math.max(Energy.Momentum^ACF.KinFudgeFactor - math.max(Speed-LimitVel,0)/(LimitVel*5) * Energy.Momentum , Energy.Momentum*0.1)

		return Energy
	end
end

do -- Sound aliases
	local Stored = {}
	local Lookup = {}
	local Path = "sound/%s"

	local function CreateData(Name)
		if not Lookup[Name] then
			Lookup[Name] = {
				Name = Name,
				Children = {}
			}
		else
			Stored[Name] = nil
		end

		return Lookup[Name]
	end

	local function RegisterAlias(Old, New)
		if not isstring(Old) then return end
		if not isstring(New) then return end

		Old = Old:lower()
		New = New:lower()

		local OldData = CreateData(Old)
		local NewData = CreateData(New)

		NewData.Children[OldData] = true
		OldData.Parent = NewData
	end

	local function GetParentSound(Name, List, Total)
		for I = Total, 1, -1 do
			local Sound = List[I].Name

			if file.Exists(Path:format(Sound), "GAME") then
				Stored[Name] = Sound

				return Sound
			end
		end
	end

	-- Note: This isn't syncronized between server and client.
	-- If a sound happens to have multiple children, the result will differ between client and server.
	local function GetChildSound(Name)
		local Data = Lookup[Name]
		local Next = Data.Children
		local Checked = { [Data] = true }

		repeat
			local New = {}

			for Child in pairs(Next) do
				if Checked[Child] then continue end

				local Sound = Child.Name

				if file.Exists(Path:format(Sound), "GAME") then
					Stored[Name] = Sound

					return Sound
				end

				for K in pairs(Child.Children) do
					New[K] = true
				end

				Checked[Child] = true
			end

			Next = New

		until not next(Next)
	end

	local function GetAlias(Name)
		if not isstring(Name) then return end

		Name = Name:lower()

		if not Lookup[Name] then return Name end
		if Stored[Name] then return Stored[Name] end

		local Checked, List = {}, {}
		local Next = Lookup[Name]
		local Count = 0

		repeat
			if Checked[Next] then break end

			Count = Count + 1

			Checked[Next] = true
			List[Count] = Next

			Next = Next.Parent
		until not Next

		local Parent = GetParentSound(Name, List, Count)
		if Parent then return Parent end

		local Children = GetChildSound(Name)
		if Children then return Children end

		Stored[Name] = Name

		return Name
	end

	function ACF.RegisterSoundAliases(Table)
		if not istable(Table) then return end

		for K, V in pairs(Table) do
			RegisterAlias(K, V)
		end
	end

	ACF.GetSoundAlias = GetAlias

	-- sound.Play hijacking
	-- TODO: BURN THIS TO THE GROUND
	sound.DefaultPlay = sound.DefaultPlay or sound.Play

	function sound.Play(Name, ...)
		Name = GetAlias(Name)

		return sound.DefaultPlay(Name, ...)
	end

	-- ENT:EmitSound hijacking
	local ENT = FindMetaTable("Entity")

	ENT.DefaultEmitSound = ENT.DefaultEmitSound or ENT.EmitSound

	function ENT:EmitSound(Name, ...)
		Name = GetAlias(Name)

		return self:DefaultEmitSound(Name, ...)
	end

	-- CreateSound hijacking
	DefaultCreateSound = DefaultCreateSound or CreateSound

	function CreateSound(Entity, Name, ...)
		Name = GetAlias(Name)

		return DefaultCreateSound(Entity, Name, ...)
	end

	-- Valid sound check
	if CLIENT then
		local SoundCache = {}

		function ACF.IsValidSound(Name)
			Name = GetAlias(Name:Trim())

			if SoundCache[Name] == nil then
				SoundCache[Name] = #Name > 0 and file.Exists(Path:format(Name), "GAME")
			end

			return SoundCache[Name]
		end
	end
end
