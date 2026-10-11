local ACF = ACF
local IsEntityValid = ACF.Optimizations.IsEntityValid

-- NET SURFER 2.0
util.AddNetworkString("ACF_RequestGearboxInfo")
util.AddNetworkString("ACF_InvalidateGearboxInfo")

function ENT:InvalidateClientInfo()
    net.Start("ACF_InvalidateGearboxInfo")
        net.WriteEntity(self)
    net.Broadcast()
end

net.Receive("ACF_RequestGearboxInfo", function(_, Ply)
    local Entity = net.ReadEntity()

    if IsEntityValid(Entity) then
        local Inputs = {}
        local OutputL = {}
        local OutputR = {}
        local In = Entity.In.Pos
        local OutL = Entity.OutL.Pos
        local OutR = Entity.OutR.Pos

        local SingleTargets, CoupleTargets =
            { Entity.GearboxIn, Entity.Engines },
            { Entity.GearboxOut, Entity.Wheels, Entity.Effectors }

        for _, Singles in ipairs(SingleTargets) do
            if next(Singles) then
                for E in pairs(Singles) do
                    Inputs[#Inputs + 1] = E:EntIndex()
                end
            end
        end

        for _, Couples in ipairs(CoupleTargets) do
            if next(Couples) then
                for E, L in pairs(Couples) do
                    if L.Side == 0 then
                        OutputL[#OutputL + 1] = E:EntIndex()
                    else
                        OutputR[#OutputR + 1] = E:EntIndex()
                    end
                end
            end
        end

        net.Start("ACF_RequestGearboxInfo")
            net.WriteEntity(Entity)

            net.WriteVector(In)
            net.WriteVector(OutL)
            net.WriteVector(OutR)

            net.WriteUInt(#Inputs, 6)
            net.WriteUInt(#OutputL, 6)
            net.WriteUInt(#OutputR, 6)

            if next(Inputs) then
                for _, E in ipairs(Inputs) do
                    net.WriteUInt(E, MAX_EDICT_BITS)
                end
            end

            if next(OutputL) then
                for _, E in ipairs(OutputL) do
                    net.WriteUInt(E, MAX_EDICT_BITS)
                end
            end

            if next(OutputR) then
                for _, E in ipairs(OutputR) do
                    net.WriteUInt(E, MAX_EDICT_BITS)
                end
            end
        net.Send(Ply)
    end
end)
