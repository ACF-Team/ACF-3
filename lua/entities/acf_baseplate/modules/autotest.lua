-- TODO: ACF Missiles tests
local TestCategories = {}
local Tests = {}
local TestMap = {}

local function RegisterTestCategory(CategoryName)
    if not Tests[CategoryName] then
        table.insert(TestCategories, CategoryName)
        Tests[CategoryName] = {}
    end
end

local function RegisterTest(CategoryName, TestName, TestFunc, FixFunc, Advice)
    if not Tests[CategoryName] then RegisterTestCategory(CategoryName) end

    local testData = {
        Name = TestName,
        Func = TestFunc,
        Advice = Advice or "",
        FixFunc = FixFunc
    }
    table.insert(Tests[CategoryName], testData)
    TestMap[TestName] = testData
end

-- Sets up the test environment for each test, from the baseplate.
local function SetupTests(Env)
    Env.Physical = constraint.GetAllConstrainedEntities(Env.Baseplate)
    Env.Contraption = Env.Baseplate:GetContraption()
end

-- Returns a list of entities missing the required links
local function GetEntsMissingLinks(Entities, LinkStores)
    if not Entities then return {} end
    local Missing = {}

    for Ent in pairs(Entities) do
        local found = false
        for _, LinkStore in ipairs(LinkStores) do
            local Links = Ent[LinkStore]
            if istable(Links) then
                if not table.IsEmpty(Links) then found = true end
            elseif IsValid(Links) then
                found = true
            end
        end
        if not found then table.insert(Missing, Ent) end
    end
    return Missing
end

-- Links all entities of Type1 to all entities of Type2
local function LinkAll(Env, Type1, Type2)
    for Ent1 in pairs(Env.Contraption.entsbyclass[Type1] or {}) do
        for Ent2 in pairs(Env.Contraption.entsbyclass[Type2] or {}) do
            Ent1:Link(Ent2)
        end
    end
end

local ParentedVisibilityWhitelist = {
    prop_physics = true,
    primitive_shape = true,
}

---------------------------------------------------------------------------------------------------------------------------
-- TEST DEFINITIONS
---------------------------------------------------------------------------------------------------------------------------

RegisterTest("Optimization", "Physical Entity Constraints", function(Env)
    local Max = 8
    local Faults = {}
    for _, v in pairs(Env.Physical) do
        if v ~= Env.Baseplate then
            local Count = table.Count(constraint.GetTable(v))
            if Count > Max then
                table.insert(Faults, {Ent = v, Msg = "Excessive constraints (" .. Count .. " > " .. Max .. ")"})
            end
        end
    end
    return #Faults == 0, Faults
end, nil, "Try to remove unnecessary constraints in your suspension or between props.")

-- 2. Parenting vs Constraints Check
RegisterTest("Optimization", "Parented Entity Constraints", function(Env)
    local Faults = {}
    for _, v in pairs(Env.Physical) do
        if v ~= Env.Baseplate and IsValid(v:GetParent()) then
            table.insert(Faults, {Ent = v, Msg = "Entity is both parented and constrained"})
        end
    end
    return #Faults == 0, Faults
end, function(Env)
    for _, v in pairs(Env.Physical) do
        if v ~= Env.Baseplate and IsValid(v:GetParent()) then constraint.RemoveAll(v) end
    end
end, "Parented props should not have physical constraints")

-- 3. Physical Prop Visibility
RegisterTest("Optimization", "Physical Prop Visibility", function(Env)
    local Faults = {}
    for _, v in pairs(Env.Physical) do
        if v ~= Env.Baseplate and v:GetColor().a ~= 0 and not v:GetNoDraw() then
            table.insert(Faults, {Ent = v, Msg = "Physical prop should be alpha 0 or NoDraw"})
        end
    end
    return #Faults == 0, Faults
end, function(Env)
    for _, v in pairs(Env.Physical) do
        if v ~= Env.Baseplate and v:GetColor().a ~= 0 then
            v:SetColor(Color(255, 255, 255, 0))
            v:SetRenderMode(RENDERMODE_TRANSCOLOR)
        end
    end
end, "Physical props should be invisible")

