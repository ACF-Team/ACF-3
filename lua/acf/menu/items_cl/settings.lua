local ACF = ACF

do -- Clientside settings
	local Ent_Info = GetConVar("acf_show_entity_info")
	local InfoHelp = {
		[0] = "#acf.menu.settings.show_ent_info.never_desc",
		[1] = "#acf.menu.settings.show_ent_info.not_seated_desc",
		[2] = "#acf.menu.settings.show_ent_info.always_desc"
	}

	ACF.AddMenuItem(1, "#acf.menu.settings", "#acf.menu.settings.client", "user", ACF.GenerateClientSettings)

	ACF.AddClientSettings(1, "#acf.menu.settings.ent_info", function(Base)
		local InfoValue = InfoHelp[Ent_Info:GetInt()] and Ent_Info:GetInt() or 1

		Base:AddLabel("#acf.menu.settings.show_ent_info")

		local Info = Base:AddComboBox()
		Info:AddChoice("#acf.menu.settings.show_ent_info.never", 0)
		Info:AddChoice("#acf.menu.settings.show_ent_info.not_seated", 1)
		Info:AddChoice("#acf.menu.settings.show_ent_info.always", 2)

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

		local HitBox = Base:AddCheckBox("#acf.menu.settings.draw_hitbox")
		HitBox:SetConVar("acf_drawboxes")

		Base:AddHelp("#acf.menu.settings.draw_hitbox_desc")

		local Rounds = Base:AddSlider("#acf.menu.settings.max_rounds", 0, 64, 0)
		Rounds:SetConVar("ACF_MaxRoundsDisplay")

		Base:AddHelp("#acf.menu.settings.max_rounds_desc")
	end)

	ACF.AddClientSettings(100, "#acf.menu.settings.sound_volume", function(Base)
		local Volume = Base:AddSlider("#acf.menu.settings.sound_volume_client", 0, 1, 2)
		Volume:SetClientData("Volume", "OnValueChanged")
		Volume:DefineSetter(function(Panel, _, _, Value)
			Value = math.Clamp(tonumber(Value) or 1, 0, 1)

			Panel:SetValue(Value)

			ACF.Volume = Value

			return Value
		end)
	end)

	ACF.AddClientSettings(101, "#acf.menu.settings.effects_visual_elements", function(Base)
		local Ropes = Base:AddCheckBox("#acf.menu.settings.effects_visual_elements.rope_links")
		Ropes:SetConVar("acf_mobilityropelinks")

		local Particles = Base:AddSlider("#acf.menu.settings.effects_visual_elements.particle_mult", 0.1, 1, 2)
		Particles:SetConVar("acf_cl_particlemul")

		Base:AddHelp("#acf.menu.settings.effects_visual_elements.particle_mult_desc")

		Base:AddLabel("#acf.menu.settings.effects_visual_elements.ammo_refill")
		local AmmoRefillColor = Base:AddPanel("DColorMixer")
		AmmoRefillColor:SetColor(ACF.AmmoRefillColor)
		AmmoRefillColor:SetClientData("AmmoRefillColor", "ValueChanged")
		AmmoRefillColor:DefineSetter(function(_, _, _, Value)
			ACF.AmmoRefillColor = Value

			return Value
		end)

		Base:AddLabel("#acf.menu.settings.effects_visual_elements.fuel_refill")
		local FuelRefillColor = Base:AddPanel("DColorMixer")
		FuelRefillColor:SetColor(ACF.FuelRefillColor)
		FuelRefillColor:SetClientData("FuelRefillColor", "ValueChanged")
		FuelRefillColor:DefineSetter(function(_, _, _, Value)
			ACF.FuelRefillColor = Value

			return Value
		end)
	end)

	ACF.AddClientSettings(201, "#acf.menu.settings.legal_checks", function(Base)
		local Hints = Base:AddCheckBox("#acf.menu.settings.legal_checks.legal_hints")
		Hints:SetConVar("acf_legalhints")

		local ShameMsgs = Base:AddCheckBox("#acf.menu.settings.legal_checks.legal_shame")
		ShameMsgs:SetConVar("acf_legalshame")
		Base:AddHelp("#acf.menu.settings.legal_checks.legal_shame_desc")
	end)

	ACF.AddClientSettings(301, "#acf.menu.settings.debris", function(Base)
		local Debris = Base:AddCheckBox("#acf.menu.settings.debris.clientside")
		Debris:SetConVar("acf_debris")

		local Collisions = Base:AddCheckBox("#acf.menu.settings.debris.collision")
		Collisions:SetConVar("acf_debris_collision")

		Base:AddHelp("#acf.menu.settings.debris.collision_desc")

		local Lifetime = Base:AddSlider("#acf.menu.settings.debris.lifetime", 1, 300)
		Lifetime:SetConVar("acf_debris_lifetime")

		Base:AddHelp("#acf.menu.settings.debris.lifetime_desc")

		local Multiplier = Base:AddSlider("#acf.menu.settings.debris.gib_mult", 0.01, 1, 2)
		Multiplier:SetConVar("acf_debris_gibmultiplier")

		Base:AddHelp("#acf.menu.settings.debris.gib_mult_desc")

		local GibLifetime = Base:AddSlider("#acf.menu.settings.debris.gib_lifetime", 1, 300)
		GibLifetime:SetConVar("acf_debris_giblifetime")

		Base:AddHelp("#acf.menu.settings.debris.gib_lifetime_desc")
	end)

	ACF.AddClientSettings(401, "#acf.menu.settings.tool_category", function(Base)
		local Category = Base:AddCheckBox("#acf.menu.settings.tool_category.option")
		Category:SetConVar("acf_tool_category")

		Base:AddHelp("#acf.menu.settings.tool_category.option_desc")
	end)
