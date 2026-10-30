-- Keeps a local copy of the server's kill log in cl.db. The Update button refreshes the session list
-- and downloads kills for the selected sessions only. The browser compares two teams across them.
local ACF = ACF

local TEAM_COLORS = { Color(80, 150, 255), Color(235, 85, 70) }
local MAX_FEED_ROWS = 1000

local Browser -- The open browser window, if any

do -- MARK: Local copy
	sql.Query([[CREATE TABLE IF NOT EXISTS acf_kill_log_copy (
		Id INTEGER PRIMARY KEY,
		Session INTEGER NOT NULL,
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

	sql.Query("CREATE TABLE IF NOT EXISTS acf_kill_log_copy_meta (Key TEXT NOT NULL)")
	sql.Query([[CREATE TABLE IF NOT EXISTS acf_kill_log_copy_sessions (
		Session INTEGER PRIMARY KEY,
		Kills INTEGER NOT NULL,
		First INTEGER NOT NULL,
		Last INTEGER NOT NULL
	)]])

	local COLUMNS = {
		"Id", "Session", "Time", "Attacker", "AttackerSteamID", "AttackerCost",
		"Victim", "VictimSteamID", "VictimCost", "Inflictor", "IsDrone",
	}

	local ColumnList = table.concat(COLUMNS, ", ")

	-- Server rows arrive as strings, and NULL columns are missing entirely
	local function SQLValue(Value)
		return Value == nil and "NULL" or sql.SQLStr(Value)
	end

	local function StoreRows(Rows)
		if #Rows == 0 then return end

		sql.Begin()

		for _, Row in ipairs(Rows) do
			local Values = {}
			for I, Column in ipairs(COLUMNS) do Values[I] = SQLValue(Row[Column]) end

			sql.Query("INSERT OR REPLACE INTO acf_kill_log_copy (" .. ColumnList .. ") VALUES (" .. table.concat(Values, ", ") .. ")")
		end

		sql.Commit()
	end

	-- Replaces the session list, then drops the kills of every session the server no longer has
	local function StoreSessions(Sessions)
		sql.Begin()
		sql.Query("DELETE FROM acf_kill_log_copy_sessions")

		for _, Row in ipairs(Sessions) do
			local Values = {}
			for I, Column in ipairs({ "Session", "Kills", "First", "Last" }) do
				Values[I] = math.floor(tonumber(Row[Column]) or 0)
			end

			sql.Query("INSERT OR REPLACE INTO acf_kill_log_copy_sessions (Session, Kills, First, Last) VALUES (" .. table.concat(Values, ", ") .. ")")
		end

		sql.Query("DELETE FROM acf_kill_log_copy WHERE Session NOT IN (SELECT Session FROM acf_kill_log_copy_sessions)")
		sql.Commit()
	end

	local function GetLastId(Session)
		local Value = sql.QueryValue("SELECT MAX(Id) FROM acf_kill_log_copy WHERE Session = " .. math.floor(Session))

		return Value and tonumber(Value) or 0
	end

	local function ClearCopy()
		sql.Query("DELETE FROM acf_kill_log_copy")
		sql.Query("DELETE FROM acf_kill_log_copy_sessions")
	end

	-- The copy only ever holds one server's log, so joining another server starts it over
	local function CheckKey()
		local Key = GetGlobal2String("ACF_KillLog_Key", "")
		if Key == "" or sql.QueryValue("SELECT Key FROM acf_kill_log_copy_meta") == Key then return end

		sql.Begin()
		ClearCopy()
		sql.Query("DELETE FROM acf_kill_log_copy_meta")
		sql.Query("INSERT INTO acf_kill_log_copy_meta (Key) VALUES (" .. sql.SQLStr(Key) .. ")")
		sql.Commit()
	end

	-- Every session the server has, with how many of its kills are stored locally
	function ACF.GetKillLogSessions()
		return sql.Query([[SELECT S.Session, S.Kills, S.First, S.Last, COUNT(C.Id) AS Stored
			FROM acf_kill_log_copy_sessions S LEFT JOIN acf_kill_log_copy C ON C.Session = S.Session
			GROUP BY S.Session ORDER BY S.Session DESC]]) or {}
	end

	function ACF.GetKillLogKills(Sessions)
		if #Sessions == 0 then return {} end

		local List = {}
		for I, Session in ipairs(Sessions) do List[I] = math.floor(Session) end

		local Rows = sql.Query("SELECT * FROM acf_kill_log_copy WHERE Session IN (" .. table.concat(List, ", ") .. ") ORDER BY Session, Time, Id") or {}

		-- sql.Query returns NULL columns as the string "NULL", which no real SteamID or class can be
		for _, Row in ipairs(Rows) do
			if Row.AttackerSteamID == "NULL" then Row.Attacker, Row.AttackerSteamID = nil, nil end
			if Row.Inflictor == "NULL" then Row.Inflictor = nil end
		end

		return Rows
	end

	function ACF.GetKillLogCount()
		return tonumber(sql.QueryValue("SELECT COUNT(*) FROM acf_kill_log_copy") or 0) or 0
	end

	-- MARK: Syncing
	local UPDATE_TIMEOUT = 10 -- Seconds without a reply before an update is given up on
	local MAX_REQUESTS   = 64 -- Sessions one update may download, matching the server's limit

	local UpdateDeadline = 0 -- CurTime() an update in progress is abandoned at
	local NextUpdateTime = 0 -- Predicts the server's cooldown so the button can show it

	ACF.KillLogSync = { Received = 0, LastUpdate = nil, ServerCount = 0, ServerBytes = 0, ServerDBSize = 0 }

	local Sync = ACF.KillLogSync

	local function RequestChunk()
		UpdateDeadline = CurTime() + UPDATE_TIMEOUT

		net.Start("ACF_KillLog_Update")
			net.WriteBool(true)
		net.SendToServer()
	end

	function ACF.IsKillLogUpdating()
		return CurTime() < UpdateDeadline
	end

	function ACF.GetKillLogCooldown()
		return math.max(0, NextUpdateTime - CurTime())
	end

	--- Refreshes the session list and downloads the kills of the given sessions that aren't stored yet.
	function ACF.UpdateKillLog(Sessions)
		if ACF.IsKillLogUpdating() or ACF.GetKillLogCooldown() > 0 then return end

		CheckKey()

		local Count = math.min(#Sessions, MAX_REQUESTS)

		Sync.Received  = 0
		NextUpdateTime = CurTime() + ACF.KillLogQueryCooldown
		UpdateDeadline = CurTime() + UPDATE_TIMEOUT

		net.Start("ACF_KillLog_Update")
			net.WriteBool(false)
			net.WriteUInt(Count, 8)

			for I = 1, Count do
				net.WriteUInt(Sessions[I], 32)
				net.WriteUInt(GetLastId(Sessions[I]), 32)
			end
		net.SendToServer()
	end

	local function ReadCompressed()
		local Data = util.Decompress(net.ReadData(net.ReadUInt(32)))

		return Data and util.JSONToTable(Data) or {}
	end

	net.Receive("ACF_KillLog_Update", function()
		if net.ReadBool() then
			local Sessions = ReadCompressed()

			Sync.ServerCount  = net.ReadUInt(32)
			Sync.ServerBytes  = net.ReadUInt(32)
			Sync.ServerDBSize = net.ReadUInt(32)

			StoreSessions(Sessions)
		end

		local More = net.ReadBool()
		local Rows = ReadCompressed()

		StoreRows(Rows)

		Sync.Received = Sync.Received + #Rows

		if More then return RequestChunk() end

		UpdateDeadline  = 0
		Sync.LastUpdate = os.time()

		if IsValid(Browser) then Browser:OnCopyUpdated() end
	end)

	net.Receive("ACF_KillLog_Wipe", function()
		ClearCopy()

		if IsValid(Browser) then Browser:OnCopyUpdated() end
	end)
end

do -- MARK: Analysis
	local Teams = {} -- [SteamID64] = 1 or 2, kept until the game closes

	ACF.KillLogTeams = Teams

	local function NewTeamStats()
		return { Players = 0, Kills = 0, Deaths = 0, Destroyed = 0, Lost = 0, TeamKills = 0, SelfDeaths = 0, Drones = 0 }
	end

	--- Aggregates kills per player and per team. Team kills only count against the opposing team.
	function ACF.AnalyzeKillLog(Kills)
		local Players   = {} -- [SteamID64] = Stats
		local Order     = {}
		local TeamStats = { NewTeamStats(), NewTeamStats() }
		local Timeline  = { { { 0, 0 } }, { { 0, 0 } } } -- Cumulative points destroyed per team over elapsed time

		local function GetPlayer(ID, Name)
			local Player = Players[ID]

			if not Player then
				Player = { ID = ID, Kills = 0, Deaths = 0, Destroyed = 0, Lost = 0, Weapons = {} }

				Players[ID] = Player
				Order[#Order + 1] = Player
			end

			Player.Name = Name -- Rows are chronological, so the newest name wins

			return Player
		end

		-- Sessions are laid end to end, so the timeline skips the gaps between them
		local Session, Base, Elapsed = nil, 0, 0

		for _, Kill in ipairs(Kills) do
			local Time = tonumber(Kill.Time)

			if Kill.Session ~= Session then
				Session = Kill.Session
				Base    = Time - Elapsed
			end

			Elapsed = Time - Base

			local Cost     = tonumber(Kill.VictimCost) or 0
			local Victim   = GetPlayer(Kill.VictimSteamID, Kill.Victim)
			local Attacker = Kill.AttackerSteamID and GetPlayer(Kill.AttackerSteamID, Kill.Attacker)
			local IsSelf   = not Attacker or Attacker == Victim

			Victim.Deaths = Victim.Deaths + 1
			Victim.Lost   = Victim.Lost + Cost

			if not IsSelf then
				local Weapon = Kill.Inflictor or "Unknown"

				Attacker.Kills     = Attacker.Kills + 1
				Attacker.Destroyed = Attacker.Destroyed + Cost
				Attacker.Weapons[Weapon] = (Attacker.Weapons[Weapon] or 0) + 1
			end

			local VictimTeam   = Teams[Victim.ID]
			local AttackerTeam = Attacker and Teams[Attacker.ID]

			if VictimTeam then
				local Stats = TeamStats[VictimTeam]

				Stats.Deaths = Stats.Deaths + 1
				Stats.Lost   = Stats.Lost + Cost

				if IsSelf then
					Stats.SelfDeaths = Stats.SelfDeaths + 1
				elseif AttackerTeam == VictimTeam then
					Stats.TeamKills = Stats.TeamKills + 1
				end
			end

			if AttackerTeam and VictimTeam and AttackerTeam ~= VictimTeam then
				local Stats = TeamStats[AttackerTeam]
				local Line  = Timeline[AttackerTeam]

				Stats.Kills     = Stats.Kills + 1
				Stats.Destroyed = Stats.Destroyed + Cost

				if tonumber(Kill.IsDrone) == 1 then Stats.Drones = Stats.Drones + 1 end

				Line[#Line + 1] = { Elapsed, Stats.Destroyed }
			end
		end

		for _, Player in ipairs(Order) do
			local Team = Teams[Player.ID]
			if Team then TeamStats[Team].Players = TeamStats[Team].Players + 1 end

			local Top, TopCount = nil, 0
			for Weapon, Count in pairs(Player.Weapons) do
				if Count > TopCount then Top, TopCount = Weapon, Count end
			end

			Player.TopWeapon = Top
		end

		-- Carry both lines out to the end so they finish level with each other
		for Team, Line in ipairs(Timeline) do
			Line[#Line + 1] = { Elapsed, TeamStats[Team].Destroyed }
		end

		table.sort(Order, function(A, B) return A.Name < B.Name end)

		return Order, TeamStats, { Lines = Timeline, Duration = Elapsed }
	end

	--- Splits players into the two teams that put the most kills between them (a local max cut).
	function ACF.AutoSplitKillLog(Kills, Players)
		local Weights = {}
		local Totals  = {}

		for _, Player in ipairs(Players) do
			Weights[Player.ID] = {}
			Totals[Player.ID]  = 0
		end

		for _, Kill in ipairs(Kills) do
			local A, B = Kill.AttackerSteamID, Kill.VictimSteamID

			if A and A ~= B and Weights[A] and Weights[B] then
				Weights[A][B] = (Weights[A][B] or 0) + 1
				Weights[B][A] = (Weights[B][A] or 0) + 1
				Totals[A]     = Totals[A] + 1
				Totals[B]     = Totals[B] + 1
			end
		end

		local IDs = {}
		for I, Player in ipairs(Players) do IDs[I] = Player.ID end

		-- Most involved players first, so the greedy pass anchors on them
		table.sort(IDs, function(A, B) return Totals[A] > Totals[B] end)

		local Assigned = {}
		local Sizes    = { 0, 0 }

		local function WeightTo(ID, Team)
			local Sum = 0
			for Other, Weight in pairs(Weights[ID]) do
				if Assigned[Other] == Team then Sum = Sum + Weight end
			end

			return Sum
		end

		for _, ID in ipairs(IDs) do
			local Join1, Join2 = WeightTo(ID, 2), WeightTo(ID, 1)
			local Team = Join1 > Join2 and 1 or Join2 > Join1 and 2 or (Sizes[1] <= Sizes[2] and 1 or 2)

			Assigned[ID] = Team
			Sizes[Team]  = Sizes[Team] + 1
		end

		-- Flip anyone with more kills against their own side; the cut grows every flip, so this ends
		for _ = 1, 100 do
			local Changed = false

			for _, ID in ipairs(IDs) do
				local Team = Assigned[ID]

				if WeightTo(ID, Team) > WeightTo(ID, 3 - Team) then
					Assigned[ID] = 3 - Team
					Changed      = true
				end
			end

			if not Changed then break end
		end

		for ID, Team in pairs(Assigned) do Teams[ID] = Team end
	end
end

do -- MARK: Browser
	local MISSING_COLOR = Color(140, 140, 140) -- Sessions with no kills downloaded yet

	-- Drawn by hand, since the font strikeout flag doesn't render on every platform
	local function PaintStrikethrough(Label, _, H)
		local X = Label:GetTextInset()

		surface.SetDrawColor(MISSING_COLOR)
		surface.DrawLine(X, H / 2, X + Label:GetTextSize(), H / 2)
	end

	local function FormatTime(UnixTime)
		UnixTime = tonumber(UnixTime)
		return UnixTime and os.date("%Y-%m-%d %H:%M:%S", UnixTime) or "Unknown"
	end

	local function FormatDuration(Seconds)
		Seconds = math.floor(Seconds)

		if Seconds >= 3600 then return string.format("%d:%02d:%02d", math.floor(Seconds / 3600), math.floor(Seconds / 60) % 60, Seconds % 60) end

		return string.format("%d:%02d", math.floor(Seconds / 60), Seconds % 60)
	end

	local function FormatPoints(Points)
		return string.Comma(math.Round(Points))
	end

	local function FormatSize(Bytes)
		if Bytes >= 1048576 then return string.format("%.1f MB", Bytes / 1048576) end
		if Bytes >= 1024 then return string.format("%.1f KB", Bytes / 1024) end

		return Bytes .. " B"
	end

	-- Kills per death style ratio that stays readable when nothing was lost
	local function FormatRatio(A, B)
		if A == 0 and B == 0 then return "-" end

		return string.format("%.2f", B > 0 and A / B or A)
	end

	local function TeamName(Team)
		return Team and ("Team " .. Team) or "-"
	end

	local function CreateList(Parent, ...)
		local List = vgui.Create("DListView", Parent)
		List:Dock(FILL)
		List:SetMultiSelect(true)

		for _, Name in ipairs({...}) do
			List:AddColumn(Name).Header:SetFont("ACF_Control")
		end

		return List
	end

	local function AddLine(List, ...)
		local Line = List:AddLine(...)

		for _, Column in ipairs(Line.Columns) do Column:SetFont("ACF_Control") end

		return Line
	end

	local function CreateLabel(Parent, Text, Font)
		local Label = vgui.Create("DLabel", Parent)
		Label:Dock(TOP)
		Label:SetFont(Font or "ACF_Label")
		Label:SetText(Text or "")
		Label:SetDark(true)
		Label:SetWrap(true)
		Label:SetAutoStretchVertical(true)
		Label:DockMargin(0, 0, 0, 4)

		return Label
	end

	-- A strip of equally wide buttons
	local function CreateButtonRow(Parent, Buttons)
		local Row = vgui.Create("DPanel", Parent)
		Row:Dock(BOTTOM)
		Row:SetTall(24)
		Row:SetPaintBackground(false)
		Row:DockMargin(0, 4, 0, 0)

		for _, Def in ipairs(Buttons) do
			local Button = vgui.Create("DButton", Row)
			Button:SetText(Def[1])
			Button:SetFont("ACF_Control")
			Button.DoClick = Def[2]
		end

		function Row:PerformLayout(W, H)
			local Children = self:GetChildren()
			local Width    = W / #Children

			for I, Button in ipairs(Children) do
				Button:SetPos(math.floor((I - 1) * Width), 0)
				Button:SetSize(math.floor(Width) - 2, H)
			end
		end

		return Row
	end

	local function CreateTimeline(Parent)
		local Timeline = vgui.Create("DPanel", Parent)
		Timeline:Dock(FILL)

		local MARGIN_LEFT, MARGIN_BOTTOM, MARGIN = 60, 22, 10

		local BasePaint = Timeline.Paint

		function Timeline:Paint(W, H)
			BasePaint(self, W, H)

			local TextColor = self:GetSkin().Colours.Label.Dark -- Matches the SetDark labels around it
			local Data      = self.Data
			local Max  = Data and math.max(Data.Lines[1][#Data.Lines[1]][2], Data.Lines[2][#Data.Lines[2]][2]) or 0

			if Max <= 0 or Data.Duration <= 0 then
				draw.SimpleText("No kills between the two teams yet.", "ACF_Label", W / 2, H / 2, TextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				return
			end

			local Left, Right  = MARGIN_LEFT, W - MARGIN
			local Top, Bottom  = MARGIN, H - MARGIN_BOTTOM
			local ScaleX       = (Right - Left) / Data.Duration
			local ScaleY       = (Bottom - Top) / Max

			surface.SetDrawColor(TextColor)
			surface.DrawLine(Left, Top, Left, Bottom)
			surface.DrawLine(Left, Bottom, Right, Bottom)

			draw.SimpleText(FormatPoints(Max), "ACF_Control", Left - 4, Top, TextColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			draw.SimpleText("0", "ACF_Control", Left - 4, Bottom, TextColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
			draw.SimpleText("0:00", "ACF_Control", Left, Bottom + 2, TextColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			draw.SimpleText(FormatDuration(Data.Duration), "ACF_Control", Right, Bottom + 2, TextColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
			draw.SimpleText("Points destroyed over time", "ACF_Control", (Left + Right) / 2, Bottom + 2, TextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

			for Team, Line in ipairs(Data.Lines) do
				surface.SetDrawColor(TEAM_COLORS[Team])

				for I = 2, #Line do
					local X1, Y1 = Left + Line[I - 1][1] * ScaleX, Bottom - Line[I - 1][2] * ScaleY
					local X2, Y2 = Left + Line[I][1] * ScaleX, Bottom - Line[I][2] * ScaleY

					surface.DrawLine(X1, Y1, X2, Y1)
					surface.DrawLine(X2, Y1, X2, Y2)
				end

				draw.SimpleText(TeamName(Team), "ACF_Label", Left + 8, Top + (Team - 1) * 16, TEAM_COLORS[Team])
			end
		end

		return Timeline
	end

	local function OpenBrowser()
		if IsValid(Browser) then
			Browser:MoveToFront()
			return
		end

		local Teams = ACF.KillLogTeams
		local SW, SH = ScrW(), ScrH()

		local Frame = vgui.Create("DFrame")
		Frame:SetTitle("ACF Kill Log Browser")
		Frame:SetSize(math.min(SW, math.max(900, math.Round(SW * 0.7))), math.min(SH, math.max(560, math.Round(SH * 0.75))))
		Frame:SetMinWidth(800)
		Frame:SetMinHeight(480)
		Frame:SetSizable(true)
		Frame:Center()
		Frame:MakePopup()

		Browser = Frame

		local SideW = math.Round(Frame:GetWide() * 0.22)

		local Kills, Players = {}, {}

		-- MARK: Sessions panel
		local SessionPanel = vgui.Create("DPanel", Frame)
		SessionPanel:Dock(LEFT)
		SessionPanel:SetWide(SideW)
		SessionPanel:DockPadding(5, 5, 5, 5)
		SessionPanel:DockMargin(0, 0, 5, 0)

		CreateLabel(SessionPanel, "Sessions", "ACF_Title")
		CreateLabel(SessionPanel, "Ctrl or Shift click to combine several sessions into one battle.", "ACF_Control")

		if LocalPlayer():IsSuperAdmin() then
			local WipeButton = vgui.Create("DButton", SessionPanel)
			WipeButton:Dock(BOTTOM)
			WipeButton:SetTall(24)
			WipeButton:DockMargin(0, 4, 0, 0)
			WipeButton:SetFont("ACF_Control")
			WipeButton:SetText("Clear All Sessions")
			WipeButton:SetTextColor(Color(180, 40, 40))
			WipeButton.DoClick = function()
				Derma_Query("Permanently delete every logged session? This cannot be undone.", "Clear Kill Log", "Clear", function()
					net.Start("ACF_KillLog_Wipe")
					net.SendToServer()
				end, "Cancel")
			end
		end

		local StatusLabel = vgui.Create("DLabel", SessionPanel)
		StatusLabel:Dock(BOTTOM)
		StatusLabel:SetFont("ACF_Control")
		StatusLabel:SetDark(true)
		StatusLabel:SetWrap(true)
		StatusLabel:SetTall(64)
		StatusLabel:SetContentAlignment(7)
		StatusLabel:DockMargin(0, 4, 0, 0)

		local UpdateButton = vgui.Create("DButton", SessionPanel)
		UpdateButton:Dock(BOTTOM)
		UpdateButton:SetTall(28)
		UpdateButton:SetFont("ACF_Label")
		UpdateButton:SetText("Update")
		UpdateButton:SetTooltip("Refresh the session list and download the kills of the selected sessions.")
		UpdateButton.DoClick = function() ACF.UpdateKillLog(Frame:GetSelectedSessions()) end

		function UpdateButton:Think()
			self:SetEnabled(not ACF.IsKillLogUpdating() and ACF.GetKillLogCooldown() <= 0)
		end

		function UpdateButton:PaintOver(W, H)
			local Remaining = ACF.GetKillLogCooldown()
			if Remaining <= 0 or ACF.KillLogQueryCooldown <= 0 then return end

			surface.SetDrawColor(50, 200, 50, 60)
			surface.DrawRect(0, 0, W * (1 - Remaining / ACF.KillLogQueryCooldown), H)
		end

		local Sync = ACF.KillLogSync

		function StatusLabel:Think()
			local Text

			if ACF.IsKillLogUpdating() then
				Text = string.format("Updating, %s kills received...", string.Comma(Sync.Received))
			else
				Text = string.format("%s kills stored locally.", string.Comma(ACF.GetKillLogCount()))

				if Sync.LastUpdate then
					Text = Text .. string.format("\nLast updated %s.\nServer log is about %s", os.date("%H:%M:%S", Sync.LastUpdate), FormatSize(Sync.ServerBytes))

					if Sync.ServerDBSize > 0 then Text = Text .. string.format(" of sv.db (%s)", FormatSize(Sync.ServerDBSize)) end

					Text = Text .. "."
				end
			end

			if Text ~= self:GetText() then self:SetText(Text) end
		end

		CreateButtonRow(SessionPanel, {
			{ "Select All", function()
				for _, Line in ipairs(Frame.SessionList:GetLines()) do Line:SetSelected(true) end
				Frame:LoadKills()
			end },
			{ "Newest", function() Frame:SelectNewest() end },
		})

		local SessionList = CreateList(SessionPanel, "Started", "Kills", "Length")
		SessionList.Columns[2]:SetFixedWidth(40)
		SessionList.Columns[3]:SetFixedWidth(50)

		Frame.SessionList = SessionList

		-- Selection can change through clicks, Ctrl or Shift, so read it back after every click
		local BaseClickLine = SessionList.OnClickLine
		function SessionList:OnClickLine(...)
			BaseClickLine(self, ...)
			Frame:LoadKills()
		end

		-- MARK: Result panel
		local ResultPanel = vgui.Create("DPanel", Frame)
		ResultPanel:Dock(RIGHT)
		ResultPanel:SetWide(math.Round(SideW * 1.15))
		ResultPanel:DockPadding(5, 5, 5, 5)
		ResultPanel:DockMargin(5, 0, 0, 0)

		CreateLabel(ResultPanel, "Battle Result", "ACF_Title")

		local VerdictLabel = CreateLabel(ResultPanel, "", "ACF_Title")
		local DetailLabel  = CreateLabel(ResultPanel, "", "ACF_Control")

		local CompareList = CreateList(ResultPanel, "Metric", "Team 1", "Team 2")
		CompareList:SetMultiSelect(false)
		CompareList:SetSortable(false)

		-- MARK: Players and kills
		local CenterPanel = vgui.Create("DPanel", Frame)
		CenterPanel:Dock(FILL)
		CenterPanel:DockPadding(5, 5, 5, 5)

		local PlayerPanel = vgui.Create("DPanel", CenterPanel)
		PlayerPanel:Dock(TOP)
		PlayerPanel:SetPaintBackground(false)
		PlayerPanel:DockMargin(0, 0, 0, 5)

		function CenterPanel:PerformLayout(_, H)
			PlayerPanel:SetTall(math.Round(H * 0.45))
		end

		CreateLabel(PlayerPanel, "Players", "ACF_Title")
		CreateLabel(PlayerPanel, "Select players and pick their team, or double click one to cycle it. Auto Split guesses the teams from who killed whom.", "ACF_Control")

		local PlayerList

		local function SetSelectedTeam(Team)
			for _, Line in ipairs(PlayerList:GetSelected()) do Teams[Line.ID] = Team end

			Frame:Refresh()
		end

		CreateButtonRow(PlayerPanel, {
			{ "Team 1", function() SetSelectedTeam(1) end },
			{ "Team 2", function() SetSelectedTeam(2) end },
			{ "Unassign", function() SetSelectedTeam(nil) end },
			{ "Auto Split", function() ACF.AutoSplitKillLog(Kills, Players) Frame:Refresh() end },
			{ "Clear Teams", function()
				for _, Player in ipairs(Players) do Teams[Player.ID] = nil end
				Frame:Refresh()
			end },
		})

		PlayerList = CreateList(PlayerPanel, "Player", "Team", "Kills", "Deaths", "Destroyed", "Lost", "Top Weapon")

		function PlayerList:DoDoubleClick(_, Line)
			local Team = Teams[Line.ID]

			Teams[Line.ID] = not Team and 1 or Team == 1 and 2 or nil

			Frame:Refresh()
		end

		local Sheet = vgui.Create("DPropertySheet", CenterPanel)
		Sheet:Dock(FILL)

		local FeedList = CreateList(Sheet, "Time", "Attacker", "Victim", "Weapon", "Cost")
		FeedList:SetMultiSelect(false)
		Sheet:AddSheet("Kills", FeedList, "icon16/table.png")

		local Timeline = CreateTimeline(Sheet)
		Sheet:AddSheet("Timeline", Timeline, "icon16/chart_line.png")

		-- MARK: Refreshing
		function Frame:SelectNewest()
			SessionList:ClearSelection()

			local Line = SessionList:GetLines()[1]
			if Line then Line:SetSelected(true) end

			self:LoadKills()
		end

		-- Rebuilds the session list from the copy, keeping whatever was selected
		function Frame:OnCopyUpdated()
			local Selected = {}
			for _, Line in ipairs(SessionList:GetSelected()) do Selected[Line.Session] = true end

			SessionList:Clear()

			local HasSelection = false

			for _, Row in ipairs(ACF.GetKillLogSessions()) do
				local Session   = tonumber(Row.Session)
				local Length    = tonumber(Row.Last) - tonumber(Row.First)
				local KillCount = tonumber(Row.Kills)
				local Stored    = tonumber(Row.Stored)
				local KillText  = (Stored > 0 and Stored < KillCount) and (Stored .. "/" .. KillCount) or KillCount
				local Line      = AddLine(SessionList, FormatTime(Session), KillText, FormatDuration(Length))

				Line:SetSortValue(1, Session)
				Line:SetSortValue(2, KillCount)
				Line:SetSortValue(3, Length)
				Line.Session = Session

				if Stored == 0 then
					for _, Column in ipairs(Line.Columns) do
						Column:SetTextColor(MISSING_COLOR)
						Column.PaintOver = PaintStrikethrough
					end

					Line:SetTooltip("Not downloaded yet. Select it and press Update.")
				end

				if Selected[Session] then
					Line:SetSelected(true)
					HasSelection = true
				end
			end

			if HasSelection then self:LoadKills() else self:SelectNewest() end
		end

		function Frame:GetSelectedSessions()
			local Sessions = {}
			for _, Line in ipairs(SessionList:GetSelected()) do Sessions[#Sessions + 1] = Line.Session end

			return Sessions
		end

		function Frame:LoadKills()
			Kills = ACF.GetKillLogKills(self:GetSelectedSessions())

			self:Refresh()
		end

		local function ColorTeam(Line, Column, ID)
			local Team = ID and Teams[ID]
			if Team then Line.Columns[Column]:SetTextColor(TEAM_COLORS[Team]) end
		end

		function Frame:Refresh()
			local TeamStats, TimelineData
			Players, TeamStats, TimelineData = ACF.AnalyzeKillLog(Kills)

			-- Players
			local Selected = {}
			for _, Line in ipairs(PlayerList:GetSelected()) do Selected[Line.ID] = true end

			PlayerList:Clear()

			for _, Player in ipairs(Players) do
				local Line = AddLine(PlayerList, Player.Name, TeamName(Teams[Player.ID]), Player.Kills, Player.Deaths,
					FormatPoints(Player.Destroyed), FormatPoints(Player.Lost), Player.TopWeapon or "-")

				Line:SetSortValue(5, Player.Destroyed)
				Line:SetSortValue(6, Player.Lost)
				Line.ID = Player.ID

				ColorTeam(Line, 1, Player.ID)
				ColorTeam(Line, 2, Player.ID)

				if Selected[Player.ID] then Line:SetSelected(true) end
			end

			-- Kill feed, newest first
			FeedList:Clear()

			for I = #Kills, math.max(1, #Kills - MAX_FEED_ROWS + 1), -1 do
				local Kill   = Kills[I]
				local Victim = tonumber(Kill.IsDrone) == 1 and (Kill.Victim .. "'s Drone") or Kill.Victim
				local Line   = AddLine(FeedList, FormatTime(Kill.Time), Kill.Attacker or "-", Victim, Kill.Inflictor or "-", FormatPoints(tonumber(Kill.VictimCost) or 0))

				Line:SetSortValue(1, tonumber(Kill.Time))
				Line:SetSortValue(5, tonumber(Kill.VictimCost) or 0)

				ColorTeam(Line, 2, Kill.AttackerSteamID)
				ColorTeam(Line, 3, Kill.VictimSteamID)
			end

			Timeline.Data = TimelineData

			self:ShowResult(TeamStats)
		end

		function Frame:ShowResult(TeamStats)
			local T1, T2 = TeamStats[1], TeamStats[2]

			CompareList:Clear()
			CompareList.Columns[2]:SetName("Team 1")
			CompareList.Columns[3]:SetName("Team 2")

			if #Kills == 0 then
				VerdictLabel:SetText("No kills")
				VerdictLabel:SetTextColor(nil)
				DetailLabel:SetText(#SessionList:GetSelected() > 0 and "Press Update to download the selected sessions." or "Select a session.")
				return
			end

			if T1.Players == 0 or T2.Players == 0 then
				self:ShowTopPlayer()
				return
			end

			-- Points destroyed decide it, since a cheap kill and an expensive one are not worth the same
			local Winner
			if T1.Destroyed ~= T2.Destroyed then
				Winner = T1.Destroyed > T2.Destroyed and 1 or 2
			elseif T1.Kills ~= T2.Kills then
				Winner = T1.Kills > T2.Kills and 1 or 2
			end

			if Winner then
				local Win, Lose = TeamStats[Winner], TeamStats[3 - Winner]

				VerdictLabel:SetText(TeamName(Winner) .. " won")
				VerdictLabel:SetTextColor(TEAM_COLORS[Winner])
				DetailLabel:SetText(string.format("Destroyed %s points while losing %s, with %d kills to %d.",
					FormatPoints(Win.Destroyed), FormatPoints(Win.Lost), Win.Kills, Lose.Kills))
			else
				VerdictLabel:SetText("Draw")
				VerdictLabel:SetTextColor(nil)
				DetailLabel:SetText("Both teams destroyed the same points with the same number of kills.")
			end

			-- Best player per team by points destroyed
			local Best = {}
			for _, Player in ipairs(Players) do
				local Team = Teams[Player.ID]

				if Team and Player.Destroyed > 0 and (not Best[Team] or Player.Destroyed > Best[Team].Destroyed) then
					Best[Team] = Player
				end
			end

			local Rows = {
				{ "Players", T1.Players, T2.Players },
				{ "Kills", T1.Kills, T2.Kills },
				{ "Deaths", T1.Deaths, T2.Deaths },
				{ "K/D", FormatRatio(T1.Kills, T1.Deaths), FormatRatio(T2.Kills, T2.Deaths) },
				{ "Points Destroyed", FormatPoints(T1.Destroyed), FormatPoints(T2.Destroyed) },
				{ "Points Lost", FormatPoints(T1.Lost), FormatPoints(T2.Lost) },
				{ "Exchange Ratio", FormatRatio(T1.Destroyed, T1.Lost), FormatRatio(T2.Destroyed, T2.Lost) },
				{ "Drones Destroyed", T1.Drones, T2.Drones },
				{ "Team Kills", T1.TeamKills, T2.TeamKills },
				{ "Self/World Deaths", T1.SelfDeaths, T2.SelfDeaths },
				{ "Top Player", Best[1] and Best[1].Name or "-", Best[2] and Best[2].Name or "-" },
			}

			for _, Row in ipairs(Rows) do
				local Line = AddLine(CompareList, unpack(Row))

				Line.Columns[2]:SetTextColor(TEAM_COLORS[1])
				Line.Columns[3]:SetTextColor(TEAM_COLORS[2])
			end
		end

		-- Without two teams there is no battle to judge, so compare the top player with the runner up
		function Frame:ShowTopPlayer()
			local Ranked, TotalDestroyed = {}, 0

			for I, Player in ipairs(Players) do
				Ranked[I]      = Player
				TotalDestroyed = TotalDestroyed + Player.Destroyed
			end

			-- Same order as the team verdict: points destroyed, then kills
			table.sort(Ranked, function(A, B)
				if A.Destroyed ~= B.Destroyed then return A.Destroyed > B.Destroyed end

				return A.Kills > B.Kills
			end)

			local Top, Second = Ranked[1], Ranked[2]
			local TopTeam = Teams[Top.ID]

			VerdictLabel:SetText("Top player: " .. Top.Name)
			VerdictLabel:SetTextColor(TopTeam and TEAM_COLORS[TopTeam] or nil)
			DetailLabel:SetText(string.format("Destroyed %s points with %d kills. Assign players to both teams to see who won.",
				FormatPoints(Top.Destroyed), Top.Kills))

			CompareList.Columns[2]:SetName(Top.Name)
			CompareList.Columns[3]:SetName(Second and Second.Name or "-")

			local function Share(Player)
				return TotalDestroyed > 0 and string.format("%.0f%%", Player.Destroyed / TotalDestroyed * 100) or "-"
			end

			local Rows = {
				{ "Kills", function(P) return P.Kills end },
				{ "Deaths", function(P) return P.Deaths end },
				{ "K/D", function(P) return FormatRatio(P.Kills, P.Deaths) end },
				{ "Points Destroyed", function(P) return FormatPoints(P.Destroyed) end },
				{ "Points Lost", function(P) return FormatPoints(P.Lost) end },
				{ "Exchange Ratio", function(P) return FormatRatio(P.Destroyed, P.Lost) end },
				{ "Share of Points", Share },
				{ "Top Weapon", function(P) return P.TopWeapon or "-" end },
			}

			for _, Row in ipairs(Rows) do
				AddLine(CompareList, Row[1], Row[2](Top), Second and Row[2](Second) or "-")
			end
		end

		Frame:OnCopyUpdated()

		-- No session list yet, so fetch it straight away
		if #SessionList:GetLines() == 0 then ACF.UpdateKillLog({}) end
	end

	local function CreateMenu(Menu)
		Menu:AddTitle("Kill Log")
		Menu:AddLabel("Browse past battles on this server. Pick one or more sessions, split the players into two teams, and see which side came out ahead.")
		Menu:AddButton("Open Kill Log Browser", OpenBrowser)
	end

	ACF.AddMenuItem(402, "Tools", "Kill Log", "chart_bar", CreateMenu)
end