-- 4. Parented Prop Visibility (General)
RegisterTest("Optimization", "Parented Prop Visibility", function(Env)
    local Faults = {}
    for v in pairs(Env.Contraption.ents) do
        if IsValid(v:GetParent()) and ParentedVisibilityWhitelist[v:GetClass()] and v:GetColor().a ~= 0 and not v:GetNoDraw() then
            table.insert(Faults, {Ent = v, Msg = "Parented prop should be alpha 0 or NoDraw"})
        end
    end
    return #Faults == 0, Faults
end, function(Env)
    for v in pairs(Env.Contraption.ents) do
        if IsValid(v:GetParent()) and ParentedVisibilityWhitelist[v:GetClass()] and v:GetColor().a ~= 0 then
            v:SetColor(Color(255, 255, 255, 0))
            v:SetRenderMode(RENDERMODE_TRANSCOLOR)
        end
    end
end, "Parented armor props should be invisible")

RegisterTest("Optimization", "Total Entity Count", function(Env)
    local MaxEntities = 150
    local TotalEnts = Env.Contraption.count
    if TotalEnts > MaxEntities then
        return false, {{Ent = Env.Baseplate, Msg = "Total entities " .. TotalEnts .. " > " .. MaxEntities}}
    end
    return true, "Entity count OK"
end, nil, "Use prop to mesh to merge detail props")

RegisterTest("Optimization", "Total Physical Entity Count", function(Env)
    local MaxPhysicals = 11
    local TotalPhysical = table.Count(Env.Physical)
    if TotalPhysical > MaxPhysicals then
        return false, {{Ent = Env.Baseplate, Msg = "Physical entities " .. TotalPhysical .. " > " .. MaxPhysicals}}
    end
    return true, "Physical count OK"
end, nil, "Only your baseplate, wheels and possibly steer plate need to be physical")

RegisterTest("Optimization", "Total Constraints", function(Env)
    -- Check max total constraint count
    local MaxConstraintsTotal = 50
    local TotalConstraints = table.Count(Env.UniqueConstraints or {})
    if TotalConstraints > MaxConstraintsTotal then
        return false, {{Ent = Env.Baseplate, Msg = "Total constraints (" .. TotalConstraints .. ") exceeds recommended (" .. MaxConstraintsTotal .. ")"}}
    end
    return true, "Constraint count OK"
end, nil, "Try to remove unnecessary constraints in your suspension or between props")

RegisterTest("Optimization", "P2M Controller", function(Env)
    if table.IsEmpty(Env.Contraption.entsbyclass.sent_prop2mesh or {}) then
        return false, {{Ent = Env.Baseplate, Msg = "Missing p2m controller for visual optimization"}}
    end
    return true, "P2M found"
end, nil, "Use prop to mesh to merge detail props")

RegisterTest("Crew", "Basic Crew", function(Env)
    local Necessary = {}
    if Env.Contraption:ACF_IsGroundVehicle() then
        if not table.IsEmpty(Env.Contraption.entsbyclass.acf_turret or {}) then Necessary.Gunner = true end
        if not table.IsEmpty(Env.Contraption.entsbyclass.acf_engine or {}) then Necessary.Driver = true end
    elseif Env.Contraption:ACF_IsAircraft() then
        Necessary.Pilot = true
    end

    local Faults = {}
    for Type in pairs(Necessary) do
        local Crews = Env.Contraption.CrewsByType and Env.Contraption.CrewsByType[Type] or {}
        if table.IsEmpty(Crews) then
            table.insert(Faults, {Ent = Env.Baseplate, Msg = "Vehicle missing " .. Type})
        end
    end
    return #Faults == 0, Faults
end, nil, "Ensure all necessary crew members are present")

RegisterTest("Crew", "Crew Efficiency", function(Env)
    local MinEff = 0.25
    local Faults = {}
    for _, v in ipairs(Env.Contraption.Crews or {}) do
        if v.TotalEff <= MinEff then
            table.insert(Faults, {Ent = v.Ent or Env.Baseplate, Msg = "Efficiency " .. math.Round(v.TotalEff, 2) .. " is too low"})
        end
    end
    return #Faults == 0, Faults
end, nil, "Ensure crew members have adequate efficiency")

RegisterTest("Links", "Guns, Racks and Ammo", function(Env)
    local Faults = {}
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_gun, {"Crates"})) do table.insert(Faults, {Ent = e, Msg = "Gun needs link to ammo crate"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_rack, {"Crates"})) do table.insert(Faults, {Ent = e, Msg = "Rack needs link to ammo crate"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_ammo, {"Weapons"})) do table.insert(Faults, {Ent = e, Msg = "Ammo needs link to weapons"}) end

    -- Don't have to have a loader for belt fed or smoke launchers
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_gun, {"Crews", "Autoloader"})) do
        if not e.IsBelted and e.Weapon ~= "ACF.Guns.SmokeLauncher" and e.Weapon ~= "40mmFGL" then
            table.insert(Faults, {Ent = e, Msg = "Gun needs link to loader/autoloader"})
        end
    end

    -- for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_rack, {"Crew", "Autoloader"})) do table.insert(Faults, {Ent = e, Msg = "Ammo unlinked from Guns"}) end
    return #Faults == 0, Faults