end

do -- Serverside settings
	ACF.AddMenuItem(101, "#acf.menu.settings", "#acf.menu.settings.server", "server", ACF.GenerateServerSettings)

	ACF.AddServerSettings(1, "#acf.menu.settings.general", function(Base)
		local Admins = Base:AddCheckBox("#acf.menu.settings.general.allow_admin")
		Admins:SetServerData("ServerDataAllowAdmin", "OnChange")
		Admins:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("#acf.menu.settings.general.allow_admin_desc")

		local Info = Base:AddCheckBox("#acf.menu.settings.general.restrict_info")
		Info:SetServerData("RestrictInfo", "OnChange")
		Info:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("#acf.menu.settings.general.restrict_info_desc")

		local LegalChecks = Base:AddCheckBox("#acf.menu.settings.general.legal_checks")
		LegalChecks:SetServerData("LegalChecks", "OnChange")
		LegalChecks:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local VehicleLegalChecks = Base:AddCheckBox("#acf.menu.settings.general.legal_checks_vehicle")
		VehicleLegalChecks:SetServerData("VehicleLegalChecks", "OnChange")
		VehicleLegalChecks:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local LegalCheckNameAndShame = Base:AddCheckBox("#acf.menu.settings.general.name_and_shame")
		LegalCheckNameAndShame:SetServerData("NameAndShame", "OnChange")
		LegalCheckNameAndShame:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local GunFire = Base:AddCheckBox("#acf.menu.settings.general.gun_fire")
		GunFire:SetServerData("GunsCanFire", "OnChange")
		GunFire:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local GunSmoke = Base:AddCheckBox("#acf.menu.settings.general.gun_smoke")
		GunSmoke:SetServerData("GunsCanSmoke", "OnChange")
		GunSmoke:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local RackFire = Base:AddCheckBox("#acf.menu.settings.general.rack_fire")
		RackFire:SetServerData("RacksCanFire", "OnChange")
		RackFire:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local RequireFuel = Base:AddCheckBox("#acf.menu.settings.general.require_fuel")
		RequireFuel:SetServerData("RequireFuel", "OnChange")
		RequireFuel:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local MaxThickness = Base:AddSlider("#acf.menu.settings.general.max_thickness", ACF.MinimumArmor, ACF.MaximumArmor)
		MaxThickness:SetServerData("MaxThickness", "OnValueChanged")
		MaxThickness:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local Health = Base:AddSlider("#acf.menu.settings.general.health_factor", 0.01, 2, 2)
		Health:SetServerData("HealthFactor", "OnValueChanged")
		Health:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local Fuel = Base:AddSlider("#acf.menu.settings.general.fuel_factor", 0.01, 2, 2)
		Fuel:SetServerData("FuelFactor", "OnValueChanged")
		Fuel:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)
	end)

	ACF.AddServerSettings(101, "#acf.menu.settings.entity_pushing", function(Base)
		local HEPush = Base:AddCheckBox("#acf.menu.settings.entity_pushing.he_push")
		HEPush:SetServerData("HEPush", "OnChange")
		HEPush:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local KEPush = Base:AddCheckBox("#acf.menu.settings.entity_pushing.ke_push")
		KEPush:SetServerData("KEPush", "OnChange")
		KEPush:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local Recoil = Base:AddCheckBox("#acf.menu.settings.entity_pushing.recoil_push")
		Recoil:SetServerData("RecoilPush", "OnChange")
		Recoil:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)
	end)

	ACF.AddServerSettings(201, "#acf.menu.settings.fun_menu", function(Base)
		local Entities = Base:AddCheckBox("#acf.menu.settings.fun_menu.allow_fun")
		Entities:SetServerData("AllowFunEnts", "OnChange")
		Entities:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("#acf.menu.settings.fun_menu.allow_fun_desc")

		local Menu = Base:AddCheckBox("#acf.menu.settings.fun_menu.show_fun")
		Menu:SetServerData("ShowFunMenu", "OnChange")
		Menu:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("#acf.menu.settings.fun_menu.show_fun_desc")

		local AllowProcArmor = Base:AddCheckBox("#acf.menu.settings.fun_menu.allow_proc_armor")
		AllowProcArmor:SetServerData("AllowProcArmor", "OnChange")
		AllowProcArmor:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)
	end)

	ACF.AddServerSettings(301, "#acf.menu.settings.workshop", function(Base)
		local Content = Base:AddCheckBox("#acf.menu.settings.workshop.enable")
		Content:SetServerData("WorkshopContent", "OnChange")
		Content:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local Extra = Base:AddCheckBox("#acf.menu.settings.workshop.enable_extra")
		Extra:SetServerData("WorkshopExtras", "OnChange")
		Extra:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("#acf.menu.settings.workshop.enable_desc")
	end)

	ACF.AddServerSettings(501, "#acf.menu.settings.debris", function(Base)
		local Debris = Base:AddCheckBox("#acf.menu.settings.debris.network")
		Debris:SetServerData("CreateDebris", "OnChange")
		Debris:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		local Fireballs = Base:AddCheckBox("#acf.menu.settings.debris.fireball")
		Fireballs:SetServerData("CreateFireballs", "OnChange")
		Fireballs:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("#acf.menu.settings.debris.fireball_desc")

		local Multiplier = Base:AddSlider("#acf.menu.settings.debris.fireball_mult", 0.01, 1, 2)
		Multiplier:SetServerData("FireballMult", "OnValueChanged")
		Multiplier:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)

		Base:AddHelp("#acf.menu.settings.debris.fireball_mult_desc")
	end)
end