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
	ACF.MissileMenu = ACF.MissileMenu or {}

	-- The fuze sub-context (nested inside the ammo crate's missile Weapon) that the current fuze menu
	-- controls write into. Set by FuzeList:OnSelect before a fuze's AddMenuControls runs.
	local FuzeSub

	-- Binds a fuze menu slider to a field on the fuze sub-context, so its value serializes with the crate
	-- (deep nesting: acf_ammo -> Weapon(missile) -> Fuze -> field) instead of the old global ClientData.
	-- Replaces the per-slider SetClientData/DefineSetter dance in the fuze classes.
	function ACF.MissileMenu.FuzeSlider(Panel, Field)
		if FuzeSub then Panel:SetValue(FuzeSub:Get(Field) or 0) end

		function Panel:OnValueChanged(Value)
			if self._Suppress then return end
			if FuzeSub then FuzeSub:Set(Field, Value) end
		end

		return Panel
	end

	-- Resolve a guidance/fuze identifier (FQN or short id) to its V2 class.
	local function ResolveType(Key)
		return Classes.GetTypeByName(Key)
	end

	local function GetTypeList(Set)
		local Result = {}
		if Set then
			for Key in pairs(Set) do
				local Info = ResolveType(Key)
				if Info then Result[Classes.GetTypeName(Info)] = Info end
			end
		end
		return Result
	end

	-- Populates a guidance/fuze combo without auto-firing OnSelect, then selects the option matching the
	-- crate's currently-configured instance -- so the menu reflects the context on open (like the ammo list),
	-- and the select handler still runs once to (re)build the sub-controls.
	local function RestoreTypeCombo(Combo, List, Current)
		ACF.Menu.PopulateCombo(Combo, List, "Name")

		local WantFQN = (Current and Current.GetType) and Classes.GetTypeName(Current:GetType()) or nil
		local Choices = Combo.ListData and Combo.ListData.Choices
		local Target  = 1

		if WantFQN and Choices then
			for I, Data in ipairs(Choices) do
				if Classes.GetTypeName(Data) == WantFQN then
					Target = I
					break
				end
			end
		end

		Combo.Selected = nil
		if Choices and Choices[1] ~= nil then Combo:ChooseOptionID(Target) end
	end

	hook.Add("ACF_OnCreateAmmoControls", "ACF Add Missiles Menu", function(Base, ToolData, Ammo, BulletData)
		local Missile = Base.MissileData
		if not Missile then return end

		-- Guidance + Fuze live on the crate's nested missile Weapon instance, so they serialize + commit
		-- with the crate. Edit them through sub-contexts of the ammo context (not global ClientData).
		local AmmoCtx   = ACF.AmmoMenu.GetContext and ACF.AmmoMenu.GetContext()
		local WeaponSub = AmmoCtx and ACF.Menu.SubContext(AmmoCtx, "Weapon")
		if not WeaponSub then return end

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

			local Cur = WeaponSub:Get("Guidance")
			if not (Cur and Cur.GetType and Cur:GetType() == Data) then
				WeaponSub:Set("Guidance", { Type = Classes.GetTypeName(Data), Data = {} })
			end

			local Guidance = WeaponSub:Get("Guidance")
			if Guidance.OnFirst then Guidance:OnFirst("Menu") end

			GuidanceBase:ClearTemporal()
			GuidanceBase:StartTemporal()
			if Guidance.AddMenuControls then Guidance:AddMenuControls(GuidanceBase, ToolData, Ammo, BulletData) end
			GuidanceBase:AddHelp(Guidance.Description)
			GuidanceBase:EndTemporal()

			BulletData.Guidance = Guidance
		end

		function FuzeList:OnSelect(Index, Name, Data)
			if self.Selected == Data then return end
			self:SetText("Fuze: " .. Name)
			self.ListData.Index = Index
			self.Selected = Data

			local Cur = WeaponSub:Get("Fuze")
			if not (Cur and Cur.GetType and Cur:GetType() == Data) then
				WeaponSub:Set("Fuze", { Type = Classes.GetTypeName(Data), Data = {} })
			end

			FuzeSub = ACF.Menu.SubContext(WeaponSub, "Fuze")

			local Fuze = WeaponSub:Get("Fuze")
			if Fuze.OnFirst then Fuze:OnFirst("Menu", ToolData) end

			FuzeBase:ClearTemporal()
			FuzeBase:StartTemporal()
			if Fuze.AddMenuControls then Fuze:AddMenuControls(FuzeBase, ToolData, Ammo, BulletData) end
			FuzeBase:AddHelp(Fuze.Description)
			FuzeBase:EndTemporal()

			BulletData.Fuze = Fuze
		end

		RestoreTypeCombo(GuidanceList, GetTypeList(Missile:GetType().Guidances), WeaponSub:Get("Guidance"))
		RestoreTypeCombo(FuzeList, GetTypeList(Missile:GetType().Fuzes), WeaponSub:Get("Fuze"))
	end)
else
	-- Each missile needs its OWN guidance/fuze instance: Configure/OnLaunched store per-missile state
	-- (Source/Target/TimeStarted), so multiple missiles fired from one crate must not share the crate
	-- weapon's single configured instance. Clone it (a fresh instance of the same class with the
	-- configured fields copied over) for every missile.
	local function CloneConfigured(Inst)
		local Class = Inst:GetType()
		local Copy  = Class()
		for _, Field in ipairs(Classes.GetTypeFields(Class)) do
			Copy[Field.Name] = Inst[Field.Name]
		end
		return Copy
	end

	-- The crate's missile weapon instance already carries deserialized Guidance/Fuze V2 instances.
	hook.Add("ACF_OnAmmoFirst", "ACF Missile Ammo", function(Ammo, Entity)
		if Entity.IsRefill then return end
		local Class = GetMissileClass(Ammo and Ammo.Weapon)
		if not Class then return end

		local Weapon = Ammo.Weapon
		if not (Weapon.Guidance and Weapon.Fuze) then return end

		local Guidance = CloneConfigured(Weapon.Guidance)
		local Fuze     = CloneConfigured(Weapon.Fuze)

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