end, function(Env)
    LinkAll(Env, "acf_gun", "acf_ammo")
    LinkAll(Env, "acf_rack", "acf_ammo")
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_gun, {"Crew", "Autoloader"})) do
        if not e.IsBelted and e.Weapon ~= "ACF.Guns.SmokeLauncher" and e.Weapon ~= "40mmFGL" then
            for _, crew in pairs(Env.Contraption.Crews or {}) do
                if crew.Type == "Loader" then e:Link(crew.Ent) end
            end
        end
    end
end, "Ensure all guns and racks are linked to ammo crates, and all ammo crates are linked to guns or racks")

RegisterTest("Links", "Guidance", function(Env)
    local Faults = {}
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_rack, {"Computer"})) do
        for crate in pairs(e.Crates or {}) do
            if crate.Guidance ~= "Dumb" then table.insert(Faults, {Ent = e, Msg = "Guided rack needs link to guidance computer"}) break end
        end
    end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_computer, {"Weapons"})) do table.insert(Faults, {Ent = e, Msg = "Guidance computer needs link to guns or racks"}) end
    return #Faults == 0, Faults
end, function(Env)
    LinkAll(Env, "acf_computer", "acf_rack")
end, "Ensure all ground loaders are linked to racks and ammo crates")

RegisterTest("Links", "Engines, Fuel and Gearboxes", function(Env)
    local Faults = {}
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_fueltank, {"Engines"})) do table.insert(Faults, {Ent = e, Msg = "Fuel Tank shares no parent with a compatible engine"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_engine, {"FuelTanks"})) do table.insert(Faults, {Ent = e, Msg = "Engine shares no parent with a compatible fuel tank"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_engine, {"Gearboxes"})) do table.insert(Faults, {Ent = e, Msg = "Engine needs link to Gearbox"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_gearbox, {"GearboxIn", "Engines"})) do table.insert(Faults, {Ent = e, Msg = "Gearbox missing Input link"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_gearbox, {"GearboxOut", "Wheels", "Effectors"})) do table.insert(Faults, {Ent = e, Msg = "Gearbox missing Output link"}) end
    return #Faults == 0, Faults
end, function(Env)
    LinkAll(Env, "acf_engine", "acf_gearbox") -- Fuel can't be fixed by linking; tanks must share the engine's parent
end, "Ensure engines share a parent with compatible fuel tanks, engines are linked to gearboxes, and all gearboxes have proper input and output links")

RegisterTest("Baseplate", "Orientation", function(Env)
    local Deviation = math.deg(math.acos(Env.Baseplate:GetForward():Dot(Vector(0, 1, 0))))
    if Deviation > 0.05 then
        return false, {{Ent = Env.Baseplate, Msg = "Baseplate is misaligned with north by " .. math.Round(Deviation, 2) .. " degrees"}}
    end
    return true
end, function(Env)
    Env.Baseplate:SetAngles(Angle(0, 90, 0))
end, "The smile paint / sprays face north")

RegisterTest("AIO", "Drivetrain Discovery", function(Env)
    local AIO = next(Env.Contraption.entsbyclass.acf_controller or {})
    if not AIO then return true, "No AIO controller found" end

    local Faults = {}
    for Ent in pairs(Env.Contraption.entsbyclass.acf_gearbox or {}) do
        if not AIO.GearboxEnds[Ent] and not AIO.GearboxIntermediates[Ent] then table.insert(Faults, {Ent = Ent, Msg = "Gearbox not discovered by AIO"}) end
    end
    for _, Ent in pairs(Env.Physical) do
        local Gearboxes = Ent.ACF_Gearboxes
        if Gearboxes and table.Count(Gearboxes) > 1 then table.insert(Faults, {Ent = Ent, Msg = "Entity powered by multiple gearboxes"}) end
    end
    return #Faults == 0, Faults
end, nil, "A gearbox is probably not linked to the rest of the drivetrain")

---------------------------------------------------------------------------------------------------------------------------
-- Networking + autotest function
---------------------------------------------------------------------------------------------------------------------------

