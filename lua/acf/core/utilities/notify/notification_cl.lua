local Notify = ACF.Utilities.Notify
local notification = notification

local MAX_BUTTON_BITS = 4

-- This sucks but there's no better way to do it right now.
local _, Notices = debug.getupvalue(notification.Kill, 1)

function Notify.Display(Data)
    local Parent = nil
    if GetOverlayPanel then Parent = GetOverlayPanel() end

    local Panel = vgui.Create("ACF_NoticePanel", Parent)
    Panel.StartTime = SysTime()
    Panel.Length = Data.Duration
    Panel:SetData(Data)
    Panel.VelX = -5
    Panel.VelY = 0
    Panel.fx = ScrW() + 200
    Panel.fy = ScrH()
    Panel:SetAlpha(255)
    Panel:SetPos(Panel.fx, Panel.fy)

    table.insert(Notices, Panel)
end

do -- Receiving new notifications
    net.Receive("ACF_Notify", function()
        local Title = Notify.Net_ReadFormattedText()
        local Description = Notify.Net_ReadFormattedText()
        local Duration = net.ReadFloat()
        local Icon = net.ReadString()
        local TargetEntityIdx = net.ReadUInt(MAX_EDICT_BITS)
        local TargetPhysObjIdx = net.ReadInt(10)
        local ButtonCount = net.ReadUInt(MAX_BUTTON_BITS)
        local Buttons = {}

        for I = 1, ButtonCount do
            local Button = {}
            Button.Text = Notify.Net_ReadFormattedText()
            Button.Pulsing = net.ReadBool()
            Button.Action = net.ReadString()
            Button.Params = {}
            local NumParams = net.ReadUInt(6)
            for I2 = 1, NumParams do
                Button.Params[I2] = net.ReadType()
            end
            Buttons[I] = Button
        end

        -- Use the received data
        CurrentNotification = {
            Title = Title,
            Description = Description,
            Duration = Duration,
            Icon = Icon,
            Buttons = Buttons,
            TargetEntity = TargetEntityIdx,
            TargetPhysObj = TargetPhysObjIdx,
        }

        local TargetEnt = Entity(TargetEntityIdx)
        if IsValid(TargetEnt) then
            Notify.SingleEntityImpulse(TargetEnt)
        end

        Notify.Display(CurrentNotification)
    end)
end

surface.CreateFont("ACF_GModNotify_Description", {
    font	= "Arial",
    size	= 16,
    weight	= 0,
    extended = true
})

-- Notifications can use these shared helper functions to highlight entities with the halo system
-- Perhaps we should do our own thing instead of halos, but its abstracted away so we can do that later
-- if its determined to be worth it
do
    local Entities = {}
    local HoveredEntities = {}

    local TempEntityBufferSustained = {}
    local HaloColor = Color(210, 222, 255)
    hook.Add("PreDrawHalos", "ACF_DrawNotificationHolos", function()
        if #Entities == 0 and not next(HoveredEntities) then return end

        local DeltaTime = RealFrameTime()
        local Time      = SysTime()
        for I = #Entities, 1, -1 do
            local EntityData = Entities[I]
            if not IsValid(EntityData.Ent) or EntityData.Time <= 0 then
                table.remove(Entities, I)
            else
                local AnimT = math.ease.InCubic(EntityData.Time)
                halo.Add({EntityData.Ent}, EntityData.Color, 5 * AnimT, 5 * AnimT, 2, true, true)
                EntityData.Color.a = 255 * AnimT
                EntityData.Time = EntityData.Time - DeltaTime
            end
        end

        TempEntityBufferSustained[1] = nil
        local I = 1
        for Entity in pairs(HoveredEntities) do
            if IsValid(Entity) then
                TempEntityBufferSustained[I] = Entity
            end
        end
        TempEntityBufferSustained[I + 1] = nil -- null terminate
        HaloColor.a = 255 * math.Remap(math.sin(Time * 7), -1, 1, 0.6, 1)
        halo.Add(TempEntityBufferSustained, HaloColor, 3, 3, 2, true, true)
        HaloColor.a = 255
    end)

    function Notify.SingleEntityImpulse(Entity, Color)
        if not IsValid(Entity) then return end
        Entities[#Entities + 1] = {
            Ent = Entity,
            Color = (Color or HaloColor):Copy(),
            Time = 1
        }
    end

    function Notify.StartEntityPulse(Entity)
        HoveredEntities[Entity] = true
    end

    function Notify.StopEntityPulse(Entity)
        HoveredEntities[Entity] = nil
    end
end

