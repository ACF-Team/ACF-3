DEFINE_BASECLASS("acf_base_scalable") -- Required to get the local BaseClass

include("shared.lua")

function ENT:Initialize(...)
	BaseClass.Initialize(self, ...)
end

----

local Turrets = ACF.Classes.TurretTypes

do -- Updating
	function ENT:Update()

	end
end

do -- Turret menu item
	local function CreateMenu(Menu)
		ACF.SetToolMode("acf_menu", "Spawner", "Component")

		ACF.SetClientData("PrimaryClass", "acf_turret")
		ACF.SetClientData("SecondaryClass", "N/A")

		Menu:AddTitle("Procedural Turrets")
		Menu:AddLabel("WARNING: EXPERIMENTAL!\nProcedural Turrets are an experimental work in progress and may cause crashes, errors, or just not work properly with all of ACF.\n\nProcedural Turrets can be prevented from spawning by setting sbox_acf_max_turrets to 0")

		local ClassList = Menu:AddComboBox()
		local SizeX     = Menu:AddSlider("Ring diameter (gmu)", 5, 96 * 2, 2)

		local ClassBase = Menu:AddCollapsible("Turret Drive Information")
		local ClassName = ClassBase:AddTitle()
		local ClassDesc = ClassBase:AddLabel()

		function ClassList:OnSelect(Index, _, Data)
			if self.Selected == Data then return end

			self.ListData.Index = Index
			self.Selected       = Data

			ClassName:SetText(Data.Name)
			ClassDesc:SetText(Data.Description)

			ACF.SetClientData("Class", Data.ID)
		end

		SizeX:SetClientData("PlateSizeX", "OnValueChanged")
		SizeX:DefineSetter(function(Panel, _, _, Value)
			local X = math.Round(Value, 2)

			Panel:SetValue(X)

			return X
		end)

		ACF.LoadSortedList(ClassList, Turrets, "Name")
	end

	ACF.AddMenuItem(3, "Entities", "Turrets", "cog", CreateMenu)
end