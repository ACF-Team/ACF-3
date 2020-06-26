function PANEL:Init()
	acfmenupanel = self.Panel
	-- height
	self:SetTall(surface.ScreenHeight() - 120)
	--Weapon Select
	self.WeaponSelect = vgui.Create("DTree", self)
	self.WeaponData = ACF.Weapons
	local Classes = ACF.Classes
	self.Classes = {}

	for ID, Table in pairs(Classes) do
		self.Classes[ID] = {}

		for ClassID, Class in pairs(Table) do
			Class.id = ClassID
			table.insert(self.Classes[ID], Class)
		end

		table.sort(self.Classes[ID], function(a, b) return a.id < b.id end)
	end

	local WeaponDisplay = ACF.Weapons
	self.WeaponDisplay = {}

	for ID, Table in pairs(WeaponDisplay) do
		self.WeaponDisplay[ID] = {}

		for _, Data in pairs(Table) do
			table.insert(self.WeaponDisplay[ID], Data)
		end

		if ID == "Guns" then
			table.sort(self.WeaponDisplay[ID], function(a, b)
				if a.gunclass == b.gunclass then
					return a.caliber < b.caliber
				else
					return a.gunclass < b.gunclass
				end
			end)
		else
			table.sort(self.WeaponDisplay[ID], function(a, b) return a.id < b.id end)
		end
	end

	local HomeNode = self.WeaponSelect:AddNode("ACF Home", "icon16/newspaper.png")
	local OldSelect = HomeNode.OnNodeSelected
	HomeNode.mytable = {}

	HomeNode.mytable.guicreate = (function(_, Table)
		ACFHomeGUICreate(Table)
	end or nil)

	function HomeNode:OnNodeSelected(Node)
		acfmenupanel:UpdateDisplay(self.mytable)

		OldSelect(self, Node)
	end

	self.WeaponSelect:SetSelectedItem(HomeNode)

	local RoundAttribs = ACF.RoundTypes
	self.RoundAttribs = {}

	for ID, Table in pairs(RoundAttribs) do
		Table.id = ID
		table.insert(self.RoundAttribs, Table)
	end

	table.sort(self.RoundAttribs, function(a, b) return a.id < b.id end)
	local Guns = self.WeaponSelect:AddNode("Guns")

	for _, Class in pairs(self.Classes["GunClass"]) do
		local SubNode = Guns:AddNode(Class.name or "No Name")

		for _, Ent in pairs(self.WeaponDisplay["Guns"]) do
			if Ent.gunclass == Class.id then
				local EndNode = SubNode:AddNode(Ent.name or "No Name")
				EndNode.mytable = Ent

				function EndNode:DoClick()
					RunConsoleCommand("acfmenu_type", self.mytable.type)
					acfmenupanel:UpdateDisplay(self.mytable)
				end

				EndNode.Icon:SetImage("icon16/newspaper.png")
			end
		end
	end

	local Ammo = self.WeaponSelect:AddNode("Ammo")

	for _, AmmoTable in pairs(self.RoundAttribs) do
		local EndNode = Ammo:AddNode(AmmoTable.name or "No Name")
		EndNode.mytable = AmmoTable

		function EndNode:DoClick()
			RunConsoleCommand("acfmenu_type", self.mytable.type)
			acfmenupanel:UpdateDisplay(self.mytable)
		end

		EndNode.Icon:SetImage("icon16/newspaper.png")
	end

	local Mobility = self.WeaponSelect:AddNode("Mobility")
	local Engines = Mobility:AddNode("Engines")
	local Gearboxes = Mobility:AddNode("Gearboxes")
	local FuelTanks = Mobility:AddNode("Fuel Tanks")
	local EngineSubcats = {}

	for _, MobilityTable in pairs(self.WeaponDisplay["Mobility"]) do
		local NodeAdd = Mobility

		if (MobilityTable.ent == "acf_engine") then
			NodeAdd = Engines
		elseif (MobilityTable.ent == "acf_gearbox") then
			NodeAdd = Gearboxes
		elseif (MobilityTable.ent == "acf_fueltank") then
			NodeAdd = FuelTanks
		end

		if ((EngineSubcats["misce"] == nil) and (EngineSubcats["miscg"] == nil)) then
			EngineSubcats["misce"] = Engines:AddNode("Miscellaneous")
			EngineSubcats["miscg"] = Gearboxes:AddNode("Miscellaneous")
		end

		if MobilityTable.category and not EngineSubcats[MobilityTable.category] then
			EngineSubcats[MobilityTable.category] = NodeAdd:AddNode(MobilityTable.category)
		end
	end

	for _, MobilityTable in pairs(self.WeaponDisplay["Mobility"]) do
		local NodeAdd = Mobility

		if MobilityTable.ent == "acf_engine" then
			NodeAdd = Engines

			if (MobilityTable.category) then
				NodeAdd = EngineSubcats[MobilityTable.category]
			else
				NodeAdd = EngineSubcats["misce"]
			end
		elseif MobilityTable.ent == "acf_gearbox" then
			NodeAdd = Gearboxes

			if (MobilityTable.category) then
				NodeAdd = EngineSubcats[MobilityTable.category]
			else
				NodeAdd = EngineSubcats["miscg"]
			end
		elseif MobilityTable.ent == "acf_fueltank" then
			NodeAdd = FuelTanks

			if (MobilityTable.category) then
				NodeAdd = EngineSubcats[MobilityTable.category]
			end
		end

		local EndNode = NodeAdd:AddNode(MobilityTable.name or "No Name")
		EndNode.mytable = MobilityTable

		function EndNode:DoClick()
			RunConsoleCommand("acfmenu_type", self.mytable.type)
			acfmenupanel:UpdateDisplay(self.mytable)
		end

		EndNode.Icon:SetImage("icon16/newspaper.png")
	end
	--[[local Missiles = self.WeaponSelect:AddNode( "Missiles" )
	for MisID, MisTable in pairs(self.WeaponDisplay["Missiles"]) do

		local EndNode = Missiles:AddNode( MisTable.name or "No Name" )

		EndNode.mytable = MisTable
		function EndNode:DoClick()
			RunConsoleCommand( "acfmenu_type", self.mytable.type )
			acfmenupanel:UpdateDisplay( self.mytable )
		end

		EndNode.Icon:SetImage( "icon16/newspaper.png")

	end]]
	-- local Sensors = self.WeaponSelect:AddNode( "Sensors" )
	-- for SensorsID,SensorsTable in pairs(self.WeaponDisplay["Sensors"]) do
	-- local EndNode = Sensors:AddNode( SensorsTable.name or "No Name" )
	-- EndNode.mytable = SensorsTable
	-- function EndNode:DoClick()
	-- RunConsoleCommand( "acfmenu_type", self.mytable.type )
	-- acfmenupanel:UpdateDisplay( self.mytable )
	-- end
	-- EndNode.Icon:SetImage( "icon16/newspaper.png" )
	-- end
