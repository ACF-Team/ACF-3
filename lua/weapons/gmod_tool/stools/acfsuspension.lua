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
	{name = "right1", stage = 0, desc = "Select a wheel"},
	{name = "reload", desc = "Reset the tool", icon2 = "gui/refresh.png"}
}

TOOL.Selections = {}				-- Holds the selections
TOOL.Selections.Plates = {}			-- Holds the plates
TOOL.Selections.Wheels = {}			-- Holds the wheels
TOOL.Selections.PlatesToWheels = {}	-- Holds the wheels for each plate

local EmptyTable = {}
if CLIENT then
	-- Add descriptions to tool info
	language.Add("tool.acfsuspension.name", "ACF Suspension Tool")
	language.Add("tool.acfsuspension.desc", "Aids in setting up basic suspensions.")

	for _, v in pairs(TOOL.Information) do
		language.Add("tool.acfsuspension." .. v.name, v.desc)
	end

	CreateClientConVar("ACF_Sus_Tool_IsTracked", 1, false, true)
	CreateClientConVar("ACF_Sus_Tool_Use_Custom", 0, false, true)

	--- Creates/recreates the menu for this tool
	local function CreateMenu(Panel)
		local Menu = ACF.ArmorMenu

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

		local IsTracked = Menu:AddCheckBox("Drivetrain Uses Tracks", "ACF_Sus_Tool_IsTracked")
		IsTracked:SetTooltip("If checked, the drivetrain will be tracked. Otherwise, it will be wheeled.")

		local UseCustom = Menu:AddCheckBox("Use my own suspension", "ACF_Sus_Tool_Use_Custom")
		UseCustom:SetTooltip("If checked, the drivetrain will only make your wheels rotate propperly.\nYou will need to create the constraints that hold it in place/suspend it yourself.")

		local Create = Menu:AddButton("Create Drivetrain")
		Create:SetTooltip("Creates a new drivetrain with the selected entitites.")

		function Create:DoClickInternal()
			net.Start("ACF_Sus_Tool")
			net.WriteString("Create")
			net.SendToServer()
		end

		local Clear = Menu:AddButton("Clear Drivetrain")
		Clear:SetTooltip("Clears all constraints on selected entities.")

		function Clear:DoClickInternal()
			net.Start("ACF_Sus_Tool")
			net.WriteString("Clear")
			net.SendToServer()
		end

		Menu:AddTitle("Instructions (General)")
		Menu:AddLabel("When selecting wheels, select in alternating order starting with left then right.")
		Menu:AddLabel("If you hold the tool, the entities you selected will be labelled, which should help.")
		Menu:AddLabel("Pressing R at any time will reset the tool's record of the selected entities, in case you made a mistake.")

		Menu:AddTitle("Instructions (Tracked)")
		Menu:AddLabel("1. Select the baseplate with SHIFT + RMB")
		Menu:AddLabel("2. Select left/right drive wheels with RMB")
		Menu:AddLabel("3. Select left/right road wheels with RMB")
		Menu:AddLabel("4. If you ever want to add a steer plate, select it with SHIFT + RMB")
		Menu:AddLabel("5. Then all steer wheels selected after will belong to that steer plate")

		Menu:AddTitle("Instructions (Wheeled)")
		Menu:AddLabel("1. Select the baseplate with SHIFT + RMB")
		Menu:AddLabel("2. Select left/right road wheels with RMB")
		Menu:AddLabel("3. If you ever want to add a steer plate, select it with SHIFT + RMB")
		Menu:AddLabel("4. Then all steer wheels selected after will belong to that steer plate")
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
		draw.SimpleTextOutlined(Text, nil, SP.x, SP.y, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
	end

	function DrawEntLink(Entity1, Entity2, Col)
		local Pos1 = Entity1:GetPos()
		local SP1 = Pos1:ToScreen()
		local Pos2 = Entity2:GetPos()
		local SP2 = Pos2:ToScreen()

		surface.SetDrawColor(Col)
		surface.DrawLine(SP1.x, SP1.y, SP2.x, SP2.y)
	end

	--- Draws the hud/tooltips for this tool
	function TOOL:DrawHUD()
		local Player = LocalPlayer()
		local Selections = Player.ACF_Sus_Tool_Info
		local IsTracked = GetConVar("ACF_Sus_Tool_IsTracked"):GetInt()

		-- For each plate...
		for PlateIndex, Plate in ipairs(Selections.Plates or EmptyTable) do
			if not IsValid(Plate) then continue end
			if PlateIndex == 1 then DrawEntText(Plate, "Baseplate", Color(255, 0, 255))
			else DrawEntText(Plate, "Steer plate", Color(0, 255, 255)) end

			-- For each wheel of the plate...
			for WheelIndex, Wheel in ipairs(Selections.PlatesToWheels[Plate] or EmptyTable) do
				if not IsValid(Wheel) then continue end
				local Direction = IsTracked and WheelIndex % 2 == 1 and " Left" or " Right"
				local Steer = PlateIndex > 1 and " Steer" or ""
				local Drive = IsTracked and PlateIndex == 1 and  WheelIndex <= 2 and " Drive" or ""
				local Road = IsTracked and PlateIndex == 1 and WheelIndex > 2 and " Road" or ""
				Name = Direction .. Drive .. Steer .. Road .. " Wheel"

				DrawEntLink(Plate, Wheel, Color(255, 255, 0))
				DrawEntText(Wheel, Name, Color(255, 0, 0))
			end
		end
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
		if IsShift then
			table.insert(self.Selections.Plates, Ent)
			self.Selections.PlatesToWheels[Ent] = {}

			Ent:CallOnRemove("ACF_Sus_Tool", function(Ent) self:RemoveEntity(Ent, Player) end)
		else
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
		return constraint.AdvBallsocket(Wheel, Plate, 0, 0, Vector(0, 0, 0), Vector(0, 0, 0), 0, 0, -180, 180, MinTol, MaxTol, MaxTol, MaxTol, 0, 0, 0, 1, 0)
	end

	--- Creates a adv ballsocket constraint between the wheel and its drive wheel
	--- This forces the wheel to rotate freely, with the drive wheel
	local function SlaveSocket(Wheel, DriveWheel)
		return constraint.AdvBallsocket(Wheel, DriveWheel, 0, 0, Vector(0, 0, 0), Vector(0, 0, 0), 0, 0, MinTol, MinTol, MinTol, MaxTol, MaxTol, MaxTol, 0, 0, 0, 1, 0)
	end

	--- Creates a simple ballsocket constraint between the wheel and the plate
	--- This forces the wheel to rotate in place, in any direction
	local function RotationSocket(Wheel, Plate)
		return constraint.Ballsocket(Wheel, Plate, 0, 0, Vector(0, 0, 0), 0, 0, 0)
	end

	function TOOL:CreateSuspension()
		local Player = self:GetOwner()
		local Selections = self.Selections

		local IsTracked = GetConVar("ACF_Sus_Tool_IsTracked"):GetInt()
		local UseCustom = GetConVar("ACF_Sus_Tool_Use_Custom"):GetInt()

		local Baseplate = Selections.Plates[1]
		local LeftDriveWheel = Selections.Wheels[1]
		local RightDriveWheel = Selections.Wheels[2]
		if IsTracked == 1 then -- Tracked
			for Index, Wheel in ipairs(Selections.PlatesToWheels[Baseplate] or EmptyTable) do
				if not IsValid(Wheel) and checkOwner(Player, Wheel) or not checkOwner(Wheel, Player) then continue end
				if Index > 2 then SlaveSocket(Wheel, Index % 2 == 1 and LeftDriveWheel or RightDriveWheel) end
				if UseCustom == 0 then Axis(Wheel, Baseplate) end
			end
		else -- Wheeled
			for Index, Plate in ipairs(Selections.Plates) do
				if not IsValid(Plate) then continue end
				for _, Wheel in ipairs(Selections.PlatesToWheels[Plate] or EmptyTable) do
					if not IsValid(Wheel) and checkOwner(Player, Wheel) then continue end
					if Index == 1 then
						if UseCustom == 0 then Axis(Wheel, Plate) end
					else
						HullSocket(Wheel, Plate)
						if UseCustom == 0 then RotationSocket(Wheel, Plate) end
					end
				end
			end
		end

		-- Unlikely, but maybe this will help...
		if not IsValid(Baseplate) then ACF.SendNotify(Player, false, "Drivetrain could not be created. Components missing/Corrupted. Please refresh (R) and redo the suspension.") return end
		ACF.SendNotify(Player, true, "Created " .. (IsTracked and "tracked" or "wheeled") .. " drivetrain")
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