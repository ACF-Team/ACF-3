local ACF     = ACF
local Classes = ACF.Classes

local function Build(Menu, Contexts)
	local Gun = Contexts.Gun

	local WeaponField = Classes.GetTypeFieldByName(Gun.Class, "Weapon")
	local Class       = Classes.GetTypeByName(WeaponField.Options.InstantiateTypeForDefault)
	local ClassID     = Classes.GetTypeName(Class)
	local CaliberOpts = Classes.GetTypeFieldByName(Class, "Caliber").Options
	local AmmoType    = Classes.GetSubtypeByName("ACF.Ammunition.BaseAmmo", "ACF.Ammunition.HP")
	local Ammo        = AmmoType()

	Menu:AddTitle("#acf.menu.fun.piledrivers.settings")

	local Caliber = Menu:AddSlider("#acf.menu.caliber", CaliberOpts.Min, CaliberOpts.Max, CaliberOpts.Decimals)

	local ClassBase    = Menu:AddCollapsible("#acf.menu.fun.piledrivers.piledriver_info", nil, "icon16/monitor_edit.png")
	local ClassName    = ClassBase:AddTitle()
	local ClassDesc    = ClassBase:AddLabel()
	local ClassPreview = ClassBase:AddModelPreview(nil, true, "Primary")
	local ClassInfo    = ClassBase:AddLabel()
	local ClassStats   = ClassBase:AddLabel()

	ClassDesc:SetText(Class.Description)
	ClassPreview:UpdateModel(Class.Model)
	ClassPreview:UpdateSettings(Class.Preview)

	local function Recompute(Cal)
		local Scale  = Cal / Class.BaseCaliber
		local Length = Class.Round.MaxLength * Scale

		local WeaponInst   = Class()
		WeaponInst.Caliber = Cal

		Ammo.SpikeLength = Length
		Ammo.Weapon      = WeaponInst
		Ammo.RoundLength = Length
		Ammo.PropRatio   = 0
		Ammo.Tracer      = false

		local BulletData = Ammo:ClientConvert()

		ClassPreview:SetModelScale(Scale, true)

		-- Penetration is reported on GUIData (via GetDisplayData), not on BulletData.
		local MaxPen = (Ammo.GUIData and Ammo.GUIData.MaxPen) or 0

		ClassName:SetText(language.GetPhrase("acf.menu.fun.piledrivers.class_name"):format(math.Round(Cal, 2), Class.Name))
		ClassInfo:SetText(language.GetPhrase("acf.menu.fun.piledrivers.stats"):format(Class.Mass * Scale, Class.Cyclic, Class.MagSize, Class.ChargeRate))
		ClassStats:SetText(language.GetPhrase("acf.menu.fun.piledrivers.damage_stats"):format(math.Round(MaxPen, 2), math.Round(BulletData.MuzzleVel or 0, 2), BulletData.ProjLength or 0, ACF.FormatMass(BulletData.ProjMass or 0)))
	end

	local W        = Gun:Get("Weapon")
	local StartCal = math.Clamp((W and W.Caliber) or CaliberOpts.Default or CaliberOpts.Min, CaliberOpts.Min, CaliberOpts.Max)

	function Caliber:OnValueChanged(Value)
		if self._Suppress then return end
		Value = math.Round(Value, 2)
		self._Suppress = true
		self:SetValue(Value)
		self._Suppress = false

		Gun:Set("Weapon", { Type = ClassID, Data = { Caliber = Value } })
		Recompute(Value)
	end

	Caliber:SetValue(StartCal)
	Gun:Set("Weapon", { Type = ClassID, Data = { Caliber = StartCal } })
	Recompute(StartCal)
end

ACF.Menu.RegisterPage({
	ID       = "acf_piledriver",
	Category = "#acf.menu.fun",
	Name     = "#acf.menu.fun.piledrivers",
	Icon     = "pencil",
	Order    = 1,

	Contexts = { Gun = "acf_piledriver" },

	Actions = {
		{ Bind = "left",  Context = "Gun", Preview = true, Desc = "Spawn a new piledriver, or update the one you're aiming at." },
		{ Bind = "right", Commit = "link", Desc = "Select entities, then a piledriver, to link them (hold R to unlink)." },
	},

	Build = Build,
})

-- The Fun menu category is gated behind the ShowFunMenu server setting.
hook.Add("ACF_OnEnableMenuOption", "Enable Fun Menu", function(Name)
	if Name ~= "#acf.menu.fun" then return end
	if not ACF.GetServerBool("ShowFunMenu") then return false end
end)
