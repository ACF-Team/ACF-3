local Path = "acf/presets.txt"

-- Ensure the presets file exists
local FileExists = file.Exists(Path, "DATA")
if not FileExists then
    print("[ACF] Presets file not found. Creating empty file.")
    file.Write(Path, "")
end

-- Load in the file (guaranteed to exist?)
local Raw = file.Read(Path, "DATA")
local JSONTable = util.JSONToTable(Raw) or {}
ACF.Presets = JSONTable

-- Saves preset data from the Presets table into the file at Path
function ACF.SavePresets(Presets)
    local JSONString = util.TableToJSON(Presets)
    return file.Write(Path, JSONString)
end

-- Creates a new preset for the given type, name and data
-- Also usable for updating / overriding an existing preset
function ACF.UpdatePreset(Presets, PresetType, PresetName, Filter)
    Presets[PresetType] = Presets[PresetType] or {}
    Presets[PresetType][PresetName] = {}
    for _, Key in pairs(Filter) do
        Presets[PresetType][PresetName][Key] = ACF.GetClientData(Key)
    end
    ACF.SavePresets(Presets)
end

-- Removes a preset with the given type and name
function ACF.RemovePreset(Presets, PresetType, PresetName)
    Presets[PresetType] = Presets[PresetType] or {}
    Presets[PresetType][PresetName] = nil
end

-- Reads a preset with the given type and name and applies it
function ACF.ApplyPreset(Presets, PresetType, PresetName, Filter)
    Presets[PresetType] = Presets[PresetType] or {}
    local Preset = Presets[PresetType][PresetName]
    for _, Key in pairs(Filter) do
        if Preset[Key] then ACF.SetClientData(Key, Preset[Key]) end
    end
end

-- Reads and returns if a preset already exists
function ACF.HasPreset(Presets, PresetType, PresetName)
    Presets[PresetType] = Presets[PresetType] or {}
    return Presets[PresetType][PresetName] ~= nil
end