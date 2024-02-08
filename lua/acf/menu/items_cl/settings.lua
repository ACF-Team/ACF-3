local ACF = ACF

do -- Clientside settings
	local Ent_Info = GetConVar("acf_show_entity_info")
	local InfoHelp = {
		[0] = "ACF entities will never display their information bubble when the player looks at them.",
		[1] = "ACF entities will only display their information bubble when the player looks at them while they're not seated.",
		[2] = "ACF entities will always display their information bubble when a player looks at them."
	}

	ACF.AddMenuItem(1, "Settings", "Clientside Settings", "user", ACF.GenerateClientSettings)

	ACF.AddClientSettings(1, "Entity Information", function(Base)
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

	ACF.AddClientSettings(100, "Sound Volume", function(Base)
		local Volume = Base:AddSlider("Client Sound Volume", 0, 1, 2)
		Volume:SetClientData("Volume", "OnValueChanged")
		Volume:DefineSetter(function(Panel, _, _, Value)
			Value = math.Clamp(tonumber(Value) or 1, 0, 1)

			Panel:SetValue(Value)

			ACF.Volume = Value

			return Value
		end)
	end)

	ACF.AddClientSettings(101, "Effects and Visual Elements", function(Base)
		local Ropes = Base:AddCheckBox("Create mobility rope links.")
		Ropes:SetConVar("acf_mobilityropelinks")

		local Particles = Base:AddSlider("Particle Mult.", 0.1, 1, 2)
		Particles:SetConVar("acf_cl_particlemul")

		Base:AddHelp("Defines the clientside particle multiplier, reduce it if you're experiencing lag when ACF effects are created.")
	end)

	ACF.AddClientSettings(201, "Legal Checks", function(Base)
		local Hints = Base:AddCheckBox("Enable hints on entity disabling.")
		Hints:SetConVar("acf_legalhints")
	end)

	ACF.AddClientSettings(251, "Legal Check Name and Shame", function(Base)
		local Hints = Base:AddCheckBox("Enable receiving console messages for entities getting disabled.")
		Hints:SetConVar("acf_legalshame")
	end)

	ACF.AddClientSettings(301, "Debris", function(Base)
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

	ACF.AddClientSettings(401, "Tool Category", function(Base)
		local Category = Base:AddCheckBox("Use custom category for ACF tools.")
		Category:SetConVar("acf_tool_category")

		Base:AddHelp("You will need to rejoin the server for this option to apply.")
	end)
end

do -- Serverside settings
	ACF.AddMenuItem(101, "Settings", "Serverside Settings", "server", ACF.GenerateServerSettings)

	ACF.AddServerSettings(1, "General Settings", function(Base)
		local Admins = Base:AddCheckBox("Allow admins to control server data.")
		Admins:SetServerData("ServerDataAllowAdmin", "OnChange")
		Admins:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("If enabled, admins will be able to mess with the settings on this panel.")

		local Info = Base:AddCheckBox("Restrict entity information.")
		Info:SetServerData("RestrictInfo", "OnChange")
		Info:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("You'll need the player's permissions in order to check relevant information on entities owned by them.")

		local LegalChecks = Base:AddCheckBox("Enable legality checks on ACF entities.")
		LegalChecks:SetServerData("LegalChecks", "OnChange")
		LegalChecks:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local VehicleLegalChecks = Base:AddCheckBox("Enable legality checks on vehicle entities.")
		VehicleLegalChecks:SetServerData("VehicleLegalChecks", "OnChange")
		VehicleLegalChecks:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local LegalCheckNameAndShame = Base:AddCheckBox("Pubicly shame someone in everyone's console for a failed legal check.")
		LegalCheckNameAndShame:SetServerData("NameAndShame", "OnChange")
		LegalCheckNameAndShame:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local GunFire = Base:AddCheckBox("Allow guns to fire.")
		GunFire:SetServerData("GunsCanFire", "OnChange")
		GunFire:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local GunSmoke = Base:AddCheckBox("Allow guns to produce sounds and particles.")
		GunSmoke:SetServerData("GunsCanSmoke", "OnChange")
		GunSmoke:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local RackFire = Base:AddCheckBox("Allow missiles and bombs to fire.")
		RackFire:SetServerData("RacksCanFire", "OnChange")
		RackFire:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local RequireFuel = Base:AddCheckBox("Require fuel usage for engines.")
		RequireFuel:SetServerData("RequireFuel", "OnChange")
		RequireFuel:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local MaxThickness = Base:AddSlider("Max Armor Thickness", ACF.MinimumArmor, ACF.MaximumArmor)
		MaxThickness:SetServerData("MaxThickness", "OnValueChanged")
		MaxThickness:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local Health = Base:AddSlider("Health Factor", 0.01, 2, 2)
		Health:SetServerData("HealthFactor", "OnValueChanged")
		Health:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local Fuel = Base:AddSlider("Fuel Factor", 0.01, 2, 2)
		Fuel:SetServerData("FuelFactor", "OnValueChanged")
		Fuel:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)
	end)

	ACF.AddServerSettings(101, "Entity Pushing", function(Base)
		local HEPush = Base:AddCheckBox("Push entities due to HE forces.")
		HEPush:SetServerData("HEPush", "OnChange")
		HEPush:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local KEPush = Base:AddCheckBox("Push entities due to kinetic forces.")
		KEPush:SetServerData("KEPush", "OnChange")
		KEPush:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local Recoil = Base:AddCheckBox("Push entities due to weapon recoil.")
		Recoil:SetServerData("RecoilPush", "OnChange")
		Recoil:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)
	end)

	ACF.AddServerSettings(201, "Fun Entities and Menu", function(Base)
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

		local AllowProcArmor = Base:AddCheckBox("Allow use of Procedural Armor.")
		AllowProcArmor:SetServerData("AllowProcArmor", "OnChange")
		AllowProcArmor:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)
	end)

	ACF.AddServerSettings(301, "Workshop Content", function(Base)
		local Content = Base:AddCheckBox("Enable workshop content download for clients.")
		Content:SetServerData("WorkshopContent", "OnChange")
		Content:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local Extra = Base:AddCheckBox("Enable extra workshop content download for clients.")
		Extra:SetServerData("WorkshopExtras", "OnChange")
		Extra:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("Both of these options require a server restart to apply changes.")
	end)

	ACF.AddServerSettings(501, "Debris", function(Base)
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