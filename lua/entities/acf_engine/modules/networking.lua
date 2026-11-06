local ACF = ACF
local IsEntityValid = ACF.Optimizations.IsEntityValid

--===============================================================================================--
-- Networking 
--===============================================================================================--

-- NET SURFER 2.0
util.AddNetworkString("ACF_RequestEngineInfo")
util.AddNetworkString("ACF_InvalidateEngineInfo")

function ENT:InvalidateClientInfo()
    net.Start("ACF_InvalidateEngineInfo")
        net.WriteEntity(self)
    net.Broadcast()
end

net.Receive("ACF_RequestEngineInfo", function(_, Ply)
    local Entity = net.ReadEntity()

    if IsEntityValid(Entity) then
        local Outputs    = {}
        local FuelTanks  = {}
        local Driveshaft = Entity.Out.Pos

        if next(Entity.Gearboxes) then
            for E in pairs(Entity.Gearboxes) do
                Outputs[#Outputs + 1] = E:EntIndex()
            end
        end

        if next(Entity.FuelTanks) then
            for E in pairs(Entity.FuelTanks) do
                FuelTanks[#FuelTanks + 1] = E:EntIndex()
            end
        end

        net.Start("ACF_RequestEngineInfo")
            net.WriteEntity(Entity)
            net.WriteVector(Driveshaft)
            net.WriteUInt(#Outputs, 6)
            net.WriteUInt(#FuelTanks, 6)

            if next(Outputs) then
                for _, E in ipairs(Outputs) do
                    net.WriteUInt(E, MAX_EDICT_BITS)
                end
            end

            if next(FuelTanks) then
                for _, E in ipairs(FuelTanks) do
                    net.WriteUInt(E, MAX_EDICT_BITS)
                end
            end
        net.Send(Ply)
    end
end)