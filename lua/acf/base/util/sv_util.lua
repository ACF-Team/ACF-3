util.AddNetworkString("ACF_ChatMessage")

function ACF.SendMessage(Player, Type, ...)
	if not ... then return end

	local Message = istable(...) and ... or { ... }

	net.Start("ACF_ChatMessage")
		net.WriteString(Type or "Normal")
		net.WriteTable(Message)
	if IsValid(Player) then
		net.Send(Player)
	else
		net.Broadcast()
	end
end

local Types = {
	Normal = {
		Prefix = "",
		Color = Color(80, 255, 80)
	},
	Info = {
		Prefix = " - Info",
		Color = Color(0, 233, 255)
	},
	Warning = {
		Prefix = " - Warning",
		Color = Color(255, 160, 0)
	},
	Error = {
		Prefix = " - Error",
		Color = Color(255, 80, 80)
	}
}

function ACF.AddLogType(Name, Prefix, TitleColor)
	if not Name then return end

	Types[Name] = {
		Prefix = Prefix and (" - " .. Prefix) or "",
		Color = TitleColor or Color(80, 255, 80),
	}
end

function ACF.PrintLog(Type, ...)
	if not ... then return end

	local Data = Types[Type] or Types.Normal
	local Prefix = "[ACF" .. Data.Prefix .. "] "
	local Message = istable(...) and ... or { ... }

	Message[#Message + 1] = "\n"

	MsgC(Data.Color, Prefix, color_white, unpack(Message))
end

function ACF_GetHitAngle(HitNormal, HitVector)
	local Ang = math.deg(math.acos(HitNormal:Dot(-HitVector:GetNormalized()))) -- Can output nan sometimes on extremely small angles

	if Ang ~= Ang then -- nan is the only value that does not equal itself
		return 0 -- return 0 instead of nan
	else
		return Ang
	end
end

do -- Serverside visclip check
	-- Compatibility with Proper Clipping tool: https://github.com/DaDamRival/proper_clipping
	-- They save the clip distance on a slightly different way so we have to do some minor changes
	local function GetDistance(Entity, Clip)
		if not ProperClipping then return Clip.d end

		return Clip.norm:Dot(Clip.norm * Clip.d - Entity:OBBCenter())
	end

	local function CheckClip(Entity, Clip, Center, Pos)
		if Clip.physical then return false end -- Physical clips will be ignored, we can't hit them anyway

		local Distance = GetDistance(Entity, Clip)
		local Normal = Entity:LocalToWorldAngles(Clip.n):Forward()
		local Origin = Center + Normal * Distance

		return Normal:Dot((Origin - Pos):GetNormalized()) > 0
	end

	function ACF.CheckClips(Ent, Pos)
		if not IsValid(Ent) then return false end
		if not Ent.ClipData then return false end -- Doesn't have clips
		if Ent:GetClass() ~= "prop_physics" then return false end -- Only care about props
		if not Ent:GetPhysicsObject():GetVolume() then return false end -- Spherical collisions applied to it

		local Center = Ent:LocalToWorld(Ent:OBBCenter())

		for _, Clip in ipairs(Ent.ClipData) do
			if CheckClip(Ent, Clip, Center, Pos) then return true end
		end

		return false
	end

	-- Backwards compatibility
	ACF_CheckClips = ACF.CheckClips
end
