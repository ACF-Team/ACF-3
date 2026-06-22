DEFINE_BASECLASS("acf_container")

ENT.ACF_Limit = 32

ACF.AutoRegisterV2(function()
	MENU_FIELD("ACF.Weapons.BaseWeapon", 	"Weapon",            	{OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Guns.Cannon"})
	MENU_FIELD("ACF.Ammunition.BaseAmmo", 	"AmmoType",          	{OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Ammunition.AP"})
	MENU_FIELD("Number", 					"AmmoStage",         	{Min = ACF.AmmoStageMin or 1, Max = ACF.AmmoStageMax or 5, Default = 1, Decimals = 0})
	MENU_FIELD("Number", 					"CrateProjectilesX", 	{Min = 1, Default = 3, Decimals = 0})
	MENU_FIELD("Number", 					"CrateProjectilesY", 	{Min = 1, Default = 3, Decimals = 0})
	MENU_FIELD("Number", 					"CrateProjectilesZ", 	{Min = 1, Default = 3, Decimals = 0})

	function CLASS:VerifyData()
		self.Weapon:VerifyData()
		self.AmmoType:VerifyData()
	end
end, "Ammo Crate", "Ammo Crates")

ENT.ACF_StaticWireInputs = {
	"Load (If set to a non-zero value, it'll allow weapons to use rounds from this ammo crate.)",
}

ENT.ACF_StaticWireOutputs = {
	"Loading (Whether or not weapons can use rounds from this crate.)",
	"Ammo (Rounds left in this ammo crate.)",
	"Entity (The ammo crate itself.) [ENTITY]",
}