end

--[[------------------------------------
	Think
------------------------------------]]
function PANEL:Think()
end

function PANEL:UpdateDisplay(Table)
	RunConsoleCommand("acfmenu_id", Table.id or 0)

	--If a previous display exists, erase it
	if (acfmenupanel.CustomDisplay) then
		acfmenupanel.CustomDisplay:Clear(true)
		acfmenupanel.CustomDisplay = nil
		acfmenupanel.CData = nil
	end

	--Create the space to display the custom data
	acfmenupanel.CustomDisplay = vgui.Create("DPanelList", acfmenupanel)
	acfmenupanel.CustomDisplay:SetSpacing(10)
	acfmenupanel.CustomDisplay:EnableHorizontal(false)
	acfmenupanel.CustomDisplay:EnableVerticalScrollbar(false)
	acfmenupanel.CustomDisplay:SetSize(acfmenupanel:GetWide(), acfmenupanel:GetTall())

	if not acfmenupanel["CData"] then
		--Create a table for the display to store data
		acfmenupanel["CData"] = {}
	end

	acfmenupanel.CreateAttribs = Table.guicreate
	acfmenupanel.UpdateAttribs = Table.guiupdate
	acfmenupanel:CreateAttribs(Table)
	acfmenupanel:PerformLayout()
