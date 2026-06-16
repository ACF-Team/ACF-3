local ACF			= ACF
local Contraption	= ACF.Contraption
local Objects		= Contraption.Objects
local CostSystem	= Contraption.CostSystem

do
	local Meta		= {}
	local String	= "Cost [Value = %.1f points]"

	---Creates a new Cost object.
	---@param	Contraption	contraption
	---@return	Cost	number	A new Cost object
	function Objects.Cost(Contraption)
		if not Contraption then ACF.DumpStack("Objects.Cost called without valid contraption") return end

		if Contraption.CostObj then return Contraption.CostObj end

		local Object	= {
			Contraption	= Contraption,
			Breakdown	= {},	--	A breakdown of the cost by class, class=cost
			Cost		= 0		--	Final calculated cost of the contraption
		}

		setmetatable(Object, Meta)

		Contraption.CostObj	= Object

		return Object
	end

	---Attempts to calculate the cost of the contraption stored in the Cost object.
	---@return Cost number Amount of points that the contraption is worth
	---@return Breakdown table A breakdown of costs of the contraption, indexed by class
	function Meta:Compute()
		if not self.Contraption then ACF.DumpStack("Attempted to compute Cost object without a contraption") return 0, {} end
		local Ctrp = self.Contraption

		local Cost		= 0
		local Breakdown	= {}
		local PostCalc	= {}

		for class, entlist in pairs(Ctrp.entsbyclass) do
			local C 			= 0
			local ClassCost		= 0
			local identifier	= CostSystem.CalcBulk[class]
			local ignore		= false

			if CostSystem.PostBulkOperations[identifier] then	-- Gather all of the entities that have post-calc costs
				if not PostCalc[identifier] then PostCalc[identifier] = {} end

				for ent in pairs(entlist) do
					if not IsValid(ent) then continue end
					table.insert(PostCalc[identifier], ent)
				end
			else
				if CostSystem.CostSingle[class] then	-- Gather all of the entities with static costs, and just add it all together
					ClassCost = (table.Count(entlist) * CostSystem.CostSingle[class])
				elseif CostSystem.BulkOperations[identifier] then	-- Gather all of the entities with specific bulk costs, and run them individually
					local op = CostSystem.BulkOperations[identifier]

					local BulkCostAmtID = "**" .. string.upper(identifier)

					for ent in pairs(entlist) do
						if not IsValid(ent) then continue end

						C = op(ent)

						local BulkCostAmt = Breakdown[BulkCostAmtID] or 0

						if C == nil then
							ACF.Utilities.Messages.PrintLog("Warning", "Nil cost for entity: " .. tostring(ent))
						else
							ClassCost = ClassCost + C
							Breakdown[BulkCostAmtID] = BulkCostAmt + C
						end
					end
				else
					for ent in pairs(entlist) do
						if not IsValid(ent) then continue end
						if not ent.GetCost then ignore = true break end

						if not CostSystem.MainFilter[class] then CostSystem.RegisterClass(class) end

						C = ent:GetCost()

						if C == nil then
							ACF.Utilities.Messages.PrintLog("Warning", "Nil cost for entity: " .. tostring(ent))
						else
							ClassCost = ClassCost + C
						end
					end
				end
			end

			Cost = Cost + ClassCost
			if not ignore then Breakdown[class] = ClassCost end
		end

		for identifier, entlist in pairs(PostCalc) do
			local op = CostSystem.PostBulkOperations[identifier]

			local C = op(entlist)

			Cost = Cost + C

			Breakdown["**" .. string.upper(identifier)] = C
		end

		self.Cost		= Cost
		self.Breakdown	= Breakdown

		return Cost, Breakdown
	end

	function Meta:ToString()
		return String:format(self.Cost)
	end

	AccessorFunc(Meta, "Cost", "Cost", FORCE_NUMBER)

	Meta.__index	= Meta
	Meta.__tostring	= Meta.ToString
end