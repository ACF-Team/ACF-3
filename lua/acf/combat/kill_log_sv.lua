-- Persistent, session-grouped record of ACF kills for the Kill Log menu. Kills are buffered
-- and flushed to SQLite in batched transactions, and clients pull new rows into their own copy.
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

-- Identifies this server's log, so clients know when their copy belongs to another server.
do
    sql.Query("CREATE TABLE IF NOT EXISTS acf_kill_log_meta (Key TEXT NOT NULL)")

    local Key = sql.QueryValue("SELECT Key FROM acf_kill_log_meta")

    if not Key then
        Key = string.format("%08x%08x", os.time(), math.random(0, 0x7FFFFFFF))
        sql.Query("INSERT INTO acf_kill_log_meta (Key) VALUES (" .. sql.SQLStr(Key) .. ")")
    end

    SetGlobal2String("ACF_KillLog_Key", Key)
end

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
--- Runs the ACF_OnKillLogged hook (same args, Attacker nil'd out if not a player) for gamemode integration.
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

    hook.Run("ACF_OnKillLogged", {
        Attacker     = HasAttacker and Attacker or nil,
        AttackerCost = AttackerCost,
        Victim       = Victim,
        VictimCost   = VictimCost,
        Inflictor    = InflictorClass,
        IsDrone      = IsDrone or false,
    })
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

-- Writes a fake battle between two teams as a new past session, for testing the Kill Log browser.
-- Usage: acf_killlog_dummy [kills = 500] [players per team = 4]
concommand.Add("acf_killlog_dummy", function(Player, _, Args)
    if IsValid(Player) and not Player:IsSuperAdmin() then
        ACF.PrintLog("Error", "You can't use this because you are not a superadmin.")
        return
    end

    local Kills   = math.Clamp(math.floor(tonumber(Args[1]) or 500), 1, 10000)
    local PerTeam = math.Clamp(math.floor(tonumber(Args[2]) or 4), 1, 32)
    local Teams   = { {}, {} }

    -- Fixed names and IDs, so repeated runs can be combined as the same players
    for I = 1, PerTeam do
        Teams[1][I] = { Name = "Red " .. I, ID = "DUMMY:Red" .. I, Cost = math.random(5000, 20000) }
        Teams[2][I] = { Name = "Blue " .. I, ID = "DUMMY:Blue" .. I, Cost = math.random(5000, 20000) }
    end

    local Interval = 3 -- Seconds between kills
    local Session  = os.time() - Kills * Interval - 60 -- Ends just before now, so it never merges with this session
    local Weapons  = { "acf_gun", "acf_gun", "acf_rack", "acf_piledriver" }
    local Bias     = math.Rand(0.35, 0.65) -- Chance Red gets each kill, so either side can win

    sql.Begin()

    for I = 1, Kills do
        local Winner = math.random() < Bias and 1 or 2
        local Attacker = Teams[Winner][math.random(PerTeam)]
        local Victim = Teams[3 - Winner][math.random(PerTeam)]
        local Roll = math.random()

        if Roll < 0.02 then
            Attacker = nil -- World death
        elseif Roll < 0.04 then
            Victim = Teams[Winner][math.random(PerTeam)] -- Team kill, or a self kill when it picks the attacker
        end

        local Query = string.format(
            "INSERT INTO acf_kill_log (Session, Time, Attacker, AttackerSteamID, AttackerCost, Victim, VictimSteamID, VictimCost, Inflictor, IsDrone) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
            SQLValue(Session), SQLValue(Session + I * Interval), SQLValue(Attacker and Attacker.Name), SQLValue(Attacker and Attacker.ID), SQLValue(Attacker and Attacker.Cost),
            SQLValue(Victim.Name), SQLValue(Victim.ID), SQLValue(Victim.Cost), SQLValue(Attacker and Weapons[math.random(#Weapons)]), SQLValue(math.random() < 0.05)
        )

        if sql.Query(Query) == false then
            sql.Commit()
            ACF.PrintLog("Error", "Kill Log dummy insert failed: " .. sql.LastError())
            return
        end
    end

    sql.Commit()

    ACF.PrintLog("Info", string.format("Added %d dummy kills between two teams of %d to the Kill Log.", Kills, PerTeam))
end)

-- One net string per request/response pair, reused both ways: server and client each register
-- their own net.Receive for the same name, so there's no ambiguity about which side sent it.
util.AddNetworkString("ACF_KillLog_Update")
util.AddNetworkString("ACF_KillLog_Wipe")

local ChunkRows   = 500 -- Rows per update message, compressed to stay well under the net message limit
local MaxRequests = 64  -- Sessions a single update may download rows for

local NextQueryTime = {} -- [SteamID64] = CurTime() they're next allowed to start an update
local Transfers     = {} -- [Player] = { Where = row filter, Cursor = last Id sent }, while one is in progress

hook.Add("PlayerDisconnected", "ACF_KillLog_Transfers", function(Player)
    Transfers[Player] = nil
end)

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

local function WriteCompressed(Value)
    local Data = util.Compress(util.TableToJSON(Value))

    net.WriteUInt(#Data, 32)
    net.WriteData(Data, #Data)
end

-- Starts an update: the client lists the sessions it wants rows for, each with the newest Id it already
-- has. Only these requests are rate limited, and the reply carries the full session list.
local function StartTransfer(Player)
    local SteamID = Player:SteamID64()
    if (NextQueryTime[SteamID] or 0) > CurTime() then return end

    local Count = net.ReadUInt(8)
    if Count > MaxRequests then return end

    NextQueryTime[SteamID] = CurTime() + ACF.KillLogQueryCooldown

    -- Both values are read as unsigned integers, so they can only ever be digits in the query
    local Conditions = {}
    for I = 1, Count do
        local Session = net.ReadUInt(32)
        local AfterId = net.ReadUInt(32)

        Conditions[I] = "(Session = " .. Session .. " AND Id > " .. AfterId .. ")"
    end

    FlushKillLog() -- Ensure recent kills are included too

    Transfers[Player] = Count > 0 and { Where = table.concat(Conditions, " OR "), Cursor = 0 } or nil

    return true
end

-- Sends the next chunk of rows for the requested sessions. Continuing reads no input at all: the
-- server holds the filter and cursor, so a client can only move forward through its own update.
net.Receive("ACF_KillLog_Update", function(_, Player)
    if not IsValid(Player) then return end

    local Continue = net.ReadBool()

    if Continue then
        if not Transfers[Player] then return end
    elseif not StartTransfer(Player) then
        return
    end

    local Transfer = Transfers[Player]
    local Rows     = {}

    if Transfer then
        Rows = RunSelect("SELECT * FROM acf_kill_log WHERE (" .. Transfer.Where .. ") AND Id > " .. Transfer.Cursor .. " ORDER BY Id LIMIT " .. ChunkRows)
    end

    local More = #Rows == ChunkRows

    if More then
        Transfer.Cursor = tonumber(Rows[#Rows].Id)
    else
        Transfers[Player] = nil
    end

    net.Start("ACF_KillLog_Update")
        net.WriteBool(not Continue)

        if not Continue then
            local Count, Bytes, DBSize = GetLogStats()

            WriteCompressed(RunSelect("SELECT Session, COUNT(*) AS Kills, MIN(Time) AS First, MAX(Time) AS Last FROM acf_kill_log GROUP BY Session"))
            WriteSize(Count)
            WriteSize(Bytes)
            WriteSize(DBSize)
        end

        net.WriteBool(More)
        WriteCompressed(Rows)
    net.Send(Player)
end)
