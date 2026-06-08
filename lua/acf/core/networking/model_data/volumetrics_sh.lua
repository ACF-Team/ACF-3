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
                local A = Entity:LocalToWorld(Convex[I].pos)
                local B = Entity:LocalToWorld(Convex[I + 1].pos)
                local C = Entity:LocalToWorld(Convex[I + 2].pos)

                ConvexTris[#ConvexTris + 1] = Vector(GetIndex(A), GetIndex(B), GetIndex(C))
            end
        end

        Entity.ACF_Volumetric_Mesh = MeshData
    end

    hook.Add("ACF_OnLoadAddon", "ACF_Volumetric_Detours", function()
        local Detours = ACF and ACF.Detours
        print("Loading ACF Volumetric Detours", Detours)

        -- Stuff like primitives reinitializing
        local PhysInitConvex_Orig PhysInitConvex_Orig = Detours.Metatable("Entity", "PhysicsInitConvex", function(self, Mesh, ...)
            print("physinitconvex", self, Mesh)
            ACF.ProcessMesh(self, Mesh)
            return PhysInitConvex_Orig(self, Mesh, ...)
        end)

        -- Stuff like primitives reinitializing
        local PhysInitMultiConvex_Orig PhysInitMultiConvex_Orig = Detours.Metatable("Entity", "PhysicsInitMultiConvex", function(self, Meshes, ...)
            print("physinitmulticonvex", self, Meshes)
            ACF.ProcessMesh(self, Meshes)
            return PhysInitMultiConvex_Orig(self, Meshes, ...)
        end)

        -- Everything in general
        hook.Add("OnEntityCreated", "ACF_Volumetric_Detours", function(ent)
            timer.Simple(0, function()
                if IsValid(ent) and IsValid(ent:GetPhysicsObject()) then
                    ACF.ProcessMesh(ent, ent:GetPhysicsObject():GetMeshConvexes() or {})
                end
            end)
        end)
    end)
end