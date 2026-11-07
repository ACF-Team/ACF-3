DEFINE_BASECLASS("base_scalable")

ENT.PrintName     = "Scalable ACF Base Entity"
ENT.WireDebugName = "Scalable ACF Base Entity"
ENT.PluralName    = "Scalable ACF Base Entities"
ENT.IsACFEntity   = true
ENT.ACF_PreventArmoring = true
ENT.ACF_KillableButIndestructible = true
ENT.ACF_HealthUpdatesWireOverlay = true
ENT.ACF_HasOverlay = true -- Clientside mirror of ACF_UpdateOverlayState, which only exists serverside
ENT.ConvexMaterial = "Component"