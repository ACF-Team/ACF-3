local ACF         = ACF
local Classes     = ACF.Classes
local Loaded

local function AddPerformanceData(Engine)
    local Type = Classes.GetSubtypeByName("ACF.EngineTypes.BaseEngineType", Engine.Type)

    if not Type then
        Type = Classes.GetTypeByName("ACF.EngineTypes.GenericPetrol")
        Engine.Type = "ACF.EngineTypes.GenericPetrol"
    end

    if not Engine.TorqueCurve then
        Engine.TorqueCurve = Type.TorqueCurve
    end

    ACF.AddEnginePerformanceData(Engine)
end

Classes.DefineClass("ACF.Engines.BaseEngine", function()
    local CLASS = CLASS

    CLASS.Sound = "vehicles/junker/jnk_fourth_cruise_loop2.wav"
    function CLASS.__inherited(NewClass)
        if not NewClass.LimitConVar then
            NewClass.LimitConVar = {
                Name   = "_acf_engine",
                Amount = 16,
                Text   = "Maximum amount of ACF engines a player can create."
            }
        end

        Classes.AddSboxLimit(NewClass.LimitConVar)

        if NewClass.MuzzleFlash then
            PrecacheParticleSystem(NewClass.MuzzleFlash)
        end

        if Loaded and Classes.GetBaseClass(NewClass) ~= CLASS then
            AddPerformanceData(NewClass)
        end
    end

    CLASS.IsSpecial = false
end)

do -- Adding engine performance data
    hook.Add("ACF_OnLoadAddon", "ACF Engine Performance", function()
        Loaded = true

        for _, EngineGroup in pairs(Classes.GetChildren(Classes.GetTypeByName("ACF.Engines.BaseEngine"))) do
            for _, Engine in pairs(Classes.GetSubtypes(Classes.GetTypeName(EngineGroup))) do
                AddPerformanceData(Engine)
            end
        end

        hook.Remove("ACF_OnLoadAddon", "ACF Engine Performance")
    end)
end