-- Another notification library helper...
do
    function Notify.InterpViewAngleTo(Target, Duration, OnComplete, CompleteThreshold)
        Duration = Duration or 0.3
        CompleteThreshold = CompleteThreshold or 1

        local View = render.GetViewSetup()
        local Start = View.angles
        local StartTime = CurTime()

        hook.Add("Think", "ACF_NotifyInterpViewAngleTo", function()
            local Frac = math.Clamp((CurTime() - StartTime) / Duration, 0, 1)
            local Ang = LerpAngle(math.ease.InOutCubic(Frac), Start, Target)
            LocalPlayer():SetEyeAngles(Ang)

            if Frac >= CompleteThreshold and OnComplete then
                OnComplete()
                OnComplete = nil
            end
            if Frac >= 1 then
                hook.Remove("Think", "ACF_NotifyInterpViewAngleTo")
            end
        end)
    end
    hook.Remove("Think", "ACF_NotifyInterpViewAngleTo")
end

-- Toast notifications (mostly for notification errors)
do
    local ACF_NotificationToast = {}
    local ACF_NotificationToasts = {}

    function ACF_NotificationToast:SetText(Text)
        self.Text = Text
        surface.SetFont("DermaDefault")
        local W, H = surface.GetTextSize(Text)
        self.DesiredW, self.DesiredH = W + 8 + H + 16, H + 8
    end

    function ACF_NotificationToast:SetType(Type)
        self.Icon = Material("icon16/" .. Type .. ".png")
    end

    function ACF_NotificationToast:SetDeathTime(Time)
        self.DeathTime = Time
        self.Birth = RealTime()
        self.TTL = Time - self.Birth
    end

    function ACF_NotificationToast:GetTimeLeftToLive()
        return self.TTL - (RealTime() - self.Birth)
    end

    function ACF_NotificationToast:GetLifeTime()
        return RealTime() - self.Birth
    end

    function ACF_NotificationToast:Paint(W, H)
        local M = surface.GetAlphaMultiplier()
        surface.SetAlphaMultiplier(
            math.ease.OutQuad(math.Clamp(self:GetLifeTime() * 1.7, 0, 1))
            * math.ease.InQuart(math.Clamp(self:GetTimeLeftToLive() * 1.7, 0, 1))
        )

        DPanel.Paint(self, W, H)
        draw.SimpleText(self.Text, "DermaDefault", (W / 2) + (H / 2), H / 2, self:GetSkin().Colours.Label.Dark, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        surface.SetMaterial(self.Icon)
        surface.DrawTexturedRect(2 + 4, 2, H - 4, H - 4)
        surface.SetAlphaMultiplier(M)
    end

    function ACF_NotificationToast:Think()
        if not self.DeathTime then
            ErrorNoHaltWithStack("No death time???")
            self:Remove()
            return
        end

        if RealTime() > self.DeathTime then
            self:Remove()
            return
        end

        local LifeMult = math.Clamp(self:GetLifeTime() * 2, 0, 1)
        self:SetSize(self.DesiredW * math.ease.OutBack(LifeMult), self.DesiredH)
    end

    hook.Add("Think", "ACF_NotificationToasts_Think", function()
        for Panel in pairs(ACF_NotificationToasts) do
            local Parent = IsValid(Panel) and Panel.Parent
            if IsValid(Panel) and Parent ~= nil then
                local PnlW, PnlH = Panel:GetWide(), Panel:GetTall()
                local X, Y = Panel.DesiredX, Panel.DesiredY
                if Parent ~= false and IsValid(Parent) then
                    if Panel.RelativeCoords then
                        X, Y = (X * Parent:GetWide()), (Y * Parent:GetTall())
                    end
                    X, Y = Parent:LocalToScreen(X, Y)
                end

                Y = Y + math.ease.InQuad(math.Clamp(Panel:GetTimeLeftToLive() * 2, 0, 1))
                Panel:SetPos(X - (PnlW / 2), Y - (PnlH / 2))
            else
                ACF_NotificationToasts[Panel] = nil
            end
        end
    end)
    vgui.Register("ACF_NotificationToast", ACF_NotificationToast, "DPanel")

    function Notify.ToastAtXY(X, Y, Text, Type, Time)
        local Panel = vgui.Create("ACF_NotificationToast", GetOverlayPanel and GetOverlayPanel() or nil)
        Panel.DesiredX = X
        Panel.Parent   = false
        Panel.DesiredY = Y
        Panel:SetText(Text)
        Panel:SetType(Type)
        Panel:SetDeathTime(RealTime() + (Time or 5))
        ACF_NotificationToasts[Panel] = true
    end

    function Notify.ToastAtParent(Parent, X, Y, Relative, Text, Type, Time)
        local Panel = vgui.Create("ACF_NotificationToast", GetOverlayPanel and GetOverlayPanel() or nil)
        Panel.DesiredX = X
        Panel.Parent   = Parent
        Panel.RelativeCoords = Relative or false
        Panel.DesiredY = Y
        Panel:SetText(Text)
        Panel:SetType(Type)
        Panel:SetDeathTime(RealTime() + (Time or 5))
        ACF_NotificationToasts[Panel] = true
    end
end

do
    local PANEL = {}

    local function PulsingPaintFunction(self, w, h)
        DButton.Paint(self, w, h)
        local Skin = self:GetSkin()
        surface.SetAlphaMultiplier(math.Remap(math.sin(CurTime() * 7), -1, 1, 0.6, 1))
        Skin.tex.Selection(0, 0, w + 6, h)
    end

    local function CallActionButtonFunction(self)
        Notify.CallAction(self.ActionContext)
    end

    local function DoErrorButtonFunction(self, Text)
        Notify.ToastAtParent(self, 0.5, 1.5, true, Text, "error")
    end

    local function SetupButtonFunctions(RealButton, ButtonData)
        RealButton.DoClick = CallActionButtonFunction
        RealButton.DoError = DoErrorButtonFunction

        if ButtonData.Pulsing then
            RealButton.Paint = PulsingPaintFunction
        end
    end

    function PANEL:Init()
        self.Progress = true
        self:DockPadding( 3, 3, 3, 3 )

        self.Label = vgui.Create("DLabel", self)
        self.Label:SetFont("GModNotify")
        self.Label:SetTextColor(color_white)
        self.Label:SetExpensiveShadow(1, Color( 0, 0, 0, 200 ))
        self.Label:SetContentAlignment(4)

        self.Desc = vgui.Create("DLabel", self)
        self.Desc:SetFont("ACF_GModNotify_Description")
        self.Desc:SetTextColor(color_white)
        self.Desc:SetExpensiveShadow(1, Color( 0, 0, 0, 200 ))
        self.Desc:SetContentAlignment(7)

        self:SetBackgroundColor( Color( 20, 20, 20, 255 * 0.6 ))
        self:SizeToContents()
        self.Buttons = {}
    end

    local function ApplySizing(wide, tall, Label)
        surface.SetFont(Label:GetFont())
        local tw, th = surface.GetTextSize(Label:GetText())
        wide = math.max(wide, tw + 32)
        tall = tall + th
        return wide, tall
    end

    function PANEL:PerformLayout(W, H)
        local LW, LH = ApplySizing(0, 0, self.Label)
        local DW, DH = ApplySizing(0, 0, self.Desc)

        if IsValid(self.Image) then
            self.Image:SetPos(6, 6)
            self.Image:SetSize(20, 20)

            self.Label:SetPos(24 + 8, 6)
            self.Label:SetSize(LW, LH)
            self.Desc:SetPos(8, 8 + LH)
            self.Desc:SetSize(DW, DH)
        else
            self.Label:SetPos(4, 4)
            self.Label:SetSize(LW, LH)
            self.Desc:SetPos(8, 4 + LH)
            self.Desc:SetSize(DW, DH)
        end

        local ButtonGutterPadding = 16
        local ButtonGutterX = ButtonGutterPadding
        local ButtonGutterY = H - 48
        local ButtonGutterWidth = W - (ButtonGutterPadding * 2)

        local SpaceInbetweenButtons = 4

        local PerButtonWidth = ButtonGutterWidth / #self.Buttons
        for I, Button in ipairs(self.Buttons) do
            Button:SetPos(ButtonGutterX + ((I - 1) * PerButtonWidth) + SpaceInbetweenButtons, ButtonGutterY)
            Button:SetSize(PerButtonWidth - (SpaceInbetweenButtons * 2), 24)
        end
    end

    function PANEL:SizeToContents()
        local wide, tall = 0, 0

        wide, tall = ApplySizing(wide, tall, self.Label)
        wide, tall = ApplySizing(wide, tall, self.Desc)

        if IsValid(self.Image) then
            wide = wide + 24
        end

        local HasButtons = self.Buttons ~= nil and #self.Buttons ~= 0

        tall = tall + 32
        if HasButtons then
            tall = tall + 32
        end
        self:SetSize(wide, tall)
        self.DesiredWidth = wide
        self.DesiredHeight = tall
        self:InvalidateLayout()
    end

    function PANEL:SetData(Data)
        self.DataReference = Data
        self.TargetEntity = Entity(Data.TargetEntity)

        for _, Btn in ipairs(self.Buttons) do Btn:Remove() end
        self.Buttons = {}

        self.Label:SetText(string.format(unpack(Data.Title)))
        self.Desc:SetText(string.format(unpack(Data.Description)))

        if Data.Icon then
            local T = type(Data.Icon)
            if T == "string" and #Data.Icon > 0 then
                self.Image = vgui.Create( "DImageButton", self )
                self.Image:SetMaterial(Material(Data.Icon, "smooth"))
                self.Image:SetSize( 32, 32)
                self.Image.DoClick = function()
                    self.StartTime = 0
                end
                self.Image:MoveToBack()
            end
        end

        for _, ButtonData in ipairs(Data.Buttons) do
            local RealButton = vgui.Create("DButton", self)
            self.Buttons[#self.Buttons + 1] = RealButton

            RealButton:SetBright(false)
            RealButton.ActionContext = Notify.CreateActionContext(self, ButtonData.Params, RealButton, ButtonData.Action) -- This object gets reused for a few button callbacks.
            -- So this gets stored in the button itself so it doesnt have to be remade all the time

            RealButton:SetText(string.format(unpack(ButtonData.Text)))
            SetupButtonFunctions(RealButton, ButtonData)
        end

        self:SizeToContents()
    end

    function PANEL:Think()
        -- If the player is hovering over this, then keep it alive
        local RecursiveHoverCheck = false
        local RecursiveHoverCheckElement = vgui.GetHoveredPanel()
        while IsValid(RecursiveHoverCheckElement) do
            if RecursiveHoverCheckElement == self then
                RecursiveHoverCheck = true
                break
            end

            RecursiveHoverCheckElement = RecursiveHoverCheckElement:GetParent()
        end

        local TargetEntity = self.TargetEntity
        if RecursiveHoverCheck then
            self.StartTime = self.StartTime + RealFrameTime()
            if IsValid(TargetEntity) then Notify.StartEntityPulse(TargetEntity) end
        else
            if IsValid(TargetEntity) then Notify.StopEntityPulse(TargetEntity) end
        end
        self.RecursivelyHovered = RecursiveHoverCheck
    end

    function PANEL:Paint( w, h )
        self.ProgressFrac = (SysTime() - self.StartTime) / self.Length
        local shouldDraw = not (LocalPlayer and IsValid(LocalPlayer()) and IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "gmod_camera")

        if IsValid(self.Label) then self.Label:SetVisible(shouldDraw) end
        if IsValid(self.Image) then self.Image:SetVisible(shouldDraw) end

        if not shouldDraw then return end

        local Skin = self:GetSkin()
        Skin.tex.Panels.Normal(0, 0, w, h, self.m_bgColor )

        if not self.Progress then return end

        local BoxX, BoxY = 10, self:GetTall() - 13
        local BoxW, BoxH = self:GetWide() - 20, 5

        local BoxInnerW = BoxW - 2

        surface.SetDrawColor(0, 100, 0, 150)
        surface.DrawRect(BoxX, BoxY, BoxW, BoxH)

        surface.SetDrawColor(0, 50, 0, 255)
        surface.DrawRect(BoxX + 1, BoxY + 1, BoxW - 2, BoxH - 2)

        local w = math.ceil(BoxInnerW * 0.25)
        local x = math.fmod(math.floor(SysTime() * 200), BoxInnerW + w) - w

        if self.ProgressFrac then
            x = 0
            w = math.ceil(BoxInnerW * self.ProgressFrac)
        end

        if x + w > BoxInnerW then w = math.ceil(BoxInnerW - x) end
        if x < 0 then
            w = w + x
            x = 0
        end
        surface.SetDrawColor(232, 243, 255)
        surface.DrawRect(BoxX + 1 + x, BoxY + 1, w, BoxH - 2)
    end

    function PANEL:KillSelf()
        if self.Length < 0 then return false end

        if self.StartTime + self.Length < SysTime() then
            self:Remove()
            return true
        end

        return false
    end

    vgui.Register("ACF_NoticePanel", PANEL, "DPanel")
end

do -- Backwards compatibility with the old notification system.
    local Messages = ACF.Utilities.Messages
    local ReceiveShame = GetConVar("acf_legalshame")
    local LastNotificationSoundTime = 0
    net.Receive("ACF_LegacyNotify", function()
        local IsOK = net.ReadBool()
        local Msg  = net.ReadString()
        local Type = IsOK and NOTIFY_GENERIC or NOTIFY_ERROR

        local Now = SysTime()
        local DeltaTime = Now - LastNotificationSoundTime

        if not IsOK and DeltaTime > 0.2 then -- Rate limit sounds. Helps with lots of sudden errors not killing your ears
            surface.PlaySound("buttons/button10.wav")
            LastNotificationSoundTime = Now
        end

        Msg = "[ACF] " .. Msg
        notification.AddLegacy(Msg, Type, 7)
    end)

    net.Receive("ACF_NameAndShame", function()
        if not ReceiveShame:GetBool() then return end
        Messages.PrintLog("Error", net.ReadString())
    end)
end