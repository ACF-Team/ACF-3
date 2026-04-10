local ACF        = ACF
local Components = ACF.Classes.Components

Components.Register("AL", {
	Name   = "Autoloader",
	Entity = "acf_autoloader",
	TutorialURL = "docs/acf_tutorials/autoloaders.html",
})

-- Converts shell scale to model scale
local RefSize = Vector(43.233333587646, 7.2349619865417, 7.2349619865417)
Components.RegisterItem("AL-IMP", "AL", {
	Name        = "Autoloader",
	Description = "An automatic ammunition loading system.",
	Model       = "models/acf/autoloader_tractorbeam.mdl",
	CreateMenu = function(_, Menu)
		ACF.SetClientData("PrimaryClass", "acf_autoloader")
		ACF.SetClientData("SecondaryClass", "N/A")

		local MassLabel = Menu:AddLabel("")
		local AutoloaderSize = Vector(0, 0, 0)

		local function UpdateAutoloaderStats()
			-- Mass is proportional to volume of the shell
			local R, H = AutoloaderSize.y, AutoloaderSize.x
			local Volume = math.pi * R * R * H

			MassLabel:SetText(string.format("Mass : %s", ACF.GetProperMass(Volume * 250)))

			if Menu.ComponentPreview then
				Menu.ComponentPreview:SetModelScale(AutoloaderSize, true)
			end
		end

		local CaliberSlider = Menu:AddSlider("Max Caliber (mm)", ACF.MinAutoloaderCaliber, ACF.MaxAutoloaderCaliber, 2)
		CaliberSlider:SetClientData("AutoloaderCaliber", "OnValueChanged")
		CaliberSlider:DefineSetter(function(Panel, _, _, Value)
			local Size = math.Round(Value, 2)

			Panel:SetValue(Size)

			AutoloaderSize.y = Size / RefSize.y / ACF.InchToMm
			AutoloaderSize.z = Size / RefSize.z / ACF.InchToMm

			UpdateAutoloaderStats()

			return Size
		end)

		local LengthSlider = Menu:AddSlider("Length (cm)", ACF.MinAutoloaderLength, ACF.MaxAutoloaderLength, 2)
		LengthSlider:SetClientData("AutoloaderLength", "OnValueChanged")
		LengthSlider:DefineSetter(function(Panel, _, _, Value)
			local Length = math.Round(Value, 2)

			Panel:SetValue(Length)

			AutoloaderSize.x = (Length / RefSize.x * 10) / ACF.InchToMm

			UpdateAutoloaderStats()

			return Length
		end)

		-- Helper text
		Menu:AddLabel("Set the max caliber and length to the dimensions of your shell (See ammo crate overlay).")
		Menu:AddLabel("They can link to multiple ammo crates, but only one gun.")
		Menu:AddLabel("They must have the same parent as their ammo crates.")
		Menu:AddLabel("They must be aligned with the gun's breech.")
		Menu:AddLabel("Aiming at the autoloader with the menu tool will show a line between the autoloader and the gun's breech. Use this to help align them.")
	end
})