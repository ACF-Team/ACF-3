local ACF     = ACF
local Clock   = ACF.Utilities.Clock
local Lights  = GetConVar("acf_missiles_missilelights")
local Default = Color(255, 128, 48)

local function CanEmitLight(Size)
	local MinSize = Lights:GetFloat()

	if MinSize == 0 then return false end
	if MinSize == 1 then return true end

	return MinSize < Size
end

function ACF.RenderLight(Index, Size, LightColor, Position)
	if not CanEmitLight(Size) then return end

	local Light = DynamicLight(Index)

	if Light then
		if not LightColor then LightColor = Default end

		Light.Pos = Position
		Light.r = LightColor.r
		Light.g = LightColor.g
		Light.b = LightColor.b
		Light.Brightness = 2 + math.random() * 1
		Light.Decay = Size * 15
		Light.Size = Size * 0.66 + math.random() * (Size * 0.33)
		Light.DieTime = Clock.CurTime + 1
	end
end