end

function PANEL:PerformLayout()
	--Starting positions
	local vspacing = 10
	local ypos = 0
	--Selection Tree panel
	acfmenupanel.WeaponSelect:SetPos(0, ypos)
	acfmenupanel.WeaponSelect:SetSize(acfmenupanel:GetWide(), ScrH() * 0.4)
	ypos = acfmenupanel.WeaponSelect.Y + acfmenupanel.WeaponSelect:GetTall() + vspacing

	if acfmenupanel.CustomDisplay then
		--Custom panel
		acfmenupanel.CustomDisplay:SetPos(0, ypos)
		acfmenupanel.CustomDisplay:SetSize(acfmenupanel:GetWide(), acfmenupanel:GetTall() - acfmenupanel.WeaponSelect:GetTall() - 10)
		ypos = acfmenupanel.CustomDisplay.Y + acfmenupanel.CustomDisplay:GetTall() + vspacing
	end
end

function ACFHomeGUICreate()
	if not acfmenupanel.CustomDisplay then return end

	local Display	= acfmenupanel.CustomDisplay
	local CData		= acfmenupanel.CData

	local Text		= "%s Status\n\nVersion: %s\nBranch:  %s\nStatus:   %s\n\n"
	local Repo		= ACF.GetVersion("ACF-3")
	local Server	= Repo.Server
	local SVCode	= Server and Server.Code or "Unable to Retrieve"
	local SVHead	= Server and Server.Head or "Unable to Retrieve"
	local SVStatus	= Server and Server.Status or "Unable to Retrieve"

	if not Repo.Status then
		ACF.GetVersionStatus("ACF-3")
	end

	CData.Header = vgui.Create("DLabel")
	CData.Header:SetText("ACF Version Status\n")
	CData.Header:SetFont("ACF_Subtitle")
	CData.Header:SetDark(true)
	CData.Header:SizeToContents()
	Display:AddItem(CData.Header)

	CData.ServerStatus = vgui.Create("DLabel")
	CData.ServerStatus:SetText(Text:format("Server", SVCode, SVHead, SVStatus))
	CData.ServerStatus:SetFont("ACF_Paragraph")
	CData.ServerStatus:SetDark(true)
	CData.ServerStatus:SizeToContents()
	Display:AddItem(CData.ServerStatus)

	CData.ClientStatus = vgui.Create("DLabel")
	CData.ClientStatus:SetText(Text:format("Client", Repo.Code, Repo.Head, Repo.Status))
	CData.ClientStatus:SetFont("ACF_Paragraph")
	CData.ClientStatus:SetDark(true)
	CData.ClientStatus:SizeToContents()
	Display:AddItem(CData.ClientStatus)
end

