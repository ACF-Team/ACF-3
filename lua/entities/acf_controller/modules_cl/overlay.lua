return function(_)
	function ENT:DrawOverlay()
		if self.Targets then
			for Target in pairs(self.Targets) do
				local Target = Entity(Target)
				if not IsValid(Target) then continue end
				render.DrawWireframeBox(Target:GetPos(), Target:GetAngles(), Target:OBBMins(), Target:OBBMaxs(), green, true)
			end
		end
	end
end