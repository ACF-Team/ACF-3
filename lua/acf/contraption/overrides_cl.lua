hook.Add("OnEntityCreated", "ACF Stub Exploitables",function(Entity)
	timer.Simple(1,function()
		if not IsValid(Entity) then return end
		if not Entity.IsACFEntity then return end

		Entity.RenderOverride = nil
	end)
end)