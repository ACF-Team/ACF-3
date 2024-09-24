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

function ACF.ConvertEntityToBaseplate(Player, Target)
    if not IsValid(Target) then return end

    local Owner = Target:CPPIGetOwner()
    if not IsValid(Owner) or Owner ~= Player then return end

    local PhysObj = Target:GetPhysicsObject()
    if not IsValid(PhysObj) then return end

    if Target:GetClass() ~= "prop_physics" then return end

    local AMi, AMa = PhysObj:GetAABB()
    local BoxSize = AMa - AMi

    -- Duplicate the entire thing
    local Entities, Constraints = AdvDupe2.duplicator.Copy(Player, Target, {}, {}, Vector(0, 0, 0))

    -- Find the baseplate
    local Baseplate = Entities[Target:EntIndex()]

    -- Setup the dupe table to convert it to a baseplate
    local w, l, t = BoxSize.x, BoxSize.y, BoxSize.z
    Baseplate.Class = "acf_baseplate"
    Baseplate.Width = w
    Baseplate.Length = l
    Baseplate.Thickness = t

    -- Delete everything now
    for k, _ in pairs(Entities) do
        local e = Entity(k)
        if IsValid(e) then e:Remove() end
    end

    -- Paste the stuff back to the dupe
    local Ents = AdvDupe2.duplicator.Paste(Owner, Entities, Constraints, Vector(0, 0, 0), Angle(0, 0, 0), Vector(0, 0, 0), true)
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

    return NewBaseplate
end