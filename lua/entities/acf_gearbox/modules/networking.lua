local ACF = ACF
local IsEntityValid = ACF.Optimizations.IsEntityValid
local ANGLE_MARGIN  = 0.8 -- TODO: This constant is redundant with spawning.lua

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

        -- Each output also says whether its shaft is close to the angle limit, so the client can color it
        local Warn = ACF.MaxDriveshaftAngle * ANGLE_MARGIN

        for _, Couples in ipairs(CoupleTargets) do
            if next(Couples) then
                for E, L in pairs(Couples) do
                    local _, Angle = ACF.IsDriveshaftAngleExcessive(E, E.In, L)
                    local Output   = { Index = E:EntIndex(), Bent = Angle > Warn }

                    if L.Side == 0 then
                        OutputL[#OutputL + 1] = E:EntIndex()
                        OutputL[#OutputL + 1] = Output
                    else
                        OutputR[#OutputR + 1] = E:EntIndex()
                        OutputR[#OutputR + 1] = Output
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
                for _, Output in ipairs(OutputL) do
                    net.WriteUInt(Output.Index, MAX_EDICT_BITS)
                    net.WriteBool(Output.Bent)
                end
            end

            if next(OutputR) then
                for _, Output in ipairs(OutputR) do
                    net.WriteUInt(Output.Index, MAX_EDICT_BITS)
                    net.WriteBool(Output.Bent)
                end
            end

            net.WriteBool(Entity.ACF_Hints and Entity.ACF_Hints.gearbox_overloaded ~= nil or false)
        net.Send(Ply)
    end
end)
