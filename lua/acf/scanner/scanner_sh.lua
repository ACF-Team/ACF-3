-- This file is NOT DONE: It needs to be split into several files. However, I ran into issues with the ACF loading order, so
-- it's being pushed in this state until I can do a bit more looking into on how to properly maintain a loading order.
-- A lot of this code has been optimized/profiled, but there's more work to do in that department...

local ACF = ACF

if ACF.Scanning and ACF.Scanning.ClearPanels and CLIENT then
    ACF.Scanning.ClearPanels()
end

local scanning = {}
ACF.Scanning = scanning

local net_ReadBool = net.ReadBool
local net_ReadEntity = net.ReadEntity
local net_ReadString = net.ReadString
local net_ReadUInt = net.ReadUInt
local net_ReadVector = net.ReadVector
local net_Send = net.Send
local net_Broadcast = net.Broadcast
local net_SendToServer = net.SendToServer
local net_Start = net.Start
local net_WriteBool = net.WriteBool
local net_WriteEntity = net.WriteEntity
local net_WriteString = net.WriteString
local net_WriteUInt = net.WriteUInt
local net_WriteVector = net.WriteVector

-- Color helpers
local function ColorAlpha(c, a)
    return Color(c.r, c.g, c.b, a)
end

local function ColorHSVAdjust(c, hA, sA, vA, a)
    local h, s, v = ColorToHSV(c)
    h = h + hA
    s = s * sA
    v = v * vA
    s = math.Clamp(s, 0, 1)
    v = math.Clamp(v, 0, 1)
    local rgb = HSVToColor(h, s, v)
    return Color(rgb.r, rgb.g, rgb.b, a or c.a)
end

local vector_zero = Vector(0, 0, 0)

