local ACF = ACF

local RecursiveEntityRemove
function RecursiveEntityRemove(ent, track)
    track = track or {}
    if track[ent] == true then return end
    local constrained = constraint.GetAllConstrainedEntities(ent)
    ent:Remove()
    track[ent] = true
    for k, _ in pairs(constrained) do
        if k ~= ent then RecursiveEntityRemove(k, track) end
    end
end

-- permutation is of the form (Axis mapped to X, Axis mapped to Y, Axis mapped to Z). Default is Vector(1, 2, 3) which means X -> X, Y -> Y, Z -> Z.
-- addAngles is the angles to add to the model angles after the conversion
local bpConvertibleModelPaths = {
    { startWith = "models/sprops/rectangles", permutation = Vector(1, 2, 3), addAngles = Angle(0, 0, 0) },
    { startWith = "models/sprops/misc/sq_holes", permutation = Vector(1, 2, 3), addAngles = Angle(0, 0, 90), warning = "This model normally has weird angles. Please make sure to check the angles after conversion." },
    { startWith = "models/hunter/plates/plate", permutation = Vector(2, 1, 3), addAngles = Angle(0, -90, 0), warning = "This model normally has weird angles. Please make sure to check the angles after conversion." },
    { startWith = "models/hunter/blocks/cube", permutation = Vector(2, 1, 3), addAngles = Angle(0, -90, 0), warning = "This model normally has weird angles. Please make sure to check the angles after conversion." },
}

function ACF.ConvertEntityToBaseplate(Player, Target)
    if not AdvDupe2 then return false, "Advanced Duplicator 2 is not installed" end

    if not IsValid(Target) then return false, "Invalid target" end

    local Owner = Target:CPPIGetOwner()
    if not IsValid(Owner) or Owner ~= Player then return false, "You do not own this entity" end

    local PhysObj = Target:GetPhysicsObject()
    if not IsValid(PhysObj) then return false, "Entity is not physical" end

    if Target:GetClass() ~= "prop_physics" then return false, "Entity must be typeof 'prop_physics'" end

    local foundTranslation
    local targetModel = Target:GetModel()

    for _, v in ipairs(bpConvertibleModelPaths) do
        if string.StartsWith(targetModel, v.startWith) then
            foundTranslation = v
            break
        end
    end

    if not foundTranslation then return false, "Incompatible model '" .. targetModel .. "'" end

    local AMi, AMa = PhysObj:GetAABB()
    local BoxSize = AMa - AMi

    -- Duplicate the entire thing
    local Entities, Constraints = AdvDupe2.duplicator.Copy(Player, Target, {}, {}, vector_origin)

    -- Find the baseplate
    local Baseplate = Entities[Target:EntIndex()]

    -- Setup the dupe table to convert it to a baseplate
    local permutation = foundTranslation.permutation
    local w, l, t = BoxSize[permutation.x], BoxSize[permutation.y], BoxSize[permutation.z]
    Baseplate.Class = "acf_baseplate"
    Baseplate.ACF_UserData = Baseplate.ACF_UserData or {}
    Baseplate.ACF_UserData.Length = w
    Baseplate.ACF_UserData.Width = l
    Baseplate.ACF_UserData.Thickness = t
    Baseplate.PhysicsObjects[0].Angle = Baseplate.PhysicsObjects[0].Angle + foundTranslation.addAngles

    -- Swap width/thickness if necessary
    if foundTranslation.addAngles.z == 90 then
        Baseplate.ACF_UserData.Width = t
        Baseplate.ACF_UserData.Thickness = l
    end

    -- Delete everything now
    for k, _ in pairs(Entities) do
        local e = Entity(k)
        if IsValid(e) then e:Remove() end
    end

    -- Paste the stuff back to the dupe
    local Ents = AdvDupe2.duplicator.Paste(Owner, Entities, Constraints, vector_origin, angle_zero, vector_origin, true)
    -- Try to find the baseplate
    local NewBaseplate
    for _, v in pairs(Ents) do
        if v:GetClass() == "acf_baseplate" and v:GetPos() == Baseplate.Pos then
            NewBaseplate = v
            break
        end
    end

    undo.Create("acf_baseplate")
    undo.AddEntity(NewBaseplate)
    undo.SetPlayer(Player)
    undo.Finish()

    if foundTranslation.warning then
        ACF.SendNotify(Player, false, foundTranslation.warning)
    end

    return true, NewBaseplate
end