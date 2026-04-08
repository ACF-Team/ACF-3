local Notify = ACF.Utilities.Notify

local CurrentNotification = {}

-- Text is networked as a sequential table. The first value is expected to always be text. The remaining values are networked over
-- and inserted into the format string on client.

local MAX_FORMATTED_TEXT_PARAM_BITS = 8
local MAX_BUTTON_BITS = 4

function Notify.Net_ReadFormattedText()
    local FormattedTextObject = {}
    local Count = net.ReadUInt(MAX_FORMATTED_TEXT_PARAM_BITS)
    for I = 1, Count do
        FormattedTextObject[I] = net.ReadType()
    end

    return FormattedTextObject
end

function Notify.Net_WriteFormattedText(FormattedTextObject)
    net.WriteUInt(#FormattedTextObject, MAX_FORMATTED_TEXT_PARAM_BITS)
    for I = 1, #FormattedTextObject do
        net.WriteType(FormattedTextObject[I])
    end
end

function Notify.Start()
    CurrentNotification.Title           = {"Title"}
    CurrentNotification.Text            = {"Text"}
    CurrentNotification.Duration        = 8
    CurrentNotification.Icon            = "icon16/lightbulb.png"
    CurrentNotification.Buttons         = {}
    CurrentNotification.TargetEntity    = 0
    CurrentNotification.TargetPhysObj   = -1
    if SERVER then
        CurrentNotification.Filter = CurrentNotification.Filter or RecipientFilter()
        CurrentNotification.Filter:RemoveAllPlayers()
    end
end

function Notify.WithTitle(Title, ...) CurrentNotification.Title = {Title, ...} end
function Notify.WithDescription(Text, ...) CurrentNotification.Text = {Text, ...} end
function Notify.Duration(Duration) CurrentNotification.Duration = Duration end
function Notify.WithIcon(Icon) CurrentNotification.Icon = Icon end
function Notify.WithSilkIcon(Icon) Notify.WithIcon("icon16/" .. Icon .. ".png") end
function Notify.WithTargetEntity(Entity) CurrentNotification.TargetEntity = IsValid(Entity) and Entity:EntIndex() or 0 end
function Notify.WithTargetPhysObj(PhysObj)
    if not IsValid(PhysObj) then
        CurrentNotification.TargetEntity = 0
        CurrentNotification.TargetPhysObj = -1
        return
    end

    Notify.WithTargetEntity(PhysObj:GetEntity())
    CurrentNotification.TargetPhysObj = PhysObj:GetIndex()
end

local function ActionSetFunction(self, Action, ...)
    self.Action = Action
    self.Params = {...}
    return self
end

local function ActionPulsing(self)
    self.Pulsing = true
    return self
end

function Notify.AddButton(Text, ...)
    local Button = {
        Text = {Text, ...},
        Action = "",
        Params = {},
        Pulsing = false
    }
    CurrentNotification.Buttons[#CurrentNotification.Buttons + 1] = Button
    Button.WithAction = ActionSetFunction
    Button.WithPulse = ActionPulsing
    return Button
end

-- Recipient filter features.
if SERVER then
    function Notify.AddTargetEntityOwner()
        local Ent = Entity(CurrentNotification.TargetEntity)
        if not IsValid(Ent) then return end

        local Owner = Ent:CPPIGetOwner()
        if not IsValid(Owner) then return end

        CurrentNotification.Filter:AddPlayer(Owner)
    end
    function Notify.AddAllPlayers(...) CurrentNotification.Filter:AddAllPlayers(...) end
    function Notify.AddPAS(...) CurrentNotification.Filter:AddPAS(...) end
    function Notify.AddPlayer(...) CurrentNotification.Filter:AddPlayer(...) end
    function Notify.AddPlayers(...) CurrentNotification.Filter:AddPlayers(...) end
    function Notify.AddPVS(...) CurrentNotification.Filter:AddPVS(...) end
    function Notify.RemoveAllPlayers(...) CurrentNotification.Filter:RemoveAllPlayers(...) end
    function Notify.RemoveMismatchedPlayers(...) CurrentNotification.Filter:RemoveMismatchedPlayers(...) end
    function Notify.RemovePAS(...) CurrentNotification.Filter:RemovePAS(...) end
    function Notify.RemovePlayer(...) CurrentNotification.Filter:RemovePlayer(...) end
    function Notify.RemovePlayers(...) CurrentNotification.Filter:RemovePlayers(...) end
    function Notify.RemovePVS(...) CurrentNotification.Filter:RemovePVS(...) end
    function Notify.RemoveRecipientsByTeam(...) CurrentNotification.Filter:RemoveRecipientsByTeam(...) end
    function Notify.RemoveRecipientsNotOnTeam(...) CurrentNotification.Filter:RemoveRecipientsNotOnTeam(...) end
else -- Nulled out functions for clientside.
    function Notify.AddTargetEntityOwner() end
    function Notify.AddAllPlayers() end
    function Notify.AddPAS() end
    function Notify.AddPlayer() end
    function Notify.AddPlayers() end
    function Notify.AddPVS() end
    function Notify.RemoveAllPlayers() end
    function Notify.RemoveMismatchedPlayers() end
    function Notify.RemovePAS() end
    function Notify.RemovePlayer() end
    function Notify.RemovePlayers() end
    function Notify.RemovePVS() end
    function Notify.RemoveRecipientsByTeam() end
    function Notify.RemoveRecipientsNotOnTeam() end
end

function Notify.Transmit()
    if CLIENT then
        Notify.Display(CurrentNotification)
    else
        net.Start("ACF_Notify")
        Notify.Net_WriteFormattedText(CurrentNotification.Title)
        Notify.Net_WriteFormattedText(CurrentNotification.Text)
        net.WriteFloat(CurrentNotification.Duration)
        net.WriteString(CurrentNotification.Icon)
        net.WriteUInt(CurrentNotification.TargetEntity, MAX_EDICT_BITS)
        net.WriteInt(CurrentNotification.TargetPhysObj, 10)
        net.WriteUInt(#CurrentNotification.Buttons, MAX_BUTTON_BITS)
        for I = 1, #CurrentNotification.Buttons do
            local Button = CurrentNotification.Buttons[I]
            Notify.Net_WriteFormattedText(Button.Text)
            net.WriteBool(Button.Pulsing)
            net.WriteString(Button.Action)
            net.WriteUInt(#Button.Params, 6)
            for I2 = 1, #Button.Params do
                net.WriteType(Button.Params[I2])
            end
        end

        net.Send(CurrentNotification.Filter)
    end
end

-- Notification actions API.
do
    Notify.Actions = {}

    -- Handlers are given an ActionContext (allows interacting with the prompt a little if need be), and  
    function Notify.RegisterAction(ActionName)
        local Obj = Notify.Actions[ActionName] or {}
        Notify.Actions[ActionName] = Obj
        return Obj
    end

    if CLIENT then
        local ActionContextFns = {}
        local ActionContextMT = {__index = ActionContextFns}

        function ActionContextFns:GetActionName() return self.ActionName end
        function ActionContextFns:GetActionParams() return self.ActionParams end
        function ActionContextFns:GetNotifyPanel() return self.Panel end
        function ActionContextFns:GetActionButton() return self.ActionButton end

        function ActionContextFns:GetNotifyData() return self.Panel.Data end
        function ActionContextFns:GetTargetEntity() return Entity(self.Panel.Data.TargetEntity) end
        function ActionContextFns:DoButtonError(Reason)
            if not IsValid(self.ActionButton) then return end
            self.ActionButton:DoError(Reason)
        end

        function Notify.CreateActionContext(NotifyPanel, ActionParams, ActionButton, ActionName)
            return setmetatable({ActionName = ActionName, ActionParams = ActionParams, Panel = NotifyPanel, ActionButton = ActionButton}, ActionContextMT)
        end

        function Notify.CallAction(ActionContext)
            if not ActionContext or not ActionContext.ActionName then return end
            local Action = Notify.Actions[ActionContext:GetActionName()]
            if not Action then ErrorNoHalt("Action '" .. ActionContext:GetActionName() .. "' was not registered with the ACF notification subsystem.") return end
            Action.DoClickCL(ActionContext, unpack(ActionContext:GetActionParams()))
        end
    end
end

-- Here are some base action types.
do
    do
        local LookAt = Notify.RegisterAction("LookAtEntity")
        function LookAt.DoClickCL(Context, Entity)
            if not IsValid(Entity) then return Context:DoButtonError("The entity is no longer valid.") end
            local View = render.GetViewSetup()
            local Lookat = (Entity:WorldSpaceCenter() - View.origin):Angle()
            Notify.InterpViewAngleTo(Lookat, nil, function() Notify.SingleEntityImpulse(Entity) end, 0.8)
        end
    end

    do
        local OpenPonder = Notify.RegisterAction("OpenPonder")
        function OpenPonder.DoClickCL(_, UUID)
            if not Ponder then return Context:DoButtonError("Ponder is not installed.") end -- This shouldn't even show up in the future
            Ponder.Open(UUID)
        end
    end

    do
        local OpenWiki = Notify.RegisterAction("OpenWiki")

        function OpenWiki.DoClickCL(_, URL)
            URL = "https://lengthenedgradient.github.io/Wiki/docs/" .. URL
            local Panel = vgui.Create("DPanel")
            local startTime = SysTime()

            Panel:SetSize(ScrW() * 0.85, ScrH() * 0.85)
            Panel:Center()
            Panel:MakePopup()

            local BackColor = color_white:Copy()
            BackColor.a = 0
            local Back = Panel:Add("DButton")
            Back:Dock(TOP)
            Back:SetPaintBackground(false)
            Back:SetColor(BackColor)
            Back:SetText("Exit")
            Back:SetFont("ACF_Title")
            function Back:DoClick()
                Panel:Remove()
            end

            local HTML = Panel:Add("DHTML")
            HTML:Dock(FILL)
            HTML:OpenURL(URL)
            HTML:DockMargin(16, 16, 16, 16)

            local DHTML_Paint = HTML.Paint
            function HTML:Paint(W, H)
                DHTML_Paint(self, W, H)
            end

            function Panel:Paint(W, H)
                Derma_DrawBackgroundBlur(self, startTime)
                BackColor.a = math.ease.InCubic(math.Clamp(SysTime() - startTime - 0.6, 0, 1)) * 255
                Back:SetColor(BackColor)

                local Size = ScrH() * 0.05
                local CenterX, CenterY = W / 2, H / 2
                local Radius = Size / 2
                local Spokes = 12
                local Time = SysTime()
                for I = 0, Spokes - 1 do
                    local Angle = math.rad((I / Spokes) * 360 - 90)
                    local Frac = 1 - (((I / Spokes) + Time * 1.5) % 1)
                    local Alpha = Frac * 100
                    local Thick = Size * 0.02
                    local InnerRadius = Radius * 0.4
                    local OuterRadius = Radius * 0.85
                    local X1 = CenterX + math.cos(Angle) * InnerRadius
                    local Y1 = CenterY + math.sin(Angle) * InnerRadius
                    local X2 = CenterX + math.cos(Angle) * OuterRadius
                    local Y2 = CenterY + math.sin(Angle) * OuterRadius
                    surface.SetDrawColor(255, 255, 255, Alpha)
                    surface.DrawLine(X1, Y1, X2, Y2)
                    for T = -Thick / 2, Thick / 2 do
                        local Offset = math.abs(Angle) < math.rad(45) or math.abs(Angle - math.pi) < math.rad(45)
                        if Offset then
                            surface.DrawLine(X1, Y1 + T, X2, Y2 + T)
                        else
                            surface.DrawLine(X1 + T, Y1, X2 + T, Y2)
                        end
                    end
                end
            end
        end
    end
end

-- Some useful helper functions
do
    function Notify.AddPonderButton(Ponder)
        Notify.AddButton("Ponder About...")
            :WithAction("OpenPonder", Ponder)
    end

    function Notify.AddWikiArticleButton(WikiArticle)
        Notify.AddButton("Wiki Article...")
            :WithAction("OpenWiki", WikiArticle)
    end

    function Notify.NotifyDisabledEntity(Ent, Reason, Ponder, WikiArticle)
        if not IsValid(Ent) then return end

        Notify.Start()
        Notify.WithTitle("An ACF entity has been disabled.")
        Notify.WithSilkIcon("error")
        Notify.WithTargetEntity(Ent)
        Notify.WithDescription(Reason)

        Notify.AddButton("Look at Entity")
            :WithAction("LookAtEntity", Ent)
            :WithPulse()

        if Ponder then Notify.AddPonderButton(Ponder) end
        if WikiArticle then Notify.AddWikiArticleButton(WikiArticle) end

        Notify.AddPlayer(Ent:CPPIGetOwner())
        Notify.Transmit()
    end

    function Notify.NotifyWarning(Warning, Description, Ent)
        Notify.Start()
        Notify.WithTitle(Warning)
        Notify.WithSilkIcon("error")
        if Description then Notify.WithDescription(Description) end

        if IsValid(Ent) then
            Notify.WithTargetEntity(Ent)
            Notify.AddButton("Look at Entity")
                :WithAction("LookAtEntity", Ent)
                :WithPulse()
        end

        if Ponder then Notify.AddPonderButton(Ponder) end
        if WikiArticle then Notify.AddWikiArticleButton(WikiArticle) end

        Notify.AddPlayer(Ent:CPPIGetOwner())
        Notify.Transmit()
    end
end