local ACF = ACF
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

function ACF.AddMessageType(Name, Prefix, TitleColor)
	if not Name then return end

	Types[Name] = {
		Prefix = Prefix and (" - " .. Prefix) or "",
		Color = TitleColor or Color(80, 255, 80),
	}
end

local function PrintToChat(Type, ...)
	if not ... then return end

	local Data = Types[Type] or Types.Normal
	local Prefix = "[ACF" .. Data.Prefix .. "] "
	local Message = istable(...) and ... or { ... }

	chat.AddText(Data.Color, Prefix, color_white, unpack(Message))
end

ACF.PrintToChat = PrintToChat

net.Receive("ACF_ChatMessage", function()
	local Type = net.ReadString()
	local Message = net.ReadTable()

	PrintToChat(Type, Message)
end)

surface.CreateFont("ACF_Title", {
	font = "Roboto",
	size = 23,
	weight = 1000,
})

surface.CreateFont("ACF_Subtitle", {
	font = "Roboto",
	size = 18,
	weight = 1000,
})

surface.CreateFont("ACF_Paragraph", {
	font = "Roboto",
	size = 14,
	weight = 750,
})

surface.CreateFont("ACF_Control", {
	font = "Roboto",
	size = 14,
	weight = 550,
})

do -- Clientside visclip check
	local function CheckClip(Entity, Clip, Center, Pos)
		if Clip.physics then return false end -- Physical clips will be ignored, we can't hit them anyway

		local Normal = Entity:LocalToWorldAngles(Clip.n or Clip[1]):Forward()
		local Origin = Center + Normal * (Clip.d or Clip[2])

		return Normal:Dot((Origin - Pos):GetNormalized()) > 0
	end

	function ACF.CheckClips(Ent, Pos)
		if not IsValid(Ent) then return false end
		if not Ent.ClipData then return false end -- Doesn't have clips
		if Ent:GetClass() ~= "prop_physics" then return false end -- Only care about props

		-- Compatibility with Proper Clipping tool: https://github.com/DaDamRival/proper_clipping
		-- The bounding box center will change if the entity is physically clipped
		-- That's why we'll use the original OBBCenter that was stored on the entity
		local Center = Ent:LocalToWorld(Ent.OBBCenterOrg or Ent:OBBCenter())

		for _, Clip in ipairs(Ent.ClipData) do
			if CheckClip(Ent, Clip, Center, Pos) then return true end
		end

		return false
	end
end
