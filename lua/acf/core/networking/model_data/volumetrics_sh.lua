local ArmorableClasses = {
    prop_physics = true,
    primitive_shape = true,
}

if SERVER then
    function ACF.ProcessMesh(Entity, Meshes)
        local MeshData = { Verts = {}, Convexes = {} }
        local Lookup = {}

        local function GetIndex(Pos)
            local Key = Pos.x .. " " .. Pos.y .. " " .. Pos.z
            local Index = Lookup[Key]
            if not Index then
                MeshData.Verts[#MeshData.Verts + 1] = Pos
                Index = #MeshData.Verts
                Lookup[Key] = Index
            end
            return Index
        end

        for _, Convex in ipairs(Meshes) do
            local ConvexTris = {}
            MeshData.Convexes[#MeshData.Convexes + 1] = ConvexTris

            for I = 1, #Convex, 3 do
                local A = Convex[I].pos
                local B = Convex[I + 1].pos
                local C = Convex[I + 2].pos

                ConvexTris[#ConvexTris + 1] = Vector(GetIndex(A), GetIndex(B), GetIndex(C))
            end
        end

        Entity.ACF_Volumetric_Mesh = MeshData
    end

    local function ProcessEntity(entity)
        if IsValid(entity) and (entity.IsACFEntity or ArmorableClasses[entity:GetClass()]) and IsValid(entity:GetPhysicsObject()) then
            local convexes = entity:GetPhysicsObject():GetMeshConvexes() or {}
            ACF.ProcessMesh(entity, convexes)
        end
    end

    hook.Add("ACF_OnLoadAddon", "ACF_Volumetric_Detours", function()
        local Detours = ACF and ACF.Detours
        print("Loading ACF Volumetric Detours", Detours)

        local PhysInitConvex_Orig PhysInitConvex_Orig = Detours.Metatable("Entity", "PhysicsInitConvex", function(self, Mesh, ...)
            timer.Simple(0, function()
                -- print("PhysicsInitConvex", self, Mesh)
                ProcessEntity(self)
            end)
            return PhysInitConvex_Orig(self, Mesh, ...)
        end)

        local PhysInitMultiConvex_Orig PhysInitMultiConvex_Orig = Detours.Metatable("Entity", "PhysicsInitMultiConvex", function(self, Meshes, ...)
            timer.Simple(0, function()
                -- print("PhysicsInitMultiConvex", self, Meshes)
                ProcessEntity(self)
            end)
            return PhysInitMultiConvex_Orig(self, Meshes, ...)
        end)

        -- Everything in general
        hook.Add("OnEntityCreated", "ACF_Volumetric_Detours", function(ent)
            timer.Simple(0, function()
                -- print("OnEntityCreated", ent)
                ProcessEntity(ent)
            end)
        end)
    end)
end