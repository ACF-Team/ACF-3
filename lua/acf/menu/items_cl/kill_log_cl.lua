-- Lets players browse the server's kill log by session. The server does the filtering; only
-- matching rows come back.
local ACF = ACF

-- sql.Query results come back as strings for every column, numeric or not.
local function FormatTime(UnixTime)
    UnixTime = tonumber(UnixTime)
    return UnixTime and os.date("%Y-%m-%d %H:%M:%S", UnixTime) or "Unknown"
end

local function FormatCost(Cost)
    Cost = tonumber(Cost)
    return Cost and string.format("%.0f", Cost) or "-"
end

local function RequestSessions()
    net.Start("ACF_KillLog_Sessions")
    net.SendToServer()
end

local function RequestPlayers(Session)
    net.Start("ACF_KillLog_Players")
        net.WriteUInt(Session or 0, 32)
    net.SendToServer()
end

local function RequestQuery(Names, Session)
    net.Start("ACF_KillLog_Query")
        net.WriteString(util.TableToJSON(Names or {}))
        net.WriteUInt(Session or 0, 32)
    net.SendToServer()
end

local function CreateMenu(Menu)
    Menu:AddTitle("Kill Log")
    Menu:AddLabel("Pick a session, then optionally check specific players to narrow the results. Leaving all players unchecked matches everyone in the session.")

    local SessionList = Menu:AddListView()
    SessionList:AddColumn("Session")
    SessionList:SetTall(120)

    Menu:AddButton("Refresh Sessions", RequestSessions)

    local PlayersBase = Menu:AddCollapsible("Players", true)
    local PlayerChecks = {}

    local CurrentSession = nil
    local LastNames = {} -- Names used for the query currently on screen, for the kills/deaths split below

    local function RunQuery(Names, Session)
        LastNames = Names or {}
        RequestQuery(LastNames, Session)
    end

    Menu:AddButton("Run Query", function()
        if not CurrentSession then return end

        local Selected = {}
        for Name, Check in pairs(PlayerChecks) do
            if IsValid(Check) and Check:GetChecked() then Selected[#Selected + 1] = Name end
        end

        RunQuery(Selected, CurrentSession)
    end)

    local Summary = Menu:AddLabel("")

    local KillList = Menu:AddListView()
    KillList:AddColumn("Time")
    KillList:AddColumn("Attacker")
    KillList:AddColumn("Attacker Cost")
    KillList:AddColumn("Victim")
    KillList:AddColumn("Victim Cost")
    KillList:AddColumn("Weapon")

    SessionList.OnRowSelected = function(_, _, Line)
        CurrentSession = Line.Session

        RequestPlayers(CurrentSession)
        RunQuery({}, CurrentSession)
    end

    -- Re-registering on each rebuild just replaces the old handler, which is fine here.
    net.Receive("ACF_KillLog_Sessions", function()
        local Sessions = util.JSONToTable(net.ReadString()) or {}
        if not IsValid(SessionList) then return end

        SessionList:Clear()

        for _, Session in ipairs(Sessions) do
            local Line = SessionList:AddLine(FormatTime(Session))
            Line.Session = Session
        end

        SessionList:SetTall(120) -- Cap the height; the list scrolls internally past this

        if not CurrentSession and Sessions[1] then
            CurrentSession = Sessions[1]

            RequestPlayers(CurrentSession)
            RunQuery({}, CurrentSession)
        end
    end)

    net.Receive("ACF_KillLog_Players", function()
        local Names = util.JSONToTable(net.ReadString()) or {}
        if not IsValid(PlayersBase) then return end

        PlayersBase:ClearAll()
        PlayerChecks = {}

        for _, Name in ipairs(Names) do
            local Check = PlayersBase:AddCheckBox(Name)
            Check:SetValue(true)

            PlayerChecks[Name] = Check
        end
    end)

    net.Receive("ACF_KillLog_Query", function()
        local Kills = util.JSONToTable(net.ReadString()) or {}
        if not IsValid(KillList) then return end

        KillList:Clear()

        -- LastNames empty means "everyone", so treat any name as in scope in that case.
        local NameSet = nil
        if #LastNames > 0 then
            NameSet = {}
            for _, Name in ipairs(LastNames) do NameSet[Name] = true end
        end

        local function InScope(Name)
            return Name ~= nil and (NameSet == nil or NameSet[Name])
        end

        local KillCount, KillPoints = 0, 0
        local DeathCount, DeathPoints = 0, 0

        for _, Kill in ipairs(Kills) do
            local Victim = tonumber(Kill.IsDrone) == 1 and (Kill.Victim .. "'s Drone") or Kill.Victim
            local Points = tonumber(Kill.VictimCost) or 0

            KillList:AddLine(FormatTime(Kill.Time), Kill.Attacker or "-", FormatCost(Kill.AttackerCost), Victim, FormatCost(Kill.VictimCost), Kill.Inflictor or "-")

            if InScope(Kill.Attacker) then
                KillCount = KillCount + 1
                KillPoints = KillPoints + Points
            end

            if InScope(Kill.Victim) then
                DeathCount = DeathCount + 1
                DeathPoints = DeathPoints + Points
            end
        end

        Summary:SetText(string.format("%d kills (%d pts) / %d deaths (%d pts)", KillCount, math.Round(KillPoints), DeathCount, math.Round(DeathPoints)))
        KillList:SetTall(400) -- Cap the height; the list scrolls internally past this
    end)

    RequestSessions()
end

ACF.AddMenuOption(103, "Kill Log", "chart_bar")
ACF.AddMenuItem(1, "Kill Log", "View Kills", "chart_bar", CreateMenu)
