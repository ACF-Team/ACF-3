AddCSLuaFile("autorun/aaa_autoincludes.lua")

aaa_debug = false

function aaa_IncludeHere(dir)
	//print("hi from "..dir)
	local files, folders = file.Find(dir.."/*", "LUA")

	for k,v in pairs(file.Find(dir.."/*.lua", "LUA")) do
		if aaa_debug then Msg("AAA: including file \""..dir.."/"..v.."\"!\n") end
		include(dir.."/"..v)
	end
	
	for _, fdir in pairs(folders) do
		aaa_IncludeHere(dir.."/"..fdir)
	end
 
end



function aaa_IncludeClient(dir)
	
	local files, folders = file.Find(dir.."/*", "LUA")
	
	for k,v in pairs(file.Find(dir.."/*.lua", "LUA")) do
		if aaa_debug then Msg("AAA: adding client file \""..dir.."/"..v.."\"!\n") end
		AddCSLuaFile(dir.."/"..v)
	end
	
	for _, fdir in pairs(folders) do
		aaa_IncludeClient(dir.."/"..fdir)
	end
 
end



function aaa_IncludeShared(dir)
	
	local files, folders = file.Find(dir.."/*", "LUA")
	
	for k,v in pairs(file.Find(dir.."/*.lua", "LUA")) do
		if aaa_debug then Msg("AAA: adding client file \""..dir.."/"..v.."\"!\n") end
		include(dir.."/"..v)
		AddCSLuaFile(dir.."/"..v)
	end
	
	for _, fdir in pairs(folders) do
		aaa_IncludeShared(dir.."/"..fdir)
	end
 
end