function PANEL:AmmoSelect(Blacklist)
	if not acfmenupanel.CustomDisplay then return end

	local AmmoData = acfmenupanel.AmmoData

	if not Blacklist then
		Blacklist = {}
	end

	if not AmmoData then
		AmmoData = {
			--Id = "Ammo2x4x4",
			Type = "Ammo",
			Data = acfmenupanel.WeaponData.Guns["12.7mmMG"].round
		}

		acfmenupanel.AmmoData = AmmoData
	end

	--Creating the ammo crate selection
	--[[
	acfmenupanel.CData.CrateSelect = vgui.Create("DComboBox", acfmenupanel.CustomDisplay) --Every display and slider is placed in the Round table so it gets trashed when selecting a new round type
	acfmenupanel.CData.CrateSelect:SetSize(100, 30)

	for Key, Value in pairs(acfmenupanel.WeaponDisplay["Ammo"]) do
		acfmenupanel.CData.CrateSelect:AddChoice(Value.id, Key)
	end

	acfmenupanel.CData.CrateSelect.OnSelect = function(_, _, data)
		RunConsoleCommand("acfmenu_id", data)
		acfmenupanel.AmmoData["Id"] = data
		self:UpdateAttribs()
	end

	acfmenupanel.CData.CrateSelect:SetText(acfmenupanel.AmmoData["Id"])
	acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData.CrateSelect)
	]]--

	RunConsoleCommand("acfmenu_id", AmmoData.Id)
	--Create the caliber selection display
	acfmenupanel.CData.CaliberSelect = vgui.Create("DComboBox", acfmenupanel.CustomDisplay)
	acfmenupanel.CData.CaliberSelect:SetSize(100, 30)

	for Key, Value in pairs(acfmenupanel.WeaponDisplay["Guns"]) do
		if (not table.HasValue(Blacklist, Value.gunclass)) then
			acfmenupanel.CData.CaliberSelect:AddChoice(Value.id, Key)
		end
	end

	acfmenupanel.CData.CaliberSelect.OnSelect = function(_, _, data)
		AmmoData.Data = acfmenupanel.WeaponData.Guns[data].round

		self:UpdateAttribs()
		self:UpdateAttribs() --Note : this is intentional
	end

	acfmenupanel.CData.CaliberSelect:SetText(AmmoData.Data.id)
	acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData.CaliberSelect)

	-- Create ammo crate scale sliders
	local X = AmmoData["Ammo Scale X"] or 24
	local Y = AmmoData["Ammo Scale Y"] or 24
	local Z = AmmoData["Ammo Scale Z"] or 24

	acfmenupanel:AmmoSlider("Ammo Scale X", X, 6, 96, 3, "Crate X scale")
	acfmenupanel:AmmoSlider("Ammo Scale Y", Y, 6, 96, 3, "Crate Y scale")
	acfmenupanel:AmmoSlider("Ammo Scale Z", Z, 6, 96, 3, "Crate Z scale")

	acfmenupanel["CData"]["Ammo Scale X"].OnValueChanged = function(_, val)
		if AmmoData["Ammo Scale X"] ~= val then
			AmmoData["Ammo Scale X"] = val

			self:UpdateAttribs("Ammo Scale X")

			RunConsoleCommand("acfmenu_data11", val)
		end
	end

	acfmenupanel["CData"]["Ammo Scale Y"].OnValueChanged = function(_, val)
		if AmmoData["Ammo Scale Y"] ~= val then
			AmmoData["Ammo Scale Y"] = val

			self:UpdateAttribs("Ammo Scale Y")

			RunConsoleCommand("acfmenu_data12", val)
		end
	end

	acfmenupanel["CData"]["Ammo Scale Z"].OnValueChanged = function(_, val)
		if AmmoData["Ammo Scale Z"] ~= val then
			AmmoData["Ammo Scale Z"] = val

			self:UpdateAttribs("Ammo Scale Z")

			RunConsoleCommand("acfmenu_data13", val)
		end
	end
end

-- If it works don't fix it man, btw just add this function to every single ammo type
function PANEL:AmmoUpdate()
	local AmmoData = acfmenupanel.AmmoData

	acfmenupanel:AmmoSlider("Ammo Scale X", AmmoData["Ammo Scale X"], 6, 96, 3, "Crate X scale")
	acfmenupanel:AmmoSlider("Ammo Scale Y", AmmoData["Ammo Scale Y"], 6, 96, 3, "Crate Y scale")
	acfmenupanel:AmmoSlider("Ammo Scale Z", AmmoData["Ammo Scale Z"], 6, 96, 3, "Crate Z scale")
end

