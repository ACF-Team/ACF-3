local ACF         = ACF
local Mobility    = ACF.Mobility
local Fuel        = Mobility.Fuel
local IsValid     = IsValid

--===============================================================================================--
-- CFW meta 
--===============================================================================================--
function ENT:CFW_PreParentedTo(_, NewParent)
	local ParentValid = IsValid(NewParent) and NewParent:GetClass() == "acf_baseplate"
	self.ACF_EngineParentValid = ParentValid
end

function ENT:CFW_OnParentedTo()
	Fuel.Join(self)
	self:UpdateOverlay()
end

hook.Add("cfw.contraption.entityAdded", "ACF_Engine_ContraptionChecks", function(Contraption, Ent)
	if Ent:GetClass() == "acf_engine" then
		if Contraption.Engines then
			Contraption.Engines[Ent] = true
		else
			Contraption.Engines = {[Ent] = true}
		end

		Contraption.HasEngines   = true
		Contraption.TotalEngines = (Contraption.TotalEngines or 0) + 1
	end
end)

hook.Add("cfw.contraption.entityRemoved", "ACF_Engine_ContraptionChecks", function(Contraption, Ent)
	if Ent:GetClass() == "acf_engine" then
		if Contraption.Engines then
			Contraption.Engines[Ent] = nil
		end

		Contraption.HasEngines   = next(Contraption.Engines) and true or nil
		Contraption.TotalEngines = Contraption.HasEngines and 0 or table.Count(Contraption.Engines)
	end
end)
