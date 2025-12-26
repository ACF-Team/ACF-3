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
TOOL.Name		 = "#tool.acfarmormesh.name"
TOOL.Command	 = nil
TOOL.ConfigName	 = ""
TOOL.Information = {
	{ name = "left0", stage = 0 },
	{ name = "right0", stage = 0 },
	{ name = "reload0", stage = 0 },
	{ name = "left1", stage = 1 },
	{ name = "left2", stage = 1, icon2 = "gui/key.png" },
	{ name = "right1", stage = 1 },
	{ name = "right2", stage = 1, icon2 = "gui/key.png" },
	{ name = "flashlight1", stage = 1, icon = "gui/key.png" },
	{ name = "reload1", stage = 1, icon = "gui/r.png" },

	{ name = "modes", stage = 0, icon = "gui/key.png" },
	{ name = "targets", stage = 0, icon = "gui/key.png" },
	{ name = "modes", stage = 1, icon = "gui/key.png" },
	{ name = "targets", stage = 1, icon = "gui/key.png" },
}

--- Readable? No. Check the definition in the other ACF file. Just compressed this lazilly.
local function SpawnEntity(Tool, Trace)
	if Trace.HitSky then return false end

	local Player = Tool:GetOwner()
	local Data   = ACF.GetAllClientData(Player)
	local Entity = Trace.Entity
	if IsValid(Entity) and Entity:GetClass() == "acf_armor_controller" then
		local Result, Message = Entities.Update(Entity, Data)
		Messages.SendChat(Player, Result and "Info" or "Error", Message)
		return true
	end
	local Position = Trace.HitPos + Trace.HitNormal * 128
	local Angles   = Trace.HitNormal:Angle():Up():Angle()
	local Success, Result = Entities.Spawn("acf_armor_controller", Player, Position, Angles, Data)
	if Success then
		local PhysObj = Result:GetPhysicsObject()
		Result:DropToFloor()
		if IsValid(PhysObj) then PhysObj:EnableMotion(false) end
	else Messages.SendChat(Player, "Error", "Couldn't create entity: " .. Result) end

	return Success
end

if CLIENT then
	language.Add("tool.acfarmormesh.name", "ACF Armor Compiler")
	language.Add("tool.acfarmormesh.desc", "Aids in editting an ACF Armor Mesh")

	language.Add("tool.acfarmormesh.modes", "[ALT] Switch between editing/armoring")
	language.Add("tool.acfarmormesh.targets", "[CTRL] Switch between selecting anything/vertex/convex")

	language.Add("tool.acfarmormesh.left0", "Place a mesh controller")
	language.Add("tool.acfarmormesh.right0", "Select a mesh controller")
	language.Add("tool.acfarmormesh.reload0", "Clear a mesh controller")

	language.Add("tool.acfarmormesh.left1", "Add a vertex/convex")
	language.Add("tool.acfarmormesh.left2", "[SHIFT] Add a basic cube for modification")
	language.Add("tool.acfarmormesh.right1", "Deselect a controller")
	language.Add("tool.acfarmormesh.right2", "[SHIFT] Select a vertex/convex")
	language.Add("tool.acfarmormesh.flashlight1", "[F] Move a vertex/convex")
	language.Add("tool.acfarmormesh.reload1", "[R] Delete a vertex/convex")

	surface.CreateFont("Torchfont", { size = 40, weight = 1000, font = "arial" })

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

		local Instructions = Menu:AddCollapsible("General Instructions", false)
		Instructions:AddLabel("Test")

		Menu:AddTextEntry("Controller Model: ", "models/hunter/plates/plate025x025.mdl")
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

	net.Receive("acf_mesh_selected", function()
		local Ent = net.ReadEntity()
		local Selected = net.ReadBool()
		if not IsValid(Ent) then return end

		LocalPlayer().SelectedController = Selected and Ent or nil
	end)

	--- Draws the hud/tooltips for this tool
	function TOOL:DrawHUD()
		local ent = LocalPlayer().SelectedController
		if IsValid(ent) then
			cam.Start3D()
			render.SetColorMaterial()
			ent:DrawOverlay()
			cam.End3D()
		end
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
	util.AddNetworkString("acf_mesh_selected") -- Currently selected mesh controller

	local function checkOwner(ply, ent)
		if CPPI then
			local owner = ent:CPPIGetOwner() or (ent.GetPlayer and ent:GetPlayer())
			if owner then
				return owner == ply
			end
		end
		return true
	end

	function TOOL:SetController(ent)
		if not IsValid(ent) or ent:GetClass() ~= "acf_armor_controller" or not checkOwner(self:GetOwner(), ent) then
			return
		end

		net.Start("acf_mesh_selected")
		net.WriteEntity(ent)
		net.WriteBool(true)
		net.Broadcast()

		self.controller = { ent = ent, col = ent:GetColor(), mat = ent:GetMaterial(), mode = ent:GetRenderMode() }
		ent:SetColor(Color(0, 0, 255, 255))
		ent:SetRenderMode(RENDERMODE_TRANSCOLOR)
		ent:SetMaterial("models/debug/debugwhite")
		self:SetStage(1)
	end

	function TOOL:UnSetController()
		if IsValid(self.controller.ent) then
			self.controller.ent:SetColor(self.controller.col)
			self.controller.ent:SetRenderMode(self.controller.mode)
			self.controller.ent:SetMaterial(self.controller.mat)

			net.Start("acf_mesh_selected")
			net.WriteEntity(self.controller.ent)
			net.WriteBool(false)
			net.Broadcast()
		end
		self.controller = nil
		self:SetStage(0)
	end

	function TOOL:CheckForExtras()
		local isFirstTimePredicted = IsFirstTimePredicted()
		if not isFirstTimePredicted then return end

		local Player = self:GetOwner()

		if Player:KeyPressed(IN_DUCK) then
			-- Switch between editing/armoring
			print("Change Modes")
		end

		if Player:KeyPressed(IN_WALK) then
			-- Switch between only selecting anything/vertex/convex
			print("Change Targets")
		end
	end

	function TOOL:Think()
		local Player = self:GetOwner()
		local Trace = Player:GetEyeTrace()
		local Ent = Trace.Entity

		self:CheckForExtras()
	end

	function TOOL:LeftClick(Trace)
		local Player = self:GetOwner()
		if not self.controller then
			-- No controller, so spawn one
			SpawnEntity(self, Trace)
		end
		return true
	end

	function TOOL:RightClick(Trace)
		local Player = self:GetOwner()
		if Player:KeyDown(IN_SPEED) then
			-- Select the vertex/convex
			print("Shift + RightClick")
			return true
		end

		print("RightClick")
		-- Select or deselect the controller...
		if not self.controller then
			self:SetController(Trace.Entity)
		else
			self:UnSetController()
		end
		return true
	end

	function TOOL:Reload(Trace)
		print("Reload")
		return true
	end
end