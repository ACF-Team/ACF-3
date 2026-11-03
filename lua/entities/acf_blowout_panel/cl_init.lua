include("shared.lua")

DEFINE_BASECLASS("acf_base_scalable")

local ACF        = ACF
local Damage     = ACF.Damage
local MeshMat    = Material("hunter/myplastic")
local GhostColor = Color(255, 190, 90)

-- Both windings, so the faces show from either side whatever order the corners come in
local function AddQuad(Tris, A, B, C, D, Normal)
	for _, Tri in ipairs({ { A, B, C }, { A, C, D }, { C, B, A }, { D, C, A } }) do
		for _, Pos in ipairs(Tri) do
			Tris[#Tris + 1] = { pos = Pos, normal = Normal, u = 0, v = 0 }
		end
	end
end

-- The panel's own box, as debris otherwise takes on the unscaled model
local function GetBoxMesh(Mins, Maxs)
	local Tris = {}

	for Axis = 1, 3 do
		local U, V = Axis % 3 + 1, (Axis + 1) % 3 + 1

		for _, Side in ipairs({ Mins, Maxs }) do
			local Normal = Vector()

			Normal[Axis] = Side == Maxs and 1 or -1

			local Corners = {}

			for I, Pick in ipairs({ { Mins, Mins }, { Maxs, Mins }, { Maxs, Maxs }, { Mins, Maxs } }) do
				local Corner = Vector()

				Corner[Axis] = Side[Axis]
				Corner[U]    = Pick[1][U]
				Corner[V]    = Pick[2][V]

				Corners[I] = Corner
			end

			AddQuad(Tris, Corners[1], Corners[2], Corners[3], Corners[4], Normal)
		end
	end

	return { Tris = Tris, Material = MeshMat, Mins = Mins, Maxs = Maxs }
end

net.Receive("ACF_BlowoutPanel_Debris", function()
	local Panel    = net.ReadEntity()
	local Velocity = net.ReadVector()

	if not IsValid(Panel) then return end

	local Color  = (Panel:GetColor():ToVector() * math.Rand(0.3, 0.6)):ToColor() -- Scorched like other debris
	local Half   = Panel:GetSize() * 0.5
	local Debris = Damage.CreateDebris(Panel:GetModel(), Panel:GetPos(), Panel:GetAngles(), Panel:GetMaterial(), Color, Velocity:GetNormalized(), 0, false, true, GetBoxMesh(-Half, Half))
	local Phys   = IsValid(Debris) and Debris:GetPhysicsObject()

	if not IsValid(Phys) then return end

	-- Set outright rather than pushed, as a push barely moves a large plate
	Phys:Wake()
	Phys:SetVelocity(Velocity)
	Phys:AddAngleVelocity(VectorRand() * 180)
end)

function ENT:Draw(...)
	if not self:IsBlownOut() then return BaseClass.Draw(self, ...) end

	-- Blown off, only shown to someone holding the torch so they can find where to refit it
	local Weapon = LocalPlayer():GetActiveWeapon()

	if not IsValid(Weapon) or Weapon:GetClass() ~= "acf_torch" then return end

	local Half = self:GetSize() * 0.5

	render.DrawWireframeBox(self:GetPos(), self:GetAngles(), -Half, Half, GhostColor, true)
end
