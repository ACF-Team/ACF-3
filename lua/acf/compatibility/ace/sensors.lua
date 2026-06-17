ACF.Classes.Entities.RegisterCompatPatch("ace_trackingradar",   -100000, function(Data) Data.Class = "acf_radar" end)
ACF.Classes.Entities.RegisterCompatPatch("ace_searchradar",     -100000, function(Data) Data.Class = "acf_radar" end)

ACF.Classes.Entities.RegisterCompatPatch("ace_rwr_dir",         -100000, function(Data) Data.Class = "acf_receiver" end)
ACF.Classes.Entities.RegisterCompatPatch("ace_rwr_sphere",      -100000, function(Data) Data.Class = "acf_receiver" end)