--Variable name in the table, Value, Min value, Max Value, slider text title, slider decimals, description text below slider
function PANEL:AmmoSlider(Name, Value, Min, Max, Decimals, Title, Desc)
	local Panels = acfmenupanel.CData

	if not Panels[Name] then
		Panels[Name] = vgui.Create("DNumSlider", acfmenupanel.CustomDisplay)
		Panels[Name].Label:SetSize(0) --Note : this is intentional
		Panels[Name]:SetTall(50) -- make the slider taller to fit the new label
		Panels[Name]:SetMin(Min)
		Panels[Name]:SetMax(Max)
		Panels[Name]:SetDecimals(Decimals)
		Panels[Name .. "_label"] = vgui.Create("DLabel", Panels[Name]) -- recreating the label
		Panels[Name .. "_label"]:SetPos(0, 0)
		Panels[Name .. "_label"]:SetText(Title)
		Panels[Name .. "_label"]:SizeToContents()
		Panels[Name .. "_label"]:SetDark(true)

		Panels[Name].OnValueChanged = function(_, val)
			if acfmenupanel.AmmoData[Name] ~= val then
				acfmenupanel.AmmoData[Name] = val
				self:UpdateAttribs(Name)
			end
		end

		local OldValue = acfmenupanel.AmmoData[Name]

		if OldValue then
			Panels[Name]:SetValue(OldValue)
		end

		acfmenupanel.CustomDisplay:AddItem(Panels[Name])
	end

	Panels[Name]:SetMin(Min)
	Panels[Name]:SetMax(Max)
	Panels[Name]:SetValue(Value)

	if Desc then
		if not Panels[Name .. "_text"] then
			Panels[Name .. "_text"] = vgui.Create("DLabel")
			Panels[Name .. "_text"]:SetText(Desc)
			Panels[Name .. "_text"]:SetDark(true)
			Panels[Name .. "_text"]:SetTall(20)
			acfmenupanel.CustomDisplay:AddItem(Panels[Name .. "_text"])
		end

		Panels[Name .. "_text"]:SetText(Desc)
		Panels[Name .. "_text"]:SetSize(acfmenupanel.CustomDisplay:GetWide(), 10)
		Panels[Name .. "_text"]:SizeToContentsX()
	end
end

--Variable name in the table, slider text title, slider decimeals, description text below slider
function PANEL:AmmoCheckbox(Name, Title, Desc)
	if not acfmenupanel["CData"][Name] then
		acfmenupanel["CData"][Name] = vgui.Create("DCheckBoxLabel")
		acfmenupanel["CData"][Name]:SetText(Title or "")
		acfmenupanel["CData"][Name]:SetDark(true)
		acfmenupanel["CData"][Name]:SizeToContents()

		if acfmenupanel.AmmoData[Name] ~= nil then
			acfmenupanel["CData"][Name]:SetChecked(acfmenupanel.AmmoData[Name])
		else
			acfmenupanel.AmmoData[Name] = false
		end

		acfmenupanel["CData"][Name].OnChange = function(_, bval)
			acfmenupanel.AmmoData[Name] = bval
			self:UpdateAttribs({Name, bval})
		end

		acfmenupanel.CustomDisplay:AddItem(acfmenupanel["CData"][Name])
	end

	acfmenupanel["CData"][Name]:SetText(Title)

	if not acfmenupanel["CData"][Name .. "_text"] and Desc then
		acfmenupanel["CData"][Name .. "_text"] = vgui.Create("DLabel")
		acfmenupanel["CData"][Name .. "_text"]:SetText(Desc or "")
		acfmenupanel["CData"][Name .. "_text"]:SetDark(true)
		acfmenupanel.CustomDisplay:AddItem(acfmenupanel["CData"][Name .. "_text"])
	end

	acfmenupanel["CData"][Name .. "_text"]:SetText(Desc)
	acfmenupanel["CData"][Name .. "_text"]:SetSize(acfmenupanel.CustomDisplay:GetWide(), 10)
	acfmenupanel["CData"][Name .. "_text"]:SizeToContentsX()
end

function PANEL:CPanelText(Name, Desc)
	if not acfmenupanel["CData"][Name .. "_text"] then
		acfmenupanel["CData"][Name .. "_text"] = vgui.Create("DLabel")
		acfmenupanel["CData"][Name .. "_text"]:SetText(Desc or "")
		acfmenupanel["CData"][Name .. "_text"]:SetDark(true)
		acfmenupanel["CData"][Name .. "_text"]:SetWrap(true)
		acfmenupanel["CData"][Name .. "_text"]:SetAutoStretchVertical(true)
		acfmenupanel.CustomDisplay:AddItem(acfmenupanel["CData"][Name .. "_text"])
	end

	acfmenupanel["CData"][Name .. "_text"]:SetText(Desc)
	acfmenupanel["CData"][Name .. "_text"]:SetSize(acfmenupanel.CustomDisplay:GetWide(), 10)
	acfmenupanel["CData"][Name .. "_text"]:SizeToContentsY()
end