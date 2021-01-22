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

	function MakeACF_Armor(Player, Pos, Ang, Data)
		if not Player:CheckLimit("props") then return end

		local Plate = ents.Create("acf_armor")

		if not IsValid(Plate) then return end

		Player:AddCount("props", Plate)
		Player:AddCleanup("props", Plate)

		Plate:SetModel("models/holograms/cube.mdl")
		Plate:SetMaterial("sprops/textures/sprops_metal1")
		Plate:SetPlayer(Player)
		Plate:SetAngles(Ang)
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
end