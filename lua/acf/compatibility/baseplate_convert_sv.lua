local ACF = ACF
local Notify = ACF.Utilities.Notify

-- permutation is of the form (Axis mapped to X, Axis mapped to Y, Axis mapped to Z). Default is Vector(1, 2, 3) which means X -> X, Y -> Y, Z -> Z.
-- addAngles is the angles to add to the model angles after the conversion
local bpConvertibleModelPaths = {
    { startWith = "models/sprops/rectangles", permutation = Vector(1, 2, 3), addAngles = Angle(0, 0, 0) },
    { startWith = "models/sprops/misc/sq_holes", permutation = Vector(1, 2, 3), addAngles = Angle(0, 0, 90), warning = "This model normally has weird angles. Please make sure to check the angles after conversion." },
    { startWith = "models/hunter/plates/plate", permutation = Vector(2, 1, 3), addAngles = Angle(0, -90, 0), warning = "This model normally has weird angles. Please make sure to check the angles after conversion." },
    { startWith = "models/hunter/blocks/cube", permutation = Vector(2, 1, 3), addAngles = Angle(0, -90, 0), warning = "This model normally has weird angles. Please make sure to check the angles after conversion." },
}

-- Shadowscion i kneel
local SpropsPain = {
    [0.5] = {String = nil, Size = "0", Rect = "rectangles_superthin"},
    [1.5] = {String = "1_5", Size = "0", Rect = "rectangles_thin"},
    [3] = {String = "3", Size = "1", Rect = "rectangles"},
    [6] = {String = "6", Size = "1_5", Rect = "cube"},
    [12] = {String = "12", Size = "2", Rect = "cube"},
    [18] = {String = "18", Size = "2_5", Rect = "cube"},
    [24] = {String = "24", Size = "3", Rect = "cube"},
    [30] = {String = "30", Size = "3_5", Rect = "cube"},
    [36] = {String = "36", Size = "4", Rect = "cube"},
    [42] = {String = "42", Size = "4_5", Rect = "cube"},
    [48] = {String = "48", Size = "5", Rect = "cube"},
    [54] = {String = "54", Size = "54", Rect = "cube"},
    [60] = {String = "60", Size = "60", Rect = "cube"},
    [66] = {String = "66", Size = "66", Rect = "cube"},
    [72] = {String = "72", Size = "72", Rect = "cube"},
    [78] = {String = "78", Size = "78", Rect = "cube"},
    [84] = {String = "84", Size = "84", Rect = "cube"},
    [90] = {String = "90", Size = "90", Rect = "cube"},
    [96] = {String = "96", Size = "6", Rect = "cube"},
    [108] = {String = "108", Size = nil, Rect = "cube"},
    [120] = {String = "120", Size = nil, Rect = "cube"},
    [132] = {String = "132", Size = nil, Rect = "cube"},
    [144] = {String = "144", Size = "7", Rect = "cube"},
    [192] = {String = "192", Size = "8", Rect = "cube"},
    [240] = {String = "240", Size = "9", Rect = "cube"},
    [288] = {String = "288", Size = nil, Rect = "cube"},
    [336] = {String = "336", Size = nil, Rect = "cube"},
    [384] = {String = "384", Size = nil, Rect = "cube"},
    [432] = {String = "432", Size = nil, Rect = "cube"},
    [480] = {String = "480", Size = nil, Rect = "cube"},
}

local SpropsSizes = table.GetKeys(SpropsPain)
table.sort(SpropsSizes)

local function FindNiceDimension(x)
    for _, Key in ipairs(SpropsSizes) do
        if Key >= x then return Key end
    end
end

local function DimToModel(x, y, z)
    local XK = FindNiceDimension(x)
    local YK = FindNiceDimension(y)
    local ZK = FindNiceDimension(z)

    if XK > YK then
        XK, YK = YK, XK
    end

    local XEntry = SpropsPain[XK]
    local YEntry = SpropsPain[YK]
    local ZEntry = SpropsPain[ZK]
    if XEntry.Size == nil then return nil, "Not a valid sprops size" end
    local Model = "models/sprops/" .. ZEntry.Rect .. "/size_" .. XEntry.Size .. "/rect_" .. XEntry.String .. "x" .. YEntry.String
    if ZK ~= 0.5 then Model = Model .. "x" .. ZEntry.String end
    return Model .. ".mdl"
