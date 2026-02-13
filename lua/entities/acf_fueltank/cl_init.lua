local ACF		= ACF
local Clock		= ACF.Utilities.Clock
local Queued	= {}

include("shared.lua")

do	-- NET SURFER 2.0
	net.Receive("ACF_InvalidateFuelTankInfo", function()
		local FuelTank = net.ReadEntity()
		if not IsValid(FuelTank) then return end

		FuelTank.HasData	= false
	end)

	net.Receive("ACF_RequestFuelTankInfo", function()
		local FuelTank		= net.ReadEntity()
		local Engines		= {}
		local EnginesLen	= net.ReadUInt(6)

		if EnginesLen > 0 then
			for I = 1, EnginesLen do
				Engines[I] = net.ReadUInt(MAX_EDICT_BITS)
			end
		end

		local ValidEngines	= {}

		for _, E in ipairs(Engines) do
			local Ent = Entity(E)

			if IsValid(Ent) then
				ValidEngines[#ValidEngines + 1] = {Ent = Ent}
			end
		end

		FuelTank.Engines	= ValidEngines
		FuelTank.HasData	= true
		FuelTank.Age		= Clock.CurTime + 5

		Queued[FuelTank]	= nil
	end)

	function ENT:RequestFuelTankInfo()
		if Queued[self] then return end

		Queued[self]	= true

		timer.Simple(5, function() Queued[self] = nil end)

		net.Start("ACF_RequestFuelTankInfo")
			net.WriteEntity(self)
		net.SendToServer()
	end
end

do	-- Overlay
	local EngineColor = Color(255, 255, 0, 25)

	function ENT:DrawOverlay()
		local SelfTbl = self:GetTable()

		if not SelfTbl.HasData then
			self:RequestFuelTankInfo()
			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestFuelTankInfo()
		end

		render.SetColorMaterial()

		if next(SelfTbl.Engines) then
			for _, T in ipairs(SelfTbl.Engines) do
				local E = T.Ent

				if IsValid(E) then
					local Pos, Ang, Mins, Maxs = E:GetPos(), E:GetAngles(), E:OBBMins(), E:OBBMaxs()

					render.DrawWireframeBox(Pos, Ang, Mins, Maxs, EngineColor, true)
					render.DrawBox(Pos, Ang, Mins, Maxs, EngineColor)
				end
			end
		end
	end
end