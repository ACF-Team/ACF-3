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
    for _, Ent1 in pairs(Env.Contraption.entsbyclass[Type1] or {}) do
        for _, Ent2 in pairs(Env.Contraption.entsbyclass[Type2] or {}) do
            Ent1:LinkTo(Ent2)
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
        if not e.IsBelted and e.Weapon ~= "SL" then
            table.insert(Faults, {Ent = e, Msg = "Gun needs link to loader/autoloader"})
        end
    end

    -- for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_rack, {"Crew", "Autoloader"})) do table.insert(Faults, {Ent = e, Msg = "Ammo unlinked from Guns"}) end
    return #Faults == 0, Faults
end, function(Env)
    LinkAll(Env, "acf_gun", "Crates")
    LinkAll(Env, "acf_rack", "Crates")
    LinkAll(Env, "acf_ammo", "Weapons")
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_gun, {"Crew", "Autoloader"})) do
        if not e.IsBelted and e.Weapon ~= "SL" then
            for _, crew in pairs(Env.Contraption.Crews or {}) do
                if crew.Type == "Loader" then e:LinkTo(crew.Ent) end
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
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_fueltank, {"Engines"})) do table.insert(Faults, {Ent = e, Msg = "Fuel Tank needs link to Engines"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_engine, {"FuelTanks"})) do table.insert(Faults, {Ent = e, Msg = "Engine needs link to Fuel or Gearbox"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_engine, {"Gearboxes"})) do table.insert(Faults, {Ent = e, Msg = "Engine needs link to Fuel or Gearbox"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_gearbox, {"GearboxIn", "Engines"})) do table.insert(Faults, {Ent = e, Msg = "Gearbox missing Input link"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_gearbox, {"GearboxOut", "Wheels", "Effectors"})) do table.insert(Faults, {Ent = e, Msg = "Gearbox missing Output link"}) end
    return #Faults == 0, Faults
end, function(Env)
    LinkAll(Env, "acf_fueltank", "Engines")
    LinkAll(Env, "acf_engine", "FuelTanks")
    LinkAll(Env, "acf_engine", "Gearboxes")
end, "Ensure all engines are linked to fuel tanks and gearboxes, and all gearboxes have proper input and output links")

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
-- NETWORKING
---------------------------------------------------------------------------------------------------------------------------

if SERVER then
    util.AddNetworkString("ACF_Baseplate_RunTest")
    util.AddNetworkString("ACF_Baseplate_TestResult")

    local LastRun = {}

    net.Receive("ACF_Baseplate_RunTest", function(_, ply)
        local ent = net.ReadEntity()
        local testName = net.ReadString()
        local isFix = net.ReadBool()

        if not IsValid(ent) or not ent.IsACFBaseplate then return end
        local test = TestMap[testName]
        if not test then return end

        -- Rate limit: 1-second global cooldown per test
        local Time = CurTime()
        if (LastRun[testName] or 0) + 2 > Time then return end
        LastRun[testName] = Time -- Update the last run timestamp

        local Env = {Baseplate = ent}
        SetupTests(Env)
        if isFix then
            if test.FixFunc then test.FixFunc(Env) end
        else
            local ok, results = test.Func(Env)

            net.Start("ACF_Baseplate_TestResult")
                net.WriteString(testName)
                net.WriteBool(ok or false)
                if not ok and istable(results) then
                    net.WriteUInt(#results, 16)
                    for _, fault in ipairs(results) do
                        net.WriteEntity(fault.Ent)
                        net.WriteString(fault.Msg)
                    end
                else
                    net.WriteUInt(0, 16)
                    net.WriteString(isstring(results) and results or "Success")
                end
            net.Send(ply)
        end
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

                net.Receive("ACF_Baseplate_TestResult", function()
                    local name = net.ReadString()
                    local ok = net.ReadBool()
                    local count = net.ReadUInt(16)

                    local test = TestMap[name]
                    if test and IsValid(test.RowCategory) then
                        test.RowCategory.Header.ResultColor = ok and Color(0, 200, 0, 150) or Color(255, 0, 0, 150)

                        local Content = test.RowCategory.Contents
                        Content:Clear()

                        if ok then
                            local Lbl = Content:Add("DLabel")
                            Lbl:SetText("  PASSED: " .. (count == 0 and net.ReadString() or "OK"))
                            Lbl:Dock(TOP)
                            Lbl:SetDark(true)
                            Lbl:DockMargin(10, 5, 10, 5)
                        else
                            for _ = 1, count do
                                local targetEnt = net.ReadEntity()
                                local reason = net.ReadString()

                                local Btn = Content:Add("DButton")
                                Btn:SetText("[" .. (IsValid(targetEnt) and targetEnt:EntIndex() or "NULL") .. "] " .. reason)
                                Btn:Dock(TOP)
                                Btn:DockMargin(5, 2, 5, 2)
                                Btn:SetContentAlignment(4)
                                Btn:SetTextInset(8, 0)
                                Btn.DoClick = function()
                                    if not IsValid(targetEnt) then return end
                                    local View = render.GetViewSetup()
                                    local Lookat = (targetEnt:WorldSpaceCenter() - View.origin):Angle()
                                    ACF.Utilities.Notify.InterpViewAngleTo(Lookat, nil, function()
                                        ACF.Utilities.Notify.SingleEntityImpulse(targetEnt)
                                    end, 0.8)
                                    ACF.Utilities.Notify.SingleEntityImpulse(targetEnt)
                                end
                            end
                        end
                        test.RowCategory:SetExpanded(not ok)
                        test.RowCategory:InvalidateLayout(true)
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

                ent:CallOnRemove("ACF_Baseplate_DebugCleanup", function()
                    if IsValid(window) then window:Remove() end
                end)
            end
        }
        properties.Add("edit.debug_baseplate", Autotester)
    end
end
