DEFINE_BASECLASS("acf_container")

ENT.ACF_Limit = 32

ACF.Entities.AutoRegister(2026091001, function(CLASS)
	MENU_FIELD("ACF.Weapons.BaseWeapon", 	"Weapon",            	{Title = "#acf.menu.fields.acf_ammo.weapon", OnlyAllowSubtypes = true, OnlyAllowLeafTypes = true, InstantiateTypeForDefault = "ACF.Guns.Cannon"})
	MENU_FIELD("ACF.Ammunition.BaseAmmo", 	"AmmoType",          	{Title = "#acf.menu.fields.acf_ammo.ammo_type", OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Ammunition.AP"})
	MENU_FIELD("Number", 					"AmmoStage",         	{Title = "#acf.menu.fields.acf_ammo.ammo_stage", Min = ACF.AmmoStageMin or 1, Max = ACF.AmmoStageMax or 5, Default = 1, Decimals = 0})
	MENU_FIELD("Number", 					"CrateProjectilesX", 	{Title = "#acf.menu.fields.acf_ammo.crate_projectiles_x", Min = 1, Default = 3, Decimals = 0})
	MENU_FIELD("Number", 					"CrateProjectilesY", 	{Title = "#acf.menu.fields.acf_ammo.crate_projectiles_y", Min = 1, Default = 3, Decimals = 0})
	MENU_FIELD("Number", 					"CrateProjectilesZ", 	{Title = "#acf.menu.fields.acf_ammo.crate_projectiles_z", Min = 1, Default = 3, Decimals = 0})
	MENU_FIELD("Boolean", 					"HexPacking",        	{Title = "#acf.menu.fields.acf_ammo.hex_packing", Default = false})

	-- The rounds the crate holds top first and how many of each, the counts scale to fill the crate.
	-- AmmoType fills an empty list, the slots fit the biggest round of the lot
	MENU_FIELD("ACF.Ammunition.BaseAmmo[]", "Rounds",            	{Title = "#acf.menu.fields.acf_ammo.rounds", OnlyAllowSubtypes = true})
	MENU_FIELD("Number[]", 					"RoundCounts",       	{Title = "#acf.menu.fields.acf_ammo.round_counts", Min = 0, Decimals = 0})

	function CLASS:VerifyData()
		self.Weapon:VerifyData()
		self.AmmoType:VerifyData()
	end
end, "Ammo Crate", "Ammo Crates")

-- Returns the weapon instance this crate is configured to feed.
function ENT:GetWeapon()
	return self:ACF_GetUserVar("Weapon")
end

ENT.GetRoundKindColor = ACF.GetRoundKindColor

ENT.ACF_StaticWireInputs = {
	"Load (If set to a non-zero value, it'll allow weapons to use rounds from this ammo crate.)",
	"Round Select (Loads the round at this position in the crate's list, 0 cycles through all of them.)",
}

ENT.ACF_StaticWireOutputs = {
	"Loading (Whether or not weapons can use rounds from this crate.)",
	"Ammo (Rounds left in this ammo crate.)",
	"Entity (The ammo crate itself.) [ENTITY]",
}

-- Bits of the count of changes to a crate's mix
local MIX_VERSION_BITS = 16
local COUNT_BITS       = 25 -- Bits of a networked round count, above any crate's capacity

ENT.MixVersionBits = MIX_VERSION_BITS
ENT.CountBits      = COUNT_BITS
