-- Adds point costs to the native kill feed.
local ACF = ACF
local NPC_Color_Enemy    = Color(250, 50, 50, 255)
local NPC_Color_Friendly = Color(50, 200, 50, 255)
local Color_Cost         = Color(255, 210, 0, 255)

local hud_deathnotice_time = GetConVar("hud_deathnotice_time")
local cl_drawhud           = GetConVar("cl_drawhud")

local PendingCost = {} -- [VictimName] = { VictimCost, AttackerCost, Time }
local PendingTimeout = 2 -- Max wait for a matching death-notice entry

net.Receive("ACF_KillFeed_ContraptionCost", function()
    local Victim = net.ReadEntity()
    local VictimCost = net.ReadFloat()

    local AttackerCost
    if net.ReadBool() then AttackerCost = net.ReadFloat() end

    if not IsValid(Victim) then return end

    PendingCost[Victim:Name()] = { VictimCost = VictimCost, AttackerCost = AttackerCost, Time = RealTime() }
end)

local MaxNameLength = 10
local function ClipName(Name)
    return isstring(Name) and string.sub(Name, 1, MaxNameLength) or Name
end

local function GetDeathColor(TeamID)
    if TeamID == -1 then return table.Copy(NPC_Color_Enemy) end
    if TeamID == -2 then return table.Copy(NPC_Color_Friendly) end

    return table.Copy(team.GetColor(TeamID))
end

-- Mirrors GM's death-notice list so we can attach cost fields.
local Deaths = {}

local function InsertDeath(Left, Color1, Icon, Right, Color2, VictimCost, AttackerCost)
    table.insert(Deaths, {
        time         = CurTime(),
        left         = Left,
        right        = Right,
        icon         = Icon,
        victimCost   = VictimCost,
        attackerCost = AttackerCost,
        color1       = Color1,
        color2       = Color2,
    })
end

hook.Add("AddDeathNotice", "ACF_KillFeed_TrackCost", function(Attacker, Team1, Inflictor, Victim, Team2, Flags)
    if not ACF.EnableKillFeedCost then return end
    if Inflictor == "suicide" then Attacker = nil end

    local VictimCost, AttackerCost
    local Pending = isstring(Victim) and PendingCost[Victim]

    if Pending and (RealTime() - Pending.Time) <= PendingTimeout then
        VictimCost = Pending.VictimCost
        AttackerCost = Pending.AttackerCost
        PendingCost[Victim] = nil
    end

    InsertDeath(ClipName(Attacker), GetDeathColor(Team1), Inflictor, ClipName(Victim), GetDeathColor(Team2), VictimCost, AttackerCost)
end)

-- A vehicle dying isn't a player death, so it bypasses AddDeathNotice entirely.
net.Receive("ACF_KillFeed_VehicleEntry", function()
    local Owner = net.ReadEntity()
    local OwnerCost = net.ReadFloat()
    local Attacker = net.ReadEntity()
    local AttackerCost = net.ReadFloat()
    local InflictorClass = net.ReadString()

    if not IsValid(Owner) or not IsValid(Attacker) then return end

    local Left   = ClipName(Attacker:Name())
    local Color1 = GetDeathColor(Attacker:Team())
    local Color2 = GetDeathColor(Owner:Team())

    InsertDeath(Left, Color1, InflictorClass, ClipName(Owner:Name()) .. "'s Vehicle", Color2, OwnerCost, AttackerCost)
end)

-- Draws a "(N pts)" label at X (its leading edge per Align) and returns its rendered width.
local function DrawCost(Cost, X, y, Align)
    if not Cost then return 0 end

    surface.SetFont("ChatFont")
    local Text = string.format("(%d pts)", math.Round(Cost))
    local Width = surface.GetTextSize(Text)

    draw.SimpleText(Text, "ChatFont", X, y, Color_Cost, Align, TEXT_ALIGN_CENTER)

    return Width
end

local function DrawDeath(x, y, Death, Time)
    local w, h = killicon.GetSize(Death.icon)
    if not w or not h then return y end

    local Fadeout = (Death.time + Time) - CurTime()
    local Alpha   = math.Clamp(Fadeout * 255, 0, 255)

    Death.color1.a = Alpha
    Death.color2.a = Alpha
    Color_Cost.a   = Alpha

    killicon.Render(x - w / 2, y, Death.icon, Alpha)

    local TextY = y + h / 2

    -- Attacker: "(cost) Name", name ending at the icon.
    if Death.left then
        surface.SetFont("ChatFont")
        local NameX = x - (w / 2) - 16
        local NameWidth = surface.GetTextSize(Death.left)

        draw.SimpleText(Death.left, "ChatFont", NameX, TextY, Death.color1, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        DrawCost(Death.attackerCost, NameX - NameWidth - 8, TextY, TEXT_ALIGN_RIGHT)
    end

    -- Victim: "(cost) Name", cost starting at the icon.
    local VictimX = x + (w / 2) + 16
    local CostWidth = DrawCost(Death.victimCost, VictimX, TextY, TEXT_ALIGN_LEFT)
    local NameX = Death.victimCost and (VictimX + CostWidth + 8) or VictimX
    draw.SimpleText(Death.right, "ChatFont", NameX, TextY, Death.color2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

    return math.ceil(y + h * 0.75)
end

hook.Add("DrawDeathNotice", "ACF_KillFeed_DrawWithCost", function(x, y)
    if not ACF.EnableKillFeedCost then return end -- Let the native kill feed draw instead
    if cl_drawhud:GetInt() == 0 then return true end

    local Time  = hud_deathnotice_time:GetFloat()
    local Reset = Deaths[1] ~= nil

    x = x * ScrW()
    y = y * ScrH()

    for _, Death in ipairs(Deaths) do
        if Death.time + Time > CurTime() then
            if Death.lerp then
                x = x * 0.3 + Death.lerp.x * 0.7
                y = y * 0.3 + Death.lerp.y * 0.7
            end

            Death.lerp = Death.lerp or {}
            Death.lerp.x = x
            Death.lerp.y = y

            y = DrawDeath(math.floor(x), math.floor(y), Death, Time)
            Reset = false
        end
    end

    if Reset then Deaths = {} end

    return true
end)
