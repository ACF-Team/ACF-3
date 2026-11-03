include("shared.lua")

DEFINE_BASECLASS("acf_base_scalable")

local ACF    = ACF
local Clock  = ACF.Utilities.Clock
local Queued = {}

do -- MARK: Client info
	net.Receive("ACF_InvalidateExtinguisherInfo", function()
		local Extinguisher = net.ReadEntity()

		if not IsValid(Extinguisher) then return end

		Extinguisher.HasData = false
	end)

	net.Receive("ACF_RequestExtinguisherInfo", function()
		local Extinguisher = net.ReadEntity()
		local Reach        = net.ReadFloat()
		local Watched      = {} -- Watched[Entity] = whether its agent would get there

		for _ = 1, net.ReadUInt(8) do
			local Ent     = Entity(net.ReadUInt(MAX_EDICT_BITS))
			local Reached = net.ReadBool()

			if IsValid(Ent) then Watched[Ent] = Reached end
		end

		if not IsValid(Extinguisher) then return end

		Extinguisher.Reach   = Reach
		Extinguisher.Watched = Watched
		Extinguisher.HasData = true
		Extinguisher.Age     = Clock.CurTime + 5

		Queued[Extinguisher] = nil
	end)

	function ENT:RequestExtinguisherInfo()
		if Queued[self] then return end

		Queued[self] = true

		timer.Simple(5, function() Queued[self] = nil end)

		net.Start("ACF_RequestExtinguisherInfo")
			net.WriteEntity(self)
		net.SendToServer()
	end
end

do -- MARK: Overlay
	local ReachColor     = Color(80, 160, 255, 120)
	local ReachedColor   = Color(80, 160, 255, 25)
	local UnreachedColor = Color(255, 60, 60, 25)

	-- How far its agent reaches, and which linked components it would put out (blue) or not (red)
	function ENT:DrawOverlay()
		local SelfTbl = self:GetTable()

		if not SelfTbl.HasData then
			self:RequestExtinguisherInfo()

			return
		elseif Clock.CurTime > SelfTbl.Age then
			self:RequestExtinguisherInfo()
		end

		render.SetColorMaterial()
		render.DrawWireframeSphere(self:WorldSpaceCenter(), SelfTbl.Reach, 24, 24, ReachColor, true)

		for E, Reached in pairs(SelfTbl.Watched) do
			if IsValid(E) then
				local Pos, Ang, Mins, Maxs = E:GetPos(), E:GetAngles(), E:OBBMins(), E:OBBMaxs()
				local BoxColor             = Reached and ReachedColor or UnreachedColor

				render.DrawWireframeBox(Pos, Ang, Mins, Maxs, BoxColor, true)
				render.DrawBox(Pos, Ang, Mins, Maxs, BoxColor)
			end
		end
	end
end
