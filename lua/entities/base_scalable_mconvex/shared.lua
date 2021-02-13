DEFINE_BASECLASS("base_scalable")

ENT.PrintName     = "Scalable Multi Convex"
ENT.WireDebugName = "Scalable Multi Convex"

do -- Dirty, dirty hacking to prevent other addons initializing physics the wrong way
	local EntMeta = FindMetaTable("Entity")

	EntMeta.DefaultPhysics = EntMeta.DefaultPhysics or EntMeta.PhysicsInit

	function EntMeta:PhysicsInit(Solid, Bypass)
		if self.IsScalable and not Bypass then
			local Init = self.FirstInit

			if not Init then
				self.FirstInit = true
			end

			if Init or CLIENT then
				self:Restore()

				return true
			end
		end

		return self:DefaultPhysics(Solid)
	end

	function ENT:Restore()
		local Size = self:GetSize()

		-- We must manually reset the mesh on the clientside for this to work
		if CLIENT then
			self.Mesh = table.Copy(self.RealMesh)
		end

		self:SetSize(Size)
	end
end
