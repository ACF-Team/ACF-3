
local ACF = ACF
local AmmoTypes = ACF.Classes.AmmoTypes
local CurrentAmmo, AmmoData

local function GetAmmoList(Class)
	local Result = {}

	for K, V in pairs(AmmoTypes) do
		if V.Unlistable then continue end
		if V.Blacklist[Class] then continue end

		Result[K] = V
	end

	return Result
end

function ACF.GetCurrentAmmoData()
	return AmmoData
end

function ACF.UpdateAmmoMenu(Menu)
	local Ammo = CurrentAmmo

	if not Ammo then return end

	local ToolData = ACF.GetToolData()
	local Base = Menu.AmmoBase

	AmmoData = Ammo:ClientConvert(ToolData)

	Menu:ClearTemporal(Base)
	Menu:StartTemporal(Base)

	if not Ammo.SupressDefaultMenu then
		local RoundLength = Base:AddLabel()
		RoundLength:TrackDataVar("Projectile", "SetText")
		RoundLength:TrackDataVar("Propellant")
		RoundLength:TrackDataVar("Tracer")
		RoundLength:SetValueFunction(function()
			local Text = "Round Length: %s / %s cm"
			local CurLength = AmmoData.ProjLength + AmmoData.PropLength + AmmoData.Tracer
			local MaxLength = AmmoData.MaxRoundLength

			return Text:format(CurLength, MaxLength)
		end)

		local Projectile = Base:AddSlider("Projectile Length", 0, AmmoData.MaxRoundLength, 2)
		Projectile:SetDataVar("Projectile", "OnValueChanged")
		Projectile:SetValueFunction(function(Panel, IsTracked)
			ToolData.Projectile = ACF.ReadNumber("Projectile")

			if not IsTracked then
				AmmoData.Priority = "Projectile"
			end

			Ammo:UpdateRoundData(ToolData, AmmoData)

			ACF.WriteValue("Propellant", AmmoData.PropLength)

			Panel:SetValue(AmmoData.ProjLength)

			return AmmoData.ProjLength
		end)

		local Propellant = Base:AddSlider("Propellant Length", 0, AmmoData.MaxRoundLength, 2)
		Propellant:SetDataVar("Propellant", "OnValueChanged")
		Propellant:SetValueFunction(function(Panel, IsTracked)
			ToolData.Propellant = ACF.ReadNumber("Propellant")

			if not IsTracked then
				AmmoData.Priority = "Propellant"
			end

			Ammo:UpdateRoundData(ToolData, AmmoData)

			ACF.WriteValue("Projectile", AmmoData.ProjLength)

			Panel:SetValue(AmmoData.PropLength)

			return AmmoData.PropLength
		end)
	end

	if Ammo.MenuAction then
		Ammo:MenuAction(Base, ToolData, AmmoData)
	end

	Base:AddLabel("This entity can be fully parented.")

	Menu:EndTemporal(Base)
end

function ACF.CreateAmmoMenu(Menu)
	Menu:AddTitle("Ammo Settings")

	local List = Menu:AddComboBox()

	local SizeX = Menu:AddSlider("Crate Width", 6, 96, 2)
	SizeX:SetDataVar("CrateSizeX", "OnValueChanged")
	SizeX:SetValueFunction(function(Panel)
		local Value = ACF.ReadNumber("CrateSizeX")

		Panel:SetValue(Value)

		return Value
	end)

	local SizeY = Menu:AddSlider("Crate Height", 6, 96, 2)
	SizeY:SetDataVar("CrateSizeY", "OnValueChanged")
	SizeY:SetValueFunction(function(Panel)
		local Value = ACF.ReadNumber("CrateSizeY")

		Panel:SetValue(Value)

		return Value
	end)

	local SizeZ = Menu:AddSlider("Crate Depth", 6, 96, 2)
	SizeZ:SetDataVar("CrateSizeZ", "OnValueChanged")
	SizeZ:SetValueFunction(function(Panel)
		local Value = ACF.ReadNumber("CrateSizeZ")

		Panel:SetValue(Value)

		return Value
	end)

	local Base = Menu:AddCollapsible("Ammo Information")
	local Desc = Base:AddLabel()

	local Preview = Base:AddModelPreview()
	Preview:SetCamPos(Vector(45, 45, 30))
	Preview:SetHeight(120)
	Preview:SetFOV(50)

	function List:LoadEntries(Class)
		ACF.LoadSortedList(self, GetAmmoList(Class), "Name")
	end

	function List:OnSelect(Index, _, Data)
		if self.Selected == Data then return end

		self.ListData.Index = Index
		self.Selected = Data

		CurrentAmmo = Data

		ACF.WriteValue("AmmoType", Data.ID)

		Desc:SetText(Data.Description)
		Preview:SetModel(Data.Model)

		ACF.UpdateAmmoMenu(Menu)
	end

	Menu.AmmoBase = Base

	return List
end
