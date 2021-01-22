AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

do -- Spawning and Updating
	local function VerifyData(Data)
		local Size = Data.Size

		if not isvector(Size) then
			Size = Vector(Data.PlateSizeX or 24, Data.PlateSizeY or 24, Data.PlateSizeZ or 24)

			Data.Size = Size
		end

		Size.x = math.Clamp(Size.x, 0.19685, 420)
		Size.y = math.Clamp(Size.y, 0.19685, 420)
		Size.z = math.Clamp(Size.z / 25.4, 0.19685, 420)
	end

	function MakeACF_Armor(Player, Pos, Angle, Data)
		if not Player:CheckLimit("props") then return end

		local Plate = ents.Create("acf_armor")

		if not IsValid(Plate) then return end

		Player:AddCount("props", Plate)
		Player:AddCleanup("props", Plate)

		Plate:SetModel("models/holograms/cube.mdl")
		Plate:SetMaterial("sprops/textures/sprops_metal1")
		Plate:SetPlayer(Player)
		Plate:SetAngles(Angle)
		Plate:SetPos(Pos)
		Plate:Spawn()

		VerifyData(Data)

		Plate:SetSize(Data.Size)

		--

		Plate.Owner = Player -- MUST be stored on ent for PP

		do -- Mass entity mod removal
			local EntMods = Data.EntityMods

			if EntMods and EntMods.mass then
				EntMods.mass = nil
			end
		end

		return Plate
	end

	ACF.RegisterEntityClass("acf_armor", MakeACF_Armor, "Size")

	function ENT:OnResized(Size)
		local Volume = Size.x * Size.y * Size.z
		local Mass   = Volume * 0.13 -- Kg of steel per inch

		self:GetPhysicsObject():SetMass(Mass)
	end
end

do -- ACF Activation and Damage
	function ENT:ACF_Activate(Recalc) -- TODO: Remove this
		local PhysObj = self.ACF.PhysObj

		if not self.ACF.Area then
			self.ACF.Area = PhysObj:GetSurfaceArea() * 6.45
		end

		local Volume = PhysObj:GetVolume()

		local Armour = 1
		local Health = Volume / ACF.Threshold
		local Percent = 1

		if Recalc and self.ACF.Health and self.ACF.MaxHealth then
			Percent = self.ACF.Health / self.ACF.MaxHealth
		end

		self.ACF.Health = Health * Percent
		self.ACF.MaxHealth = Health
		self.ACF.Armour = Armour * (0.5 + Percent / 2)
		self.ACF.MaxArmour = Armour
		self.ACF.Type = "Prop"
	end

	local function ArmorTrace(Trace)
		local R = ACF.Trace(Trace)

		if IsValid(R.Entity) and R.Entity:GetClass() == "acf_armor" then
			Trace.filter[#Trace.filter + 1] = R.Entity

			return ArmorTrace(Trace)
		end

		return R.HitPos
	end

	local function GetOpposite(Ent, Trace)
		local Size       = Ent:GetSize()
		local Mins, Maxs = Size * -0.5, Size * 0.5
		local Delta      = (Trace.HitPos - Trace.StartPos):GetNormalized()

		local Pos = util.IntersectRayWithOBB(Trace.HitPos + Delta * 1000, -Delta * 1000, Ent:GetPos(), Ent:GetAngles(), Mins, Maxs)
		debugoverlay.Cross(Pos + Vector(0, 0.1, 0.1), 3, 5, Color(255, 255, 255), true)

		return ArmorTrace({start = Trace.HitPos, endpos = Pos, filter = {ent} })
	end

	function ENT:GetArmor(Trace)
		local Enter = Trace.HitPos
		local Exit  = GetOpposite(self, Trace)

		debugoverlay.Cross(Enter, 3, 5, Color(0, 255, 0), true)
		debugoverlay.Cross(Exit, 3, 5, Color(255, 0, 0), true)
		debugoverlay.Line(Enter, Exit, 5, Color(0, 255, 255), true)

		return (Exit - Enter):Length() * 25.4 -- Inches to mm
	end
end