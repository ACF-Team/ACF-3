--[[
Notes:
- We treat baseplates as the first plate and the rest as steer plates.
- Since we have a mapping from plates to wheels, we also know which wheels belong to the baseplate, or any of the given steer plates.
--]]

local ACF = ACF
local IsValid = IsValid

TOOL.Category	 = (ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction"
TOOL.Name		 = "ACF Suspension Tool"
TOOL.Command	 = nil
TOOL.ConfigName	 = ""
TOOL.Information = {
	-- Note: desc is not a valid property, I just use it to generate language descriptions. (See language.Add)
	{name = "right1shift", stage = 0, desc = "[SHIFT] Select a base/steer plate", icon2 = "gui/key.png"},
	{name = "right1ctrl", stage = 0, desc = "[Ctrl] Select the hydraulic controller plate", icon2 = "gui/key.png"},
	{name = "right1", stage = 0, desc = "Select a wheel"},
	{name = "reload", desc = "Reset the tool", icon2 = "gui/refresh.png"}
}

TOOL.Selections = {}				-- Holds the selections
TOOL.Selections.ControlPlates = {}	-- Holds the control plate
TOOL.Selections.Plates = {}			-- Holds the plates
TOOL.Selections.Wheels = {}			-- Holds the wheels
TOOL.Selections.PlatesToWheels = {}	-- Holds the wheels for each plate

-- MakeWireHydraulicController
-- MakeWireHydraulic
local EmptyTable = {}
if CLIENT then
	-- Add descriptions to tool info
	language.Add("tool.acfsuspension.name", "ACF Suspension Tool")
	language.Add("tool.acfsuspension.desc", "Aids in setting up basic suspensions.")

	for _, v in pairs(TOOL.Information) do
		language.Add("tool.acfsuspension." .. v.name, v.desc)
	end

	CreateClientConVar("acf_sus_tool_usesdrivewheel", 1, false, true)
	CreateClientConVar("acf_sus_tool_makespherical", 1, false, true)
	CreateClientConVar("acf_sus_tool_disablecollisions", 1, false, true)

	CreateClientConVar("acf_sus_tool_limiterlength", 0, false, true)

	CreateClientConVar("acf_sus_tool_springx", 0, false, true)
	CreateClientConVar("acf_sus_tool_springy", 0, false, true)
	CreateClientConVar("acf_sus_tool_springz", 40, false, true)

	CreateClientConVar("acf_sus_tool_armx", 40, false, true)
	CreateClientConVar("acf_sus_tool_army", 40, false, true)
	CreateClientConVar("acf_sus_tool_armz", 0, false, true)

	CreateClientConVar("acf_sus_tool_springtype", 1, false, true)
	CreateClientConVar("acf_sus_tool_armtype", 1, false, true)

	CreateClientConVar("acf_sus_tool_elasticity", 10000, false, true)
	CreateClientConVar("acf_sus_tool_damping", 500, false, true)
	CreateClientConVar("acf_sus_tool_relativedamping", 0.1, false, true)
	CreateClientConVar("acf_sus_tool_inoutspeedmul", 4, false, true)

	CreateClientConVar("acf_sus_tool_showwheelinfo", 1, false, true)
	CreateClientConVar("acf_sus_tool_showarminfo", 1, false, true)
	CreateClientConVar("acf_sus_tool_showspringinfo", 1, false, true)

	CreateClientConVar("acf_sus_tool_suspenddrivewheels", 0, false, true)
	CreateClientConVar("acf_sus_tool_suspendidlerwheels", 0, false, true)

	local orange = Color(255, 93, 0)
	local blue = Color(0, 0, 255)
	local purple = Color(255, 0, 255)
	local cyan = Color(0, 255, 255)
	local yellow = Color(255, 255, 0)
	local red = Color(255, 0, 0)
	local green = Color(0, 255, 0)
	local black = Color(0, 0, 0)

	--- Creates/recreates the menu for this tool
	local function CreateMenu(Panel)
		local Menu = ACF.ArmorMenu

		-- Handles recreating the menu, useful if you change elements.
		if not IsValid(Menu) then
			Menu = vgui.Create("ACF_Panel")
			Menu.Panel = Panel

			Panel:AddItem(Menu)

			ACF.ArmorMenu = Menu
		else
			Menu:ClearAllTemporal()
			Menu:ClearAll()
		end

		local Reload = Menu:AddButton("Reload Menu")
		Reload:SetTooltip("You can also type 'acf_reload_suspension_menu' in console.")
		function Reload:DoClickInternal()
			RunConsoleCommand("acf_reload_suspension_menu")
		end

		Menu:AddTitle("ACF Suspension Tool")
		Menu:AddLabel("This tool helps create constraints for basic drivetrains.")
		Menu:AddLabel("You can hover over any of these elements to see their description.")
		local WIP = Menu:AddLabel("This tool is mostly stable, but may need further testing.")
		WIP:SetTextColor(yellow)

		local GeneralSettings = Menu:AddCollapsible("General Settings", true)

		local UsesDriveWheel = GeneralSettings:AddCheckBox("Drive wheels used", "acf_sus_tool_usesdrivewheel")
		UsesDriveWheel:SetTooltip("If checked, wheels will be slaved to the drive wheels. (Partially) Tracked vehicles should use this.")

		local MakeSpherical = GeneralSettings:AddCheckBox("Make Spherical", "acf_sus_tool_makespherical")
		MakeSpherical:SetTooltip("If checked, makespherical is applied to the wheels.\nShould have the same affect as the makespherical tool.")

		local DisableCollisions = GeneralSettings:AddCheckBox("Disable Collisions", "acf_sus_tool_disablecollisions")
		DisableCollisions:SetTooltip("If checked, the wheels will not collide with anything else.\nSame thing as doing it via the context menu.")

		-- local SuspendDriveWheels = GeneralSettings:AddCheckBox("Suspend Drive Wheels", "acf_sus_tool_suspenddrivewheels")
		-- SuspendDriveWheels:SetTooltip("If checked, the drive wheels will be suspended as well.")

		-- local SuspendIdlerWheels = GeneralSettings:AddCheckBox("Suspend Idler Wheels", "acf_sus_tool_suspendidlerwheels")
		-- SuspendIdlerWheels:SetTooltip("If checked, the idler wheels will be suspended as well.")

		-- Spring related
		local SpringType = GeneralSettings:AddComboBox()
		SpringType:AddChoice("Spring Type: Axis (None)", 1)
		SpringType:AddChoice("Spring Type: Hydraulic", 2)
		SpringType:AddChoice("Spring Type: Elastic", 3)

		local SpringGeneral = GeneralSettings:AddCollapsible("General Spring Settings", true)

		-- Generate spring specific settings
		function SpringType:OnSelect(_, _, Data)
			GetConVar("acf_sus_tool_springtype"):SetInt(Data)
			SpringGeneral:ClearAll()
			if Data ~= 1 then
				local SpringSpecific = SpringGeneral:AddCollapsible("Specific Spring Settings", true)
				if Data == 2 then
					-- Hydraulic Specific
					local InOutSpeedMul = SpringSpecific:AddSlider("In/Out Speed Multiplier", 4, 120)
					InOutSpeedMul:SetConVar("acf_sus_tool_inoutspeedmul")
					InOutSpeedMul:SetTooltip("How fast it changes the length.")
				elseif Data == 3 then
					-- Elastic Specific
					local Elasticity = SpringSpecific:AddSlider("Elasticity", 0, 400)
					Elasticity:SetConVar("acf_sus_tool_elasticity")
					Elasticity:SetTooltip("Stiffness of the elastic. The larger the number the less the elastic will stretch.")

					local Dampening = SpringSpecific:AddSlider("Damping", 0, 50)
					Dampening:SetConVar("acf_sus_tool_damping")
					Dampening:SetTooltip("How much energy the elastic loses. The larger the number, the less bouncy the elastic.")

					local RelativeDampening = SpringSpecific:AddSlider("Relative Damping", 0, 1)
					RelativeDampening:SetConVar("acf_sus_tool_relativedamping")
					RelativeDampening:SetTooltip("The amount of energy the elastic loses proportional to the relative velocity of the two objects the elastic is attached to.")
				end

				local SpringX = SpringGeneral:AddSlider("Spring X", -100, 100)
				SpringX:SetConVar("acf_sus_tool_springx")

				local SpringY = SpringGeneral:AddSlider("Spring Y", -100, 100)
				SpringY:SetConVar("acf_sus_tool_springy")

				local SpringZ = SpringGeneral:AddSlider("Spring Z", -100, 100)
				SpringZ:SetConVar("acf_sus_tool_springz")

				-- Arm related
				local ArmType = SpringGeneral:AddComboBox()
				ArmType:AddChoice("Arm Type: Fork", 1)
				ArmType:AddChoice("Arm Type: Forward Lever", 2)
				ArmType:AddChoice("Arm Type: Sideways Lever", 3)

				function ArmType:OnSelect(_, _, Data)
					GetConVar("acf_sus_tool_armtype"):SetInt(Data)
				end

				ArmType:ChooseOptionID(GetConVar("acf_sus_tool_armtype"):GetInt())

				local ArmX = SpringGeneral:AddSlider("Arm X", -100, 100)
				ArmX:SetConVar("acf_sus_tool_armx")

				local ArmY = SpringGeneral:AddSlider("Arm Y", -100, 100)
				ArmY:SetConVar("acf_sus_tool_army")

				local ArmZ = SpringGeneral:AddSlider("Arm Z", -100, 100)
				ArmZ:SetConVar("acf_sus_tool_armz")

				local LimiterLength = SpringGeneral:AddSlider("Limiter Length", 0, 100)
				LimiterLength:SetConVar("acf_sus_tool_limiterlength")
				LimiterLength:SetTooltip("Limits the distance the wheel can move from its default position")
			end
		end

		SpringType:ChooseOptionID(GetConVar("acf_sus_tool_springtype"):GetInt())

		local Create = Menu:AddButton("Create Drivetrain")
		Create:SetTextColor(green)
		Create:SetTooltip("Creates a new drivetrain with the selected entitites.")

		function Create:DoClickInternal()
			net.Start("ACF_Sus_Tool")
			net.WriteString("Create")
			net.SendToServer()
		end

		local Clear = Menu:AddButton("Clear Drivetrain")
		Clear:SetTextColor(red)
		Clear:SetTooltip("Clears all constraints on selected entities.")

		function Clear:DoClickInternal()
			net.Start("ACF_Sus_Tool")
			net.WriteString("Clear")
			net.SendToServer()
		end

		local SettingsVisual = Menu:AddCollapsible("Visual Settings", true)
		SettingsVisual:AddCheckBox("Show Wheel Info", "acf_sus_tool_showwheelinfo")
		SettingsVisual:AddCheckBox("Show Arms Info", "acf_sus_tool_showarminfo")
		SettingsVisual:AddCheckBox("Show Springs Info", "acf_sus_tool_showspringinfo")

		local InstructionsGeneral = Menu:AddCollapsible("Instructions", true)
		InstructionsGeneral:AddLabel("Left/Right is relative to the baseplate's forward direction.")
		InstructionsGeneral:AddLabel("Drive wheels are directly connected to gearboxes.\nIdler wheels are not connected to a gearbox and are at the very front.\nRoad wheels are meant to touch the ground.")
		InstructionsGeneral:AddLabel("Skip steps 2 to 5 if you do not use drive wheels (Usually fully wheeled vehichles).")
		InstructionsGeneral:AddLabel("1. Select the baseplate with SHIFT + RMB")
		InstructionsGeneral:AddLabel("2. Select the left drive wheel with RMB")
		InstructionsGeneral:AddLabel("3. Select the right drive wheel with RMB")
		InstructionsGeneral:AddLabel("4. Select the left idler wheel with RMB")
		InstructionsGeneral:AddLabel("5. Select the right idler wheel with RMB")
		InstructionsGeneral:AddLabel("6. For each pair of road wheels, select the left then the right with RMB.")
		InstructionsGeneral:AddLabel("7. (Optional) Selecting a new plate with SHIFT + RMB will select a new steer plate.\nWheels selected afterwards will belong to this new plate.")
		InstructionsGeneral:AddLabel("8. (Optional) When you finish selecting the wheels, select the control plate with CTRL + RMB.")
		InstructionsGeneral:AddLabel("9. (Optional) If applicable, press the cleanup button in the menu to remove old constraints.")
		InstructionsGeneral:AddLabel("10. (Optional) If applicable, press the create button in the menu to create the suspension.")
	end

	TOOL.BuildCPanel = CreateMenu

	concommand.Add("acf_reload_suspension_menu", function()
		if not IsValid(ACF.ArmorMenu) then return end

		CreateMenu(ACF.ArmorMenu.Panel)
	end)

	net.Receive("ACF_Sus_Tool", function()
		local Player = LocalPlayer()
		Player.ACF_Sus_Tool_Info = net.ReadTable()
	end)

	function DrawEntText(Entity, Text, Col)
		local Pos = Entity:GetPos()
		local SP = Pos:ToScreen()
		draw.SimpleTextOutlined(Text, nil, SP.x, SP.y, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, black)
	end

	function DrawEntLink(Entity1, Entity2, Col)
		local Pos1 = Entity1:GetPos()
		local SP1 = Pos1:ToScreen()
		local Pos2 = Entity2:GetPos()
		local SP2 = Pos2:ToScreen()

		surface.SetDrawColor(Col)
		surface.DrawLine(SP1.x, SP1.y, SP2.x, SP2.y)
	end

	function DrawArm(Wheel, Plate, Vec, Col)
		local WheelPos = Wheel:GetPos()
		local SP = WheelPos:ToScreen()
		local WorldPos = Plate:LocalToWorld(Plate:WorldToLocal(Wheel:GetPos()) + Vec)
		local SP2 = WorldPos:ToScreen()

		surface.SetDrawColor(Col)
		surface.DrawLine(SP.x, SP.y, SP2.x, SP2.y)
	end

	--- Draws the hud/tooltips for this tool
	function TOOL:DrawHUD()
		local Player = LocalPlayer()
		Player.ACF_Sus_Tool_Info = Player.ACF_Sus_Tool_Info or {}
		local Selections = Player.ACF_Sus_Tool_Info

		-- TODO: Try getinfonum
		local UsesDriveWheel = tonumber(Player:GetInfo("acf_sus_tool_usesdrivewheel"))
		local SpringType = tonumber(Player:GetInfo("acf_sus_tool_springtype"))
		local ArmType = tonumber(Player:GetInfo("acf_sus_tool_armtype"))
		local ArmX = tonumber(Player:GetInfo("acf_sus_tool_armx"))
		local ArmY = tonumber(Player:GetInfo("acf_sus_tool_army"))
		local ArmZ = tonumber(Player:GetInfo("acf_sus_tool_armz"))
		local SpringX = tonumber(Player:GetInfo("acf_sus_tool_springx"))
		local SpringY = tonumber(Player:GetInfo("acf_sus_tool_springy"))
		local SpringZ = tonumber(Player:GetInfo("acf_sus_tool_springz"))

		local ShowWheelInfo = tonumber(Player:GetInfo("acf_sus_tool_showwheelinfo"))
		local ShowArmInfo = tonumber(Player:GetInfo("acf_sus_tool_showarminfo"))
		local ShowSpringInfo = tonumber(Player:GetInfo("acf_sus_tool_showspringinfo"))

		-- For each plate...
		local Baseplate = Selections.Plates and Selections.Plates[1]
		if not IsValid(Baseplate) then return end
		for PlateIndex, Plate in ipairs(Selections.Plates or EmptyTable) do
			if not IsValid(Plate) then continue end
			if PlateIndex == 1 then DrawEntText(Plate, "Baseplate", purple)
			else DrawEntText(Plate, "Steer plate", cyan) end

			-- For each wheel of the plate...
			for WheelIndex, Wheel in ipairs(Selections.PlatesToWheels[Plate] or EmptyTable) do
				if not IsValid(Wheel) then continue end
				-- Determine wheel name...
				local IsLeft = WheelIndex % 2 == 1
				local Direction = IsLeft and "Left" or "Right"
				local Steer = PlateIndex > 1 and " Steer" or ""
				local Drive = UsesDriveWheel == 1 and PlateIndex == 1 and WheelIndex <= 2 and " Drive" or ""
				local Idler = UsesDriveWheel == 1 and PlateIndex == 1 and WheelIndex > 2 and WheelIndex <= 4 and " Idler" or ""
				local Road = UsesDriveWheel == 1 and PlateIndex == 1 and WheelIndex > 4 and " Road" or ""
				Name = Direction .. Drive .. Idler .. Steer .. Road .. " Wheel"

				if ShowWheelInfo == 1 then
					DrawEntLink(Plate, Wheel, yellow)
					DrawEntText(Wheel, Name, red)
				end

				-- Not axis, so it has a suspension...
				local Mirror = IsLeft and 1 or -1
				local ShouldSus = (UsesDriveWheel == 1 and WheelIndex > 4) or (UsesDriveWheel == 0)
				if ShouldSus and SpringType ~= 1 then
					if ShowSpringInfo == 1 then DrawArm(Wheel, Baseplate, Vector(SpringX, SpringY, SpringZ), blue) end
					if ShowArmInfo == 1 then
						if ArmType == 1 then
							DrawArm(Wheel, Baseplate, Vector(ArmX, ArmY * Mirror, ArmZ), orange)
							DrawArm(Wheel, Baseplate, Vector(ArmX, -ArmY * Mirror, ArmZ), orange)
							DrawArm(Wheel, Baseplate, Vector(-ArmX, 0, ArmZ), orange)
						elseif ArmType == 2 then
							DrawArm(Wheel, Baseplate, Vector(ArmX, ArmY * Mirror, ArmZ), orange)
							DrawArm(Wheel, Baseplate, Vector(ArmX, -ArmY * Mirror, ArmZ), orange)
						elseif ArmType == 3 then
							DrawArm(Wheel, Baseplate, Vector(ArmX, ArmY * Mirror, ArmZ), orange)
							DrawArm(Wheel, Baseplate, Vector(-ArmX, ArmY * Mirror, ArmZ), orange)
						end
					end
				end
			end
		end

		if IsValid(Selections.ControlPlates[1]) then DrawEntText(Selections.ControlPlates[1], "Control plate", green) end
	end

	-- Toolgun beam will show even if nothing happens serverside. I don't wanna fix this :(...
	function TOOL:LeftClick(_) return true end
	function TOOL:RightClick(_) return true end
	function TOOL:Reload(_) return true end
elseif SERVER then -- Serverside-only stuff
	util.AddNetworkString("ACF_Sus_Tool")

	local function checkOwner(ply, ent)
		if CPPI then
			local owner = ent:CPPIGetOwner() or (ent.GetPlayer and ent:GetPlayer())
			if owner then
				return owner == ply
			end
		end
		return true
	end

	--- Attempts to remove the entity from any of the selections. Relies on silent fails to check everywhere.
	function TOOL:RemoveEntity(Entity, Player)
		table.RemoveByValue(self.Selections.Plates, Entity)		-- Remove from plates
		table.RemoveByValue(self.Selections.Wheels, Entity)		-- Remove from wheels
		table.RemoveByValue(self.Selections.ControlPlates, Entity)		-- Remove from wheels
		self.Selections.PlatesToWheels[Entity] = nil			-- Remove the table for the plate

		-- Remove the wheel from any plate
		for _, v in pairs(self.Selections.PlatesToWheels) do
			table.RemoveByValue(v, Entity)
		end

		net.Start("ACF_Sus_Tool")
		net.WriteTable(self.Selections)
		net.Send(Player)
	end

	function TOOL:RightClick(Trace)
		local Player = self:GetOwner()
		local Ent = Trace.Entity
		if not IsValid(Ent) then return end
		if Ent:IsPlayer() then return end
		if not checkOwner(Player, Ent) then return end

		local IsShift = Player:KeyDown(IN_SPEED)
		local IsCtrl = Player:KeyDown(IN_DUCK)
		if IsShift then
			-- Select a (new) plate
			table.insert(self.Selections.Plates, Ent)
			self.Selections.PlatesToWheels[Ent] = {}
			Ent:CallOnRemove("ACF_Sus_Tool", function(Ent) self:RemoveEntity(Ent, Player) end)
		elseif IsCtrl then
			-- Select the control plate
			self.Selections.ControlPlates[1] = Ent
		else
			-- Select a wheel for the plate
			if #self.Selections.Plates == 0 then
				ACF.SendNotify(Player, false, "You need to select a baseplate first.")
				return
			end

			table.insert(self.Selections.Wheels, Ent)
			local CurrentPlate = self.Selections.Plates[#self.Selections.Plates]
			table.insert(self.Selections.PlatesToWheels[CurrentPlate], Ent)
			Ent:CallOnRemove("ACF_Sus_Tool", function(Ent) self:RemoveEntity(Ent, Player) end)
		end

		-- Broadcast the selections to the client
		net.Start("ACF_Sus_Tool")
		net.WriteTable(self.Selections)
		net.Send(Player)
		return true
	end

	function TOOL:Reload(_)
		local Player = self:GetOwner()

		self.Selections = {}
		self.Selections.ControlPlates = {}
		self.Selections.Plates = {}
		self.Selections.Wheels = {}
		self.Selections.PlatesToWheels = {}

		-- Broadcast the selections to the client
		net.Start("ACF_Sus_Tool")
		net.WriteTable(self.Selections)
		net.Send(Player)
		return true
	end

	net.Receive("ACF_Sus_Tool", function(_, ply)
		local Action = net.ReadString()
		local Tool = ply:GetTool("acfsuspension")

		if Action == "Create" then Tool:CreateSuspension()
		elseif Action == "Clear" then Tool:ClearSuspension()
		end
	end)

	-- Tolerances for adv ballsocket constraints
	local MinTol = -0.001
	local MaxTol = 0.001

	--- Creates an axis center constraint between the wheel and the palte
	--- This forces the wheel to rotate in place, in the forward/backward direction
	local function Axis(Wheel, Plate)
		return constraint.Axis(Wheel, Plate, 0, 0, Vector(0, 0, 0), Vector(0, 0, 0), 0, 0, 0, 0, Vector(0, 1, 0), false)
	end

	--- Creates a adv ballsocket constraint between the wheel and the plate
	--- This forces the wheel to rotate freely, in the forward/backward direction
	local function HullSocket(Wheel, Plate)
		return constraint.AdvBallsocket(Wheel, Plate, 0, 0, Vector(0, 0, 0), Vector(0, 0, 0), 0, 0, -180, MinTol, MinTol, 180, MaxTol, MaxTol, 0, 0, 0, 1, 0)
	end

	--- Creates a adv ballsocket constraint between the wheel and its drive wheel
	--- This forces the wheel to rotate freely, with the drive wheel
	local function SlaveSocket(Wheel, DriveWheel)
		return constraint.AdvBallsocket(Wheel, DriveWheel, 0, 0, Vector(0, 0, 0), Vector(0, 0, 0), 0, 0, MinTol, MinTol, MinTol, MaxTol, MaxTol, MaxTol, 0, 0, 0, 1, 0)
	end

	--- Creates a simple ballsocket constraint between the wheel and the plate
	--- This forces the wheel to rotate in place, in any direction
	local function BallSocket(Wheel, Plate)
		return constraint.Ballsocket(Wheel, Plate, 0, 0, Vector(0, 0, 0), 0, 0, 0)
	end

	--- Disables collisions on the wheel with all entities
	local function DisableCollisions(Wheel)
		return Wheel:SetCollisionGroup(COLLISION_GROUP_WORLD)
	end

	--- Applies makespherical to the wheel
	--- Taken from https://github.com/daveth/makespherical/blob/master/lua/weapons/gmod_tool/stools/makespherical.lua so it behaves the same
	local function MakeSpherical(Wheel)
		local ent = Wheel -- Otherwise I would have to find and replace manually
		if not ent.noradius then
			local OBB = ent:OBBMaxs() - ent:OBBMins()
			ent.noradius = math.max( OBB.x, OBB.y, OBB.z) / 2
		end

		ent.obbcenter = ent.obbcenter or ent:OBBCenter()

		local data = {
			obbcenter 		= ent.obbcenter,
			noradius 		= ent.noradius,
			radius 			= ent.noradius,
			mass 			= ent:GetPhysicsObject():GetMass(),
			enabled 		= true,
			isrenderoffset 	= 0,
			renderoffset 	= Vector(0, 0, 0)
		}

		local phys = ent:GetPhysicsObject()
		local ismove = phys:IsMoveable()
		local issleep = phys:IsAsleep()
		local radius = math.Clamp( data.radius, 1, 200 )

		ent:PhysicsInitSphere( radius, phys:GetMaterial() )
		ent:SetCollisionBounds( Vector( -radius, -radius, -radius ) , Vector( radius, radius, radius ) )

		local phys = ent:GetPhysicsObject()
		phys:SetMass( data.mass )
		phys:EnableMotion( ismove )
		if not issleep then phys:Wake() end

		data.radius = radius
		ent.noradius = data.noradius
		duplicator.StoreEntityModifier( ent, "MakeSphericalCollisions", data )
	end

	-- Creates a simple rope
	local function Rope(ent1, ent2, v1, v2, addlength, rigid)
		local length = ( ent1:LocalToWorld( v1 ) - ent2:LocalToWorld( v2 ) ):Length()
		return constraint.Rope( ent1, ent2, 0, 0, v1, v2, length, addlength, 0, 0, "", rigid)
	end

	-- Creates am arm constraining the wheel to the baseplate
	local function Arm(Wheel, Baseplate, Vec)
		return Rope(Wheel, Baseplate, Vector(0, 0, 0), Baseplate:WorldToLocal(Wheel:GetPos()) + Vec, 0, true)
	end

	-- A specific type of suspension arm arrangement
	local function ArmFork(Wheel, Baseplate, X, Y, Z)
		Arm(Wheel, Baseplate, Vector(X, Y, Z))
		Arm(Wheel, Baseplate, Vector(X, -Y, Z))
		Arm(Wheel, Baseplate, Vector(-X, 0, Z))
	end

	-- A specific type of suspension arm arrangement
	local function ArmForwardLever(Wheel, Baseplate, X, Y, Z)
		Arm(Wheel, Baseplate, Vector(X, Y, Z))
		Arm(Wheel, Baseplate, Vector(X, -Y, Z))
	end

	-- A specific type of suspension arm arrangement
	local function ArmSidewaysLever(Wheel, Baseplate, X, Y, Z)
		Arm(Wheel, Baseplate, Vector(X, Y, Z))
		Arm(Wheel, Baseplate, Vector(-X, Y, Z))
	end

	-- Makes a hydraulic constraint between a wheel and a plate and a controller that manages it.
	local function MakeHydraulicAndController(ply, Wheel, Plate, Offset1, Offset2, Speed, CtrlPos, CtrlAng)
		local Const, Rope = MakeWireHydraulic(ply, Wheel, Plate, 0, 0, Offset1, Plate:WorldToLocal(Wheel:GetPos()) + Offset2, 0, "", Speed, false, false) -- pl, Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, width, material, speed, fixed, stretchonly, MyCrtl
		local Controller = MakeWireHydraulicController(ply, CtrlPos, CtrlAng, "models/beer/wiremod/hydraulic.mdl", nil, Const, Rope) -- pl, Pos, Ang, model, MyEntId, const, rope

		-- If the controller is removed, remove the constraint/rope. Vice versa.
		if Controller then
			Controller.Owner = ply
			Controller:CPPISetOwner(ply)

			Controller:DeleteOnRemove(Const)
			Const:DeleteOnRemove( Controller )
			if Rope then
				Controller:DeleteOnRemove( Rope )
				Const:DeleteOnRemove( Controller )
			end
			Controller:GetPhysicsObject():EnableMotion( false )
		end
		return Controller, Const, Rope
	end

	-- Makes an elastic constraint between a wheel and a plate
	local function MakeElastic(Wheel, Plate, Offset1, Offset2, Constant, Damping, RelDamping)
		return constraint.Elastic(Wheel, Plate, 0, 0, Offset1, Plate:WorldToLocal(Wheel:GetPos()) + Offset2, Constant, Damping, RelDamping, "", 0)
	end

	function TOOL:CreateSuspension()
		local Player = self:GetOwner()
		local Selections = self.Selections

		-- Handle makespherical / disable collisions BEFORE making the constraints
		local IsSpherical = tonumber(Player:GetInfo("acf_sus_tool_makespherical"))
		local IsDisableCollisions = tonumber(Player:GetInfo("acf_sus_tool_disablecollisions"))
		for _, Wheel in ipairs(Selections.Wheels or EmptyTable) do
			if not IsValid(Wheel) and checkOwner(Player, Wheel) then continue end

			if IsDisableCollisions == 1 then DisableCollisions(Wheel) end
			if IsSpherical == 1 then MakeSpherical(Wheel) end
		end

		-- Handle making the suspension constraints
		local UsesDriveWheel = tonumber(Player:GetInfo("acf_sus_tool_usesdrivewheel"))
		local SpringType = tonumber(Player:GetInfo("acf_sus_tool_springtype"))
		local ArmType = tonumber(Player:GetInfo("acf_sus_tool_armtype"))
		local ArmX = tonumber(Player:GetInfo("acf_sus_tool_armx"))
		local ArmY = tonumber(Player:GetInfo("acf_sus_tool_army"))
		local ArmZ = tonumber(Player:GetInfo("acf_sus_tool_armz"))

		local SpringX = tonumber(Player:GetInfo("acf_sus_tool_springx"))
		local SpringY = tonumber(Player:GetInfo("acf_sus_tool_springy"))
		local SpringZ = tonumber(Player:GetInfo("acf_sus_tool_springz"))
		local LimiterLength = tonumber(Player:GetInfo("acf_sus_tool_limiterlength"))
		local InOutSpeedMul = tonumber(Player:GetInfo("acf_sus_tool_inoutspeedmul"))
		local Elasticity = tonumber(Player:GetInfo("acf_sus_tool_elasticity"))
		local Damping = tonumber(Player:GetInfo("acf_sus_tool_damping"))
		local RelativeDamping = tonumber(Player:GetInfo("acf_sus_tool_relativedamping"))

		local Baseplate = Selections.Plates[1]
		local LeftDriveWheel = Selections.Wheels[1]
		local RightDriveWheel = Selections.Wheels[2]
		local LeftIdlerWheel = Selections.Wheels[3]
		local RightIdlerWheel = Selections.Wheels[4]
		local ControlPlate = Selections.ControlPlates[1]

		-- Cover edge cases
		if not IsValid(Baseplate) then ACF.SendNotify(Player, false, "Drivetrain could not be created: Baseplate missing.") return end
		if SpringType == 2 and not IsValid(ControlPlate) then ACF.SendNotify(Player, false, "Drivetrain could not be created: Control plate missing.") return end
		if UsesDriveWheel == 1 and not (IsValid(LeftDriveWheel) and IsValid(RightDriveWheel)) then ACF.SendNotify(Player, false, "Drivetrain could not be created: Track missing drive wheel(s)") return end
		if UsesDriveWheel == 1 and not (IsValid(LeftIdlerWheel) and IsValid(RightIdlerWheel)) then ACF.SendNotify(Player, false, "Drivetrain could not be created: Track missing idler wheel(s)") return end

		if UsesDriveWheel == 1 then -- Tracked
			for Index, Wheel in ipairs(Selections.PlatesToWheels[Baseplate] or EmptyTable) do
				if not IsValid(Wheel) and checkOwner(Player, Wheel) or not checkOwner(Wheel, Player) then continue end

				if Index > 2 then SlaveSocket(Wheel, Index % 2 == 1 and LeftDriveWheel or RightDriveWheel) end -- Other wheels to drive wheel
				if Index <= 4 then Axis(Wheel, Baseplate) end -- Drive and idler wheels to baseplate

				-- Road wheel to baseplate
				local Mirror = Index % 2 == 1 and 1 or -1
				if Index > 4 then
					if SpringType == 1 then Axis(Wheel, Baseplate) -- Axis suspension
					else
						HullSocket(Wheel, Baseplate) -- Restrict rotation to baseplate
						if ArmType == 1 then ArmFork(Wheel, Baseplate, ArmX, ArmY * Mirror, ArmZ)
						elseif ArmType == 2 then ArmForwardLever(Wheel, Baseplate, ArmX, ArmY * Mirror, ArmZ)
						elseif ArmType == 3 then ArmSidewaysLever(Wheel, Baseplate, ArmX, ArmY * Mirror, ArmZ) end

						if SpringType == 2 and IsValid(ControlPlate) then
							MakeHydraulicAndController(Player, Wheel, Baseplate, Vector(0, 0, 0), Vector(SpringX, SpringY * Mirror, SpringZ), InOutSpeedMul, ControlPlate:LocalToWorld(Vector((math.ceil(Index/2)-3) * 8, Mirror * 4, 0)), ControlPlate:GetAngles())
						elseif SpringType == 3 then
							MakeElastic(Wheel, Baseplate, Vector(0, 0, 0), Vector(SpringX, SpringY * Mirror, SpringZ), Elasticity, Damping, RelativeDamping)
						end
						if LimiterLength > 0 then Rope(Wheel, Baseplate, Vector(0, 0, 0), Baseplate:WorldToLocal(Wheel:GetPos()), LimiterLength, false) end
					end
				end
			end
		else -- Wheeled TODO: CHECK and FIX
			for PlateIndex, Plate in ipairs(Selections.Plates) do
				if not IsValid(Plate) then continue end
				for Index, Wheel in ipairs(Selections.PlatesToWheels[Plate] or EmptyTable) do
					if not IsValid(Wheel) and checkOwner(Player, Wheel) then continue end

					local Mirror = Index % 2 == 1 and 1 or -1
					if SpringType == 1 then -- Axis suspension
						if Index == 1 then Axis(Wheel, Plate) -- Non steered wheels
						else BallSocket(Wheel, Plate) HullSocket(Wheel, Plate) end -- Steered wheels
					else
						HullSocket(Wheel, Plate) -- Restrict rotation to baseplate or steer plate
						if ArmType == 1 then ArmFork(Wheel, Baseplate, ArmX, ArmY * Mirror, ArmZ)
						elseif ArmType == 2 then ArmForwardLever(Wheel, Baseplate, ArmX, ArmY * Mirror, ArmZ)
						elseif ArmType == 3 then ArmSidewaysLever(Wheel, Baseplate, ArmX, ArmY * Mirror, ArmZ) end

						if SpringType == 2 and IsValid(ControlPlate) then
							MakeHydraulicAndController(Player, Wheel, Baseplate, Vector(0, 0, 0), Vector(SpringX, SpringY * Mirror, SpringZ), InOutSpeedMul, ControlPlate:LocalToWorld(Vector((math.ceil(Index/2)) * 8, Mirror * 4, 0)), ControlPlate:GetAngles())
						elseif SpringType == 3 then
							MakeElastic(Wheel, Baseplate, Vector(0, 0, 0), Vector(SpringX, SpringY * Mirror, SpringZ), Elasticity, Damping, RelativeDamping)
						end
						if LimiterLength > 0 then Rope(Wheel, Baseplate, Vector(0, 0, 0), Baseplate:WorldToLocal(Wheel:GetPos()), LimiterLength, false) end
					end
				end
			end
		end

		ACF.SendNotify(Player, true, "Drivetrain successfully created.")
	end

	function TOOL:ClearSuspension()
		local Player = self:GetOwner()
		local Selections = self.Selections

		-- Remove constraints from all plates and wheels
		for _, v in pairs(Selections.Plates) do
			if IsValid(v) and checkOwner(Player, v) then constraint.RemoveAll(v) end
		end

		for _, v in pairs(Selections.Wheels) do
			if IsValid(v) and checkOwner(Player, v) then constraint.RemoveAll(v) end
		end

		ACF.SendNotify(Player, true, "Cleared all constraints in drivetrain")
	end
end