--[[
This is NOT clean code... It should be optimized enough though. 
I tried piecing this together as fast as possible due to time constraints.
If someone wants to improve it they are welcome to do so.

Due to the specific keybinds i need, doing it through the ACF tool functions is not possible.
I did use ACF's menu building/reload functions for rapid development though.

The basic controller functions were modified from Prop To Mesh ()
--]]

local ACF = ACF
local Contraption	= ACF.Contraption
local Entities   = ACF.Classes.Entities
local Messages   = ACF.Utilities.Messages
local IsValid = IsValid

TOOL.Category	 = (ACF.CustomToolCategory and ACF.CustomToolCategory:GetBool()) and "ACF" or "Construction"
TOOL.Name		 = "ACF Suspension Tool"
TOOL.Command	 = nil
TOOL.ConfigName	 = ""
TOOL.Information = {
	{ name = "right0shift", stage = 0, desc = "[SHIFT] Select a baseplate", icon2 = "gui/key.png" },
	{ name = "right1", stage = 1, desc = "Select a left drive wheel" },
	{ name = "right2", stage = 2, desc = "Select a right drive wheel" },
	{ name = "right3", stage = 3, desc = "Select a left idler wheel" },
	{ name = "right4", stage = 4, desc = "Select a right idler wheel" },
	{ name = "right5", stage = 5, desc = "Select a road wheel" },
	{ name = "right5shift", stage = 5, desc = "[SHIFT] Select a steer plate" },
	{ name = "right6", stage = 6, desc = "Select a steer plate" },
	{ name = "right6shift", stage = 6, desc = "[SHIFT] Select a steer wheel" },
	{ name = "reload", desc = "Reset the tool", icon2 = "gui/refresh.png", },
}

-- Stage 0 SHIFT + RMB: Baseplate -> Stage 1
-- Stage 1 RMB: Left Drive Wheel -> Stage 2
-- Stage 2 RMB: Right Drive Wheel -> Stage 3
-- Stage 3 RMB: Left Idler Wheel -> Stage 4
-- Stage 4 RMB: Right Idler Wheel -> Stage 5
-- Stage 5 RMB: Road wheels -> Stage 5
-- Stage 5 SHIFT + RMB: Steer Plate -> Stage 6
-- Stage 6 RMB: Steer wheel -> Stage 6
-- Stage 6 SHIFT + RMB: Steer Plate -> Stage 6

TOOL.ColMatMap = {}
TOOL.Selections = {}

TOOL.Baseplate = nil
TOOL.DriveWheels = {}
TOOL.IdlerWheels = {}
TOOL.RoadWheels = {}
TOOL.SteerPlates = {}
TOOL.SteerWheels = {}
TOOL.SteerPlatesToWheels = {}

function TOOL:SelectColor(Entity, Col, Material)
	self.ColMatMap[Entity] = {Entity:GetColor(), Entity:GetMaterial()}
	Entity:SetColor(Col or Color(0, 255, 0, 255))
	Entity:SetMaterial(Material or "models/wireframe")
end

function TOOL:UnselectColor(Entity)
	if self.ColMatMap[Entity] then
		Entity:SetColor(self.ColMatMap[Entity][1])
		Entity:SetMaterial(self.ColMatMap[Entity][2])
		self.ColMatMap[Entity] = nil
	end
end


