local Presets = ACF.Presets

local Path = "acf/permissions.txt"

-- Ensure the presets file exists
local FileExists = file.Exists(Path, "DATA")
if not FileExists then
    print("[ACF] Presets file not found. Creating empty file.")
    file.Write(Path, "")
end

-- Load current presets
local PresetData = file.Read(Path, "DATA")