local function writeEntityPacket(baseplate, baseplateMI, baseplateMA, ents, nodrawEnts)
    net_WriteEntity(baseplate)
    net_WriteVector(baseplateMI or vector_zero)
    net_WriteVector(baseplateMA or vector_zero)
    if ents ~= nil then
        local entsL = #ents
        net_WriteUInt(entsL, 16)
        for i = 1, entsL do
            net_WriteEntity(ents[i])
        end
    else
        net_WriteUInt(0, 16)
    end
    if nodrawEnts ~= nil then
        local nodrawEntsL = #nodrawEnts
        net_WriteUInt(#nodrawEnts, 16)
        for i = 1, nodrawEntsL do
            net_WriteEntity(nodrawEnts[i])
        end
    else
        net_WriteUInt(0, 16)
    end
end
local function readEntityPacket()
    local ent = net_ReadEntity()
    local mi = net_ReadVector()
    local ma = net_ReadVector()
    local entsL = net_ReadUInt(16)
    local ents = {}
    for i = 1, entsL do
        ents[i] = net_ReadEntity()
    end
    local nodrawEntsL = net_ReadUInt(16)
    local nodrawEnts = {}
    for i = 1, nodrawEntsL do
        nodrawEnts[i] = net_ReadEntity()
    end

    return ent, mi, ma, ents, nodrawEnts
end
local function writeAmmoFuelPacket(ent, isRefill)
    net_WriteEntity(ent)
    net_WriteBool(isRefill)
end
local function readAmmoFuelPacket()
    return net_ReadEntity(), net_ReadBool()
end

local scannerTypes = {}
local scannerTypesSeq = {}
local function DefineScannerType(class, nickname, color, marker, adv)
    local typeDef = {}
    typeDef.class = class
    typeDef.nickname = nickname

    typeDef.color = color
    typeDef.colorEntityInside = ColorHSVAdjust(color, 1, 0.9, 0.8)
    typeDef.colorMarkerBackground = ColorHSVAdjust(color, 1, 1, 0.4)
    typeDef.colorMarkerBorder = ColorAlpha(color, 240)
    typeDef.colorEntity = ColorHSVAdjust(color, 1, 0.9, 1.2)
    typeDef.colorLegendText = ColorHSVAdjust(color, 0, 0.5, 1)
    typeDef.colorBounds = ColorHSVAdjust(color, 0, 0.8, 1.5, 240)
    typeDef.colorBoundsInside = ColorAlpha(color, 100)
    typeDef.colorMarkerText = ColorHSVAdjust(color, 0, 0.1, 1)

    typeDef.marker = marker
    typeDef.drawBounds = adv.drawBounds ~= nil and adv.drawBounds or false
    typeDef.drawMarker = adv.drawMarker ~= nil and adv.drawMarker or true
    typeDef.drawMesh = adv.drawMesh ~= nil and adv.drawMesh or false
    typeDef.drawModelOverlay = adv.drawModelOverlay ~= nil and adv.drawModelOverlay or false
    typeDef.drawOverlay = adv.drawOverlay ~= nil and adv.drawOverlay or false

    if class ~= nil then
        scannerTypes[class] = typeDef
    end

    scannerTypesSeq[#scannerTypesSeq + 1] = typeDef
    return typeDef
end

--local unknowntype   = DefineScannerType(nil, "Unknown",        Color(255, 255, 255), "?",  {})
local baseplateC    = DefineScannerType(nil, "Baseplate",      Color(255, 150, 255), "BP", {})
local playerC       = DefineScannerType(nil, "Player",         Color(150, 200, 200), "PL", {})

DefineScannerType("acf_gun",                   "ACF Gun",                 Color(100, 130, 255), "G",   {drawModelOverlay = true})
DefineScannerType("acf_ammo",                  "ACF Ammo Crate",          Color(255, 50, 35),   "A",   {drawBounds = true, drawMarker = true})
local ammoRefill = DefineScannerType(nil,                         "ACF Ammo Refill",         Color(255, 50, 35),   "AR",  {drawBounds = true, drawMarker = true})

DefineScannerType("acf_rack",                  "ACF Missile Rack",        Color(100, 230, 255), "RK",  {drawModelOverlay = true})
DefineScannerType("acf_radar",                 "ACF Radar",               Color(255, 200, 50),  "R",   {drawModelOverlay = true})
DefineScannerType("prop_vehicle_prisoner_pod", "Seat/Pod",                Color(130, 255, 100), "P",   {drawModelOverlay = true})

DefineScannerType("acf_engine",                "ACF Engine",              Color(200, 255, 100), "E",   {drawModelOverlay = true})
DefineScannerType("acf_gearbox",               "ACF Gearbox",             Color(148, 148, 20),  "GB",  {drawModelOverlay = true, drawOverlay = true})
DefineScannerType("acf_fueltank",              "ACF Fueltank",            Color(200, 180, 230), "F",   {drawBounds = true})
local fuelRefill = DefineScannerType(nil,                         "ACF Fueltank Refill",     Color(200, 180, 230), "FR",   {drawBounds = true})

DefineScannerType("acf_piledriver",            "ACF Piledriver",          Color(255, 100, 90),  "PD",  {})
DefineScannerType("acf_computer",              "ACF Computer",            Color(235, 235, 255), "E",   {drawModelOverlay = true})
DefineScannerType("acf_armor",                 "ACF Armor",               Color(235, 235, 255), "PAR", {})

DefineScannerType("acf_turret",                "ACF Turret",              Color(155, 215, 255), "T",   {drawModelOverlay = true, drawMesh = true})
DefineScannerType("acf_turret_motor",          "ACF Turret Motor",        Color(155, 215, 255), "TM",  {drawModelOverlay = true, drawMesh = true})
DefineScannerType("acf_turret_gyro",           "ACF Turret Gyroscope",    Color(155, 215, 255), "TG",  {drawModelOverlay = true, drawMesh = true})
DefineScannerType("acf_turret_computer",       "ACF Turret Computer",     Color(155, 215, 255), "TC",  {drawModelOverlay = true, drawMesh = true})

DefineScannerType("gmod_wire_expression2",     "Expression 2 Chip",       Color(230, 40, 40),   "E2",  {})
DefineScannerType("starfall_processor",        "Starfall Chip",           Color(100, 140, 230), "SF",  {})
DefineScannerType("starfall_prop",             "Starfall-Created Prop",   Color(160, 200, 255), "SP",  {})

DefineScannerType("primitive_shape",           "Primitive Shape",         Color(200, 200, 255), "PR",  {
    drawMesh = true
})
DefineScannerType("primitive_staircase",       "Primitive Staircase",     Color(200, 200, 255), "PRs", {
    drawMesh = true
})
DefineScannerType("primitive_ladder",          "Primitive Ladder",        Color(200, 200, 255), "PRl", {
    drawMesh = true
})
DefineScannerType("primitive_rail_slider",     "Primitive Rail Slider",   Color(200, 200, 255), "PRr", {
    drawMesh = true
})
DefineScannerType("primitive_airfoil",         "Primitive Airfoil",       Color(200, 200, 255), "PRa", {
    drawMesh = true
})

local function NetStart(n)
    net_Start("ACF_Scanning_NetworkPacket")
    net_WriteString(n)
end
local receivers = {}

local function NetReceive(n, on)
    receivers[n] = on
end

net.Receive("ACF_Scanning_NetworkPacket", function(_, ply)
    local n = net_ReadString()
    if not receivers[n] then return end

    receivers[n](ply)
end)

local IsValid = IsValid

if SERVER then
    local ents_Iterator = ents.Iterator

    util.AddNetworkString("ACF_Scanning_NetworkPacket")
    util.AddNetworkString("ACF_Scanning_PlayerListChanged")
    local scanningPlayers = {}

    NetReceive("UpdatePlayer", function(ply)
        scanning.BeginScanning(ply, net_ReadEntity())
    end)
    NetReceive("EndScanning", function(ply)
        scanning.EndScanning(ply)
    end)

    hook.Add("PlayerInitialSpawn", "ACF_Scanning_PlayerInitialSpawn", function()
        net_Start("ACF_Scanning_PlayerListChanged")
        net_Broadcast()
    end)

    hook.Add("PlayerDisconnected", "ACF_Scanning_PlayerDisconnected", function()
        net_Start("ACF_Scanning_PlayerListChanged")
        net_Broadcast()
    end)

    function scanning.IsPlayerScanning(ply)
        if not IsValid(ply) then return false end
        return scanningPlayers[ply] ~= nil
    end
    function scanning.GetScanContext(ply)
        if not IsValid(ply) then return nil end
        return scanningPlayers[ply]
    end

    function scanning.BeginScanning(playerScanning, targetPlayer)
        if not IsValid(playerScanning) then return end
        if not IsValid(targetPlayer) then scanning.EndScanning() return end
        if hook.Run("ACF_PreBeginScanning", playerScanning) == false then return end
        if playerScanning:InVehicle() then return end

        scanningPlayers[playerScanning] = {
            target = targetPlayer,
            nextScan = CurTime(),
            camPos = nil,
            Overdue = function(self, now)
                local r = now >= self.nextScan
                if r then
                    self.nextScan = now + math.Rand(0.6, 1.4)
                end

                return r
            end
        }
    end

    function scanning.EndScanning(playerScanning)
        if not IsValid(playerScanning) then return end

        scanningPlayers[playerScanning] = nil
    end

    hook.Add("PlayerEnteredVehicle", "ACF_Scanning_PlayerEnteredVehicle", function(ply)
        if scanningPlayers[ply] then
            scanning.EndScanning(ply)
            NetStart("ForceScanningEnd")
            net_WriteString("You cannot scan a target while being in a vehicle.")
            net_Send(ply)
        end
    end)

    hook.Add("Think", "ACF_Scanning_ScanEnts", function()
        local now = CurTime()
        local markedForRemoval = {}
        for kPlayer, vScanCtx in pairs(scanningPlayers) do
            if vScanCtx:Overdue(now) then
                if not IsValid(kPlayer) then
                    markedForRemoval[#markedForRemoval + 1] = kPlayer
                elseif not IsValid(vScanCtx.target) then
                    scanning.EndScanning(kPlayer)
                else
                    local filtered = {}

                    local ammoCrates = {}
                    local fuelTanks = {}
                    local nodrawEnts = {}

                    local inVehicle, vehicle = vScanCtx.target:InVehicle(), vScanCtx.target:GetVehicle()

                    for _, ent in ents_Iterator() do
                        if (IsValid(ent) and not ent:IsWeapon() and IsValid(ent:GetPhysicsObject()) and not ent:IsWorld() and ent:CPPIGetOwner() == vScanCtx.target) or (inVehicle and vehicle == ent) then
                            filtered[#filtered + 1] = ent
                            if ent:GetNoDraw() then
                                nodrawEnts[#nodrawEnts + 1] = ent
                            end
                        end
                    end

                    local contraption2entlist = {}
                    local noContraption = {}
                    for i = 1, #filtered do
                        local ent = filtered[i]
                        if IsValid(ent) then
                            local class = ent:GetClass()
                            if class == "acf_ammo" then
                                ammoCrates[#ammoCrates + 1] = ent
                            elseif class == "acf_fueltank" then
                                fuelTanks[#fuelTanks + 1] = ent
                            end
                            local contraption = ent:GetContraption()
                            if contraption == nil then
                                noContraption[#noContraption + 1] = ent
                            else
                                local list = contraption2entlist[contraption]
                                if list == nil then
                                    list = {}
                                    contraption2entlist[contraption] = list
                                end

                                list[#list + 1] = ent
                            end
                        end
                    end

                    NetStart("EntityPacket")
                    writeEntityPacket(NULL, nil, nil, noContraption, nodrawEnts)
                    net_WriteUInt(table.Count(contraption2entlist), 16)

                    for _, v in pairs(contraption2entlist) do
                        -- Baseplate determination
                        local bpC = {}
                        for _, e in ipairs(v) do
                            local ancestor = e:GetAncestor()
                            if e ~= ancestor then
                                if bpC[ancestor] == nil then
                                    bpC[ancestor] = 1
                                else
                                    bpC[ancestor] = bpC[ancestor] + 1
                                end
                            end
                        end

                        local selectedAncestor, selectedCount = NULL, 0
                        for ancestor, count in pairs(bpC) do
                            if count > selectedCount then
                                selectedAncestor = ancestor
                                selectedCount = count
                            end
                        end

                        if IsValid(selectedAncestor) then
                            local po = selectedAncestor:GetPhysicsObject()
                            local mi, ma
                            if IsValid(po) then
                                mi, ma = po:GetAABB()
                            end

                            writeEntityPacket(selectedAncestor, mi, ma, v, nil)
                        end
                    end

                    net_WriteUInt(#ammoCrates, 14)
                    for _, v in ipairs(ammoCrates) do
                        writeAmmoFuelPacket(v, v.AmmoType == "Refill")
                    end

                    net_WriteUInt(#fuelTanks, 14)
                    for _, v in ipairs(fuelTanks) do
                        writeAmmoFuelPacket(v, v.SupplyFuel == true)
                    end

                    net_Send(kPlayer)
                end
            end
        end

        for _, v in ipairs(markedForRemoval) do
            scanningPlayers[v] = nil
        end
    end)

    hook.Add("SetupPlayerVisibility", "ACF_Scanning_SetupPlayerVisibility", function(ply, _)
        local scanCtx = scanning.GetScanContext(ply)
        if scanCtx ~= nil and scanCtx.camPos ~= nil then
            AddOriginToPVS(scanCtx.camPos)
        end
    end)

    NetReceive("PVSUpdate", function(ply)
        local scanCtx = scanning.GetScanContext(ply)
        if scanCtx ~= nil then
            scanCtx.camPos = net_ReadVector()
        end
    end)
end
if CLIENT then
    local TEXT_ALIGN_TOP = TEXT_ALIGN_TOP
    local TEXT_ALIGN_LEFT = TEXT_ALIGN_LEFT
    local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
    local TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM
    local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
    -- draw.SimpleText without color objects
    local draw_SimpleText = draw.SimpleText
    local function draw_SimpleTextRGBA( text, font, x, y, r, g, b, a, xalign, yalign )
        text	= tostring( text )
        font	= font		or "DermaDefault"
        x		= x			or 0
        y		= y			or 0
        xalign	= xalign	or TEXT_ALIGN_LEFT
        yalign	= yalign	or TEXT_ALIGN_TOP

        surface.SetFont( font )
        local w, h = surface.GetTextSize( text )

        if ( xalign == TEXT_ALIGN_CENTER ) then
            x = x - w / 2
        elseif ( xalign == TEXT_ALIGN_RIGHT ) then
            x = x - w
        end

        if yalign == TEXT_ALIGN_CENTER then
            y = y - h / 2
        elseif yalign == TEXT_ALIGN_BOTTOM then
            y = y - h
        end

        surface.SetTextPos( math.ceil( x ), math.ceil( y ) )

        surface.SetTextColor(r, g, b, a or 255)
        surface.DrawText(text)

        return w, h
    end
    local function RegisterPanel(name, creation, base)
        local PANEL = {}

        creation(PANEL)
        vgui.Register("ACF_Scanner_" .. name, PANEL, base or "DPanel")
        ACF.Scanning[name] = PANEL
    end

    local function RegisterBaseFrameDerivative(name, creation)
        local PANEL = {}
        local BASE = ACF.Scanning["BaseFrame"]
        creation(PANEL, BASE)
        vgui.Register("ACF_Scanner_" .. name, PANEL, "ACF_Scanner_BaseFrame")
        ACF.Scanning[name] = PANEL
    end

    local function RegisterBasePanelDerivative(name, creation)
        local PANEL = {}
        local BASE = ACF.Scanning["BasePanel"]
        creation(PANEL, BASE)
        vgui.Register("ACF_Scanner_" .. name, PANEL, "ACF_Scanner_BasePanel")
        ACF.Scanning[name] = PANEL
    end

    surface.CreateFont("ACF_Scanner_Font1", {
        font = "Tahoma",
        size = 24,
        weight = 500,
        antialias = true
    })
    surface.CreateFont("ACF_Scanner_Font2", {
        font = "Tahoma",
        size = 18,
        weight = 500,
        antialias = true
    })
    surface.CreateFont("ACF_Scanner_Font3", {
        font = "Tahoma",
        size = 14,
        weight = 500,
        antialias = true
    })

    RegisterPanel("BaseFrame", function(PANEL)
        function PANEL:Init()

        end
        function PANEL:Paint(w, h)
            surface.SetDrawColor(25, 30, 40, 190)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(176, 185, 200, 225)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end
    end, "DFrame")
    RegisterPanel("BasePanel", function(PANEL)
        function PANEL:Init()
            self.bSize = 2
        end
        function PANEL:Paint(w, h)
            surface.SetDrawColor(25, 30, 40, 200)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(176, 185, 200, 225)
            surface.DrawOutlinedRect(0, 0, w, h, self.bSize)
        end
        function PANEL:SetBorderSize(bSize)
            self.bSize = bSize or 0
        end
    end)
    RegisterPanel("BaseButton", function(PANEL)
        function PANEL:Init()
            self.drawBackgroundWhenNotHovered = true
            self.__text = ""
            self.bSize = 1
            self:SetText("")
            function self:SetText(txt) self.__text = txt end
        end
        function PANEL:GetText() return self.__text end
        function PANEL:Paint(w, h)
            local hV, dP = self.Hovered, self.Depressed
            local m = dP and 0.7 or hV and 4.6 or 1

            if self.drawBackgroundWhenNotHovered or m ~= 1 then
                surface.SetDrawColor(25 * m, 28 * m, 32 * m, 168)
                surface.DrawRect(0, 0, w, h)
                surface.SetDrawColor(176 * m, 185 * m, 200 * m, 225)
                surface.DrawOutlinedRect(0, 0, w, h, self.bSize)
            end

            draw_SimpleTextRGBA(self:GetText(), "ACF_Scanner_Font1", w / 2, h / 2, 230 * m, 240 * m, 255 * m, 255, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        function PANEL:DrawBackgroundWhenNotHovered(doit)
            self.drawBackgroundWhenNotHovered = doit
        end
        function PANEL:SetBorderSize(bSize)
            self.bSize = bSize or 0
        end
    end, "DButton")

    RegisterBasePanelDerivative("MainButtons", function(PANEL, _)
        function PANEL:Init()
            self.Buttons = {}
            self:SetSize(256, 192)

            local function makeButton(txt, onPressed)
                local btn = self:Add("ACF_Scanner_BaseButton")

                btn:SetText(txt)
                self.Buttons[#self.Buttons + 1] = btn

                btn.DoClick = function(me)
                    onPressed(me, self)
                end
                return btn
            end
            makeButton("End Scanning", function(_, panel)
                local _ = panel.OnEndPressed and panel:OnEndPressed()
            end)

            makeButton("Teleport to Target", function(_, panel)
                local _ = panel.OnTeleportPressed and panel:OnTeleportPressed()
            end)

            makeButton("Open Legend", function(self, panel)
                local _ = panel.OnLegendPressed and panel:OnLegendPressed(self)
            end)
        end
        function PANEL:Paint()

        end
        function PANEL:PerformLayout(w, _)
            local scrW = ScrW()

            self:SetPos(scrW - w - 8, 8)

            local sizeH3 = 192 / #self.Buttons
            local margin = 4
            for k, v in ipairs(self.Buttons) do
                v:SetPos(margin, margin + ((k - 1) * sizeH3))
                v:SetSize(w - (margin * 2), sizeH3 - (margin * 2))
            end
        end
    end)

    RegisterBasePanelDerivative("TabSelector", function(PANEL, _)
        function PANEL:Init()
            self.Buttons = {}
            self.Tabs = {}
            self:SetSize(800, 48)

            local remove = self.Remove

            function self:Remove()
                for _, v in ipairs(self.Tabs) do
                    v:Remove()
                end
                remove(self)
            end

            local closeButton = self:Add("ACF_Scanner_BaseButton")
            closeButton:SetBorderSize(0)
            closeButton:DrawBackgroundWhenNotHovered(false)
            closeButton:SetText("X")
            self.closeButton = closeButton
        end
        function PANEL:AddTab(labelTxt)
            local tabSelector = self:Add("ACF_Scanner_BaseButton")

            tabSelector:SetBorderSize(0)
            tabSelector:DrawBackgroundWhenNotHovered(false)
            tabSelector:SetText(labelTxt)

            local tab = vgui.Create("ACF_Scanner_BasePanel")
            tab:SetTall(256)
            local tabSelectorPaint = tabSelector.Paint
            local t = self
            function tabSelector:Paint(w, h)
                tabSelectorPaint(self, w, h)
                if t.selectedTab == tab then
                    surface.SetDrawColor(200, 220, 255)
                    surface.DrawRect(4, h - 4, w - 8, 2)
                end
            end

            function tabSelector.DoClick()
                self:SelectTab(tab)
            end

            self.Buttons[#self.Buttons + 1] = tabSelector
            self.Tabs[#self.Tabs + 1] = tab

            tab:Hide()

            local realTabInside = tab:Add("DScrollPanel")
            realTabInside:Dock(FILL)
            realTabInside:DockMargin(8,4,8,4)

            function tab:AddLabel(lblTxt)
                local lbl = realTabInside:Add("DLabel")
                lbl:Dock(TOP)
                lbl:SetText(lblTxt)
                lbl:SetFont("ACF_Scanner_Font2")
            end

            function tab:PreserveScroll()
                self._scroll = self:GetVBar():GetScroll()
            end
            function tab:RestoreScroll()
                self:GetVBar():SetScroll(self._scroll or 0)
            end
            function tab:Clear()
                for _, v in ipairs(realTabInside:GetChildren()) do
                    v:Remove()
                end
            end

            function realTabInside:Paint()

            end

            function tab:Add(type)
                return realTabInside:Add(type)
            end

            return tab, tabSelector
        end
        function PANEL:SelectTab(tab)
            for _, v in ipairs(self.Tabs) do
                v:Hide()
            end
            if IsValid(tab) then
                tab:Show()
            end
            self.selectedTab = tab
        end
        function PANEL:PerformLayout(w, h)
            local scrW, _ = ScrW(), ScrH()

            self:SetPos(scrW - w - 16 - 256, 8)

            local margin = 4
            local size = 0

            for _, v in ipairs(self.Buttons) do
                v:SetPos(margin + size, margin)

                surface.SetFont("ACF_Scanner_Font1")
                local tX, _ = surface.GetTextSize(v:GetText())
                tX = tX + (margin * 6)
                v:SetSize(tX, h - (margin * 2))
                size = size + tX + margin
            end

            for _, v in ipairs(self.Tabs) do
                v:SetPos(self:GetX() + 2, self:GetY() + h + margin)
                v:SetWide(w - 4)
            end

            self.closeButton:SetPos(w - 32 - 4, 4)
            self.closeButton:SetSize(32, h - 8)

            self.closeButton.DoClick = function()
                self:SelectTab()
            end
        end
    end)

    RegisterBasePanelDerivative("ScrollSpeed", function(PANEL, BASE)
        function PANEL:Init()
            self.Buttons = {}
            self.Tabs = {}
            self:SetSize(256 - 8, 48)
        end

        function PANEL:PerformLayout(w, _)
            local scrW = ScrW()

            self:SetPos(scrW - w - 12, 8 + 192 + 8)
        end

        function PANEL:Paint(w, h)
            BASE.Paint(self, w, h)

            if self.GetScrollSpeed then
                local sp = self:GetScrollSpeed()
                draw_SimpleTextRGBA("Speed [Mouse Scroll]: " .. sp .. " su/s", "ACF_Scanner_Font2", w / 2, h / 2, 255, 255, 255, 255, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
                draw_SimpleTextRGBA("Press [C] to release the mouse pointer", "ACF_Scanner_Font3", w / 2, h / 2, 255, 255, 255, 255, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
            end
        end
    end)

    RegisterBaseFrameDerivative("Legend", function(PANEL, BASE)
        function PANEL:Init()
            local internal = self:Add("DPanel")
            internal:Dock(FILL)
            function internal:Paint(w, h)
                ACF.Scanning.DrawLegend(0, 0, w, h)
            end

            self:SetSizable(true)
            self:SetTitle("")
            self.btnMaxim:Hide()
            self.btnMinim:Hide()
            self.btnClose:Hide()

            function self:Paint(w, h)
                BASE.Paint(self, w, h)
                draw_SimpleTextRGBA("Legend", "DermaDefault", w / 2, 12, 255, 255, 255, 255, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
    end)

    local scanningPlayer = nil
    --local specificEntity = nil -- Not yet used
    local scanningEnts = {}
    local baseplates = {}
    local contraptions = {}
    local posOffset = Vector(-35, 0, 70)
    local angOffset = Angle(0, 0, 0)
    local mouseZoom = 300 -- source units a second
    local lastCalc = CurTime()

    local ammoCrateLookup, fuelTankLookup = {}, {}

    -- Support for multiple clipping methods
    -- Taken from Starfall and slightly optimized
    local ent2framenumber = {}
    local function getClips(ent)
        local framenum = FrameNumber()
        if ent2framenumber[ent] and ent2framenumber[ent].frame == framenum then
            return ent2framenumber[ent].clips
        end

        local clips = {}

        if ent.ClipData then
            for _, clip in pairs(ent.ClipData) do
                local normal = (clip[1] or clip.n):Forward()

                clips[#clips + 1] = {
                    local_ent = ent,
                    origin = Vector((clip[4] or Vector()) + normal * (clip[2] or clip.d)),
                    normal = normal
                }
            end
        end
        if ent.clips then
            for _, clip in pairs(ent.clips) do
                if clip.enabled ~= false then
                    local local_ent = false

                    if clip.localentid then
                        local_ent = Entity(clip.localentid)
                    elseif clip.entity then
                        local_ent = clip.entity
                    end

                    clips[#clips + 1] = {
                        local_ent = local_ent,
                        origin = clip.origin,
                        normal = clip.normal
                    }
                end
            end
        end

        ent2framenumber[ent] = {
            frame = framenum,
            clips = clips
        }
        return clips
    end
    local function LocalToWorldVector(ent, v)
        local localTransform = Matrix()
        localTransform:SetTranslation(v)

        local worldTransform = Matrix()
        worldTransform:SetAngles(ent:GetAngles())

        local localToWorld = worldTransform * localTransform
        return localToWorld:GetTranslation()
    end

    function scanning.GetMouseZoom()
        return mouseZoom
    end
    function scanning.SetMouseZoom(zoom)
        mouseZoom = zoom
    end
    function scanning.AddMouseZoom(zoom)
        mouseZoom = mouseZoom + zoom
        mouseZoom = math.Clamp(mouseZoom, 50, 1000000)
    end

    scanning.Panels = {}

    function scanning.AddPanel(pnlType)
        local p = vgui.Create(pnlType)
        scanning.Panels[p] = true
        return p
    end

    function scanning.ClearPanels()
        for k, _ in pairs(scanning.Panels) do
            if IsValid(k) then
                k:Remove()
            end
        end
    end

    function scanning.BuildPanel()
        scanning.ClearPanels()

        local mainButtons = scanning.AddPanel("ACF_Scanner_MainButtons")

        function mainButtons:OnEndPressed()
            scanning.EndScanning()
        end

        function mainButtons:OnTeleportPressed()
            posOffset = Vector(-35, 0, 70)
            angOffset = scanningPlayer:EyeAngles()
        end

        local legend
        function mainButtons:OnLegendPressed(btn)
            btn:SetText(IsValid(legend) and "Open Legend" or "Close Legend")
            if IsValid(legend) then
                legend:Remove()
                return
            end
            legend = scanning.AddPanel("ACF_Scanner_Legend")
            legend:SetSize(512, 600)
            legend:Center()
            legend:SetX(legend:GetX() + (ScrW() / 2) - (legend:GetWide() / 2) - 8)
        end

        local tabSelector = scanning.AddPanel("ACF_Scanner_TabSelector")

        local overview = tabSelector:AddTab("Overview") overview:AddLabel("WIP")

        local selector = tabSelector:AddTab("Select")
        selector:AddLabel(#contraptions .. " contraptions available to select.")

        local filter   = tabSelector:AddTab("Filter") filter:AddLabel("WIP")
        local weaponry = tabSelector:AddTab("Weaponry") weaponry:AddLabel("WIP")
        local mobility = tabSelector:AddTab("Mobility") mobility:AddLabel("WIP")
        local chips    = tabSelector:AddTab("Chips") chips:AddLabel("WIP")
        local other    = tabSelector:AddTab("Other") other:AddLabel("WIP")


        local speedvis = scanning.AddPanel("ACF_Scanner_ScrollSpeed")

        function speedvis:GetScrollSpeed()
            return scanning.GetMouseZoom()
        end
    end

    function scanning.BeginScanning(target)
        if LocalPlayer():InVehicle() then
            Derma_Message("You cannot scan a target while being in a vehicle. Exit the vehicle, then try again.", "Scanning Blocked", "OK")
        return end
        local canScan, whyNot = hook.Run("ACF_PreBeginScanning", LocalPlayer())
        if canScan == false then
            Derma_Message("Scanning has been blocked by the server: " .. (whyNot or "<no reason provided>"), "Scanning Blocked", "OK")
        return end

        NetStart("UpdatePlayer")
        net_WriteEntity(target)
        net_SendToServer()

        posOffset = Vector(-35, 0, 70)
        angOffset = EyeAngles()
        scanningPlayer = target

        scanning.BuildPanel()
    end

    function scanning.EndScanning()
        scanningPlayer = nil

        NetStart("EndScanning")
        net_SendToServer()
        scanning.ClearPanels()
    end
    scanning.EndScanning()

    function scanning.IsScannerActive()
        local isValid = IsValid(scanningPlayer)
        if not isValid and scanningPlayer ~= nil then
            scanning.EndScanning()
        end
        return isValid
    end

    local ent2bp = {}

    NetReceive("EntityPacket", function()
        local _, _, _, noContraptionEnts, _ = readEntityPacket() --5th is noDraw
        local am = net_ReadUInt(16)
        table.Empty(scanningEnts)
        table.Empty(baseplates)
        table.Empty(ammoCrateLookup)
        table.Empty(fuelTankLookup)
        table.Empty(contraptions)
        for i = 1, #noContraptionEnts do
            scanningEnts[#scanningEnts + 1] = noContraptionEnts[i]
        end
        for _ = 1, am do
            local baseplate, baseplateMI, baseplateMA, ents, _ = readEntityPacket()
            if IsValid(baseplate) then
                baseplates[#baseplates + 1] = baseplate
                ent2bp[baseplate] = {baseplateMI, baseplateMA}
            end
            for i2 = 1, #ents do
                scanningEnts[#scanningEnts + 1] = ents[i2]
            end

            contraptions[#contraptions + 1] = {baseplate = baseplate, baseplateMI = baseplateMI, baseplateMA = baseplateMA, ents = ents}
        end

        local ammoCrateLen = net_ReadUInt(14)
        for _ = 1, ammoCrateLen do
            local ent, isRefill = readAmmoFuelPacket()
            ammoCrateLookup[ent] = isRefill
        end
        local fuelTankLen = net_ReadUInt(14)
        for _ = 1, fuelTankLen do
            local ent, isRefill = readAmmoFuelPacket()
            fuelTankLookup[ent] = isRefill
        end
    end)
    NetReceive("ForceScanningEnd", function()
        local why = net_ReadString() or "No reason provided."
        notification.AddLegacy("The server ended your scanning session: " .. why, NOTIFY_ERROR, 7)
        scanning.EndScanning()
    end)

    local inChat = false
    hook.Add("StartChat", "ACF_Scanning_ChatCheck", function()
        inChat = true
    end)
    hook.Add("FinishChat", "ACF_Scanning_ChatCheck", function()
        inChat = false
    end)

    local calcview_lastPos, calcview_lastAng
    timer.Create("ACF_Scanning_UpdateServerPVS", 0.5, 0, function()
        if not scanning.IsScannerActive() then return end

        NetStart("PVSUpdate")
        net_WriteVector(calcview_lastPos)
        net_SendToServer()
    end)

    hook.Add("CalcView", "ACF_Scanning_CalcView", function(_, pos, ang, fov, znear, zfar)
        if not scanning.IsScannerActive() then return end

        local xMove, yMove, zMove = 0, 0, 0

        local appliedZoom = mouseZoom * (CurTime() - lastCalc)

        if not inChat then
            if input.IsKeyDown(KEY_W)        then xMove = xMove + appliedZoom end
            if input.IsKeyDown(KEY_S)        then xMove = xMove - appliedZoom end
            if input.IsKeyDown(KEY_A)        then yMove = yMove + appliedZoom end
            if input.IsKeyDown(KEY_D)        then yMove = yMove - appliedZoom end
            if input.IsKeyDown(KEY_LCONTROL) then zMove = zMove - appliedZoom end
            if input.IsKeyDown(KEY_SPACE)    then zMove = zMove + appliedZoom end
        end

        ang = angOffset
        posOffset = posOffset + (
            (ang:Forward() * xMove) +
            (ang:Right() * -yMove) +
            vector_up * zMove
        )

        pos = scanningPlayer:GetPos() + posOffset

        lastCalc = CurTime()

        calcview_lastPos = pos
        calcview_lastAng = ang
        return {
            origin = pos,
            angles = ang,
            fov = fov,
            znear = znear,
            zfar = zfar,
            drawviewer = scanningPlayer == LocalPlayer()
        }
    end)

    hook.Add("PlayerBindPress", "ACF_Scanner_BlockInputs", function(_, bind, _, _)
        if scanning.IsScannerActive() and (bind ~= "messagemode") then
            return true
        end
    end)

    local screenClickerEnabledBecauseOfUs = false
    hook.Add("PlayerButtonDown", "ACF_Scanner_BlockInputs", function(_, btn)
        if scanning.IsScannerActive() then
            if btn == KEY_C then
                screenClickerEnabledBecauseOfUs = true
                gui.EnableScreenClicker(true)
            end
            return true
        end
    end)
    hook.Add("PlayerButtonUp", "ACF_Scanner_BlockInputs", function(_, btn)
        if btn == KEY_C and screenClickerEnabledBecauseOfUs then
            gui.EnableScreenClicker(false)
            screenClickerEnabledBecauseOfUs = false
        end
    end)

    hook.Add("CreateMove", "ACF_Scanner_BlockInputs", function(cmd)
        if scanning.IsScannerActive() then
            if lastAng == nil then
                lastAng = cmd:GetViewAngles()
            end

            local delta = cmd:GetViewAngles() - lastAng
            angOffset = angOffset + delta
            angOffset.pitch = math.Clamp(angOffset.pitch, -90, 90)
            cmd:SetViewAngles(lastAng)
            lastAng = cmd:GetViewAngles()

            local wheel = cmd:GetMouseWheel()
            if wheel ~= 0 then
                scanning.AddMouseZoom(50 * wheel)
            end
        else
            lastAng = nil
        end
    end)

    local wireframe = Material("models/wireframe")
    local colorMat = Material("models/debug/debugwhite")
    local physMeshCache = {}

    local function drawEntityNoOutline(ent, color)
        if not IsValid(ent) then return end

        render.MaterialOverride(colorMat)
        render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
        render.SetBlend(0.15)
        render.DepthRange(0, 0.01)
        render.SetLightingMode(1)
        ent:DrawModel()

        render.MaterialOverride()
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(1)
        render.DepthRange(0, 1)
        render.SetLightingMode(0)
    end

    local function drawEntity(ent, color)
        if not IsValid(ent) then return end

        render.MaterialOverride(colorMat)
        render.DepthRange(0, 0.0001)
        render.SetLightingMode(2)

        render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
        render.SetBlend(0.4)
        --ent:DrawModel()

        local m = Matrix()
        m:Translate(Vector(0, 0, 200))
        cam.PushModelMatrix(m)
        ent:DrawModel()
        cam.PopModelMatrix()

        render.MaterialOverride()
        render.SetColorModulation(1, 1, 1)
        render.SetBlend(1)
        render.DepthRange(0, 1)
        render.SetLightingMode(0)
    end

    local function drawPhysMesh(ent, color)
        if not IsValid(ent) then return end
        local physobj = ent:GetPhysicsObject()
        if not IsValid(physobj) then return end

        if not physMeshCache[ent] or physMeshCache[ent]:expired() then
            local mvs = physobj:GetMesh()
            local rm = Mesh()
            rm:BuildFromTriangles(mvs)

            physMeshCache[ent] = {
                birth = CurTime(),
                mesh = rm,
                expired = function(self)
                    return (CurTime() - self.birth) > 2
                end
            }
        end

        local m = Matrix()
        m:SetTranslation(ent:GetPos())
        m:SetAngles(ent:GetAngles())
        cam.PushModelMatrix(m)

        -- This renders the physical mesh as a solid mass using stencils. 
        -- The stencil operations are so it can render the physmesh with color as other methods didnt work for me.
        -- Basically just draws the model to a stencil mask and that model renders with the color given to this method
        render.SetStencilWriteMask(0xFF)
        render.SetStencilTestMask(0xFF)
        render.SetStencilReferenceValue(0)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilPassOperation(STENCIL_REPLACE)
        render.SetStencilFailOperation(STENCIL_KEEP)
        render.SetStencilZFailOperation(STENCIL_KEEP)
        render.ClearStencil()

        render.SetStencilEnable(true)
        render.SetStencilReferenceValue(1)
        render.SetStencilCompareFunction(STENCIL_ALWAYS)
        render.SetStencilZFailOperation(STENCIL_REPLACE)
        render.SetMaterial(wireframe)

        physMeshCache[ent].mesh:Draw()

        render.SetStencilCompareFunction(STENCIL_EQUAL)
        render.ClearBuffersObeyStencil(color.r, color.g, color.b, color.a, true);

        render.SetStencilEnable(false)

        cam.PopModelMatrix()
    end

    local function drawBounds(ent, scanDef)
        if not IsValid(ent) then return end
        local mi, ma
        if not IsValid(ent:GetPhysicsObject()) then
            if ent2bp[ent] then
                mi = ent2bp[ent][1]
                ma = ent2bp[ent][2]
            end
        else
            mi, ma = ent:GetPhysicsObject():GetAABB()
        end

        if mi == nil or ma == nil then return end

        render.SetColorMaterial()
        render.DepthRange(0, 0.01)
            render.DrawBox(ent:GetPos(), ent:GetAngles(), mi, ma, scanDef.colorBoundsInside)
            render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), mi, ma, scanDef.colorBounds)
        render.DepthRange(0, 1)
    end

    --local eyetrace_calc = nil
    local player_mt = FindMetaTable("Player")
    if not ACF_SCANNING_PLMT_GETEYETRACE then
        ACF_SCANNING_PLMT_GETEYETRACE = player_mt.GetEyeTrace
    end

    local plmt_eyetrace = ACF_SCANNING_PLMT_GETEYETRACE
    local lastFrame, lastFrameTrace

    function player_mt:GetEyeTrace()
        if not scanning.IsScannerActive() then
            return plmt_eyetrace(self)
        end
        local frameNum = FrameNumber()
        if lastFrame == frameNum then
            return lastFrameTrace
        end

        lastFrame = frameNum
        local tr = util.TraceLine{
            start = calcview_lastPos,
            endpos = calcview_lastPos + (calcview_lastAng:Forward() * 32768),
            filter = self
        }
        lastFrameTrace = tr
        return tr
    end

    local baseplateColorVC = Color(50, 255, 50, 70)
    local baseplateConnectionColor = Color(215, 255, 215)
    local function VisualizeClips(ent)
        if not IsValid(ent) then return end
        local clips = getClips(ent)
        local clipL = #clips
        if clipL == 0 then return end

        local clipR = 30
        if clipL > 0 then
            for _, clipPlane in ipairs(clips) do
                render.DepthRange(0, 0.01)
                local localEnt = clipPlane.local_ent
                local isLocalEntValid = IsValid(localEnt)
                local origin = isLocalEntValid and localEnt:LocalToWorld(clipPlane.origin) or clipPlane.origin
                local normal = (isLocalEntValid and LocalToWorldVector(localEnt, clipPlane.normal) or clipPlane.normal)
                local angles = normal:Angle()
                render.DrawBox(
                    origin,
                    angles,
                    Vector(-0.02, -clipR, -clipR),
                    Vector(0.02, clipR, clipR),
                    baseplateColorVC
                    )

                local c1 = LocalToWorld(Vector(0, -clipR, -clipR), angle_zero, origin, angles)
                local c2 = LocalToWorld(Vector(0, -clipR, clipR),  angle_zero, origin, angles)
                local c3 = LocalToWorld(Vector(0, clipR, clipR),   angle_zero, origin, angles)
                local c4 = LocalToWorld(Vector(0, clipR, -clipR),  angle_zero, origin, angles)
                local c5 = LocalToWorld(Vector(24, -clipR / 4, 0), angle_zero, origin, angles)
                local c6 = LocalToWorld(Vector(24, clipR / 4, 0),  angle_zero, origin, angles)

                render.SetColorMaterial()
                local function drawOutlineBeam(startP, endP, width, color)
                    render.DrawBeam(startP, endP, width + 0.5, 0, 1, color_black)
                    render.DrawBeam(startP, endP, width, 0, 1, color)
                end
                if isLocalEntValid then
                    local p = localEnt:GetPos()
                    drawOutlineBeam(c1, p, 0.5, baseplateConnectionColor)
                    drawOutlineBeam(c2, p, 0.5, baseplateConnectionColor)
                    drawOutlineBeam(c3, p, 0.5, baseplateConnectionColor)
                    drawOutlineBeam(c4, p, 0.5, baseplateConnectionColor)

                    drawOutlineBeam(c1, c2, 0.5, baseplateConnectionColor)
                    drawOutlineBeam(c2, c3, 0.5, baseplateConnectionColor)
                    drawOutlineBeam(c3, c4, 0.5, baseplateConnectionColor)
                    drawOutlineBeam(c4, c1, 0.5, baseplateConnectionColor)

                    drawOutlineBeam(origin, origin + (normal * 32), 0.5, baseplateConnectionColor)
                    drawOutlineBeam(origin + (normal * 32), c5, 0.5, baseplateConnectionColor)
                    drawOutlineBeam(origin + (normal * 32), c6, 0.5, baseplateConnectionColor)
                end
                render.DepthRange(0, 1)
            end
        end
    end
    hook.Add("PostDrawTranslucentRenderables", "ACF_Scanner_Render3D", function(_, _, drawing3DSkybox)
        if drawing3DSkybox then return end
        if scanning.IsScannerActive() then
            for _, ent in ipairs(scanningEnts) do
                if IsValid(ent) then
                    local class = ent:GetClass()
                    local scanDef = scannerTypes[class]
                    if scanDef ~= nil then
                        if scanDef.drawModelOverlay then
                            drawEntity(ent, scanDef.colorEntity)
                        end
                        if scanDef.drawBounds then
                            drawBounds(ent, scanDef)
                        end
                        if scanDef.drawMesh then
                            drawEntityNoOutline(ent, scanDef.colorEntityInside)
                            drawPhysMesh(ent, scanDef.color)
                        end
                        VisualizeClips(ent)
                    end
                end
            end

            for _, ent in ipairs(baseplates) do
                drawEntityNoOutline(ent, baseplateC.colorEntityInside)
                drawPhysMesh(ent, baseplateC.color)
                drawBounds(ent, baseplateC)
                VisualizeClips(ent)
            end
            render.DepthRange(0, 1)
        end
    end)

    surface.CreateFont("ACF_Scanner_FontPxMed", {
        font = "Tahoma",
        size = 22,
        antialias = true
    })
    surface.CreateFont("ACF_Scanner_FontPxSmallOutlined", {
        font = "Tahoma",
        size = 15,
        antialias = true,
        outline = true
    })

    local collision_group_conv = {
        [1] = "Debris",
        [2] = "Debris Trigger",
        [3] = "Interactive Debris",
        [4] = "Interactive",
        [5] = "Player",
        [6] = "Breakable Glass",
        [7] = "Vehicle",
        [8] = "Player Movement",
        [9] = "NPC",
        [10] = "In Vehicle",
        [11] = "Weapon",
        [12] = "Vehicle Clip",
        [13] = "Projectile",
        [14] = "Door Blocker",
        [15] = "Passable Door",
        [16] = "Dissolving",
        [17] = "Pushaway",
        [18] = "NPC Actor",
        [19] = "NPC Scripted"
    }

    local markerSizeW, markerSizeH = 39, 28
    local cornerX = 2
    local cornerY = 2
    local corners = {
        { -- top-left
            x = (-markerSizeW / 2) - (cornerX * 2), y = (-markerSizeH / 2) - cornerY,
            alignX = TEXT_ALIGN_RIGHT, alignY = TEXT_ALIGN_TOP,
            method = function(_)

            end
        },
        { -- top-right
            x = (markerSizeW / 2) + cornerX, y = (-markerSizeH / 2) - cornerY,
            alignX = TEXT_ALIGN_LEFT, alignY = TEXT_ALIGN_TOP,
            method = function(ent)
                local group = ent:GetCollisionGroup()
                if collision_group_conv[group] then
                    return "[" .. group .. "] " .. collision_group_conv[group]
                end
            end
        },
        { -- bottom-left
            x = (-markerSizeW / 2) - (cornerX * 2), y = (markerSizeH / 2) + cornerY,
            alignX = TEXT_ALIGN_RIGHT, alignY = TEXT_ALIGN_BOTTOM,
            method = function(ent)
                local clips = getClips(ent)
                local clipL = #clips
                if clipL > 0 then
                    return clipL .. " clip" .. (clipL > 1 and "s" or "")
                end
            end
        },
        { -- bottom-right
            x = (markerSizeW / 2) + cornerX, y = (markerSizeH / 2) + cornerY,
            alignX = TEXT_ALIGN_LEFT, alignY = TEXT_ALIGN_BOTTOM,
            method = function(ent)
                if not ent:IsSolid() then
                    return "NS"
                end
            end
        }
    }

    local function DrawMarker(scanDef, pX, pY, ent)
        local md2W, md2H = markerSizeW / 2, markerSizeH / 2

        surface.SetDrawColor(scanDef.colorMarkerBackground)
        surface.DrawRect(pX - md2W, pY - md2H, markerSizeW, markerSizeH)
        surface.SetDrawColor(scanDef.colorMarkerBorder)
        surface.DrawOutlinedRect(pX - md2W, pY - md2H, markerSizeW, markerSizeH, 2)

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawOutlinedRect((pX - md2W) - 1, (pY - md2H) - 1, markerSizeW + 2, markerSizeH + 2)
        surface.DrawOutlinedRect((pX - md2W) + 2, (pY - md2H) + 2, markerSizeW - 4, markerSizeH - 4)

        draw_SimpleText(scanDef.marker, "ACF_Scanner_FontPxMed", pX, pY, scanDef.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if IsValid(ent) then
            for _, v in ipairs(corners) do
                local text = v.method(ent)
                if text ~= "" and text ~= nil then
                    draw.SimpleText(text, "ACF_Scanner_FontPxSmallOutlined", pX + v.x, pY + v.y, scanDef.colorMarkerText, v.alignX, v.alignY)
                end
            end
        end
    end
    scanning.DrawMarker = DrawMarker

    function scanning.DrawLegend(x, y, w, h)
        w = w or (ScrW() - x)
        h = h or (ScrH() - y)

        local xOffset, yOffset = 0, 0

        local markersPerLine = (h - 34) / 34

        local pageTextSizes = {}
        local wipTextSize = 0
        surface.SetFont("ACF_Scanner_FontPxMed")

        for _, scanDef in ipairs(scannerTypesSeq) do
            local tX, _ = surface.GetTextSize(scanDef.nickname)
            if tX > wipTextSize then wipTextSize = tX end

            yOffset = yOffset + 1
            if yOffset >= markersPerLine then
                xOffset = xOffset + 1
                yOffset = 0
                pageTextSizes[xOffset] = wipTextSize
                wipTextSize = 0
            end
        end

        pageTextSizes[xOffset + 1] = wipTextSize

        xOffset, yOffset = 0, 0
        local xOffsetFull = 0

        x = x + (markerSizeW / 2)
        y = y + (markerSizeH / 2)
        for _, scanDef in ipairs(scannerTypesSeq) do
            DrawMarker(scanDef, x + xOffsetFull, y + (yOffset * 34))
            draw.SimpleText(scanDef.nickname, "ACF_Scanner_FontPxMed", x + xOffsetFull + (markerSizeW / 2) + 10, y + (yOffset * 34), scanDef.colorLegendText, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            yOffset = yOffset + 1
            if yOffset >= markersPerLine then
                xOffsetFull = xOffsetFull + pageTextSizes[xOffset + 1] + 64
                xOffset = xOffset + 1
                yOffset = 0
            end
        end
    end

    hook.Add("HUDPaint", "ACF_Scanner_Render2D", function()
        if scanning.IsScannerActive() then
            local pXY = (scanningPlayer:GetPos() + Vector(0, 0, scanningPlayer:InVehicle() and 0 or 30)):ToScreen()
            DrawMarker(playerC, pXY.x, pXY.y)
            for _, ent in ipairs(scanningEnts) do
                if IsValid(ent) then
                    local class = ent:GetClass()
                    local scanDef = scannerTypes[class]
                    if scanDef ~= nil then
                        if scanDef.drawMarker then
                            if class == "acf_ammo" and ammoCrateLookup[ent] then
                                scanDef = ammoRefill
                            elseif class == "acf_fueltank" and fuelTankLookup[ent] then
                                scanDef = fuelRefill
                            end
                            local pXY = ent:GetPos():ToScreen()
                            local pX, pY = pXY.x, pXY.y
                            DrawMarker(scanDef, pX, pY, ent)
                        end
                        if scanDef.drawOverlay then
                            cam.Start3D()
                            render.SetColorMaterial()
                            ent:DrawOverlay()
                            cam.End3D()
                        end
                    end
                end
            end

            for _, ent in ipairs(baseplates) do
                if IsValid(ent) then
                    local pXY = ent:GetPos():ToScreen()
                    local pX, pY = pXY.x, pXY.y
                    DrawMarker(baseplateC, pX, pY, ent)
                end
            end
        end
    end)
end