if SERVER then
    util.AddNetworkString("ACF_Baseplate_RunTest")
    util.AddNetworkString("ACF_Baseplate_TestResult")
    util.AddNetworkString("ACF_Baseplate_AutotestReport")

    -- Runs a single test (or its fix) on a baseplate. Does no permission checks or rate limiting.
    function ACF.RunBaseplateAutotest(Baseplate, TestName, IsFix)
        if not IsValid(Baseplate) or Baseplate:GetClass() ~= "acf_baseplate" then return false, "Not a valid baseplate" end
        if not Baseplate:GetContraption() then return false, "Baseplate is not part of a contraption" end

        local Test = TestMap[TestName]
        if not Test then return false, "No test with that name exists" end

        local Env = {Baseplate = Baseplate}
        SetupTests(Env)

        if IsFix then
            if not Test.FixFunc then return false, "This test has no fix" end
            Test.FixFunc(Env)
            return true
        end

        return Test.Func(Env)
    end

    -- Runs every test on a baseplate. Returns a list of {Name, OK, Results} and the total number of faults.
    function ACF.RunAllBaseplateAutotests(Baseplate)
        local AllResults, FaultCount = {}, 0

        for _, Category in ipairs(TestCategories) do
            for _, Test in ipairs(Tests[Category]) do
                -- One broken test shouldn't stop the rest from running
                local Success, OK, Results = xpcall(ACF.RunBaseplateAutotest, function(Err)
                    ErrorNoHaltWithStack(Err)
                    return Err
                end, Baseplate, Test.Name)

                if not Success then Results = "Test errored: " .. tostring(OK) end
                OK = Success and OK or false

                if not OK then FaultCount = FaultCount + (istable(Results) and #Results or 1) end
                AllResults[#AllResults + 1] = {Name = Test.Name, OK = OK, Results = Results}
            end
        end

        return AllResults, FaultCount
    end

    -- Faults are sent as entity indices since they may not exist clientside yet (e.g. right after a paste)
    local function WriteResult(TestName, OK, Results)
        net.WriteString(TestName)
        net.WriteBool(OK)
        if not OK and istable(Results) and #Results > 0 then
            net.WriteUInt(#Results, 16)
            for _, Fault in ipairs(Results) do
                net.WriteUInt(IsValid(Fault.Ent) and Fault.Ent:EntIndex() or 0, MAX_EDICT_BITS)
                net.WriteString(Fault.Msg)
            end
        else
            net.WriteUInt(0, 16)
            net.WriteString(isstring(Results) and Results or "Success")
        end
    end

    local LastRun = {}

    net.Receive("ACF_Baseplate_RunTest", function(_, Player)
        local Baseplate, TestName, IsFix = net.ReadEntity(), net.ReadString(), net.ReadBool()

        if not IsValid(Baseplate) or not Baseplate.IsACFBaseplate then return end
        if not TestMap[TestName] then return end
        if not Baseplate:CPPICanTool(Player, "") then return end

        -- Rate limit: 2-second global cooldown per test
        local Time = CurTime()
        if (LastRun[TestName] or 0) + 2 > Time then return end
        LastRun[TestName] = Time

        local OK, Results = ACF.RunBaseplateAutotest(Baseplate, TestName, IsFix)
        if IsFix then return end

        net.Start("ACF_Baseplate_TestResult")
            WriteResult(TestName, OK or false, Results)
        net.Send(Player)
    end)

    -- Autotest baseplates in freshly pasted dupes, and tell the player if anything failed
    local LastAutotest = setmetatable({}, {__mode = "k"})

    hook.Add("AdvDupe_FinishPasting", "ACF_Autotest_CatchInitialErrors", function(DupeInfo)
        local Dupe   = DupeInfo[1]
        local Player = Dupe.Player
        if not IsValid(Player) then return end

        local Now = CurTime()
        if (LastAutotest[Player] or 0) + 5 > Now then return end

        local Baseplates = {}
        for _, Entity in pairs(Dupe.CreatedEntities) do
            if IsValid(Entity) and Entity:GetClass() == "acf_baseplate" then
                Baseplates[#Baseplates + 1] = Entity
            end
        end
        if #Baseplates == 0 then return end

        LastAutotest[Player] = Now

        -- Give links, crew and contraptions a moment to settle before testing
        timer.Simple(1, function()
            if not IsValid(Player) then return end

            for _, Baseplate in ipairs(Baseplates) do
                if IsValid(Baseplate) then
                    local AllResults, FaultCount = ACF.RunAllBaseplateAutotests(Baseplate)

                    if FaultCount > 0 then
                        net.Start("ACF_Baseplate_AutotestReport")
                            net.WriteUInt(Baseplate:EntIndex(), MAX_EDICT_BITS)
                            net.WriteUInt(FaultCount, 16)
                            net.WriteUInt(#AllResults, 8)
                            for _, Result in ipairs(AllResults) do
                                WriteResult(Result.Name, Result.OK, Result.Results)
                            end
                        net.Send(Player)
                    end
                end
            end
        end)
    end)
end

---------------------------------------------------------------------------------------------------------------------------
-- UI INITIALIZATION
---------------------------------------------------------------------------------------------------------------------------

local function RunTest(Ent, Name, IsFix)
    net.Start("ACF_Baseplate_RunTest")
        net.WriteEntity(Ent)
        net.WriteString(Name)
        net.WriteBool(IsFix)
    net.SendToServer()
end

local ApplyQueuedResults

if CLIENT then
    local QueuedResults = {} -- Paste autotest results waiting for their baseplate's autotester to be opened, by entity index

    local function ReadResult()
        local Result = {Name = net.ReadString(), OK = net.ReadBool(), Faults = {}}
        local Count = net.ReadUInt(16)

        if Count == 0 then Result.Message = net.ReadString() end
        for I = 1, Count do
            Result.Faults[I] = {EntIndex = net.ReadUInt(MAX_EDICT_BITS), Msg = net.ReadString()}
        end

        return Result
    end

    -- Shows a test result in the currently open autotester
    local function ApplyResult(Result)
        local test = TestMap[Result.Name]
        if not test or not IsValid(test.RowCategory) then return end

        local ok = Result.OK
        test.RowCategory.Header.ResultColor = ok and Color(0, 200, 0, 150) or Color(255, 0, 0, 150)

        local Content = test.RowCategory.Contents
        Content:Clear()

        if Result.Message then
            local Lbl = Content:Add("DLabel")
            Lbl:SetText((ok and "  PASSED: " or "  FAILED: ") .. Result.Message)
            Lbl:Dock(TOP)
            Lbl:SetDark(true)
            Lbl:DockMargin(10, 5, 10, 5)
        end

        for _, Fault in ipairs(Result.Faults) do
            local targetEnt = Entity(Fault.EntIndex)

            local Btn = Content:Add("DButton")
            Btn:SetText("[" .. (Fault.EntIndex ~= 0 and Fault.EntIndex or "NULL") .. "] " .. Fault.Msg)
            Btn:Dock(TOP)
            Btn:DockMargin(5, 2, 5, 2)
            Btn:SetContentAlignment(4)
            Btn:SetTextInset(8, 0)
            Btn.DoClick = function()
                if not IsValid(targetEnt) then targetEnt = Entity(Fault.EntIndex) end
                if not IsValid(targetEnt) then return end
                local View = render.GetViewSetup()
                local Lookat = (targetEnt:WorldSpaceCenter() - View.origin):Angle()
                ACF.Utilities.Notify.InterpViewAngleTo(Lookat, nil, function()
                    ACF.Utilities.Notify.SingleEntityImpulse(targetEnt)
                end, 0.8)
                ACF.Utilities.Notify.SingleEntityImpulse(targetEnt)
            end
        end

        test.RowCategory:SetExpanded(not ok)
        test.RowCategory:InvalidateLayout(true)
    end

    net.Receive("ACF_Baseplate_TestResult", function()
        ApplyResult(ReadResult())
    end)

    net.Receive("ACF_Baseplate_AutotestReport", function()
        local EntIndex   = net.ReadUInt(MAX_EDICT_BITS)
        local FaultCount = net.ReadUInt(16)
        local Results    = {}

        for I = 1, net.ReadUInt(8) do Results[I] = ReadResult() end
        QueuedResults[EntIndex] = Results

        local Key = input.LookupBinding("+menu_context")
        Key = Key and Key:upper() or "C"

        local Messages = ACF.Utilities.Messages
        Messages.PrintChat("Info", "The contraption on baseplate #" .. EntIndex .. " failed the autotest with " .. FaultCount .. " failure(s).")
        Messages.PrintChat("Info", "To find out why, open the Context Menu (" .. Key .. "), right click on the baseplate, and click \"Autotester\".")
    end)

    -- Don't let stale results show up on a different entity that reuses the index
    hook.Add("EntityRemoved", "ACF_Baseplate_AutotestQueueCleanup", function(Ent, FullUpdate)
        if FullUpdate then return end
        QueuedResults[Ent:EntIndex()] = nil
    end)

    ApplyQueuedResults = function(Ent)
        local Results = QueuedResults[Ent:EntIndex()]
        if not Results then return end

        QueuedResults[Ent:EntIndex()] = nil
        for _, Result in ipairs(Results) do ApplyResult(Result) end
    end
end

return function()
    if CLIENT then
        local Autotester = {
            MenuLabel = "Autotester",
            Order = 99999,
            PrependSpacer = true,
            MenuIcon = "icon16/image_edit.png",

            Filter = function(_, ent) return IsValid(ent) and ent.IsACFBaseplate end,

            Action = function(_, ent)
                local window = g_ContextMenu:Add("DFrame")
                window:SetSize(480, ScrH() * 0.75)
                window:SetTitle("Baseplate Autotester [" .. ent:EntIndex() .. "]")
                window:Center()
                window:SetSizable(true)
                window:SetDraggable(true)
                window:MoveToFront()

                local BackPanel = window:Add("DPanel") -- This is just to draw the DWindow background basically
                BackPanel:Dock(FILL)

                local Base = BackPanel:Add("ACF_Panel")
                Base:Dock(FILL)
                Base:DockMargin(4, 4, 4, 4)

                Base:AddLabel("IMPORTANT NOTICE:")
                Base:AddLabel("Click result buttons to highlight and snap camera to offending entities.")
                Base:AddLabel("If the tests are gray, then you need to wait for a global cooldown to prevent spam.")
                Base:AddLabel("Fixes are irreversible and may have unintended side effects. Run at your own risk.")
                Base:AddLabel("Hovering over a test will show you advice on how to fix it.")

                Base:AddButton("Run All Tests", function()
                    for _, test in pairs(TestMap) do
                        if IsValid(test.RowCategory) and IsValid(test.RowCategory.Header) then
                            test.RowCategory.Header.ResultColor = nil
                        end
                        RunTest(ent, test.Name, false)
                    end
                end)

                local ScrollPanel = Base:Add("DScrollPanel")
                ScrollPanel:Dock(FILL)

                local ScrollBase = ScrollPanel:Add("ACF_Panel")
                ScrollBase:Dock(TOP)

                for _, category in ipairs(TestCategories) do
                    local CategoryPanel, CategoryObject = ScrollBase:AddCollapsible(category, true)

                    local RunAll = CategoryObject.Header:Add("DButton")
                    RunAll:SetText("Run Category")
                    RunAll:Dock(RIGHT)
                    RunAll:SetWide(80)
                    RunAll:DockMargin(0, 2, 5, 2)
                    RunAll.DoClick = function()
                        for _, test in ipairs(Tests[category]) do
                            RunTest(ent, test.Name, false)
                        end
                    end

                    for _, test in ipairs(Tests[category]) do
                        local _, RowObject = CategoryPanel:AddCollapsible(test.Name, false)
                        RowObject:Dock(TOP)
                        RowObject:DockMargin(0, 0, 0, 2)
                        test.RowCategory = RowObject
                        if test.Advice then RowObject.Header:SetTooltip(test.Advice) end

                        RowObject.Header.Paint = function(panel, w, h)
                            surface.SetDrawColor(panel.ResultColor or Color(60, 60, 60, 255))
                            surface.DrawRect(0, 0, w, h)
                            surface.SetDrawColor(0, 0, 0, 100)
                            surface.DrawOutlinedRect(0, 0, w, h)
                        end

                        local FixBtn = RowObject.Header:Add("DButton")
                        FixBtn:SetText("Fix")
                        FixBtn:Dock(RIGHT)
                        FixBtn:SetWide(50)
                        FixBtn:DockMargin(0, 2, 5, 2)
                        FixBtn.DoClick = function()
                            RunTest(ent, test.Name, true)
                        end
                        if not test.FixFunc then FixBtn:SetDisabled(true) end

                        local RunBtn = RowObject.Header:Add("DButton")
                        RunBtn:SetText("Run")
                        RunBtn:Dock(RIGHT)
                        RunBtn:SetWide(50)
                        RunBtn:DockMargin(0, 2, 5, 2)
                        RunBtn.DoClick = function()
                            RunTest(ent, test.Name, false)
                        end
                    end
                end

                ApplyQueuedResults(ent)

                ent:CallOnRemove("ACF_Baseplate_DebugCleanup", function()
                    if IsValid(window) then window:Remove() end
                end)
            end
        }
        properties.Add("edit.debug_baseplate", Autotester)
    end
end