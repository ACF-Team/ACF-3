ACF.Classes.DefineClass("ACF.ContainerShapes.BaseContainerShape", function(CLASS)
    CLASS.ID    = "BaseContainerShape"
    CLASS.Name  = "Container Shape"
    CLASS.Model = ""
    CLASS.Icon  = ""

    -- True for shapes that pack rounds in concentric rings (ammo drums).
    CLASS.IsDrum = false

    -- True for box crates that feed rounds along an internal conveyor.
    CLASS.IsCassette = false

    -- True for shapes with a feed mechanism an autoloader can draw from.
    CLASS.IsMechanized = false

    -- False for shapes whose rounds sit on a fixed lattice that hex packing cannot tighten.
    CLASS.CanHexPack = true

    -- Degrees between Direction and the way the crate's shells point, which an autoloader arm should match.
    function CLASS.GetShellAngleDiff(Crate, Direction)
        local Facing = Crate:LocalToWorldAngles(Crate.ExtraData.LocalAng):Forward()

        return math.deg(math.acos(math.Clamp(Direction:Dot(Facing), -1, 1)))
    end

    -- Subtypes must implement ShapeCalculation(Size) -> Volume (cu in).
    -- Wall thickness is no longer a fixed figure, so this is the full exterior volume;
    -- armor comes from the volumetric mesh instead.
end)