if CLIENT then
	language.Add("tool.acfsuspension.name", "ACF Armor Compiler")
	language.Add("tool.acfsuspension.desc", "Aids in editting an ACF Armor Mesh")

	surface.CreateFont("Torchfont", { size = 40, weight = 1000, font = "arial" })

	for _, v in pairs(TOOL.Information) do
		language.Add("tool.acfsuspension." .. v.name, v.desc)
	end

	--- Making the menu actually work...

	--- Creates (Or recreates) the menu for this tool
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
		Reload:SetTooltip("You can also type 'acf_reload_armor_menu' in console.")
		function Reload:DoClickInternal()
			RunConsoleCommand("acf_reload_armor_menu")
		end

		Menu:AddLabel("ACF Armor Mesh Tool")
		Menu:AddLabel("This tool is used to create and edit ACF armor meshes.")
	end

	TOOL.BuildCPanel = CreateMenu

	concommand.Add("acf_reload_armor_menu", function()
		if not IsValid(ACF.ArmorMenu) then return end

		CreateMenu(ACF.ArmorMenu.Panel)
	end)

	local TextGray = Color(224, 224, 255)
	local BGGray = Color(200, 200, 200)
	local Blue = Color(50, 200, 200)
	local Red = Color(200, 50, 50)
	local Green = Color(50, 200, 50)
	local Black = Color(0, 0, 0)
	local drawText = draw.SimpleTextOutlined

	surface.CreateFont("ACF_ToolTitle", {
		font = "Arial",
		size = 32
	})

	surface.CreateFont("ACF_ToolSub", {
		font = "Arial",
		size = 25
	})

	surface.CreateFont("ACF_ToolLabel", {
		font = "Arial",
		size = 32,
		weight = 620,
	})

	--- Draws the hud/tooltips for this tool
	function TOOL:DrawHUD()

	end

	function TOOL:DrawToolScreen()
		local Trace = self:GetOwner():GetEyeTrace()
		local Ent   = Trace.Entity
		local Weapon = self.Weapon
	end

	function TOOL:Think()

	end

	-- Toolgun beam will show even if nothing happens serverside. I don't wanna fix this :(...
	function TOOL:LeftClick(Trace) return true end
	function TOOL:RightClick(Trace) return true end
	function TOOL:Reload(Trace) return true end
elseif SERVER then -- Serverside-only stuff
	local function checkOwner(ply, ent)
		if CPPI then
			local owner = ent:CPPIGetOwner() or (ent.GetPlayer and ent:GetPlayer())
			if owner then
				return owner == ply
			end
		end
		return true
	end

	function TOOL:Think()
		local Player = self:GetOwner()
		local Trace = Player:GetEyeTrace()
		local Ent = Trace.Entity
	end

	function TOOL:RightClick(Trace)
		local Player = self:GetOwner()
		local Ent = Trace.Entity
		if not IsValid(Ent) then return end
		if Ent:IsPlayer() then return end
		if not checkOwner(Player, Ent) then return end

		local IsShift = Player:KeyDown(IN_SPEED)
		local Stage = self:GetStage()
		if IsShift then
			if Stage == 0 then
				print("Selected Baseplate")
				self.Baseplate = Ent
				self:SelectColor(Ent, Color(255, 255, 255))
				self:SetStage(1)
			elseif Stage ~= 0 then
				print("Selected Steer plate")
				local CurrentPlate = self.SteerPlates[#self.SteerPlates]
				self.SteerPlateToWheels[CurrentPlate] = self.SteerWheels
				self.SteerWheels = {}
				PrintTable(self.SteerPlateToWheels or {})
				table.insert(self.SteerPlates, Ent)
				self:SelectColor(Ent)
				self:SetStage(6)
			end
		else
			if Stage == 1 then
				print("Selected Left Drive Wheel")
				self.DriveWheels[1] = Ent
				self:SelectColor(Ent, Color(255, 0, 0))
				self:SetStage(2)
			elseif Stage == 2 then
				print("Selected Right Drive Wheel")
				self.DriveWheels[2] = Ent
				self:SelectColor(Ent, Color(255, 0, 0))
				self:SetStage(3)
			elseif Stage == 3 then
				print("Selected Left Idler Wheel")
				self.IdlerWheels[1] = Ent
				self:SelectColor(Ent, Color(255, 0, 0))
				self:SetStage(4)
			elseif Stage == 4 then
				print("Selected Right Idler Wheel")
				self.IdlerWheels[2] = Ent
				self:SelectColor(Ent, Color(255, 0, 0))
				self:SetStage(5)
			elseif Stage == 5 then
				print("Selected Road Wheel")
				table.insert(self.RoadWheels, Ent)
				self:SelectColor(Ent, Color(0, 255, 0))
			elseif Stage == 6 then
				print("Selected Steer Wheel")
				table.insert(self.SteerWheels, Ent)
				
				self:SelectColor(Ent, Color(0, 0, 255))
			end
		end
		return true
	end

	function TOOL:Reload(Trace)
		print("Reset stage")
		self:SetStage(0)

		for Ent in pairs(self.ColMatMap) do
			if IsValid(Ent) then self:UnselectColor(Ent) end
		end
		self.Baseplate = nil
		self.DriveWheels = {}
		self.IdlerWheels = {}
		self.RoadWheels = {}
		self.SteerPlates = {}
		self.SteerWheels = {}
		self.SteerPlateToWheels = {}
		return true
	end
end