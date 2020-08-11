hook.Add("Initialize", "Scalable Entities", function()
	do -- Detour decals to scale better on scaled entities
		local DecalEx = util.DecalEx

		util.DecalEx = function(Mat, Ent, Pos, Normal, Color, W, H)
			if Ent.IsScalable and Ent:GetSize() then -- If entity is scaled, offset decal pos
				local Offset = Pos - Ent:GetPos()

				-- Thank you, Garry. Very cool.
				local O 	 = Ent:GetOriginalSize()
				local C 	 = Ent:GetSize()
				local Scaler = Vector(O[1] / C[1], O[2] / C[2], O[3] / C[3])

				Pos = Ent:GetPos() + Offset * Scaler

				-- TODO: Consider every face of the box will have a different scale
				local Max = math.max(Scaler[1], Scaler[2], Scaler[3])

				W = W * Max
				H = H * Max
			end

			DecalEx(Mat, Ent, Pos, Normal, Color, W, H)
		end
	end

	do -- Dealing with visual clip's bullshit
		local Meta = FindMetaTable("Entity")
		local EnaMatr = Meta.EnableMatrix
		local DisMatr = Meta.DisableMatrix

		function Meta:EnableMatrix(Str, NewScale)
			if self.IsScalable and self:GetSize() and Str == "RenderMultiply" then
				local Size  = self:GetOriginalSize()
				local Scale = Vector(1 / Size.x, 1 / Size.y, 1 / Size.z) * self:GetSize()

				if NewScale:GetScale() == Scale then
					return
				end
			end

			EnaMatr(self, Str, NewScale)
		end

		function Meta:DisableMatrix(Str)
			if self.IsScalable and self:GetSize() and Str == "RenderMultiply" then
				local Mat = Matrix()

				local Size  = self:GetOriginalSize()
				local Scale = Vector(1 / Size.x, 1 / Size.y, 1 / Size.z) * self:GetSize()

				Mat:Scale(Scale)

				self:EnableMatrix("RenderMultiply", Mat)

				return
			end

			DisMatr(self, Str)
		end
	end

	hook.Remove("Initialize", "Scalable Entities")
end)