timer.Simple(1, function()
    if CPPI then return end

    CPPI = {}

    local Entities = {}
    local Backup   = {}

    function CPPI:GetName() return "CPPI for ACF3" end
    function CPPI:GetVersion() return "ACF3" end
    function CPPI:GetInterfaceVersion() return 1.3 end
    function CPPI:GetNameFromUID() return CPPI_NOTIMPLEMENTED end

    ----------------------------------------------

    local PLAYER = FindMetaTable("Player")

    function PLAYER:CPPIGetFriends() return CPPI_NOTIMPLEMENTED end

    ----------------------------------------------

    local ENTITY = FindMetaTable("Entity")

    function ENTITY:CPPIGetOwner()
        local Owner = SERVER and self.CPPIOwner or self:GetNWEntity("CPPIOwner")

        if not IsValid(Owner) then return end

        return Owner, Owner:UniqueID()
    end

    if CLIENT then return end

    function ENTITY:CPPISetOwner(Player)
        if not isentity(Player) and Player ~= nil then return false end
        if not IsValid(Player) then Player = nil end

        local Owner    = self.CPPIOwner
        local Previous = IsValid(Owner) and Entities[Owner]
        local Current  = Player and Entities[Player]

        if Previous then
            Previous[self] = nil

            self:RemoveCallOnRemove("CPPI_Owner")
        end

        self.CPPIOwner = Player

        self:SetNWEntity("CPPIOwner", Player)

        if Current then
            Current[self] = true

            self:CallOnRemove("CPPI_Owner", function()
                Current[self] = nil
            end)
        end

        hook.Run("CPPIAssignOwnership", Player, self)

        return true
    end

    function ENTITY:CPPISetOwnerUID() return CPPI_NOTIMPLEMENTED end

    function ENTITY:CPPICanTool(Player, ToolMode)
        local Trace = Player:GetEyeTrace()
        local Tool  = Player:GetTool()

        return hook.Run("CanTool", Player, Trace, ToolMode, Tool, 0) -- I hope that zero doesn't break anything
    end

    function ENTITY:CPPICanPhysgun(Player) return hook.Run("PhysgunPickup", Player, self) end
    function ENTITY:CPPICanPickup(Player) return hook.Run("GravGunPickupAllowed", Player, self) end
    function ENTITY:CPPICanPunt(Player) return hook.Run("GravGunPunt", Player, self) end
    function ENTITY:CPPICanUse(Player) return hook.Run("PlayerUse", Player, self) end
    function ENTITY:CPPICanDamage() return hook.Run("EntityTakeDamage", self, DamageInfo()) or true end -- Maybe just return true?
    function ENTITY:CPPIDrive(Player) return hook.Run("CanDrive", Player, self) end
    function ENTITY:CPPICanProperty(Player, Property) return hook.Run("CanProperty", Player, Property, self) end
    function ENTITY:CPPICanEditVariable(Player, Key, Value, Data) return hook.Run("CanEditVariable", self, Player, Key, Value, Data) end

    ----------------------------------------------

    local function SetOwner(Player, Entity)
        Entity:CPPISetOwner(Player)
    end

    local function SetOwnerTheReturn(Player, _, Entity)
        Entity:CPPISetOwner(Player)
    end

    hook.Add("PlayerAuthed", "ACF_CPPI", function(Player, SteamID)
        if not IsValid(Player) then return end
        if not Player:IsPlayer() then return end

        local Backed  = Backup[SteamID]
        local New     = {}

        Entities[Player] = New

        if Backed then
            for Entity in pairs(Backed) do
                local Owner = Entity:CPPIGetOwner()

                if IsValid(Owner) and Owner ~= Player then continue end

                Entity:CPPISetOwner(Player)
            end

            Backup[SteamID] = nil
        end

        Player:CallOnRemove("ACF_CPPI", function()
            Entities[Player] = nil

            if not next(New) then return end

            local Restore = {}

            for Entity in pairs(New) do
                Entity:CPPISetOwner()

                Restore[Entity] = true
            end

            Backup[SteamID] = Restore
        end)
    end)

    hook.Add("PlayerSpawnedNPC", "ACF_CPPI", SetOwner)
    hook.Add("PlayerSpawnedSENT", "ACF_CPPI", SetOwner)
    hook.Add("PlayerSpawnedSWEP", "ACF_CPPI", SetOwner)
    hook.Add("PlayerSpawnedVehicle", "ACF_CPPI", SetOwner)

    hook.Add("PlayerSpawnedEffect", "ACF_CPPI", SetOwnerTheReturn)
    hook.Add("PlayerSpawnedProp", "ACF_CPPI", SetOwnerTheReturn)
    hook.Add("PlayerSpawnedRagdoll", "ACF_CPPI", SetOwnerTheReturn)

    ACF.PrintLog("Warning", "Couldn't find a CPPI-compliant prop protection addon, using fallback methods.")
    ACF.PrintLog("Warning", "Please consider giving the README file a look in the Github repository.")
end)