
local hook      = hook
local ACF       = ACF
local Classes   = ACF.Classes
local AmmoTypes = Classes.AmmoTypes
local BoxSize   = Vector()
local Ammo, BulletData

local CrateText = [[
	Crate Armor: %s mm
	Crate Mass : %s
	Crate Capacity : %s round(s)]]

local function GetAmmoList(Class)
	local Entries = AmmoTypes.GetEntries()
	local Result  = {}

	for K, V in pairs(Entries) do
		if V.Unlistable then continue end
		if V.Blacklist[Class] then continue end

		Result[K] = V
	end

	return Result
end

local function GetWeaponClass(ToolData)
	local Destiny = Classes[ToolData.Destiny or "Weapons"]

	return Classes.GetGroup(Destiny, ToolData.Weapon)
end

local function GetEmptyMass()
	local Armor          = ACF.AmmoArmor * 0.039 -- Millimeters to inches
	local ExteriorVolume = BoxSize.x * BoxSize.y * BoxSize.z
	local InteriorVolume = (BoxSize.x - Armor) * (BoxSize.y - Armor) * (BoxSize.z - Armor)

	return math.Round((ExteriorVolume - InteriorVolume) * 0.13, 2)
end

local function AddPreview(Base, ToolData)
	if Ammo.PreCreateAmmoPreview then
		local Result = Ammo:PreCreateAmmoPreview(Base, ToolData, BulletData)

		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateAmmoPreview", Base, ToolData, Ammo, BulletData)

	if not Result then return end

	local Preview = Base:AddModelPreview(nil, true)
	local Setup   = {}

	if Ammo.OnCreateAmmoPreview then
		Ammo:OnCreateAmmoPreview(Preview, Setup, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateAmmoPreview", Preview, Setup, ToolData, Ammo, BulletData)

	Preview:UpdateModel(Setup.Model)
	Preview:UpdateSettings(Setup)
end

local function AddTracer(Base, ToolData)
	if Ammo.PreCreateTracerControls then
		local Result = Ammo:PreCreateTracerControls(Base, ToolData, BulletData)

		if not Result then
			ACF.SetClientData("Tracer", false)

			return
		end
	end

	local Result = hook.Run("ACF_PreCreateTracerControls", Base, ToolData, Ammo, BulletData)

	if not Result then
		ACF.SetClientData("Tracer", false)

		return
	end

	local Tracer = Base:AddCheckBox("Tracer")
	Tracer:SetClientData("Tracer", "OnChange")
	Tracer:DefineSetter(function(Panel, _, _, Value)
		ToolData.Tracer = Value

		Ammo:UpdateRoundData(ToolData, BulletData)

		ACF.SetClientData("Projectile", BulletData.ProjLength)
		ACF.SetClientData("Propellant", BulletData.PropLength)

		Panel:SetText("Tracer : " .. BulletData.Tracer .. " cm")
		Panel:SetValue(ToolData.Tracer)

		return ToolData.Tracer
	end)

	if Ammo.OnCreateTracerControls then
		Ammo:OnCreateTracerControls(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateTracerControls", Base, ToolData, Ammo, BulletData)
end

local function AddControls(Base, ToolData)
	if Ammo.PreCreateAmmoControls then
		local Result = Ammo:PreCreateAmmoControls(Base, ToolData, BulletData)

		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateAmmoControls", Base, ToolData, Ammo, BulletData)

	if not Result then return end

	local RoundLength = Base:AddLabel()
	RoundLength:TrackClientData("Projectile", "SetText", "GetText")
	RoundLength:TrackClientData("Propellant")
	RoundLength:TrackClientData("Tracer")
	RoundLength:DefineSetter(function()
		local Text = "Round Length: %s / %s cm"
		local CurLength = BulletData.ProjLength + BulletData.PropLength + BulletData.Tracer
		local MaxLength = BulletData.MaxRoundLength

		return Text:format(CurLength, MaxLength)
	end)

	local Projectile = Base:AddSlider("Projectile Length", 0, BulletData.MaxRoundLength, 2)
	Projectile:SetClientData("Projectile", "OnValueChanged")
	Projectile:DefineSetter(function(Panel, _, _, Value, IsTracked)
		ToolData.Projectile = Value

		if not IsTracked then
			BulletData.Priority = "Projectile"
		end

		Ammo:UpdateRoundData(ToolData, BulletData)

		ACF.SetClientData("Propellant", BulletData.PropLength)

		Panel:SetValue(BulletData.ProjLength)

		return BulletData.ProjLength
	end)

	local Propellant = Base:AddSlider("Propellant Length", 0, BulletData.MaxRoundLength, 2)
	Propellant:SetClientData("Propellant", "OnValueChanged")
	Propellant:DefineSetter(function(Panel, _, _, Value, IsTracked)
		ToolData.Propellant = Value

		if not IsTracked then
			BulletData.Priority = "Propellant"
		end

		Ammo:UpdateRoundData(ToolData, BulletData)

		ACF.SetClientData("Projectile", BulletData.ProjLength)

		Panel:SetValue(BulletData.PropLength)

		return BulletData.PropLength
	end)

	if Ammo.OnCreateAmmoControls then
		Ammo:OnCreateAmmoControls(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateAmmoControls", Base, ToolData, Ammo, BulletData)

	AddTracer(Base, ToolData)
end

local function AddCrateInformation(Base, ToolData)
	if Ammo.PreCreateCrateInformation then
		local Result = Ammo:PreCreateCrateInformation(Base, ToolData, BulletData)

		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateCrateInformation", Base, ToolData, Ammo, BulletData)

	if not Result then return end

	local Crate = Base:AddLabel()
	Crate:TrackClientData("Weapon", "SetText")
	Crate:TrackClientData("CrateSizeX")
	Crate:TrackClientData("CrateSizeY")
	Crate:TrackClientData("CrateSizeZ")
	Crate:DefineSetter(function()
		local Class  = GetWeaponClass(ToolData)
		local Rounds = ACF.GetAmmoCrateCapacity(BoxSize, Class, ToolData, BulletData)
		local Empty  = GetEmptyMass()
		local Load   = math.floor(BulletData.CartMass * Rounds)
		local Mass   = ACF.GetProperMass(math.floor(Empty + Load))

		return CrateText:format(ACF.AmmoArmor, Mass, Rounds)
	end)

	if Ammo.OnCreateCrateInformation then
		Ammo:OnCreateCrateInformation(Base, Crate, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateCrateInformation", Base, Crate, ToolData, Ammo, BulletData)
end

local function AddInformation(Base, ToolData)
	if Ammo.PreCreateAmmoInformation then
		local Result = Ammo:PreCreateAmmoInformation(Base, ToolData, BulletData)

		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateAmmoInformation", Base, ToolData, Ammo, BulletData)

	if not Result then return end

	AddCrateInformation(Base, ToolData)

	if Ammo.OnCreateAmmoInformation then
		Ammo:OnCreateAmmoInformation(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateAmmoInformation", Base, ToolData, Ammo, BulletData)
end

function ACF.GetCurrentAmmoData()
	return BulletData
end

function ACF.UpdateAmmoMenu(Menu)
	if not Ammo then return end

	local ToolData = ACF.GetAllClientData()
	local Base = Menu.AmmoBase

	BulletData = Ammo:ClientConvert(ToolData)

	Menu:ClearTemporal(Base)

	if Ammo.PreCreateAmmoMenu then
		local Result = Ammo:PreCreateAmmoMenu(ToolData, BulletData)

		if not Result then return end
	end

	local Result = hook.Run("ACF_PreCreateAmmoMenu", ToolData, Ammo, BulletData)

	if not Result then return end

	Menu:StartTemporal(Base)

	if Ammo.OnCreateAmmoMenu then
		Ammo:OnCreateAmmoMenu(Base, ToolData, BulletData)
	end

	hook.Run("ACF_OnCreateAmmoMenu", Base, ToolData, Ammo, BulletData)

	AddPreview(Base, ToolData)
	AddControls(Base, ToolData)
	AddInformation(Base, ToolData)

	Menu:EndTemporal(Base)
end

function ACF.CreateAmmoMenu(Menu)
	Menu:AddTitle("Ammo Settings")

	local List = Menu:AddComboBox()
	local Min  = ACF.AmmoMinSize
	local Max  = ACF.AmmoMaxSize

	local SizeX = Menu:AddSlider("Crate Length", Min, Max)
	SizeX:SetClientData("CrateSizeX", "OnValueChanged")
	SizeX:DefineSetter(function(Panel, _, _, Value)
		local X = math.Round(Value)

		Panel:SetValue(X)

		BoxSize.x = X

		return X
	end)

	local SizeY = Menu:AddSlider("Crate Width", Min, Max)
	SizeY:SetClientData("CrateSizeY", "OnValueChanged")
	SizeY:DefineSetter(function(Panel, _, _, Value)
		local Y = math.Round(Value)

		Panel:SetValue(Y)

		BoxSize.y = Y

		return Y
	end)

	local SizeZ = Menu:AddSlider("Crate Height", Min, Max)
	SizeZ:SetClientData("CrateSizeZ", "OnValueChanged")
	SizeZ:DefineSetter(function(Panel, _, _, Value)
		local Z = math.Round(Value)

		Panel:SetValue(Z)

		BoxSize.z = Z

		return Z
	end)

	local Base = Menu:AddCollapsible("Ammo Information")
	local Desc = Base:AddLabel()

	function List:LoadEntries(Class)
		ACF.LoadSortedList(self, GetAmmoList(Class), "Name")
	end

	function List:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		Ammo = Data

		ACF.SetClientData("AmmoType", Data.ID)

		Desc:SetText(Data.Description)

		ACF.UpdateAmmoMenu(Menu)
	end

	Menu.AmmoBase = Base

	return List
end
