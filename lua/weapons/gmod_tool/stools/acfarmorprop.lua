
local cat = (ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction"

TOOL.Category	= cat
TOOL.Name		= "#tool.acfarmorprop.name"
TOOL.Command	= nil
TOOL.ConfigName	= ""

TOOL.ClientConVar["thickness"] = 1
TOOL.ClientConVar["ductility"] = 0

-- Calculates mass, armor, and health given prop area and desired ductility and thickness.
local function CalcArmor(Area, Ductility, Thickness)
	local mass = Area * (1 + Ductility) ^ 0.5 * Thickness * 0.00078
	local armor = ACF_CalcArmor(Area, Ductility, mass)
	local health = (Area / ACF.Threshold) * (1 + Ductility)

	return mass, armor, health
end

-- Apply settings to prop and store dupe info
local function ApplySettings(_, Entity, Data)
	if CLIENT then return end
	if not Data then return end
	if not ACF.Check(Entity) then return end

	if Data.Mass then
		local PhysObj = Entity.ACF.PhysObj -- If it passed ACF.Check, then the PhysObj will always be valid
		local Mass = math.Clamp(Data.Mass, 0.1, 50000)

		PhysObj:SetMass(Mass)

		duplicator.StoreEntityModifier(Entity, "mass", { Mass = Mass })
	end

	if Data.Ductility then
		local Ductility = math.Clamp(Data.Ductility, -80, 80)

		Entity.ACF.Ductility = Ductility * 0.01

		duplicator.StoreEntityModifier(Entity, "acfsettings", { Ductility = Ductility })
	end

	ACF.Check(Entity, true) -- Forcing the entity to update its information
end

if CLIENT then
	language.Add("tool.acfarmorprop.name", "ACF Armor Properties")
	language.Add("tool.acfarmorprop.desc", "Sets the weight of a prop by desired armor thickness and ductility.")
	language.Add("tool.acfarmorprop.0", "Left click to apply settings. Right click to copy settings. Reload to get the total mass of an object and all constrained objects.")

	surface.CreateFont("Torchfont", { size = 40, weight = 1000, font = "arial" })

	local ArmorProp_Area = CreateClientConVar("acfarmorprop_area", 0, false, true) -- we don't want this one to save
	local ArmorProp_Ductility = CreateClientConVar("acfarmorprop_ductility", 0, false, true)
	local ArmorProp_Thickness = CreateClientConVar("acfarmorprop_thickness", 1, false, true)

	local Sphere = CreateClientConVar("acfarmorprop_sphere_search", 0, false, true, "", 0, 1)
	local Radius = CreateClientConVar("acfarmorprop_sphere_radius", 0, false, true, "", 0, 10000)

	function TOOL.BuildCPanel(Panel)
		local Presets = vgui.Create("ControlPresets")
			Presets:AddConVar("acfarmorprop_thickness")
			Presets:AddConVar("acfarmorprop_ductility")
			Presets:SetPreset("acfarmorprop")
		Panel:AddItem(Presets)

		Panel:NumSlider("Thickness", "acfarmorprop_thickness", 1, 5000)
		Panel:ControlHelp("Set the desired armor thickness (in mm) and the mass will be adjusted accordingly.")

		Panel:NumSlider("Ductility", "acfarmorprop_ductility", -80, 80)
		Panel:ControlHelp("Set the desired armor ductility (thickness-vs-health bias). A ductile prop can survive more damage but is penetrated more easily (slider > 0). A non-ductile prop is brittle - hardened against penetration, but more easily shattered by bullets and explosions (slider < 0).")

		local SphereCheck = Panel:CheckBox("Use sphere search for armor readout", "acfarmorprop_sphere_search")
		Panel:ControlHelp("If checked, the tool will find all the props in a sphere around the hit position instead of getting all the entities connected to a prop.")

		local SphereRadius = Panel:NumSlider("Sphere search radius", "acfarmorprop_sphere_radius", 0, 2000, 0)
		Panel:ControlHelp("Defines the radius of the search sphere, only applies if the checkbox above is checked.")

		function SphereCheck:OnChange(Bool)
			SphereRadius:SetEnabled(Bool)
		end

		SphereRadius:SetEnabled(SphereCheck:GetChecked())
	end

	local BubbleText = "Current:\nMass: %s kg\nArmor: %s mm\nHealth: %s hp\n\nAfter:\nMass: %s kg\nArmor: %s mm\nHealth: %s hp"

	function TOOL:DrawHUD()
		local Trace = self:GetOwner():GetEyeTrace()
		local Ent = Trace.Entity

		if not IsValid(Ent) then return false end
		if Ent:IsPlayer() or Ent:IsNPC() then return false end

		local Weapon = self.Weapon
		local Mass = math.Round(Weapon:GetNWFloat("WeightMass"), 2)
		local Armor = math.Round(Weapon:GetNWFloat("MaxArmour"), 2)
		local Health = math.Round(Weapon:GetNWFloat("MaxHP"), 2)

		local Area = ArmorProp_Area:GetFloat()
		local Ductility = ArmorProp_Ductility:GetFloat()
		local Thickness = ArmorProp_Thickness:GetFloat()

		local NewMass, NewArmor, NewHealth = CalcArmor(Area, Ductility / 100, Thickness)
		NewMass = math.Round(math.min(NewMass, 50000), 2)

		local Text = BubbleText:format(Mass, Armor, Health, NewMass, math.Round(NewArmor, 2), math.Round(NewHealth, 2))

		AddWorldTip(nil, Text, nil, Ent:GetPos())
	end

	local DisplayMat = Material("models/props_combine/combine_interface_disp")
	local TextGray = Color(224, 224, 255)
	local BGGray = Color(200, 200, 200)
	local Blue = Color(0, 0, 200)
	local Red = Color(200, 0, 0)

	function TOOL:DrawToolScreen()
		local Weapon = self.Weapon
		local Health = math.Round(Weapon:GetNWFloat("HP", 0), 2)
		local MaxHealth = math.Round(Weapon:GetNWFloat("MaxHP", 0), 2)
		local Armour = math.Round(Weapon:GetNWFloat("Armour", 0), 2)
		local MaxArmour = math.Round(Weapon:GetNWFloat("MaxArmour", 0), 2)

		local HealthTxt = Health .. "/" .. MaxHealth
		local ArmourTxt = Armour .. "/" .. MaxArmour

		cam.Start2D()
			render.Clear(0, 0, 0, 0)

			surface.SetMaterial(DisplayMat)
			surface.SetDrawColor(color_white)
			surface.DrawTexturedRect(0, 0, 256, 256)
			surface.SetFont("Torchfont")

			-- header
			draw.SimpleTextOutlined("ACF Stats", "Torchfont", 128, 30, TextGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)

			-- armor bar
			draw.RoundedBox(6, 10, 83, 236, 64, BGGray)
			if Armour ~= 0 and MaxArmour ~= 0 then
				draw.RoundedBox(6, 15, 88, Armour / MaxArmour * 226, 54, Blue)
			end

			draw.SimpleTextOutlined("Armour", "Torchfont", 128, 100, TextGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)
			draw.SimpleTextOutlined(ArmourTxt, "Torchfont", 128, 130, TextGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)

			-- health bar
			draw.RoundedBox(6, 10, 183, 236, 64, BGGray)
			if Health ~= 0 and MaxHealth ~= 0 then
				draw.RoundedBox(6, 15, 188, Health / MaxHealth * 226, 54, Red)
			end

			draw.SimpleTextOutlined("Health", "Torchfont", 128, 200, TextGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)
			draw.SimpleTextOutlined(HealthTxt, "Torchfont", 128, 230, TextGray, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, color_black)
		cam.End2D()
	end

	-- clamp thickness if the change in ductility puts mass out of range
	cvars.AddChangeCallback("acfarmorprop_ductility", function(_, _, value)

		local area = ArmorProp_Area:GetFloat()

		-- don't bother recalculating if we don't have a valid ent
		if area == 0 then return end

		local ductility = math.Clamp((tonumber(value) or 0) / 100, -0.8, 0.8)
		local thickness = math.Clamp(ArmorProp_Thickness:GetFloat(), 0.1, 5000)
		local mass = CalcArmor(area, ductility, thickness)

		if mass > 50000 or mass < 0.1 then
			mass = math.Clamp(mass, 0.1, 50000)

			thickness = ACF_CalcArmor(area, ductility, mass)
			ArmorProp_Thickness:SetFloat(math.Clamp(thickness, 0.1, 5000))
		end
	end)

	-- clamp ductility if the change in thickness puts mass out of range
	cvars.AddChangeCallback("acfarmorprop_thickness", function(_, _, value)

		local area = ArmorProp_Area:GetFloat()

		-- don't bother recalculating if we don't have a valid ent
		if area == 0 then return end

		local thickness = math.Clamp(tonumber(value) or 0, 0.1, 5000)
		local ductility = math.Clamp(ArmorProp_Ductility:GetFloat() / 100, -0.8, 0.8)
		local mass = CalcArmor(area, ductility, thickness)

		if mass > 50000 or mass < 0.1 then
			mass = math.Clamp(mass, 0.1, 50000)

			ductility = -(39 * area * thickness - mass * 50000) / (39 * area * thickness)
			ArmorProp_Ductility:SetFloat(math.Clamp(ductility * 100, -80, 80))
		end
	end)

	local GreenSphere = Color(0, 200, 0, 50)
	local GreenFrame = Color(0, 200, 0, 100)

	hook.Add("PostDrawOpaqueRenderables", "Armor Tool Search Sphere", function()
		local Player = LocalPlayer()
		local Tool = Player:GetTool()

		if not Tool then return end -- Player has no toolgun
		if Tool ~= Player:GetTool("acfarmorprop") then return end -- Current tool is not the armor tool
		if Tool.Weapon ~= Player:GetActiveWeapon() then return end -- Player is not holding the toolgun
		if not Sphere:GetBool() then return end

		local Value = Radius:GetFloat()

		if Value <= 0 then return end

		local Pos = Player:GetEyeTrace().HitPos

		render.SetColorMaterial()
		render.DrawSphere(Pos, Value, 20, 20, GreenSphere)
		render.DrawWireframeSphere(Pos, Value, 20, 20, GreenFrame, true)
	end)
else -- Serverside-only stuff
	local function UpdateMass(Entity)
		local PhysObj = Entity:GetPhysicsObject()

		if not IsValid(PhysObj) then return end

		local Ductility = Entity.ACF.Ductility

		ApplySettings(_, Entity, {
			Ductility = Ductility * 100,
		})
	end

	function TOOL:Think()
		local Player = self:GetOwner()
		local Ent = Player:GetEyeTrace().Entity

		if Ent == self.AimEntity then return end

		local Weapon = self.Weapon

		if ACF.Check(Ent) then
			Player:ConCommand("acfarmorprop_area " .. Ent.ACF.Area)
			Player:ConCommand("acfarmorprop_thickness " .. self:GetClientNumber("thickness")) -- Force sliders to update themselves

			Weapon:SetNWFloat("WeightMass", Ent:GetPhysicsObject():GetMass())
			Weapon:SetNWFloat("HP", Ent.ACF.Health)
			Weapon:SetNWFloat("Armour", Ent.ACF.Armour)
			Weapon:SetNWFloat("MaxHP", Ent.ACF.MaxHealth)
			Weapon:SetNWFloat("MaxArmour", Ent.ACF.MaxArmour)
		else
			Player:ConCommand("acfarmorprop_area 0")

			Weapon:SetNWFloat("WeightMass", 0)
			Weapon:SetNWFloat("HP", 0)
			Weapon:SetNWFloat("Armour", 0)
			Weapon:SetNWFloat("MaxHP", 0)
			Weapon:SetNWFloat("MaxArmour", 0)
		end

		self.AimEntity = Ent
	end

	-- Proper Clipping tool compatibility
	-- Whenever a physical clip is created, we'll attempt to keep the same armor on the entity
	hook.Add("ProperClippingPhysicsClipped", "ACF Physclip Armor", UpdateMass)
	hook.Add("ProperClippingPhysicsReset", "ACF Physclip Armor", UpdateMass)
	hook.Add("ProperClippingCanPhysicsClip", "ACF PhysClip Armor", function(Entity)
		ACF.Check(Entity, true) -- Just creating the ACF table on the entity
	end)

	duplicator.RegisterEntityModifier("acfsettings", ApplySettings)
	duplicator.RegisterEntityModifier("mass", ApplySettings)
end

do -- Allowing everyone to read contraptions
	local HookCall = hook.Call

	function hook.Call(Name, Gamemode, Player, Entity, Tool, ...)
		if Name == "CanTool" and Tool == "acfarmorprop" and Player:KeyPressed(IN_RELOAD) then
			return true
		end

		return HookCall(Name, Gamemode, Player, Entity, Tool, ...)
	end
end

-- Apply settings to prop
function TOOL:LeftClick(Trace)
	local Ent = Trace.Entity

	if not IsValid(Ent) then return false end
	if Ent:IsPlayer() or Ent:IsNPC() then return false end
	if CLIENT then return true end
	if not ACF.Check(Ent) then return false end

	local Player = self:GetOwner()

	local ductility = math.Clamp(self:GetClientNumber("ductility"), -80, 80)
	local thickness = math.Clamp(self:GetClientNumber("thickness"), 0.1, 5000)
	local mass = CalcArmor(Ent.ACF.Area, ductility / 100, thickness)

	ApplySettings(Player, Ent, { Mass = mass, Ductility = ductility })

	-- this invalidates the entity and forces a refresh of networked armor values
	self.AimEntity = nil

	return true
end

-- Suck settings from prop
function TOOL:RightClick(Trace)
	local Ent = Trace.Entity

	if not IsValid(Ent) then return false end
	if Ent:IsPlayer() or Ent:IsNPC() then return false end
	if CLIENT then return true end
	if not ACF.Check(Ent) then return false end

	local Player = self:GetOwner()

	Player:ConCommand("acfarmorprop_thickness " .. Ent.ACF.MaxArmour)
	Player:ConCommand("acfarmorprop_ductility " .. Ent.ACF.Ductility * 100)

	return true
end

do -- Armor readout
	local SendMessage = ACF.SendMessage

	local Text1 = "--- Contraption Readout (Owner: %s) ---"
	local Text2 = "Mass: %s kg total | %s kg physical (%s%%) | %s kg parented"
	local Text3 = "Mobility: %s hp/ton @ %s hp | %s liters of fuel"
	local Text4 = "Entities: %s (%s physical, %s parented, %s other entities) | %s constraints"

	-- Emulates the stuff done by ACF_CalcMassRatio except with a given set of entities
	local function ProcessList(Entities)
		local Constraints = {}

		local Owners = {}
		local Lookup = {}
		local Count  = 0

		local Power     = 0
		local Fuel      = 0
		local PhysNum   = 0
		local ParNum    = 0
		local ConNum    = 0
		local OtherNum  = 0
		local Total     = 0
		local PhysTotal = 0

		for _, Ent in ipairs(Entities) do
			if not ACF.Check(Ent) then
				if not Ent:IsWeapon() then -- We don't want to count weapon entities
					OtherNum = OtherNum + 1
				end
			elseif not (Ent:IsPlayer() or Ent:IsNPC()) then -- These will pass the ACF check, but we don't want them either
				local Owner = Ent:CPPIGetOwner()
				local PhysObj = Ent.ACF.PhysObj
				local Class = Ent:GetClass()
				local Mass = PhysObj:GetMass()
				local IsPhys = false

				if (IsValid(Owner) or Owner:IsWorld()) and not Lookup[Owner] then
					local Name = Owner:GetName()

					Count = Count + 1

					Owners[Count] = Name ~= "" and Name or "World"
					Lookup[Owner] = true
				end

				if Class == "acf_engine" then
					Power = Power + Ent.peakkw * 1.34
				elseif Class == "acf_fueltank" then
					Fuel = Fuel + Ent.Capacity
				end

				-- If it has any valid constraint then it's a physical entity
				if Ent.Constraints and next(Ent.Constraints) then
					for _, Con in pairs(Ent.Constraints) do
						if IsValid(Con) and Con.Type ~= "NoCollide" then -- Nocollides don't count
							IsPhys = true

							if not Constraints[Con] then
								Constraints[Con] = true
								ConNum = ConNum + 1
							end
						end
					end
				end

				-- If it has no valid constraints but also no valid parent, then it's a physical entity
				if not (IsPhys or IsValid(Ent:GetParent())) then
					IsPhys = true
				end

				if IsPhys then
					PhysTotal = PhysTotal + Mass
					PhysNum = PhysNum + 1
				else
					ParNum = ParNum + 1
				end

				Total = Total + Mass
			end
		end

		local Name = next(Owners) and table.concat(Owners, ", ") or "None"

		return Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum, Total, PhysTotal
	end

	local Modes = {
		Default = {
			CanCheck = function(_, Trace)
				local Ent = Trace.Entity

				if not IsValid(Ent) then return false end
				if Ent:IsPlayer() or Ent:IsNPC() then return false end

				return true
			end,
			GetResult = function(_, Trace)
				local Ent = Trace.Entity
				local Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum = ACF_CalcMassRatio(Ent, true)

				return Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum, Ent.acftotal, Ent.acfphystotal
			end
		},
		Sphere = {
			CanCheck = function(Tool)
				return Tool:GetClientNumber("sphere_radius") > 0
			end,
			GetResult = function(Tool, Trace)
				local Ents = ents.FindInSphere(Trace.HitPos, Tool:GetClientNumber("sphere_radius"))

				return ProcessList(Ents)
			end
		}
	}

	local function GetReadoutMode(Tool)
		if tobool(Tool:GetClientInfo("sphere_search")) then return Modes.Sphere end

		return Modes.Default
	end

	-- Total up mass of constrained ents
	function TOOL:Reload(Trace)
		local Mode = GetReadoutMode(self)

		if not Mode.CanCheck(self, Trace) then return false end
		if CLIENT then return true end

		local Power, Fuel, PhysNum, ParNum, ConNum, Name, OtherNum, Total, PhysTotal = Mode.GetResult(self, Trace)
		local HorsePower = math.Round(Power / math.max(Total * 0.001, 0.001), 1)
		local PhysRatio = math.Round(100 * PhysTotal / math.max(Total, 0.001))
		local ParentTotal = Total - PhysTotal
		local Player = self:GetOwner()

		SendMessage(Player, nil, Text1:format(Name))
		SendMessage(Player, nil, Text2:format(math.Round(Total, 1), math.Round(PhysTotal, 1), PhysRatio, math.Round(ParentTotal, 1)))
		SendMessage(Player, nil, Text3:format(HorsePower, math.Round(Power), math.Round(Fuel)))
		SendMessage(Player, nil, Text4:format(PhysNum + ParNum + OtherNum, PhysNum, ParNum, OtherNum, ConNum))

		return true
	end
end
