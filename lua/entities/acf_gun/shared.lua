DEFINE_BASECLASS("acf_base_scalable")

ENT.IsACFWeapon = true

function ENT:ACF_Limit()

end

ACF.Entities.AutoRegisterV2(function()
	-- The weapon type this entity represents.
	MENU_FIELD("ACF.Guns.BaseGun", "Weapon", {OnlyAllowSubtypes = true, InstantiateTypeForDefault = "ACF.Guns.Cannon"})
	MENU_FIELD("Number", "BreechIndex", {Min = 1, Default = 1, Decimals = 0})

	function CLASS:VerifyData()
		self.Weapon:VerifyData()
	end
end, "Weapon", "Weapons")

-- Smoke/flare launchers used to be their own cleanup buckets; kept for language string lookups.
cleanup.Register("acf_smokelauncher")

ENT.ACF_StaticWireInputs = {
	"Fire (Attempts to fire the weapon.)",
	"Unload (Forces the weapon to empty itself)",
	"Reload` (Forces the weapon to reload itself.)",
}

ENT.ACF_StaticWireOutputs = {
	"Ready (Returns 1 if the weapon can be fired.)",
	"Status (Returns the current state of the weapon.) [STRING]",
	"Ammo Type (Returns the name of the currently loaded ammo type.) [STRING]",
	"Shots Left (Returns the amount of rounds left in the breech or magazine.)",
	"Total Ammo (Returns the amount of rounds available for this weapon.)",
	"Rate of Fire (Returns the amount of rounds per minute the weapon can fire.)",
	"Reload Time (Returns the amount of time in seconds it'll take to reload the weapon.)",
	"Mag Reload Time (Returns the amount of time in seconds it'll take to reload the magazine.)",
	"Projectile Mass (Returns the mass in grams of the currently loaded projectile.)",
	"Muzzle Velocity (Returns the speed in m/s of the currently loaded projectile.)",
	"In Air (Returns 1 if the GLATGM is airborne.)",
	"Entity (The weapon itself.) [ENTITY]",
}

-- Returns the weapon instance backing this entity.
function ENT:GetWeapon()
	return self:ACF_GetUserVar("Weapon")
end

-- Returns the caliber (in mm) of this weapon.
function ENT:GetCaliber()
	local Weapon = self:GetWeapon()

	return Weapon and Weapon.Caliber or self.Caliber
end
