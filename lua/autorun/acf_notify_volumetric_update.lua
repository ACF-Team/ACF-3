if SERVER then return end

local COOKIE_NAME = "acf_notice_volumetric_update_dontshowagain"

local STYLE = [[
	body { margin: 12px 16px; background: #2b2b2b; color: #dcdcdc; font-family: Arial, sans-serif; font-size: 15px; line-height: 1.4; }
	p { margin: 0 0 12px; }
	ul { margin: 0 0 12px; padding-left: 24px; }
	b { color: #ffc85a; }
	a { color: #64aaff; }
]]

local TITLE       = "ACF - Volumetric Update"
local DESCRIPTION = [=[
<p>The ACF Volumetric Update was recently merged into main. With it comes changes to armor, some other mechanics and some new entities.</p>
<p>Right clicking a baseplate with the "ACF Volumetrize Dupe" tool will convert entities into primitives and scale them to have the appropriate thickness to match their previous armor values.</p>
<p>We strongly recommend you use the following addons to make building easier:</p>
<ul>
	<li><a href="https://steamcommunity.com/sharedfiles/filedetails/?id=3769415877">Improved Clipping</a>
		<ul><li>It will load clips from other addons such as <a href="https://steamcommunity.com/sharedfiles/filedetails/?id=2256491552">Proper Clipping</a> and vice versa. <b>They should not be installed at the same time.</b></li></ul></li>
	<li><a href="https://steamcommunity.com/sharedfiles/filedetails/?id=2840295308">Precision alignment retooled</a>
		<ul><li><b>Replaces <a href="https://steamcommunity.com/sharedfiles/filedetails/?id=457478322">Precision Alignment</a></b></li></ul></li>
	<li><a href="https://steamcommunity.com/sharedfiles/filedetails/?id=2840295308">Primitives</a>
		<ul><li>Help with building volumetric armor, since they can be scaled.</li></ul></li>
	<li><a href="https://steamcommunity.com/workshop/filedetails/?id=3404950276">Ponder</a>
		<ul><li>In game tutorial system addon that ACF has tutorials for. May help explain some things.</li></ul></li>
</ul>
<p>That being said, if things do break, please make a <a href="https://github.com/ACF-Team/ACF-3/issues">GitHub issue</a> (ideally,) or if you don't have GitHub, talk to us in the <a href="https://discord.com/invite/jf4cwarPUG">issues-and-suggestions channel of the acf discord</a>.</p>
<p>Extra links:</p>
<ul>
	<li><a href="https://www.youtube.com/watch?v=21tsN1_Zb7I">Update video</a></li>
	<li><a href="https://www.youtube.com/watch?v=F0xmVNCfILk">Volumetric tank building tutorial</a></li>
	<li><a href="https://github.com/ACF-Team/ACF-3/pull/707">Full list of changes</a></li>
</ul>
]=]

local function ShowNotice()
	if cookie.GetString(COOKIE_NAME, "false") == "true" then return end

	local Frame = vgui.Create("DFrame")
	Frame:SetTitle(TITLE)
	Frame:SetSize(math.max(ScrW() / 2, 600), math.max(ScrH() * 0.65, 450))
	Frame:Center()
	Frame:MakePopup()
	Frame:SetSizable(false)

	local CloseButton = vgui.Create("DButton", Frame)
	CloseButton:SetText("Close")
	CloseButton:SetTall(25)
	CloseButton:DockMargin(4, 4, 4, 4)
	CloseButton:Dock(BOTTOM)

	local HTML = vgui.Create("DHTML", Frame)
	HTML:DockMargin(8, 8, 8, 8)
	HTML:Dock(FILL)
	HTML:AddFunction("acf", "open", gui.OpenURL)

	-- Opens links in the overlay browser instead of navigating the page
	local Script = [[document.addEventListener("click", function(e) {
		var a = e.target.closest("a");
		if (!a) return;
		e.preventDefault();
		acf.open(a.href);
	});]]

	HTML:SetHTML("<style>" .. STYLE .. "</style>" .. DESCRIPTION .. "<script>" .. Script .. "</script>")

	-- Any way of closing the window counts as seen
	function Frame:OnClose()
		cookie.Set(COOKIE_NAME, "true")
	end

	function CloseButton:DoClick()
		Frame:Close()
	end
end

hook.Add("InitPostEntity", "ACF_ShowVolumetricUpdateNotice", ShowNotice)
