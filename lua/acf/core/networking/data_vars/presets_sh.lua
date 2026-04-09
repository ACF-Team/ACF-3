-- TODO: Are PresetScope and DataVarScope always going to be the same?

ACF.PresetsByScopeAndName = ACF.PresetsByScopeAndName or {} -- Maps Scope -> Name -> Preset

local BasePath = "ACF/presets/" -- Base path preset folders/files are located at

--- Creates a preset with the given information
--- @param PresetName string The name of the preset. Must be unique within the PresetScope.
--- @param PresetScope string The scope of the preset. Presets are organized by scope, and presets in the same scope share the same set of data variables.
--- @param DataVarScope string The data variable scope that this preset is associated with.
--- @param SaveUnset boolean Whether to save unset data variables using their default. Not specifying allows you to only apply changes to what you want.
function ACF.AddPreset(PresetName, PresetScope, DataVarScope, Data, TargetRealm)
	local NewPreset = {
		Name = PresetName,
		PresetScope = PresetScope,
		DataVarScope = DataVarScope,
		Data = Data,
		TargetRealm = TargetRealm,
	}

	-- If no data is provided, scrape all existing data variables in the scope
	if not Data then
		NewPreset.Data = ACF.GetDataVars(PresetScope, TargetRealm)
	end

	ACF.PresetsByScopeAndName[PresetScope] = ACF.PresetsByScopeAndName[PresetScope] or {}
	ACF.PresetsByScopeAndName[PresetScope][PresetName] = NewPreset

	return NewPreset
end

--- Removes a preset by name and scope. Also deletes the preset file from disk if it exists.
function ACF.RemovePreset(Name, Scope)
	if ACF.PresetsByScopeAndName[Scope][Name] then
		local Path = BasePath .. "/" .. Scope .. "/" .. Name .. ".txt"
		if file.Exists(Path, "DATA") then file.Delete(Path) end

		ACF.PresetsByScopeAndName[Scope][Name] = nil
		if table.IsEmpty(ACF.PresetsByScopeAndName[Scope]) then ACF.PresetsByScopeAndName[Scope] = nil end
		return true
	end

	return false
end

--- Sets all the data variables to values listed in the preset.
function ACF.ApplyPreset(Name, Scope)
	local Preset = ACF.PresetsByScopeAndName[Scope][Name]
	if not Preset then return end

	ACF.SetDataVars(Preset.Data, Preset.TargetRealm)
end

--- Saves a preset to disk. Presets are stored in garrysmod/data/ACF/presets/.
--- Used by the preset menu when saving a preset
function ACF.SavePreset(Name, Scope)
	local Preset = ACF.PresetsByScopeAndName[Scope][Name]
	if not Preset then return end

	local SubPath = BasePath .. "/" .. Scope .. "/"
	if not file.Exists(SubPath, "DATA") then file.CreateDir(SubPath) end

	local FullPath = SubPath .. Name .. ".txt"

	local SaveData = {
		Name = Preset.Name,
		PresetScope = Preset.PresetScope,
		DataVarScope = Preset.DataVarScope,
		Data = Preset.Data,
		TargetRealm = Preset.TargetRealm,
	}

	file.Write(FullPath, util.TableToJSON(SaveData, true))
end

--- Loads all presets for a specific scope from disk.
--- Used by the preset menu to populate the list of presets.
function ACF.LoadPresetsForScope(Scope)
	local ScopePath = BasePath .. Scope .. "/"
	if not file.Exists(ScopePath, "DATA") then return end

	local Files = file.Find(ScopePath .. "*.txt", "DATA")

	for _, FileName in ipairs(Files) do
		local JSON = file.Read(ScopePath .. FileName, "DATA")
		local Loaded = util.JSONToTable(JSON)
		if Loaded and Loaded.Name and Loaded.PresetScope then
			ACF.AddPreset(Loaded.Name, Loaded.PresetScope, Loaded.DataVarScope, Loaded.Data, Loaded.TargetRealm)
		end
	end
end