hook.Add("Initialize", "Scalable Entities", function()
	do -- Detour decals to scale better on scaled entities
		local DecalEx = util.DecalEx

		util.DecalEx = function(Mat, Ent, Pos, Normal, Color, W, H)
			if Ent.OriginalSize then -- If entity is scaled offset decal pos
				local Offset = Pos - Ent:GetPos()

				-- Thank you, Garry. Very cool.
				local O 	 = Ent.OriginalSize
				local C 	 = Ent.CurrentSize
				local Scaler = Vector(O[1] / C[1], O[2] / C[2], O[3] / C[3])

				Pos = Ent:GetPos() + Offset * Scaler

				local Max = math.Max(Scaler[1], Scaler[2], Scaler[3])

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
			if self.OriginalSize and Str == "RenderMultiply" then
				local Size  = self.OriginalSize
				local Scale = Vector(1 / Size.x, 1 / Size.y, 1 / Size.z) * self.Size

				if NewScale:GetScale() ~= Scale then
					return
				end
			end

			EnaMatr(self, Str, NewScale)
		end

		function Meta:DisableMatrix(Str)
			if self.OriginalSize and Str == "RenderMultiply" then
				local Mat = Matrix()

				local Size  = self.OriginalSize
				local Scale = Vector(1 / Size.x, 1 / Size.y, 1 / Size.z) * self.Size

				Mat:Scale(Scale)

				self:EnableMatrix("RenderMultiply", Mat)

				return
			end

			DisMatr(self, Str)
		end
	end

	hook.Remove("Initialize", "Scalable Entities")
end)