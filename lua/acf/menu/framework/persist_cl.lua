local ACF    = ACF
local Folder = "acf/menu"
local Delay  = 0.5

ACF.Menu = ACF.Menu or {}

local Pending = {} -- [Context] = true while a write is queued

local function FileFor(Context)
	return Context.PersistKey .. ".json"
end

--- The version an entity class saves its data with, as stored in dupes
function ACF.Menu.GetEntityVersion(ClassName)
	local Stored = scripted_ents.GetStored(ClassName)

	return Stored and Stored.t.ACF_Version
end

--- Runs saved settings through the same compatibility patches as dupes.
--- Returns the patched settings and the class they're for now, nil if a patch failed
function ACF.Menu.PatchSaved(ClassName, Data, Version)
	local Entry = { Class = ClassName, ACF_UserData = Data, ACF_Version = Version }

	if not ProtectedCall(ACF.Entities.RunCompatPatches, ClassName, Entry) then return end
	if not istable(Entry.ACF_UserData) then return end

	return Entry.ACF_UserData, Entry.Class
end

--- Immediately writes a context's current serialized state to disk.
local function Write(Context)
	Pending[Context] = nil
	if not Context.Instance then return end

	ACF.SaveToJSON(Folder, FileFor(Context), {
		ACF_Version  = ACF.Menu.GetEntityVersion(Context.ClassName),
		ACF_UserData = Context:Serialize(),
	}, true)
end

--- Queues a debounced write for a context. Reads the context's state at fire time, so the latest
--- value in a burst is what lands on disk.
function ACF.Menu.QueuePersist(Context)
	if Pending[Context] then return end

	Pending[Context] = true

	timer.Simple(Delay, function()
		if not Pending[Context] then return end
		Write(Context)
	end)
end

--- Loads a context's saved settings from disk into its instance, if a file exists.
function ACF.Menu.LoadPersisted(Context)
	local Saved = ACF.LoadFromFile(Folder, FileFor(Context))
	if not istable(Saved) then return end

	local ClassName     = Context.ClassName
	local Data, Version = Saved.ACF_UserData, Saved.ACF_Version

	-- Saved before the menu stored a version. These are recent, so they count as current
	if not istable(Data) then
		Data, Version = Saved, ACF.Menu.GetEntityVersion(ClassName)
	end

	local Patched, NewClass = ACF.Menu.PatchSaved(ClassName, Data, Version)

	-- Settings a patch moved to another entity don't belong in this one
	if not Patched or NewClass ~= ClassName then return end

	Context:Hydrate(Patched)
end

-- ------------------------------------------------------------------------------------------------
-- Page UI state: per-page combo/type selections that aren't entity-context fields (e.g. which of a
-- page's several entity types is active). Stored together in one small file, keyed by page id, and
-- loaded once per session. Written immediately (selections are discrete, infrequent user actions).
-- ------------------------------------------------------------------------------------------------

local UIFile  = "ui.json"
local UIState -- lazy-loaded: { [PageID] = { [Key] = Value } }

local function LoadUI()
	if not UIState then UIState = ACF.LoadFromFile(Folder, UIFile) or {} end
	return UIState
end

--- Reads a saved page-UI value (or nil).
function ACF.Menu.GetUIState(PageID, Key)
	local Page = LoadUI()[PageID]
	return Page and Page[Key]
end

--- Saves a page-UI value, writing to disk only when it actually changes.
function ACF.Menu.SetUIState(PageID, Key, Value)
	local State = LoadUI()
	local Page  = State[PageID]

	if not Page then
		Page = {}
		State[PageID] = Page
	end

	if Page[Key] == Value then return end

	Page[Key] = Value
	ACF.SaveToJSON(Folder, UIFile, State, true)
end

-- ------------------------------------------------------------------------------------------------
-- Per-weapon-class ammo memory: each weapon class remembers its own last ammo type + that type's tuned
-- params, so switching weapons doesn't drag one global ammo config across all of them (e.g. Autocannon-HE
-- and Howitzer-HE keep separate settings). One file, keyed by the weapon class FQN; the value is a
-- serialized { Type, Data } ammo instance (the same shape a class field serializes to).
-- ------------------------------------------------------------------------------------------------

local AmmoWeaponFile = "ammo_by_weapon.json"
local AmmoByWeapon -- lazy-loaded: { [WeaponFQN] = { Type, Data } }

local function LoadAmmoByWeapon()
	if not AmmoByWeapon then AmmoByWeapon = ACF.LoadFromFile(Folder, AmmoWeaponFile) or {} end
	return AmmoByWeapon
end

--- Returns the saved ammo ({ Type, Data }) to use for a weapon class FQN, or nil.
function ACF.Menu.GetAmmoForWeapon(WeaponFQN)
	if not WeaponFQN then return nil end
	return LoadAmmoByWeapon()[WeaponFQN]
end

--- Saves the ammo ({ Type, Data }) to remember for a weapon class FQN.
function ACF.Menu.SetAmmoForWeapon(WeaponFQN, Data)
	if not WeaponFQN then return end

	local Store = LoadAmmoByWeapon()
	Store[WeaponFQN] = Data
	ACF.SaveToJSON(Folder, AmmoWeaponFile, Store, true)
end
