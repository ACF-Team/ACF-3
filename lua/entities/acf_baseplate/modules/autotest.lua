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

local function RegisterTest(CategoryName, TestName, TestFunc, FixFunc, Description)
    if not Tests[CategoryName] then RegisterTestCategory(CategoryName) end

    local testData = {
        Name = TestName,
        Func = TestFunc,
        Description = Description or "",
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

local function LinkAll(Env, Type1, Type2)
    for _, Ent1 in pairs(Env.Contraption.entsbyclass[Type1] or {}) do
        for _, Ent2 in pairs(Env.Contraption.entsbyclass[Type2] or {}) do
            Ent1:LinkTo(Ent2)
        end
    end
end

---------------------------------------------------------------------------------------------------------------------------
-- TEST DEFINITIONS
---------------------------------------------------------------------------------------------------------------------------

RegisterTest("Optimization", "Physical Entity Tests", function(Env)
    local MaxConstraintsPerProp = 8
    local Faults = {}
    Env.UniqueConstraints = {}

    for _, v in pairs(Env.Physical) do
        local Constraints = constraint.GetTable(v)
        for _, c in ipairs(Constraints) do Env.UniqueConstraints[c.Constraint] = true end

        if v ~= Env.Baseplate then
            local Reasons = {}
            local Count = table.Count(Constraints)

            if Count > MaxConstraintsPerProp then
                table.insert(Reasons, "Excessive constraints (" .. Count .. " > " .. MaxConstraintsPerProp .. ")")
            end
            if IsValid(v:GetParent()) then
                table.insert(Reasons, "Should not be parented and constrained")
            end
            if v:GetColor().a ~= 0 and not v:GetNoDraw() then
                table.insert(Reasons, "Should have alpha 0 / NoDraw")
            end

            if #Reasons > 0 then
                table.insert(Faults, {Ent = v, Msg = table.concat(Reasons, ", ")})
            end
        end
    end
    return #Faults == 0, Faults
end, function(Env)
    for _, v in pairs(Env.Physical) do
        if v ~= Env.Baseplate then
            if IsValid(v:GetParent()) then constraint.RemoveAll(v) end
            if not IsValid(v:GetParent()) and v:GetColor().a ~= 0 then
                v:SetColor(Color(255, 255, 255, 0))
                v:SetRenderMode( RENDERMODE_TRANSCOLOR )
            end
        end
    end
end, "Checks per-prop constraint counts and visual status.")

RegisterTest("Optimization", "Parented Entity Tests", function(Env)
    local Faults = {}
    for v in pairs(Env.Contraption.ents) do
        if IsValid(v:GetParent()) then
            local Reasons = {}
            if v:GetColor().a ~= 0 and not v:GetNoDraw() then table.insert(Reasons, "Should have alpha 0 / NoDraw") end

            if #Reasons > 0 then
                table.insert(Faults, {Ent = v, Msg = table.concat(Reasons, ", ")})
            end
        end
    end
    return #Faults == 0, Faults
end, function()
    for v in pairs(Env.Contraption.ents) do
        if IsValid(v:GetParent()) then
            if v:GetColor().a ~= 0 then
                v:SetColor(Color(255, 255, 255, 0))
                v:SetRenderMode(RENDERMODE_TRANSCOLOR)
            end
        end
    end
end)

RegisterTest("Optimization", "Total Entities", function(Env)
    local MaxEntities = 150
    local TotalEnts = Env.Contraption.count
    if TotalEnts > MaxEntities then
        return false, {{Ent = Env.Baseplate, Msg = "Total entities " .. TotalEnts .. " > " .. MaxEntities}}
    end
    return true, "Entity count OK"
end, nil)

RegisterTest("Optimization", "Total Physical Entities", function(Env)
    local MaxPhysicals = 11
    local TotalPhysical = table.Count(Env.Physical)
    if TotalPhysical > MaxPhysicals then
        return false, {{Ent = Env.Baseplate, Msg = "Physical entities " .. TotalPhysical .. " > " .. MaxPhysicals}}
    end
    return true, "Physical count OK"
end, nil)

RegisterTest("Optimization", "Total Constraints", function(Env)
    -- Check max total constraint count
    local MaxConstraintsTotal = 50
    local TotalConstraints = table.Count(Env.UniqueConstraints or {})
    if TotalConstraints > MaxConstraintsTotal then
        return false, {{Ent = Env.Baseplate, Msg = "Total constraints (" .. TotalConstraints .. ") exceeds recommended (" .. MaxConstraintsTotal .. ")"}}
    end
    return true, "Constraint count OK"
end, nil)

RegisterTest("Optimization", "P2M Controller", function(Env)
    if table.IsEmpty(Env.Contraption.entsbyclass.sent_prop2mesh or {}) then
        return false, {{Ent = Env.Baseplate, Msg = "Missing p2m controller for visual optimization"}}
    end
    return true, "P2M found"
end, nil)

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
end, nil)

