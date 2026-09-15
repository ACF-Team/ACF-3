-- Persistent, session-grouped record of ACF kills for the Kill Log menu. Kills are buffered
-- and flushed to SQLite in batched transactions, and queries run server-side against the DB.
local ACF = ACF

sql.Query([[CREATE TABLE IF NOT EXISTS acf_kill_log (
    Id INTEGER PRIMARY KEY AUTOINCREMENT,
    Session INTEGER NOT NULL DEFAULT 0,
    Time INTEGER NOT NULL,
    Attacker TEXT,
    AttackerSteamID TEXT,
    AttackerCost REAL,
    Victim TEXT NOT NULL,
    VictimSteamID TEXT NOT NULL,
    VictimCost REAL,
    Inflictor TEXT,
    IsDrone INTEGER NOT NULL
)]])

-- Migrate tables from before the Session column existed.
do
    local HasSession = false
    for _, Column in ipairs(sql.Query("PRAGMA table_info(acf_kill_log)") or {}) do
        if Column.name == "Session" then HasSession = true break end
    end

    if not HasSession then
        sql.Query("ALTER TABLE acf_kill_log ADD COLUMN Session INTEGER NOT NULL DEFAULT 0")
    end
end

-- Rows without a real Session default to 0 (the Unix epoch); rebucket them under their
-- earliest kill's own timestamp instead.
do
    local Earliest = sql.QueryRow("SELECT MIN(Time) AS MinTime FROM acf_kill_log WHERE Session = 0")
    local MinTime = Earliest and tonumber(Earliest.MinTime)

    if MinTime then
        sql.Query("UPDATE acf_kill_log SET Session = " .. MinTime .. " WHERE Session = 0")
    end
end

-- Identifies this server run as a session.
local SessionStart = os.time()

