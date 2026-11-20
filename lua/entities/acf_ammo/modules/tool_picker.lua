local ACF = ACF

do
	local function GetChannel(Tool, Name)
		return math.Clamp(math.floor(Tool:GetClientNumber(Name, 255)), 0, 255)
	end

	ACF.ToolPicker.Register("colour", "acf_ammo", {
		Title = "Apply Color To",

		GetRows = function(Crate)
			local Kinds = Crate.RoundKinds

			if not Kinds then return end

			local Rows = { { Text = "Crate", Swatch = Crate:GetColor() } }

			for Index, Kind in ipairs(Kinds) do
				local Inherits = Crate:GetNW2Int("KindColor" .. ACF.GetCrateNWSuffix(Index - 1), -1) < 0

				Rows[Index + 1] = {
					Text   = Kind.Name,
					Icon   = Kind.Icon ~= "" and Kind.Icon or nil,
					Stripe = ACF.GetRoundKindColor(Index),
					Swatch = ACF.GetKindColor(Crate, Index - 1),
					Note   = Inherits and "Crate" or nil,
				}
			end

			return Rows
		end,

		LeftClick = function(Tool, Crate, Index)
			local Col = { r = GetChannel(Tool, "r"), g = GetChannel(Tool, "g"), b = GetChannel(Tool, "b") }

			return Crate:SetKindColor(Index, true, ACF.PackColor(Col))
		end,

		RightClick = function(Tool, Crate, Index)
			if not Crate.RoundKinds[Index] then return false end

			local Owner = Tool:GetOwner()
			local Col = ACF.GetKindColor(Crate, Index - 1)

			Owner:ConCommand("colour_r " .. Col.r)
			Owner:ConCommand("colour_g " .. Col.g)
			Owner:ConCommand("colour_b " .. Col.b)

			return true
		end,

		Reload = function(_, Crate, Index)
			return Crate:SetKindColor(Index, false)
		end,
	})
end
