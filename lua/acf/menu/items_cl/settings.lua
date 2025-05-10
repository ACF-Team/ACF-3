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

		local AdvShafts = Base:AddCheckBox("#acf.menu.settings.effects_visual_elements.adv_shafts")
		AdvShafts:SetConVar("acf_advancedmobilityropelinks")

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

		local AutoLod = Base:AddCheckBox("#acf.menu.settings.debris.autolod")
		AutoLod:SetConVar("acf_debris_autolod")

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

		-- What? Why is this different??
		Admins:SetServerData("ServerDataAllowAdmin", "OnChange")
		Admins:DefineSetter(function(Panel, _, _, Value)
			Panel:SetValue(Value)

			return Value
		end)
			Base:AddHelp("#acf.menu.settings.general.allow_admin_desc")

		Base:AddCheckBox("#acf.menu.settings.general.restrict_info"):        LinkToServerData("RestrictInfo")
			Base:AddHelp("#acf.menu.settings.general.restrict_info_desc")

		Base:AddCheckBox("#acf.menu.settings.general.gun_fire"):             LinkToServerData("GunsCanFire")
		Base:AddCheckBox("#acf.menu.settings.general.gun_smoke"):            LinkToServerData("GunsCanSmoke")
		Base:AddCheckBox("#acf.menu.settings.general.rack_fire"):            LinkToServerData("RacksCanFire")
		Base:AddCheckBox("#acf.menu.settings.general.require_fuel"):         LinkToServerData("RequireFuel")
		Base:AddSlider("#acf.menu.settings.general.max_thickness"):          LinkToServerData("MaxThickness")
		Base:AddSlider("#acf.menu.settings.general.health_factor"):          LinkToServerData("HealthFactor")
		Base:AddSlider("#acf.menu.settings.general.fuel_factor"):            LinkToServerData("FuelFactor")

		Base:AddSlider("#acf.menu.settings.general.min_crew_efficiency"):    LinkToServerData("CrewFallbackCoef")
			Base:AddHelp("#acf.menu.settings.general.min_crew_efficiency_desc")

		Base:AddSlider("#acf.menu.settings.general.smoke_wind"):             LinkToServerData("SmokeWind")
			Base:AddHelp("#acf.menu.settings.general.smoke_wind_desc")
	end)

	ACF.AddServerSettings(101, "#acf.menu.settings.entity_pushing", function(Base)
		Base:AddCheckBox("#acf.menu.settings.entity_pushing.he_push"):       LinkToServerData("HEPush")
		Base:AddCheckBox("#acf.menu.settings.entity_pushing.ke_push"):       LinkToServerData("KEPush")
		Base:AddCheckBox("#acf.menu.settings.entity_pushing.recoil_push"):   LinkToServerData("RecoilPush")
	end)

	ACF.AddServerSettings(201, "#acf.menu.settings.legal_checks", function(Base)
		Base:AddCheckBox("#acf.menu.settings.general.legal_checks"):         LinkToServerData("LegalChecks")
		Base:AddCheckBox("#acf.menu.settings.general.legal_checks_vehicle"): LinkToServerData("VehicleLegalChecks")
		Base:AddCheckBox("#acf.menu.settings.general.name_and_shame"):       LinkToServerData("NameAndShame")

		Base:AddCheckBox("#acf.menu.settings.fun_menu.arbitrary_parents"):LinkToServerData("AllowArbitraryParents")
			Base:AddHelp("#acf.menu.settings.fun_menu.arbitrary_parents_desc")
	end)

	ACF.AddServerSettings(301, "#acf.menu.settings.fun_menu", function(Base)
		Base:AddCheckBox("#acf.menu.settings.fun_menu.allow_fun"):LinkToServerData("AllowFunEnts")
			Base:AddHelp("#acf.menu.settings.fun_menu.allow_fun_desc")

		Base:AddCheckBox("#acf.menu.settings.fun_menu.allow_sengines"):LinkToServerData("AllowSpecialEngines")
			Base:AddHelp("#acf.menu.settings.fun_menu.allow_sengines_desc")

		Base:AddCheckBox("#acf.menu.settings.fun_menu.show_fun"):LinkToServerData("ShowFunMenu")
			Base:AddHelp("#acf.menu.settings.fun_menu.show_fun_desc")

		Base:AddCheckBox("#acf.menu.settings.fun_menu.allow_proc_armor"):LinkToServerData("AllowProcArmor")
	end)

	ACF.AddServerSettings(401, "#acf.menu.settings.workshop", function(Base)
		Base:AddCheckBox("#acf.menu.settings.workshop.enable"):        LinkToServerData("WorkshopContent")

		Base:AddCheckBox("#acf.menu.settings.workshop.enable_extra"):  LinkToServerData("WorkshopExtras")
			Base:AddHelp("#acf.menu.settings.workshop.enable_desc")
	end)

	ACF.AddServerSettings(501, "#acf.menu.settings.debris", function(Base)
		Base:AddCheckBox("#acf.menu.settings.debris.network"):         LinkToServerData("CreateDebris")

		Base:AddCheckBox("#acf.menu.settings.debris.fireball"):        LinkToServerData("CreateFireballs")
			Base:AddHelp("#acf.menu.settings.debris.fireball_desc")

		Base:AddSlider("#acf.menu.settings.debris.fireball_mult"):     LinkToServerData("FireballMult")
			Base:AddHelp("#acf.menu.settings.debris.fireball_mult_desc")
	end)
end