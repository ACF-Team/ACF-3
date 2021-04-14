hook.Add("Initialize", "Scalable Entities", function()
	do -- Detour decals to scale better on scaled entities
		local DecalEx = util.DecalEx

		util.DecalEx = function(Mat, Ent, Pos, Normal, Color, W, H, ...)
			if Ent.IsScalable and Ent:GetSize() then -- If entity is scaled, offset decal pos
				local Offset = Pos - Ent:GetPos()

				-- Thank you, Garry. Very cool.
				local O 	 = Ent:GetOriginalSize()
				local C 	 = Ent:GetSize()
				local Scaler = Vector(O[1] / C[1], O[2] / C[2], O[3] / C[3])

				Pos = Ent:GetPos() + Offset * Scaler

				local Max = math.max(Scaler[1], Scaler[2], Scaler[3])

				W = W * Max
				H = H * Max
			end

			DecalEx(Mat, Ent, Pos, Normal, Color, W, H, ...)
		end
	end

	do -- Dealing with visual clip's bullshit
		local Meta = FindMetaTable("Entity")
		local EnableMatrix = Meta.EnableMatrix
		local DisableMatrix = Meta.DisableMatrix

		function Meta:EnableMatrix(Str, Matrix, ...)
			if self.IsScalable and self.Matrix and Str == "RenderMultiply" then
				local RealScale = self.Matrix:GetScale()
				local Scale = Matrix:GetScale()

				-- Visual clip provides a scale of 0, 0, 0
				-- So we just update it with our actual scale
				if RealScale ~= Scale then
					Matrix:SetScale(RealScale)
				end
			end

			EnableMatrix(self, Str, Matrix, ...)
		end

		function Meta:DisableMatrix(Str, ...)
			if self.IsScalable and self.Matrix and Str == "RenderMultiply" then
				-- Visual clip will attempt to disable the matrix
				-- We don't want that to happen with scalable entities
				self:EnableMatrix("RenderMultiply", self.Matrix)

				return
			end

			DisableMatrix(self, Str, ...)
		end
	end

	hook.Remove("Initialize", "Scalable Entities")
end)