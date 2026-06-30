local ACF         = ACF
local Classes     = ACF.Classes
local MissileBase = "ACF.Missiles.BaseMissile"

-- True when the given weapon back-reference is a V2 missile class instance.
local function GetMissileClass(Weapon)
	local Class = Weapon and Weapon.GetType and Weapon:GetType()
	if Class and Classes.IsAssignableTo(Class, Classes.GetTypeByName(MissileBase)) then
		return Class
	end
end

-- Inject the missile warhead multipliers (authored on the missile class Round) into the round data so
-- the shared warhead math (e.g. HEAT) sees the boosted filler/liner/standoff. New hook signature:
-- (Ammo, Ammo, BulletData, GUIData).
hook.Add("ACF_OnUpdateRound", "ACF Missile Ammo", function(Ammo, _, Data)
	local Class = GetMissileClass(Ammo and Ammo.Weapon)
	local Round = Class and Class.Round
	if not Round then return end

	Data.PenMul          = Round.PenMul
	Data.MissileStandoff = Round.Standoff
	Data.FillerMul       = Round.FillerMul
	Data.LinerMassMul    = Round.LinerMassMul
end)

if CLIENT then
	-- Resolve a guidance/fuze identifier (FQN or short id) to its V2 class.
	local function ResolveType(Key, BaseFQN)
		return Classes.GetTypeByName(Key) or Classes.GetTypeByName(BaseFQN .. "." .. Key)
	end

	local function GetTypeList(Set, BaseFQN)
		local Result = {}
		if Set then
			for Key in pairs(Set) do
				local Info = ResolveType(Key, BaseFQN)
				if Info then Result[Classes.GetTypeName(Info)] = Info end
			end
		end
		return Result
	end

	hook.Add("ACF_OnCreateAmmoControls", "ACF Add Missiles Menu", function(Base, ToolData, Ammo, BulletData)
		local Missile = Base.MissileData
		if not Missile then return end

		local GuidanceList = Base:AddComboBox()
		GuidanceList:SetName("GuidanceList")
		local GuidanceBase = Base:AddPanel("ACF_Panel")
		local FuzeList     = Base:AddComboBox()
		FuzeList:SetName("FuzeList")
		local FuzeBase     = Base:AddPanel("ACF_Panel")

		function GuidanceList:OnSelect(Index, Name, Data)
			if self.Selected == Data then return end
			self:SetText("Guidance: " .. Name)
			self.ListData.Index = Index
			self.Selected = Data

			ACF.SetClientData("Guidance", Classes.GetTypeName(Data))

			local Guidance = Data()
			if Guidance.OnFirst then Guidance:OnFirst("Menu") end

			GuidanceBase:ClearTemporal(GuidanceList)
			GuidanceBase:StartTemporal(GuidanceList)
			if Guidance.AddMenuControls then Guidance:AddMenuControls(GuidanceBase, ToolData, Ammo, BulletData) end
			GuidanceBase:AddHelp(Guidance.Description)
			GuidanceBase:EndTemporal(GuidanceList)

			BulletData.Guidance = Guidance
		end

		function FuzeList:OnSelect(Index, Name, Data)
			if self.Selected == Data then return end
			self:SetText("Fuze: " .. Name)
			self.ListData.Index = Index
			self.Selected = Data

			ACF.SetClientData("Fuze", Classes.GetTypeName(Data))

			local Fuze = Data()
			if Fuze.OnFirst then Fuze:OnFirst("Menu", ToolData) end

			FuzeBase:ClearTemporal(FuzeList)
			FuzeBase:StartTemporal(FuzeList)
			if Fuze.AddMenuControls then Fuze:AddMenuControls(FuzeBase, ToolData, Ammo, BulletData) end
			FuzeBase:AddHelp(Fuze.Description)
			FuzeBase:EndTemporal(FuzeList)

			BulletData.Fuze = Fuze
		end

		ACF.LoadSortedList(GuidanceList, GetTypeList(Missile.Guidance, "ACF.Missiles.Guidance"), "Name")
		ACF.LoadSortedList(FuzeList, GetTypeList(Missile.Fuzes or Missile.Fuze, "ACF.Missiles.Fuze"), "Name")
	end)
else
	-- The crate's missile weapon instance already carries deserialized Guidance/Fuze V2 instances.
	hook.Add("ACF_OnAmmoFirst", "ACF Missile Ammo", function(Ammo, Entity)
		if Entity.IsRefill then return end
		local Class = GetMissileClass(Ammo and Ammo.Weapon)
		if not Class then return end

		local Weapon   = Ammo.Weapon
		local Guidance = Weapon.Guidance
		local Fuze     = Weapon.Fuze
		if not (Guidance and Fuze) then return end

		if Guidance.OnFirst then Guidance:OnFirst(Entity) end
		if Fuze.OnFirst then Fuze:OnFirst(Entity) end
		if Guidance.Configure then Guidance:Configure(Entity) end
		if Fuze.Configure then Fuze:Configure(Entity) end

		Entity.IsMissileAmmo = true
		Entity.GuidanceData  = Guidance
		Entity.FuzeData      = Fuze
	end)

	hook.Add("ACF_OnAmmoLast", "ACF Missile Ammo", function(_, Entity)
		if not Entity.IsMissileAmmo then return end

		local Guidance = Entity.GuidanceData
		local Fuze     = Entity.FuzeData

		if Guidance and Guidance.OnLast then Guidance:OnLast(Entity) end
		if Fuze and Fuze.OnLast then Fuze:OnLast(Entity) end

		Entity.IsMissileAmmo = nil
		Entity.GuidanceData  = nil
		Entity.FuzeData      = nil
	end)

	ACF.RegisterAdditionalOverlay("acf_ammo", "Missile Info", function(Crate, State)
		if not Crate.IsMissileAmmo then return end

		local Guidance = Crate.GuidanceData
		local Fuze     = Crate.FuzeData
		if not (Guidance and Fuze) then return end

		State:AddKeyValue("Guidance", Guidance.Name)
		if Guidance.WriteDisplayConfig then Guidance:WriteDisplayConfig(State) end
		State:AddKeyValue("Fuze", Fuze.Name)
		if Fuze.WriteDisplayConfig then Fuze:WriteDisplayConfig(State) end
	end)
end
