DEFINE_BASECLASS("acf_container")

ENT.ACF_Limit = 32

ACF.AutoRegisterV2(function()
	-- These bridge the (still legacy) grouped round/weaponry pipeline: Weapon is a weapon group ID,
	-- AmmoType an ammo-type ID, both validated against the legacy classes in ACF_OnVerifyClientData.
	MENU_FIELD("String", "Weapon",            {Default = "C"})
	MENU_FIELD("Number", "Caliber",           {Default = 50}) -- Bounds are weapon-dependent; clamped in verify.
	MENU_FIELD("String", "AmmoType",          {Default = "AP"})
	MENU_FIELD("Number", "AmmoStage",         {Min = ACF.AmmoStageMin or 1, Max = ACF.AmmoStageMax or 5, Default = 1, Decimals = 0})
	MENU_FIELD("Number", "CrateProjectilesX", {Min = 1, Default = 3, Decimals = 0})
	MENU_FIELD("Number", "CrateProjectilesY", {Min = 1, Default = 3, Decimals = 0})
	MENU_FIELD("Number", "CrateProjectilesZ", {Min = 1, Default = 3, Decimals = 0})
	-- Shape + Size are inherited from acf_container. Size is derived from the projectile counts.
end, "Ammo Crate", "Ammo Crates")

ENT.ACF_StaticWireInputs = {
	"Load (If set to a non-zero value, it'll allow weapons to use rounds from this ammo crate.)",
}

ENT.ACF_StaticWireOutputs = {
	"Loading (Whether or not weapons can use rounds from this crate.)",
	"Ammo (Rounds left in this ammo crate.)",
	"Entity (The ammo crate itself.) [ENTITY]",
}