-- Prune old sessions to stay within KillLogMaxSessions, keeping room for this new one.
do
    local Keep = math.max(0, math.floor(ACF.KillLogMaxSessions) - 1)
    local Rows = sql.Query("SELECT DISTINCT Session FROM acf_kill_log ORDER BY Session DESC") or {}

    if #Rows > Keep then
        local ToDelete = {}
        for i = Keep + 1, #Rows do
            ToDelete[#ToDelete + 1] = tostring(math.floor(tonumber(Rows[i].Session)))
        end

        sql.Query("DELETE FROM acf_kill_log WHERE Session IN (" .. table.concat(ToDelete, ", ") .. ")")
    end
end

local Pending = {}

--- Records a kill for the persistent engagement log. Both costs are optional (whichever side
--- isn't a player, e.g. an NPC victim, simply has no cost of its own).
--- @param Attacker player|nil The entity credited with the kill, if any
--- @param AttackerCost number|nil
--- @param Victim player The player who died
--- @param VictimCost number|nil
--- @param InflictorClass string|nil The class of the weapon/entity used to deal the damage
--- @param IsDrone boolean Whether this was a crewless-drone destruction rather than a player death
function ACF.RecordKill(Attacker, AttackerCost, Victim, VictimCost, InflictorClass, IsDrone)
    if not IsValid(Victim) or not Victim:IsPlayer() then return end

    local HasAttacker = IsValid(Attacker) and Attacker:IsPlayer()

    Pending[#Pending + 1] = {
        Session         = SessionStart,
        Time            = os.time(),
        Attacker        = HasAttacker and Attacker:Name() or nil,
        AttackerSteamID = HasAttacker and Attacker:SteamID64() or nil,
        AttackerCost    = AttackerCost,
        Victim          = Victim:Name(),
        VictimSteamID   = Victim:SteamID64(),
        VictimCost      = VictimCost,
        Inflictor       = InflictorClass,
        IsDrone         = IsDrone or false,
    }
end

-- Turns a Lua value into a literal safe to splice into a query string ("NULL" for nil).
local function SQLValue(Value)
    if Value == nil then return "NULL" end
    if isnumber(Value) then return tostring(Value) end
    if type(Value) == "boolean" then return Value and "1" or "0" end

    return sql.SQLStr(tostring(Value))
end

local LastFlush = 0

-- Inserts pending kills in one transaction, so the disk syncs once per flush, not once per kill.
local function FlushKillLog()
    LastFlush = CurTime()

    if #Pending == 0 then return end

    sql.Begin()

    for _, Kill in ipairs(Pending) do
        local Query = string.format(
            "INSERT INTO acf_kill_log (Session, Time, Attacker, AttackerSteamID, AttackerCost, Victim, VictimSteamID, VictimCost, Inflictor, IsDrone) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            SQLValue(Kill.Session), SQLValue(Kill.Time), SQLValue(Kill.Attacker), SQLValue(Kill.AttackerSteamID), SQLValue(Kill.AttackerCost),
            SQLValue(Kill.Victim), SQLValue(Kill.VictimSteamID), SQLValue(Kill.VictimCost), SQLValue(Kill.Inflictor), SQLValue(Kill.IsDrone)
        )

        if sql.Query(Query) == false then
            ACF.PrintLog("Error", "Kill Log insert failed: " .. sql.LastError())
        end
    end

    sql.Commit()

    Pending = {}
end

-- Polls every second so KillLogFlushInterval changes take effect immediately.
timer.Create("ACF_KillLog_Flush", 1, 0, function()
    if (CurTime() - LastFlush) < ACF.KillLogFlushInterval then return end

    FlushKillLog()
end)

hook.Add("ShutDown", "ACF_KillLog_FinalFlush", FlushKillLog)

-- Drops every session, buffered rows included
local function WipeKillLog()
    Pending = {}
    sql.Query("DELETE FROM acf_kill_log")
end

concommand.Add("acf_killlog_wipe", function(Player)
    -- Same gate as the menu button, so the command isn't a way around it
    if IsValid(Player) and not Player:IsSuperAdmin() then
        ACF.PrintLog("Error", "You can't use this because you are not a superadmin.")
        return
    end

    WipeKillLog()

    ACF.PrintLog("Info", "Kill Log wiped.")
end)

-- One net string per request/response pair, reused both ways: server and client each register
-- their own net.Receive for the same name, so there's no ambiguity about which side sent it.
util.AddNetworkString("ACF_KillLog_Sessions")
util.AddNetworkString("ACF_KillLog_Players")
util.AddNetworkString("ACF_KillLog_Query")
util.AddNetworkString("ACF_KillLog_Wipe")

local MaxResultRows = 1000

local NextQueryTime = {} -- [PlayerName] = CurTime() they're next allowed to query

-- Runs a SELECT, logging an error on failure instead of treating it as an empty result.
local function RunSelect(Query)
    local Rows = sql.Query(Query)

    if Rows == false then
        ACF.PrintLog("Error", "Kill Log query failed: " .. sql.LastError())
        return {}
    end

    return Rows or {}
end

-- Fixed-width columns plus per-row overhead, on top of the text lengths measured below
local BytesPerRow = 40

-- Which path ID reaches sv.db varies by host, and a miss comes back as either nil or -1
local function GetDatabaseSize()
    for _, PathID in ipairs({"MOD", "BASE_PATH", "GAME"}) do
        local Size = file.Size("sv.db", PathID)
        if Size and Size > 0 then return Size end
    end

    return 0
end

-- SQLite exposes no per-table size, so the log's share of sv.db is estimated from its own contents
local function GetLogStats()
    local Row = RunSelect([[SELECT COUNT(*) AS Rows, COALESCE(SUM(
        length(COALESCE(Attacker, '')) + length(COALESCE(AttackerSteamID, '')) +
        length(Victim) + length(VictimSteamID) + length(COALESCE(Inflictor, ''))
    ), 0) AS TextBytes FROM acf_kill_log]])[1]

    local Count = Row and tonumber(Row.Rows) or 0
    local Bytes = Row and tonumber(Row.TextBytes) or 0

    return Count, Bytes + Count * BytesPerRow, GetDatabaseSize()
end

local function WriteSize(Value)
    net.WriteUInt(math.floor(math.Clamp(Value, 0, 4294967295)), 32)
end

net.Receive("ACF_KillLog_Wipe", function(_, Player)
    if not IsValid(Player) or not Player:IsSuperAdmin() then return end

    WipeKillLog()

    ACF.PrintLog("Info", "Kill Log wiped by " .. Player:Nick() .. ".")

    net.Start("ACF_KillLog_Wipe")
    net.Broadcast() -- Any menu still open is showing rows that no longer exist
end)

net.Receive("ACF_KillLog_Sessions", function(_, Player)
    if not IsValid(Player) then return end

    FlushKillLog() -- Ensure the current session shows up before its first periodic write

    local Rows = RunSelect("SELECT DISTINCT Session FROM acf_kill_log ORDER BY Session DESC")
    local Sessions = {}
    for _, Row in ipairs(Rows) do Sessions[#Sessions + 1] = tonumber(Row.Session) end

    local Count, Bytes, DBSize = GetLogStats()

    net.Start("ACF_KillLog_Sessions")
        net.WriteString(util.TableToJSON(Sessions))
        WriteSize(Count)
        WriteSize(Bytes)
        WriteSize(DBSize)
    net.Send(Player)
end)

-- Returns the distinct player names seen in a session, for the client's filter checkboxes.
net.Receive("ACF_KillLog_Players", function(_, Player)
    if not IsValid(Player) then return end

    local Session = net.ReadUInt(32)

    FlushKillLog()

    local Query = "SELECT DISTINCT Attacker AS Name FROM acf_kill_log WHERE Session = " .. Session .. " AND Attacker IS NOT NULL"
        .. " UNION SELECT DISTINCT Victim AS Name FROM acf_kill_log WHERE Session = " .. Session
        .. " ORDER BY Name"

    local Rows = RunSelect(Query)
    local Names = {}
    for _, Row in ipairs(Rows) do Names[#Names + 1] = Row.Name end

    net.Start("ACF_KillLog_Players")
        net.WriteString(util.TableToJSON(Names))
    net.Send(Player)
end)

net.Receive("ACF_KillLog_Query", function(_, Player)
    if not IsValid(Player) then return end

    local PlayerName = Player:Name()
    if (NextQueryTime[PlayerName] or 0) > CurTime() then return end

    NextQueryTime[PlayerName] = CurTime() + ACF.KillLogQueryCooldown

    local Names = util.JSONToTable(net.ReadString()) or {}
    local Session = net.ReadUInt(32)

    FlushKillLog() -- Ensure recent kills are queryable too

    local Conditions = { "Session = " .. Session }

    if #Names > 0 then
        local Quoted = {}
        for _, Name in ipairs(Names) do Quoted[#Quoted + 1] = sql.SQLStr(Name) end

        local List = table.concat(Quoted, ", ")
        Conditions[#Conditions + 1] = "(Attacker IN (" .. List .. ") OR Victim IN (" .. List .. "))"
    end

    local Rows = RunSelect("SELECT * FROM acf_kill_log WHERE " .. table.concat(Conditions, " AND ") .. " ORDER BY Time DESC LIMIT " .. MaxResultRows)

    net.Start("ACF_KillLog_Query")
        net.WriteString(util.TableToJSON(Rows))
    net.Send(Player)
end)
