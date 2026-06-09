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
    ENT.ACF_ClassDef = ACF.Classes.DefineClass(ENT.ACF_ClassName, ENT.ACF_BaseClassName, DefineFields)
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

local function PrepareSpawnFunctions(ENT, ClassName)
    local ClassDef      = ENT.ACF_ClassDef
    local Serialization = ACF.Classes.Serialization

    cleanup.Register(ClassName)

    function ENT:ACF_GetUserVar(Key)
        return self.ACF_LiveData and self.ACF_LiveData[Key]
    end

    function ENT:ACF_SetUserVar(Key, Value)
        if not self.ACF_LiveData then self.ACF_LiveData = ClassDef() end
        self.ACF_LiveData[Key] = Value
    end

    -- Populates ACF_LiveData from raw ClientData (menu or duplicator).
    -- Calls ACF_OnVerifyClientData (entity-specific transforms) before,
    -- and ACF_PostUpdateEntityData (entity init) after.
    function ENT:ACF_UpdateEntityData(ClientData)
        self.ACF = self.ACF or {} -- Why does this line exist? I feel like there's a reason and it scares me from removing it

        if ENT.ACF_OnVerifyClientData then
            ENT.ACF_OnVerifyClientData(ClientData)
        end

        local CanUpdate, Reason = hook.Run("ACF_PreUpdateEntity", Class, self, ClientData)
        if CanUpdate == false then return CanUpdate, Reason end

        ACF.SaveEntity(self)

        if self.ACF_LiveData then
            Serialization.DeserializeInto(ClassDef, self.ACF_LiveData, ClientData)
        else
            self.ACF_LiveData = Serialization.DeserializePartial(ClassDef, ClientData)
        end

        hook.Run("ACF_OnUpdateEntity", Class, self, ClientData)
        ACF.RestoreEntity(self)

        if self.ACF_PostUpdateEntityData then
            self:ACF_PostUpdateEntityData(ClientData)
        end
        ACF.Activate(self, true)
        return true, (self.PrintName or Class) .. " updated successfully!"
    end

    local function DoSpawn(Player, Pos, Angle, ClientData, IsMenuSpawn)
        local Entity = ents.Create(ClassName)
        if not IsValid(Entity) then return end

        Entity:SetPos(Pos)
        Entity:SetAngles(Angle)

        if Entity.ACF_PreSpawn then Entity:ACF_PreSpawn() end

        Entity:Spawn()
        Entity:Activate()

        Entity:ACF_UpdateEntityData(ClientData)

        if Entity.ACF_PostSpawn then Entity:ACF_PostSpawn(Player, Pos, Angle, ClientData) end
        if IsMenuSpawn and Entity.ACF_PostMenuSpawn then Entity:ACF_PostMenuSpawn() end

        return Entity
    end

    duplicator.RegisterEntityClass(ClassName, function(Player, Pos, Angle, UserData)
        return DoSpawn(Player, Pos, Angle, UserData or {}, false)
    end, "Pos", "Angle", "ACF_UserData")

    hook.Add("ACF_TemporaryHook_InstantiateEntity", "AutoRegV2_" .. ClassName, function(Class, Player, Pos, Ang, ClientData)
        if Class ~= ClassName then return end
        local Entity = DoSpawn(Player, Pos, Ang, ClientData or {}, true)
        if IsValid(Entity) then return Entity end
    end)
end

local function PrepareSerializationFunctions(ENT)
    local ClassDef             = ENT.ACF_ClassDef
    local OrigPreEntityCopy    = ENT.PreEntityCopy
    local OrigPostEntityPaste  = ENT.PostEntityPaste

    function ENT:PreEntityCopy()
        if self.ACF_LiveData then
            self.ACF_UserData = ACF.Classes.Serialization.Serialize(ClassDef, self.ACF_LiveData)
        end
        if OrigPreEntityCopy then OrigPreEntityCopy(self) end
        self.BaseClass.PreEntityCopy(self)
    end

    function ENT:PostEntityPaste(Player, Ent, CreatedEntities)
        local Data = Ent.ACF_UserData or {}
        if self.ACF_LiveData then
            ACF.Classes.Serialization.ResolveEntities(ClassDef, self.ACF_LiveData, Data, CreatedEntities)
        end
        if OrigPostEntityPaste then OrigPostEntityPaste(self, Player, Ent, CreatedEntities) end
        self.BaseClass.PostEntityPaste(self, Player, Ent, CreatedEntities)
    end
end

function ACF.AutoRegisterV2(DefineFields)
    ENT.IsACFEntity = true
    ClassNameTrick(ENT)
    ClassFieldDefinitions(ENT, DefineFields)

    local ExpectedClass = ENT.ACF_ClassName

    local Idx = "ACF.AutoRegister" .. SysTime()
    hook.Add("PreRegisterSENT", Idx, function(ENT, Class)
        hook.Remove("PreRegisterSENT", Idx)

        if Class ~= ExpectedClass then return end
        PrepareWiremodFunctions(ENT)
        PrepareSerializationFunctions(ENT)
        PrepareSpawnFunctions(ENT, ExpectedClass)
        ENT.ACF_ClassDef = nil -- Otherwise hot reloading entities completely breaks lol
    end)
end