DEFINE_BASECLASS("base_wire_entity")

ENT.DoNotDuplicate    = true
ENT.DisableDuplicator = true
ENT.DoNotTrack        = true
ENT.IsACFMissile         = true
ENT.ConvexMaterial = "Aluminum" -- base_wire_entity inherits none; mesh would fall back to "Default"
ENT.ACF_PreventArmoring = true -- Stops the mesh mass overwriting ForcedMass
