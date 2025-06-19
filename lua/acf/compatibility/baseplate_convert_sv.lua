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

local bpConvertibleModelPaths = {
    { startWith = "models/sprops/rectangles", addAngles = Angle(0, 0, 0) },
    { startWith = "models/sprops/misc/sq_holes", addAngles = Angle(0, 0, 90) },
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
    local w, l, t = BoxSize.x, BoxSize.y, BoxSize.z
    Baseplate.Class = "acf_baseplate"
    Baseplate.Length = w
    Baseplate.Width = l
    Baseplate.Thickness = t
    Baseplate.PhysicsObjects[0].Angle = Baseplate.PhysicsObjects[0].Angle + foundTranslation.addAngles

    -- Swap width/thickness if necessary
    if foundTranslation.addAngles.z == 90 then
        Baseplate.Width = t
        Baseplate.Thickness = l
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

    return true, NewBaseplate
end