end

function ACF.ConvertBaseplate(Player, Target)
    if not AdvDupe2 then return false, "Advanced Duplicator 2 is not installed" end

    if not IsValid(Target) then return false, "Invalid target" end

    local Owner = Target:CPPIGetOwner()
    if not IsValid(Owner) or Owner ~= Player then return false, "You do not own this entity" end

    local PhysObj = Target:GetPhysicsObject()
    if not IsValid(PhysObj) then return false, "Entity is not physical" end

    local PropToBaseplate = Target:GetClass() == "prop_physics"
    local BaseplateToProp = Target:GetClass() == "acf_baseplate"
    if not PropToBaseplate and not BaseplateToProp then
        return false, "Incompatible entity class '" .. Target:GetClass() .. "'"
    end

    -- Compute box size
    local AMi, AMa = PhysObj:GetAABB()
    local BoxSize = AMa - AMi

    -- Determine which entities to area copy
    local EntsByIndex = {}
    local Contraption = Target:GetContraption()
    if Contraption then
        -- Save everything including turrets through contraption data
        for ent, _ in pairs(Contraption.ents) do EntsByIndex[ent:EntIndex()] = ent end
    else
        -- Otherwise, just the baseplate entity
        EntsByIndex[Target:EntIndex()] = Target
    end

    -- Perform the area copy and retrieve the dupe table
    local Entities, Constraints = AdvDupe2.duplicator.AreaCopy(Player, EntsByIndex, vector_origin, false)

    -- Find the baseplate in the dupe table
    local Baseplate = Entities[Target:EntIndex()]

    if PropToBaseplate then
        -- Prop to baseplate conversion
        local foundTranslation
        local targetModel = Target:GetModel()

        for _, v in ipairs(bpConvertibleModelPaths) do
            if string.StartsWith(targetModel, v.startWith) then
                foundTranslation = v
                break
            end
        end

        if not foundTranslation then return false, "Incompatible model '" .. targetModel .. "'" end

        -- Setup the dupe table to convert it to a baseplate
        local permutation = foundTranslation.permutation
        local w, l, t = BoxSize[permutation.x], BoxSize[permutation.y], BoxSize[permutation.z]
        Baseplate.Class = "acf_baseplate"
        Baseplate.ACF_UserData = Baseplate.ACF_UserData or {}
        Baseplate.ACF_UserData.Length = w
        Baseplate.ACF_UserData.Width = l
        Baseplate.ACF_UserData.Thickness = t
        Baseplate.ACF_UserData.DisableAltE = false
        Baseplate.PhysicsObjects[0].Angle = Baseplate.PhysicsObjects[0].Angle + foundTranslation.addAngles

        -- Swap width/thickness if necessary
        if foundTranslation.addAngles.z == 90 then
            Baseplate.ACF_UserData.Width = t
            Baseplate.ACF_UserData.Thickness = l
        end

        if foundTranslation.warning then
            Notify.WarningToPlayer(Player, "An issue occured while converting a prop to an ACF baseplate", foundTranslation.warning)
        end
    elseif BaseplateToProp then
        -- Baseplate to prop conversion
        local Model, Error = DimToModel(math.Round(BoxSize.x, 2), math.Round(BoxSize.y, 2), math.Round(BoxSize.z, 2))
        if not Model then return false, Error end

        local Baseplate = Entities[Target:EntIndex()]
        Baseplate.Class = "prop_physics"
        Baseplate.Model = Model
        Baseplate.ACF_UserData = nil
        Baseplate.EntityMods.LuaSeatID = nil
        if IsValid(Target.Pod) then Entities[Target.Pod:EntIndex()] = nil end
    end

    -- Delete everything now
    for k, _ in pairs(Entities) do
        local e = Entity(k)
        if IsValid(e) then e:Remove() end
    end

    -- Paste the modified dupe
    AdvDupe2.duplicator.Paste(Owner, Entities, Constraints, vector_origin, angle_zero, vector_origin, true)

    return true
end
