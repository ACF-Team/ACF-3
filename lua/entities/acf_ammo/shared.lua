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

	-- Other kinds of rounds the crate holds and how many of each, the crate's own round fills the rest
	FIELD("ACF.Ammunition.BaseAmmo[]", 		"OverrideAmmo",      	{OnlyAllowSubtypes = true})
	FIELD("Number[]", 						"OverrideCounts",    	{Min = 0, Decimals = 0})

	function CLASS:VerifyData()
		self.Weapon:VerifyData()
		self.AmmoType:VerifyData()
	end
end, "Ammo Crate", "Ammo Crates")

-- Returns the weapon instance this crate is configured to feed.
function ENT:GetWeapon()
	return self:ACF_GetUserVar("Weapon")
end

ENT.ACF_StaticWireInputs = {
	"Load (If set to a non-zero value, it'll allow weapons to use rounds from this ammo crate.)",
}

ENT.ACF_StaticWireOutputs = {
	"Loading (Whether or not weapons can use rounds from this crate.)",
	"Ammo (Rounds left in this ammo crate.)",
	"Entity (The ammo crate itself.) [ENTITY]",
}

-- Context menu entry to set how many rounds of each other kind a crate holds
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

	Receive = function(self, _, Player)
		local Entity = net.ReadEntity()
		local Counts = {}

		for Index = 1, net.ReadUInt(ACF.ProfileBits) do
			Counts[Index] = net.ReadUInt(25)
		end

		if not properties.CanBeTargeted(Entity, Player) or not self:Filter(Entity, Player) then return end

		Entity:ACF_SetRoundCounts(Player, Counts)
	end,
})
