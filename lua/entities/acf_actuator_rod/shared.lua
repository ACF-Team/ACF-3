DEFINE_BASECLASS("base_scalable")

ENT.PrintName      = "ACF Actuator Rod"
ENT.WireDebugName  = "ACF Actuator Rod"
ENT.ConvexMaterial = "Aluminum"
ENT.DoNotDuplicate = true -- Recreated by its actuator
ENT.ACF_IsNotLegalityChecked = true

-- Tools assume they can move or unparent what they hit, which throws the rod off its actuator
hook.Add("CanTool", "ACF Actuator Rod", function(_, Trace)
	local Entity = Trace.Entity

	if IsValid(Entity) and Entity:GetClass() == "acf_actuator_rod" then return false end
end)
