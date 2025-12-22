local ScrW = ScrW
local ScrH = ScrH
local SetDrawColor = surface.SetDrawColor
local DrawRect = surface.DrawRect
local DrawCircle = surface.DrawCircle
local DrawText = draw.DrawText
local DrawLine = surface.DrawLine

local AmmoTypes    = ACF.Classes.AmmoTypes

local TraceLine = util.TraceLine

return function(State)
    -- Receive ammo count info from server
    net.Receive("ACF_Controller_Ammo", function()
        local Ent = net.ReadEntity()
        local AmmoType = net.ReadString()
        local AmmoCount = net.ReadUInt(16)

        if not IsValid(Ent) then return end

        Ent.PrimaryAmmoCountsByType = Ent.PrimaryAmmoCountsByType or {}
        if not Ent.PrimaryAmmoCountsByType[AmmoType] then
            Ent.PrimaryAmmoCountsByType[AmmoType] = 0

            Ent.MaterialsByType = Ent.MaterialsByType or {}
            local IconName = AmmoTypes.Get(AmmoType).SpawnIcon -- Something bad has happened if this doesn't work
            Ent.MaterialsByType[AmmoType] = Material(IconName)

            Ent.TypesSorted = Ent.TypesSorted or {}
            table.insert(Ent.TypesSorted, AmmoType)
            table.sort(Ent.TypesSorted)
        end
        Ent.PrimaryAmmoCountsByType[AmmoType] = AmmoCount
    end)

    net.Receive("ACF_Controller_Receivers", function()
        local Ent = net.ReadEntity()
        local Receiver = net.ReadEntity()
        local Direction = net.ReadVector()
        if not IsValid(Ent) then return end

        Ent.ReceiverData = Ent.ReceiverData or {}
        Ent.ReceiverData[Receiver] = {Direction, CurTime()}
    end)

    local function SelectAmmoType(Index)
        if State.MyController:GetDisableAmmoSelect() then return end
        local NewAmmoType = State.MyController.TypesSorted and State.MyController.TypesSorted[Index] or nil
        local ForceSwitch = State.MyController.SelectedAmmoType == NewAmmoType
        if not NewAmmoType then return end
        net.Start("ACF_Controller_Ammo")
        net.WriteUInt(State.MyController:EntIndex(), MAX_EDICT_BITS)
        net.WriteString(NewAmmoType)
        net.WriteBool(ForceSwitch)
        net.SendToServer()
        State.MyController.SelectedAmmoType = NewAmmoType
    end

    hook.Add("PlayerButtonDown", "ACFControllerSeatButtonDown", function(_, Button)
        if not IsFirstTimePredicted() then return end
        if not IsValid(State.MyController) then return end

        if Button == KEY_1 then SelectAmmoType(1)
        elseif Button == KEY_2 then SelectAmmoType(2)
        elseif Button == KEY_3 then SelectAmmoType(3)
        end
    end)

    local rangerTrace = {}
    local ranger = function(start, dir, length, filter, mask)
        rangerTrace.start = start
        rangerTrace.endpos = start + dir * length
        rangerTrace.mask = mask or MASK_SOLID
        rangerTrace.filter = filter
        local Tr = TraceLine(rangerTrace)
        return Tr.HitPos or vector_origin
    end

    -- local Scale = State.MyController:GetHUDScale()
    -- surface.CreateFont( "ACFHUDFONT", {
    -- 	font = "Arial", extended = false, size = 13 * Scale, weight = 500, blursize = 0, scanlines = 0, antialias = true, underline = false,
    -- 	italic = false, strikeout = false, symbol = false, rotary = false, shadow = false, additive = false, outline = false,
    -- } )

    local CrewMaterial = Material("materials/icon16/status_online.png")
    local ComputerMaterial = Material("materials/icon16/computer.png")
    local ComputerCalculateMaterial = Material("materials/icon16/computer_key.png")
    local ComputerSuccessMaterial = Material("materials/icon16/computer_go.png")
    local ComputerErrorMaterial = Material("materials/icon16/computer_error.png")
    local SmokeMaterial = Material("acf/icons/shell_smoke.png")

    local ColorReady = Color(0, 255, 0, 255)
    local ColorNotReady = Color(255, 0, 0, 255)

    local function DrawReload(Entity, Ready, Radius)
        if IsValid(Entity) then
            local HitPos = ranger( Entity:GetPos(), Entity:GetForward(), 99999, State.MyFilter )
            local sp = HitPos:ToScreen()
            SetDrawColor( Ready and ColorReady or ColorNotReady )
            DrawCircle( sp.x, sp.y, Radius)
        end
    end

    local function DrawPictograph(mat, text, x, y, scale, col_fg, col_bg, col_sh)
        surface.SetDrawColor(col_sh)
        surface.DrawRect(x, y, 40 * scale, 40 * scale)
        surface.SetDrawColor(col_bg)
        surface.DrawOutlinedRect(x, y, 40 * scale, 40 * scale)
        surface.SetDrawColor(col_fg)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(x + 4 * scale, y + 4 * scale, 32 * scale, 32 * scale)
        DrawText(text, "DermaDefault", x + 4 * scale, y + 4 * scale, col_bg, TEXT_ALIGN_LEFT)
    end

    -- HUD RELATED
    local cyan = Color(0, 255, 255, 255)
    local white = Color(255, 255, 255, 255)
    local dimmed = Color(150, 150, 150, 255)
    local shade = Color(0, 0, 0, 200)
    hook.Add( "HUDPaintBackground", "ACFAddonControllerHUD", function()
        if not IsValid(State.MyController) then return end

        -- Determine screen params
        local resx, resy = ScrW(), ScrH()
        local x, y = resx / 2, resy / 2
        local thick = 1

        -- Rescale if needed
        local Scale = State.MyController:GetHUDScale()
        resx, resy, thick = resx * Scale, resy * Scale, thick

        local ColData = State.MyController:GetHUDColor() or Vector(255, 255, 255) -- See shared.lua
        local Col = Color(ColData.x * 255, ColData.y * 255, ColData.z * 255, 255)
        SetDrawColor( Col )

        if State.MyController:GetDisableAIOHUD() then return end -- Disable hud if not enabled

        -- HUD 1
        local HudType = State.MyController:GetHUDType()
        if HudType == 0 then
            DrawRect( x - 40 * Scale, y - thick / 2, 80 * Scale, thick )
            DrawRect( x - thick / 2, y - 40 * Scale, thick, 80 * Scale )

            local AmmoType, AmmoCount = State.MyController:GetNWString("AHS_Primary_AT", ""), State.MyController:GetNWInt("AHS_Primary_SL", 0)
            DrawText(AmmoType .. " | " .. AmmoCount, "DermaDefault", x - 10 * Scale, y + 50 * Scale, Col, TEXT_ALIGN_RIGHT)
            local TimeLeft = math.Round(State.MyController:GetNWFloat("AHS_Primary_NF", 0) - CurTime(), 2)
            DrawText(TimeLeft > 0 and TimeLeft or "0.00", "DermaDefault", x + 10 * Scale, y + 50 * Scale, Col, TEXT_ALIGN_LEFT)
        elseif HudType == 1 then
            -- View border
            DrawRect( x - 120 * Scale, y - thick / 2, 240 * Scale, thick )
            DrawRect( x - thick / 2, y - 60 * Scale, thick, 120 * Scale )

            DrawRect( x - 170 * Scale, y - thick / 2, 40 * Scale, thick )
            DrawRect( x + 130 * Scale, y - thick / 2, 40 * Scale, thick )

            DrawRect( x - thick / 2, y - 110 * Scale, thick, 40 * Scale )
            DrawRect( x - thick / 2, y + 70 * Scale, thick, 40 * Scale )

            DrawRect( x - 400 * Scale, y - 200 * Scale, thick, 60 * Scale )
            DrawRect( x - 400 * Scale, y + 140 * Scale, thick, 60 * Scale )
            DrawRect( x + 400 * Scale, y - 200 * Scale, thick, 60 * Scale )
            DrawRect( x + 400 * Scale, y + 140 * Scale, thick, 60 * Scale )

            DrawRect( x - 400 * Scale, y - 200 * Scale, 60 * Scale, thick )
            DrawRect( x - 400 * Scale, y + 200 * Scale, 60 * Scale, thick )
            DrawRect( x + 340 * Scale, y - 200 * Scale, 60 * Scale, thick )
            DrawRect( x + 340 * Scale, y + 200 * Scale, 60 * Scale, thick )

            surface.SetDrawColor(0, 0, 0, 200)
            surface.DrawRect(x - 400 * Scale, y + 205 * Scale, 125 * Scale, 70 * Scale)
            surface.DrawRect(x + 300 * Scale, y + 205 * Scale, 100 * Scale, 70 * Scale)

            -- Ammo type | Ammo count | Time left
            SetDrawColor( Col )
            local AmmoType, AmmoCount = State.MyController:GetNWString("AHS_Primary_AT", ""), State.MyController:GetNWInt("AHS_Primary_SL", 0)
            DrawText(AmmoType .. " | " .. AmmoCount, "DermaDefault", x - 330 * Scale, y + 210 * Scale, Col, TEXT_ALIGN_RIGHT)
            local TimeLeft = math.Round(State.MyController:GetNWFloat("AHS_Primary_NF", 0) - CurTime(), 2)
            DrawText(TimeLeft > 0 and TimeLeft or "0.00", "DermaDefault", x - 310 * Scale, y + 210 * Scale, Col, TEXT_ALIGN_LEFT)
            DrawReload(State.MyController:GetNWEntity( "AHS_Primary", nil ), State.MyController:GetNWBool("AHS_Primary_RD", false), 10 * Scale / 1)

            local AmmoType, AmmoCount = State.MyController:GetNWString("AHS_Secondary_AT", ""), State.MyController:GetNWInt("AHS_Secondary_SL", 0)
            DrawText(AmmoType .. " | " .. AmmoCount, "DermaDefault", x - 330 * Scale, y + 230 * Scale, Col, TEXT_ALIGN_RIGHT)
            local TimeLeft = math.Round(State.MyController:GetNWFloat("AHS_Secondary_NF", 0) - CurTime(), 2)
            DrawText(TimeLeft > 0 and TimeLeft or "0.00", "DermaDefault", x - 310 * Scale, y + 230 * Scale, Col, TEXT_ALIGN_LEFT)
            DrawReload(State.MyController:GetNWEntity( "AHS_Secondary", nil ), State.MyController:GetNWBool("AHS_Secondary_RD", false), 10 * Scale / 2)

            local AmmoType, AmmoCount = State.MyController:GetNWString("AHS_Tertiary_AT", ""), State.MyController:GetNWInt("AHS_Tertiary_SL", 0)
            DrawText(AmmoType .. " | " .. AmmoCount, "DermaDefault", x - 330 * Scale, y + 250 * Scale, Col, TEXT_ALIGN_RIGHT)
            local TimeLeft = math.Round(State.MyController:GetNWFloat("AHS_Tertiary_NF", 0) - CurTime(), 2)
            DrawText(TimeLeft > 0 and TimeLeft or "0.00", "DermaDefault", x - 310 * Scale, y + 250 * Scale, Col, TEXT_ALIGN_LEFT)
            DrawReload(State.MyController:GetNWEntity( "AHS_Tertiary", nil ), State.MyController:GetNWBool("AHS_Tertiary_RD", false), 10 * Scale / 3)

            -- Speed, Gear, Fuel, Crew
            local unit = State.MyController:GetSpeedUnit() == 0 and " KPH" or " MPH"
            DrawText("SPD: " .. State.MyController:GetNWFloat("AHS_Speed") .. unit, "DermaDefault", x + 310 * Scale, y + 210 * Scale, Col, TEXT_ALIGN_LEFT)
            DrawText("Gear: " .. State.MyController:GetNWFloat("AHS_Gear"), "DermaDefault", x + 310 * Scale, y + 230 * Scale, Col, TEXT_ALIGN_LEFT)
            local unit = State.MyController:GetFuelUnit() == 0 and " L" or " G"

            local Fuel = State.MyController:GetNWFloat("AHS_Fuel")
            local FuelCap = State.MyController:GetNWFloat("AHS_FuelCap")
            DrawText("Fuel: " .. Fuel .. " / " .. FuelCap .. unit, "DermaDefault", x + 310 * Scale, y + 250 * Scale, Col, TEXT_ALIGN_LEFT)

            -- Ballistic Computer, Smoke Launchers, Crew
            local ax, ay = x + 268 * Scale, y - 246 * Scale
            local BallCompStatus = State.MyController:GetNWInt("AHS_TurretComp_Status", 0)
            local BallCompMaterial = BallCompStatus == 1 and ComputerCalculateMaterial or BallCompStatus == 2 and ComputerSuccessMaterial or BallCompStatus == 3 and ComputerErrorMaterial or ComputerMaterial
            DrawPictograph(BallCompMaterial, "", ax, ay, Scale, white, Col, shade)

            local ax, ay = x + 314 * Scale, y - 246 * Scale
            DrawPictograph(SmokeMaterial, State.MyController:GetNWInt("AHS_Smoke_SL"), ax, ay, Scale, white, Col, shade)

            local ax, ay = x + 360 * Scale, y - 246 * Scale
            DrawPictograph(CrewMaterial, State.MyController:GetNWInt("AHS_Crew"), ax, ay, Scale, white, Col, shade)
        end

        local LoadedAmmoType = State.MyController:GetNWString("AHS_Primary_AT", "")
        for Index, AmmoType in pairs(State.MyController.TypesSorted or {}) do
            local Material = State.MyController.MaterialsByType[AmmoType] or ""
            local AmmoCount = State.MyController.PrimaryAmmoCountsByType[AmmoType] or 0
            local ax = x - 400 * Scale + (46 * (Index - 1) * Scale)
            local ay = y - 246 * Scale

            -- Outline currently selected ammo type
            if AmmoType == State.MyController.SelectedAmmoType then
                surface.DrawOutlinedRect(ax - 2 * Scale, ay - 2 * Scale, 44 * Scale, 44 * Scale)
            end

            local Lighting = AmmoType == LoadedAmmoType and white or dimmed
            DrawPictograph(Material, AmmoCount, ax, ay, Scale, Lighting, Col, shade)
        end

        for Receiver, Data in pairs(State.MyController.ReceiverData or {}) do
            if not IsValid(Receiver) then continue end
            local Direction, Time = Data[1], Data[2]
            local Frac = (CurTime() - Time) / 5
            if Frac < 1 then
                local RP = Receiver:GetPos()
                local HitPos = ranger( RP, Direction:GetNormalized(), 99999, MyFilter )
                local SP1 = RP:ToScreen()
                local SP2 = HitPos:ToScreen()
                SetDrawColor(cyan.r, cyan.g, cyan.b, (1 - Frac) * 255)
                DrawLine(SP1.x, SP1.y, SP2.x, SP2.y)
            end
        end
    end)
end