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
end