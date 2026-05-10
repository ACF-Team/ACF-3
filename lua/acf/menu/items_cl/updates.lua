local Orange = Color(255, 93, 50)
local Green = Color(0, 150, 0)
local Red = Color(150, 0, 0)

local function DrawGitCommit(Menu, Commit)
	local Base = Menu:AddCollapsible("Latest Commit (Server Branch)", false, "icon16/clock.png")
	if not Commit then
		Base:AddLabel("Failed to retrieve commit info from GitHub")
		return
	end

	Base:AddLabel(Commit.title)
	Base:AddLabel("Message: " .. Commit.body)
	Base:AddLabel("Author: " .. Commit.author)
	Base:AddLabel("Date: " .. os.date("%Y-%m-%d %H:%M:%S", Commit.date))
	local Button = Base:AddButton("View on GitHub")
	function Button:DoClickInternal()
		gui.OpenURL(Commit.url)
	end
end

local function DrawGitStatus(Menu, Version, MostRecentCommit, _)
	local Base = Menu:AddCollapsible(Version.realm, true, Version.realm == "Server" and "icon16/Server.png" or "icon16/computer.png")
	local Status = Base:AddLabel("")
	Status:SetText("Status: Unknown (Github API call failed)")
	Status:SetTextColor(Orange)

	Base:AddLabel("Branch: " .. Version.head)
	Base:AddLabel("Commit: " .. Version.code)

	Base:SetTooltip("Click to copy version info to clipboard")
	function Base:OnMousePressed(Enum)
		if Enum ~= MOUSE_LEFT then return end
		SetClipboardText(Version.code)
	end

	-- Note, since we're using the latest commit on the server's branch, the following is possible:
	-- Server up to date with main, client out of date with dev, but dev is ahead of main.
	if MostRecentCommit then
		local Outdated = Version.date < MostRecentCommit.date
		Status:SetText("Status: " .. (Outdated and "Outdated" or "Up to Date"))
		Status:SetTextColor(Outdated and Red or Green)
	end
end

local function CreateMenu(Menu)
	for ExtensionName, ClientExtension in pairs(ACF.Extensions) do
		ServerExtension = ACF.ServerExtensions[ExtensionName]
		local Base = Menu:AddCollapsible(ExtensionName, true, "icon16/package.png")
		DrawGitCommit(Base, ServerExtension.Commit)
		DrawGitStatus(Base, ClientExtension.Version, ServerExtension.Commit, ClientExtension.Retrieved)
		DrawGitStatus(Base, ServerExtension.Version, ServerExtension.Commit, ServerExtension.Retrieved)
	end
end

ACF.AddMenuItem(1, "#acf.menu.about", "#acf.menu.updates", "newspaper", CreateMenu)