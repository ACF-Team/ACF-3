local ACF = ACF

do
	local function GetChannel(Tool, Name)
		return math.Clamp(math.floor(Tool:GetClientNumber(Name, 255)), 0, 255)
	end

	-- Every row after the crate, a kind of round with smoke gets a second one
	local function GetTargets(Crate)
		local Targets = {}

		for Index in ipairs(Crate.RoundKinds or {}) do
			Targets[#Targets + 1] = { Index = Index, Which = "Tracer" }

			if ACF.KindHasSmokeColor(Crate, Index - 1) then
				Targets[#Targets + 1] = { Index = Index, Which = "Smoke" }
			end
		end

		return Targets
	end

	local function GetColor(Crate, Target)
		return ACF.GetKindColor(Crate, Target.Index - 1, Target.Which)
	end

	ACF.ToolPicker.Register("colour", "acf_ammo", {
		Title = "Apply Color To",

		GetRows = function(Crate)
			local Kinds = Crate.RoundKinds

			if not Kinds then return end

			local Rows = { { Text = "Crate", Swatch = Crate:GetColor() } }

			for _, Target in ipairs(GetTargets(Crate)) do
				local Kind       = Kinds[Target.Index]
				local Smoke      = Target.Which == "Smoke"
				local Col, IsOwn = GetColor(Crate, Target)
				local Text       = Kind.Name

				if Smoke or ACF.KindHasSmokeColor(Crate, Target.Index - 1) then
					Text = Text .. " " .. Target.Which
				end

				Rows[#Rows + 1] = {
					Text   = Text,
					Icon   = Kind.Icon ~= "" and Kind.Icon or nil,
					Stripe = ACF.GetRoundKindColor(Target.Index),
					Swatch = Col,
					Note   = not IsOwn and (Smoke and "Tracer" or "Crate") or nil,
				}
			end

			return Rows
		end,

		LeftClick = function(Tool, Crate, Row)
			local Target = GetTargets(Crate)[Row]

			if not Target then return false end

			local Col = { r = GetChannel(Tool, "r"), g = GetChannel(Tool, "g"), b = GetChannel(Tool, "b") }

			return Crate:SetKindColor(Target.Index, Target.Which, true, ACF.PackColor(Col))
		end,

		RightClick = function(Tool, Crate, Row)
			local Target = GetTargets(Crate)[Row]

			if not Target then return false end

			local Owner = Tool:GetOwner()
			local Col   = GetColor(Crate, Target)

			Owner:ConCommand("colour_r " .. Col.r)
			Owner:ConCommand("colour_g " .. Col.g)
			Owner:ConCommand("colour_b " .. Col.b)

			return true
		end,

		Reload = function(_, Crate, Row)
			local Target = GetTargets(Crate)[Row]

			if not Target then return false end

			return Crate:SetKindColor(Target.Index, Target.Which, false)
		end,
	})
end
