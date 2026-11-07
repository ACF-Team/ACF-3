DEFINE_BASECLASS("acf_container")

ENT.ACF_Limit = 32

ACF.Entities.AutoRegister(2026091001, function(CLASS)
	MENU_FIELD("ACF.Weapons.BaseWeapon", 	"Weapon",            	{OnlyAllowSubtypes = true, OnlyAllowLeafTypes = true, InstantiateTypeForDefault = "ACF.Guns.Cannon"})
	MENU_FIELD("ACF.Ammunition.BaseAmmo", 	"AmmoType",          	{OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Ammunition.AP"})
	MENU_FIELD("Number", 					"AmmoStage",         	{Min = ACF.AmmoStageMin or 1, Max = ACF.AmmoStageMax or 5, Default = 1, Decimals = 0})
	MENU_FIELD("Number", 					"CrateProjectilesX", 	{Min = 1, Default = 3, Decimals = 0})
	MENU_FIELD("Number", 					"CrateProjectilesY", 	{Min = 1, Default = 3, Decimals = 0})
	MENU_FIELD("Number", 					"CrateProjectilesZ", 	{Min = 1, Default = 3, Decimals = 0})
	MENU_FIELD("Boolean", 					"HexPacking",        	{Default = false})

	-- The rounds the crate holds top first and how many of each. AmmoType sizes the slots and fills an empty list
	FIELD("ACF.Ammunition.BaseAmmo[]", 		"Rounds",            	{OnlyAllowSubtypes = true})
	FIELD("Number[]", 						"RoundCounts",       	{Min = 0, Decimals = 0})

	function CLASS:VerifyData()
		self.Weapon:VerifyData()
		self.AmmoType:VerifyData()
	end
end, "Ammo Crate", "Ammo Crates")

-- Returns the weapon instance this crate is configured to feed.
function ENT:GetWeapon()
	return self:ACF_GetUserVar("Weapon")
end

do -- MARK: Round kind colors
	local KindColors = {}

	--- Color a kind of round is shown in, by its position in the crate's list
	function ENT.GetRoundKindColor(Index)
		local KindColor = KindColors[Index]

		if not KindColor then
			KindColor = HSVToColor(((Index - 1) * 72 + 120) % 360, 0.6, 0.9)
			KindColors[Index] = KindColor
		end

		return KindColor
	end
end

ENT.ACF_StaticWireInputs = {
	"Load (If set to a non-zero value, it'll allow weapons to use rounds from this ammo crate.)",
	"Ammo Type (Loads the ammo type at this position in the crate's list.)",
}

ENT.ACF_StaticWireOutputs = {
	"Loading (Whether or not weapons can use rounds from this crate.)",
	"Ammo (Rounds left in this ammo crate.)",
	"Entity (The ammo crate itself.) [ENTITY]",
}

-- Bits of the count of changes to a crate's mix, so edits made against an older mix are refused
local MIX_VERSION_BITS = 16
local COUNT_BITS       = 25 -- Bits of a networked round count, above any crate's capacity

ENT.MixVersionBits = MIX_VERSION_BITS
ENT.CountBits      = COUNT_BITS

-- Context menu entry to order a crate's kinds of rounds and set how many of each it holds
properties.Add("acf_ammo_counts", {
	MenuLabel = "Edit Round Counts",
	Order     = 2000,
	MenuIcon  = "icon16/table_edit.png",

	Filter = function(_, Entity, Player)
		if not IsValid(Entity) or Entity:GetClass() ~= "acf_ammo" or #(Entity.RoundKinds or {}) < 2 then return false end

		return gamemode.Call("CanProperty", Player, "acf_ammo_counts", Entity)
	end,

	Action = function(self, Entity)
		Entity:OpenRoundCounts(self)
	end,

	--- Sends an edit made against mix Version: Order lists kind indices top first, Counts their counts
	SendCounts = function(self, Entity, Version, Order, Counts)
		self:MsgStart()
			net.WriteEntity(Entity)
			net.WriteUInt(Version, MIX_VERSION_BITS)
			net.WriteUInt(#Order - 1, ACF.ProfileBits)

			for Position, Index in ipairs(Order) do
				net.WriteUInt(Index - 1, ACF.ProfileBits)
				net.WriteUInt(Counts[Position], COUNT_BITS)
			end
		self:MsgEnd()
	end,

	Receive = function(self, _, Player)
		local Entity        = net.ReadEntity()
		local Version       = net.ReadUInt(MIX_VERSION_BITS)
		local Order, Counts = {}, {}

		for Position = 1, net.ReadUInt(ACF.ProfileBits) + 1 do
			Order[Position]  = net.ReadUInt(ACF.ProfileBits) + 1
			Counts[Position] = net.ReadUInt(COUNT_BITS)
		end

		if not properties.CanBeTargeted(Entity, Player) or not self:Filter(Entity, Player) then return end

		if Version ~= Entity.RoundMixVersion then
			ACF.Utilities.Messages.SendChat(Player, "Error", "The crate's rounds changed while the window was open, reopen it.")

			return
		end

		Entity:ACF_SetRoundCounts(Player, Order, Counts)
	end,
})
