local ACF = ACF

do -- Clientside settings
	local Ent_Info = GetConVar("acf_show_entity_info")
	local InfoHelp = {
		[0] = "ACF entities will never display their information bubble when the player looks at them.",
		[1] = "ACF entities will only display their information bubble when the player looks at them while they're not seated.",
		[2] = "ACF entities will always display their information bubble when a player looks at them."
	}

	ACF.AddMenuItem(1, "Settings", "Clientside Settings", "user", ACF.GenerateClientSettings)

	ACF.AddClientSettings("Effects and Visual Elements", function(Base)
		local Ropes = Base:AddCheckBox("Create mobility rope links.")
		Ropes:SetConVar("acf_mobilityropelinks")

		local Particles = Base:AddSlider("Particle Mult.", 0.1, 1, 2)
		Particles:SetConVar("acf_cl_particlemul")

		Base:AddHelp("Defines the clientside particle multiplier, reduce it if you're experiencing lag when ACF effects are created.")
	end)

	ACF.AddClientSettings("Entity Information", function(Base)
		local InfoValue = InfoHelp[Ent_Info:GetInt()] and Ent_Info:GetInt() or 1

		Base:AddLabel("Display ACF entity information:")

		local Info = Base:AddComboBox()
		Info:AddChoice("Never", 0)
		Info:AddChoice("When not seated", 1)
		Info:AddChoice("Always", 2)

		local InfoDesc = Base:AddHelp()
		InfoDesc:SetText(InfoHelp[InfoValue])

		function Info:OnSelect(_, _, Data)
			if not InfoHelp[Data] then
				Data = 1
			end

			Ent_Info:SetInt(Data)

			InfoDesc:SetText(InfoHelp[Data])
		end

		Info:ChooseOptionID(InfoValue + 1)

		local HitBox = Base:AddCheckBox("Draw hitboxes on ACF entities.")
		HitBox:SetConVar("acf_drawboxes")

		Base:AddHelp("Some entities might display more than just their hitbox.")

		local Rounds = Base:AddSlider("Max Rounds", 0, 64, 0)
		Rounds:SetConVar("ACF_MaxRoundsDisplay")

		Base:AddHelp("Defines the maximum amount of rounds an ammo crate needs to have before using bulk display.")
		Base:AddHelp("Requires hitboxes to be enabled.")
	end)

	ACF.AddClientSettings("Legal Checks", function(Base)
		local Hints = Base:AddCheckBox("Enable hints on entity disabling.")
		Hints:SetConVar("acf_legalhints")
	end)

	ACF.AddClientSettings("Tool Category", function(Base)
		local Category = Base:AddCheckBox("Use custom category for ACF tools.")
		Category:SetConVar("acf_tool_category")

		Base:AddHelp("You will need to rejoin the server for this option to apply.")
	end)

	ACF.AddClientSettings("Debris", function(Base)
		local Debris = Base:AddCheckBox("Allow creation of clientside debris.")
		Debris:SetConVar("acf_debris")

		local Collisions = Base:AddCheckBox("Allow debris to collide with entities.")
		Collisions:SetConVar("acf_debris_collision")

		Base:AddHelp("Disabling this can prevent certain types of spam-induced lag and crashes.")

		local Lifetime = Base:AddSlider("Debris Lifetime", 1, 300)
		Lifetime:SetConVar("acf_debris_lifetime")

		Base:AddHelp("Defines how long each debris will live before fading out.")

		local Multiplier = Base:AddSlider("Debris Gib Amount", 0.01, 1, 2)
		Multiplier:SetConVar("acf_debris_gibmultiplier")

		Base:AddHelp("Multiplier for the amount of clientside debris gibs to be created.")

		local GibLifetime = Base:AddSlider("Debris Gib Lifetime", 1, 300)
		GibLifetime:SetConVar("acf_debris_giblifetime")

		Base:AddHelp("Defines how long each debris gib will live before fading out.")
	end)
end

do -- Serverside settings
	ACF.AddMenuItem(101, "Settings", "Serverside Settings", "server", ACF.GenerateServerSettings)

	ACF.AddServerSettings("Fun Entities and Menu", function(Base)
		local Entities = Base:AddCheckBox("Allow use of Fun Entities.")
		Entities:SetServerData("AllowFunEnts", "OnChange")
		Entities:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("Entities can be still spawned if this option is disabled.")

		local Menu = Base:AddCheckBox("Show Fun Entities menu option.")
		Menu:SetServerData("ShowFunMenu", "OnChange")
		Menu:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("Changes on this option will only take effect once the players reload their menu.")
	end)

	ACF.AddServerSettings("Custom Killicons", function(Base)
		local Icons = Base:AddCheckBox("Use custom killicons for ACF entities.")
		Icons:SetServerData("UseKillicons", "OnChange")
		Icons:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("Changing this option will require a server restart.")
	end)

	ACF.AddServerSettings("Debris", function(Base)
		local Debris = Base:AddCheckBox("Allow networking of debris to clients.")
		Debris:SetServerData("CreateDebris", "OnChange")
		Debris:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local Fireballs = Base:AddCheckBox("Allow creation of serverside debris fireballs.")
		Fireballs:SetServerData("CreateFireballs", "OnChange")
		Fireballs:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("Allows compatibility with addons such as vFire, but is more taxing on server resources.")

		local Multiplier = Base:AddSlider("Fireball Amount", 0.01, 1, 2)
		Multiplier:SetServerData("FireballMult", "OnValueChanged")
		Multiplier:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("Multiplier for the amount of serverside fireballs to be created.")
	end)
end

-- TODO
-- Replace acf_healthmod and ACF.Threshold
-- Replace acf_armormod and ACF.ArmorMod
-- Replace or deprecate acf_ammomod and ACF.AmmoMod
-- Replace acf_fuelrate and ACF.FuelRate
-- Replace acf_spalling
-- Replace acf_gunfire and ACF.GunfireEnabled