RegisterTest("Crew", "Crew Efficiency", function(Env)
    local MinEff = 0.25
    local Faults = {}
    for _, v in ipairs(Env.Contraption.Crews or {}) do
        if v.TotalEff <= MinEff then
            table.insert(Faults, {Ent = v.Ent or Env.Baseplate, Msg = "Efficiency " .. math.Round(v.TotalEff, 2) .. " is too low"})
        end
    end
    return #Faults == 0, Faults
end, nil)

RegisterTest("Links", "Guns, Racks and Ammo", function(Env)
    local Faults = {}
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_gun, {"Crates"})) do table.insert(Faults, {Ent = e, Msg = "Gun unlinked from Ammo"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_rack, {"Crates"})) do table.insert(Faults, {Ent = e, Msg = "Rack unlinked from Ammo"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_ammo, {"Weapons"})) do table.insert(Faults, {Ent = e, Msg = "Ammo unlinked from Guns"}) end
    return #Faults == 0, Faults
end, function(Env)
    LinkAll(Env, "acf_gun", "Crates")
    LinkAll(Env, "acf_rack", "Crates")
    LinkAll(Env, "acf_ammo", "Weapons")
end)

RegisterTest("Links", "Engines, Fuel and Gearboxes", function(Env)
    local Faults = {}
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_fueltank, {"Engines"})) do table.insert(Faults, {Ent = e, Msg = "Fuel Tank unlinked from Engines"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_engine, {"FuelTanks"})) do table.insert(Faults, {Ent = e, Msg = "Engine unlinked from Fuel or Gearbox"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_engine, {"Gearboxes"})) do table.insert(Faults, {Ent = e, Msg = "Engine unlinked from Fuel or Gearbox"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_gearbox, {"GearboxIn", "Engines"})) do table.insert(Faults, {Ent = e, Msg = "Gearbox missing Input link"}) end
    for _, e in ipairs(GetEntsMissingLinks(Env.Contraption.entsbyclass.acf_gearbox, {"GearboxOut", "Wheels", "Effectors"})) do table.insert(Faults, {Ent = e, Msg = "Gearbox missing Output link"}) end
    return #Faults == 0, Faults
end, function(Env)
    LinkAll(Env, "acf_fueltank", "Engines")
    LinkAll(Env, "acf_engine", "FuelTanks")
    LinkAll(Env, "acf_engine", "Gearboxes")
    LinkAll(Env, "acf_gearbox", "GearboxIn")
    LinkAll(Env, "acf_gearbox", "GearboxOut")
end)

RegisterTest("Baseplate", "Orientation", function(Env)
    local Deviation = math.deg(math.acos(Env.Baseplate:GetForward():Dot(Vector(0, 1, 0))))
    if Deviation > 0.05 then
        return false, {{Ent = Env.Baseplate, Msg = "Baseplate is misaligned with north by " .. math.Round(Deviation, 2) .. " degrees"}}
    end
    return true
end, function(Env)
    Env.Baseplate:SetAngles(Angle(0, 90, 0))
end)

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
end, nil)

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
            MenuLabel = "Debug Baseplate",
            Order = 99999,
            PrependSpacer = true,
            MenuIcon = "icon16/image_edit.png",

            Filter = function(_, ent) return IsValid(ent) and ent.IsACFBaseplate end,

            Action = function(_, ent)
                local window = g_ContextMenu:Add("DFrame")
                window:SetSize(400, 500)
                window:SetTitle("Baseplate Debug [" .. ent:EntIndex() .. "]")
                window:Center()
                window:SetSizable(true)
                window:SetDraggable(true)
                window:MoveToFront()

                local Base = window:Add("ACF_Panel")
                Base:Dock(FILL)

                local Notice = Base:AddLabel("Click result buttons to highlight and snap camera to offending entities.\nIf the tests are gray, then you need to wait for a global cooldown to prevent spam.")
                Notice:SetDark(true)
                Notice:Dock(TOP)
                Notice:DockMargin(10, 5, 10, 5)
                Notice:SetWrap(true)
                Notice:SetTall(40)

                local GlobalRun = Base:Add("DButton")
                GlobalRun:SetText("Run All Tests")
                GlobalRun:Dock(TOP)
                GlobalRun:DockMargin(10, 0, 10, 5)
                GlobalRun.DoClick = function()
                    for _, test in pairs(TestMap) do
                        if IsValid(test.RowCategory) and IsValid(test.RowCategory.Header) then
                            test.RowCategory.Header.ResultColor = nil
                        end
                        RunTest(ent, test.Name, false)
                    end
                end

                net.Receive("ACF_Baseplate_TestResult", function()
                    local name = net.ReadString()
                    local ok = net.ReadBool()
                    local count = net.ReadUInt(16)

                    local test = TestMap[name]
                    if test and IsValid(test.RowCategory) then
                        test.RowCategory.Header.ResultColor = ok and Color(0, 255, 0, 150) or Color(255, 0, 0, 150)

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
                        if test.Description then RowObject.Header:SetTooltip(test.Description) end

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