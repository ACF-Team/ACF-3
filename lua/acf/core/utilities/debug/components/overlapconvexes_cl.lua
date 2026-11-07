-- Draws the convexes of the looked at entity at the scale the overlap check samples them at
local ACF   = ACF
local Debug = ACF.Debug

local CHANNEL      = 3 -- Kept apart from the serverside legality and hint drawings
local LIFE         = 5 -- Seconds the drawing stays up
local COLOR_FULL   = Color(255, 255, 255, 60)
local COLOR_SCALED = Color(255, 220, 0)

concommand.Add("acf_debug_overlapconvexes", function(Player)
	local Entity   = Player:GetEyeTrace().Entity
	local MeshData = IsValid(Entity) and Entity.ACF_Volumetric_Mesh
	if not MeshData then print("Not looking at an entity with a volumetric mesh.") return end

	local OldLevel = Debug.GetDeveloperLevel()
	local OldGroup, OldChannel = Debug.SetGroup(Entity, CHANNEL)

	Debug.SetDeveloperLevel(0)
	Debug.Clear(Entity, CHANNEL)

	for ConvexID, Convex in ipairs(MeshData.Convexes) do
		local Scale = ACF.ConvexInsetScale(Convex, ACF.OverlapInset)

		Debug.Convex(Entity, ConvexID, LIFE, COLOR_FULL, true)
		Debug.Convex(Entity, ConvexID, LIFE, COLOR_SCALED, true, Scale)
	end

	Debug.SetDeveloperLevel(OldLevel)
	Debug.SetGroup(OldGroup, OldChannel)
end, nil, "Draws the looked at entity's convexes at the scale the overlap check samples them at.")
