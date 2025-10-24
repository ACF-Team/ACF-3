-- self.ParentState is one of three values:
-- 0:  Unparented
-- -1: Invalid parent chain
-- 1:  Valid parent chain

-- We only want to track these.
local ApplyTo = {
    ["acf_gun"] = true,
    ["acf_rack"] = true,
    ["acf_piledriver"] = true,
}

local ParentChainObj = {acf_turret = true, acf_turret_rotator = true}

local PARENT_CHAIN_STATE_NOT_PARENTED     = 0;  ACF.PARENT_CHAIN_STATE_NOT_PARENTED     = PARENT_CHAIN_STATE_NOT_PARENTED
local PARENT_CHAIN_STATE_BAD_PARENT_CHAIN = -1; ACF.PARENT_CHAIN_STATE_BAD_PARENT_CHAIN = PARENT_CHAIN_STATE_BAD_PARENT_CHAIN
local PARENT_CHAIN_STATE_PARENT_CHAIN_OK  = 1;  ACF.PARENT_CHAIN_STATE_PARENT_CHAIN_OK  = PARENT_CHAIN_STATE_PARENT_CHAIN_OK

local function LethalHasValidParentState(self)
    if self.ACF_ParentState ~= PARENT_CHAIN_STATE_PARENT_CHAIN_OK and ACF.LegalChecks and not ACF.AllowArbitraryParents then
        -- This NEEDS a better message, I can't find a good way to explain it right now
        ACF.DisableEntity(self, "Invalid Parent Chain", (self.PluralName or self:GetClass()) .. " can only be parented to turret entities and must have a baseplate root ancestor.", 5)
        return false
    end
end

local function DetermineParentState(self)
    local EntTable = self:GetTable()
    --if EntTable.ParentStateValid then return end
    -- ^^^ what did this even do? There's no reference to it anywhere!

    if not IsValid(self:GetParent()) then
        EntTable.ACF_ParentState = PARENT_CHAIN_STATE_NOT_PARENTED
    elseif not ACF.CheckParentChain(self, ParentChainObj, "acf_baseplate") then
        EntTable.ACF_ParentState = PARENT_CHAIN_STATE_BAD_PARENT_CHAIN
    else
        EntTable.ACF_ParentState = PARENT_CHAIN_STATE_PARENT_CHAIN_OK
    end
end

local function RefreshFamilyParentStates(Family)
    for ApplyToClass in pairs(ApplyTo) do
        for SecondEnt in pairs(Family:EntitiesByClass(ApplyToClass)) do
            if IsValid(SecondEnt) then DetermineParentState(SecondEnt) end
        end
    end
end

hook.Add("cfw.family.added", "acf_gun_family", function(Family, Ent)
    if not IsValid(Ent) then return end -- CFW issue?
    RefreshFamilyParentStates(Family)
end)

hook.Add("cfw.family.subbed", "acf_gun_family", function(Family, Ent)
    if not IsValid(Ent) then return end -- CFW issue?

    if ApplyTo[Ent:GetClass()] ~= nil then DetermineParentState(Ent) end
    RefreshFamilyParentStates(Family)
end)

-- Purpose: Hook into all lethals pre-fire, check valid parent state
hook.Add("ACF_PreFireWeapon", "ACF_PreventBadParentChain", function(Ent)
    local ValidParentState = LethalHasValidParentState(Ent)
    if ValidParentState == false then return false end
end)