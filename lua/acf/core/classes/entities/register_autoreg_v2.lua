-- Define base entity types that will never get these ran just so they exist
ACF.Classes.DefineClass("base_wire_entity",                       function() end)
ACF.Classes.DefineClass("base_scalable",      "base_wire_entity", function() end)
ACF.Classes.DefineClass("acf_base_simple",    "base_wire_entity", function() end)
ACF.Classes.DefineClass("acf_base_scalable",  "base_scalable",    function() end)

local function ClassNameTrick(ENT)
    local Class  = string.Split(ENT.Folder, "/"); Class = Class[#Class]
    ENT.ACF_ClassName = Class
    ENT.ACF_BaseClassName = ENT.Base
end

local function ClassFieldDefinitions(ENT, DefineFields)
    ENT.ACF_ClassDef = ACF.Classes.DefineClass(ENT.ACF_ClassName, ENT.ACF_BaseClass, DefineFields)
end

--- This sets up wiremod functions
local function PrepareWiremodFunctions(ENT)
    local Wire_Inputs, Wire_Outputs = ENT.ACF_StaticWireInputs or {}, ENT.ACF_StaticWireOutputs or {}

    -- Internal call
    function ENT:ACF_SetupWireFunctions()
        local Inputs, Outputs = {}, {}
        for K, V in ipairs(Wire_Inputs) do Inputs[K] = V end
        for K, V in ipairs(Wire_Outputs) do Outputs[K] = V end

        self:ACF_SetupWireIO(Inputs, Outputs)

        if Wire_Inputs then
            if Entity.Inputs then
                Entity.Inputs = WireLib.AdjustInputs(Entity, Inputs)
            else
                Entity.Inputs = WireLib.CreateInputs(Entity, Inputs)
            end
        end

        if Wire_Outputs then
            if Entity.Outputs then
                Entity.Outputs = WireLib.AdjustOutputs(Entity, Outputs)
            else
                Entity.Outputs = WireLib.CreateOutputs(Entity, Outputs)
            end
        end
    end

    -- ACF SENT hook
    if not ENT.ACF_SetupWireIO then ENT.ACF_SetupWireIO = function() end end
end

function ACF.AutoRegisterV2(DefineFields)
    ClassNameTrick(ENT)
    ClassFieldDefinitions(ENT, DefineFields)

    local ExpectedClass = ACF.ClassName

    local Idx = "ACF.AutoRegister" .. SysTime()
    hook.Add("PreRegisterSENT", Idx, function(ENT, Class)
        hook.Remove("PreRegisterSENT", Idx)

        if Class ~= ExpectedClass then return end
        PrepareWiremodFunctions(ENT)
    end)
end