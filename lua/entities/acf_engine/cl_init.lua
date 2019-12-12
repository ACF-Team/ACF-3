DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName     = "ACF Engine"
ENT.WireDebugName = "ACF Engine"

local SeatedInfo = CreateClientConVar("ACF_EngineInfoWhileSeated", 0, true, false)

-- copied from base_wire_entity: DoNormalDraw's notip arg isn't accessible from ENT:Draw defined there.
function ENT:Draw()
    local lply = LocalPlayer()
    local hideBubble = not SeatedInfo:GetBool() and IsValid(lply) and lply:InVehicle()
    self.BaseClass.DoNormalDraw(self, false, hideBubble)
    Wire_Render(self)

    if self.GetBeamLength and (not self.GetShowBeam or self:GetShowBeam()) then
        -- Every SENT that has GetBeamLength should draw a tracer. Some of them have the GetShowBeam boolean
        Wire_DrawTracerBeam(self, 1, self.GetBeamHighlight and self:GetBeamHighlight() or false)
    end
end

function ACFEngineGUICreate(Table)
    acfmenupanel:CPanelText("Name", Table.name)
    acfmenupanel.CData.DisplayModel = vgui.Create("DModelPanel", acfmenupanel.CustomDisplay)
    acfmenupanel.CData.DisplayModel:SetModel(Table.model)
    acfmenupanel.CData.DisplayModel:SetCamPos(Vector(250, 500, 250))
    acfmenupanel.CData.DisplayModel:SetLookAt(Vector(0, 0, 0))
    acfmenupanel.CData.DisplayModel:SetFOV(20)
    acfmenupanel.CData.DisplayModel:SetSize(acfmenupanel:GetWide(), acfmenupanel:GetWide())
    acfmenupanel.CData.DisplayModel.LayoutEntity = function(panel, entity) end
    acfmenupanel.CustomDisplay:AddItem(acfmenupanel.CData.DisplayModel)
    acfmenupanel:CPanelText("Desc", Table.desc)
    local peakkw
    local peakkwrpm
    local pbmin
    local pbmax

    --elecs and turbs get peak power in middle of rpm range
    if (Table.iselec == true) then
        peakkw = (Table.torque * (1 + Table.peakmaxrpm / Table.limitrpm)) * Table.limitrpm / (4 * 9548.8) --adjust torque to 1 rpm maximum, assuming a linear decrease from a max @ 1 rpm to min @ limiter
        peakkwrpm = math.floor(Table.limitrpm / 2)
        pbmin = Table.idlerpm
        pbmax = peakkwrpm
    else
        peakkw = Table.torque * Table.peakmaxrpm / 9548.8
        peakkwrpm = Table.peakmaxrpm
        pbmin = Table.peakminrpm
        pbmax = Table.peakmaxrpm
    end

    --if fuel required, show max power with fuel at top, no point in doing it twice
    if Table.requiresfuel then
        acfmenupanel:CPanelText("Power", "\nPeak Power : " .. math.floor(peakkw * ACF.TorqueBoost) .. " kW / " .. math.Round(peakkw * ACF.TorqueBoost * 1.34) .. " HP @ " .. peakkwrpm .. " RPM")
        acfmenupanel:CPanelText("Torque", "Peak Torque : " .. (Table.torque * ACF.TorqueBoost) .. " n/m  / " .. math.Round(Table.torque * ACF.TorqueBoost * 0.73) .. " ft-lb")
    else
        acfmenupanel:CPanelText("Power", "\nPeak Power : " .. math.floor(peakkw) .. " kW / " .. math.Round(peakkw * 1.34) .. " HP @ " .. peakkwrpm .. " RPM")
        acfmenupanel:CPanelText("Torque", "Peak Torque : " .. Table.torque .. " n/m  / " .. math.Round(Table.torque * 0.73) .. " ft-lb")
    end

    acfmenupanel:CPanelText("RPM", "Idle : " .. Table.idlerpm .. " RPM\nPowerband : " .. pbmin .. "-" .. pbmax .. " RPM\nRedline : " .. Table.limitrpm .. " RPM")
    acfmenupanel:CPanelText("Weight", "Weight : " .. Table.weight .. " kg")
    acfmenupanel:CPanelText("FuelType", "\nFuel Type : " .. Table.fuel)

    if Table.fuel == "Electric" then
        local cons = ACF.ElecRate * peakkw / ACF.Efficiency[Table.enginetype]
        acfmenupanel:CPanelText("FuelCons", "Peak energy use : " .. math.Round(cons, 1) .. " kW / " .. math.Round(0.06 * cons, 1) .. " MJ/min")
    elseif Table.fuel == "Multifuel" then
        local petrolcons = ACF.FuelRate * ACF.Efficiency[Table.enginetype] * ACF.TorqueBoost * peakkw / (60 * ACF.FuelDensity.Petrol)
        local dieselcons = ACF.FuelRate * ACF.Efficiency[Table.enginetype] * ACF.TorqueBoost * peakkw / (60 * ACF.FuelDensity.Diesel)
        acfmenupanel:CPanelText("FuelConsP", "Petrol Use at " .. peakkwrpm .. " rpm : " .. math.Round(petrolcons, 2) .. " liters/min / " .. math.Round(0.264 * petrolcons, 2) .. " gallons/min")
        acfmenupanel:CPanelText("FuelConsD", "Diesel Use at " .. peakkwrpm .. " rpm : " .. math.Round(dieselcons, 2) .. " liters/min / " .. math.Round(0.264 * dieselcons, 2) .. " gallons/min")
    else
        local fuelcons = ACF.FuelRate * ACF.Efficiency[Table.enginetype] * ACF.TorqueBoost * peakkw / (60 * ACF.FuelDensity[Table.fuel])
        acfmenupanel:CPanelText("FuelCons", Table.fuel .. " Use at " .. peakkwrpm .. " rpm : " .. math.Round(fuelcons, 2) .. " liters/min / " .. math.Round(0.264 * fuelcons, 2) .. " gallons/min")
    end

    if Table.requiresfuel then
        acfmenupanel:CPanelText("Fuelreq", "REQUIRES FUEL")
    else
        acfmenupanel:CPanelText("FueledPower", "\nWhen supplied with fuel:\nPeak Power : " .. math.floor(peakkw * ACF.TorqueBoost) .. " kW / " .. math.Round(peakkw * ACF.TorqueBoost * 1.34) .. " HP @ " .. peakkwrpm .. " RPM")
        acfmenupanel:CPanelText("FueledTorque", "Peak Torque : " .. (Table.torque * ACF.TorqueBoost) .. " n/m  / " .. math.Round(Table.torque * ACF.TorqueBoost * 0.73) .. " ft-lb")
    end

    acfmenupanel.CustomDisplay:PerformLayout()
end