local function DrawGitCommit(Menu, Commit)
	local Base = Menu:AddCollapsible("Latest Commit", false)
	Base:AddLabel(Commit.title)
	Base:AddLabel("Message: " .. Commit.body)
	Base:AddLabel("Author: " .. Commit.author)
	Base:AddLabel("Date: " .. os.date("%Y-%m-%d %H:%M:%S", Commit.date))
	local Button = Base:AddButton("View on GitHub")
	function Button:DoClickInternal()
		gui.OpenURL(Commit.url)
	end
end

local function DrawGitStatus(Menu, Name, Version, MostRecentCommit, _)
	local Base = Menu:AddCollapsible("[" .. Name .. "] - " .. Version.realm .. "", true, Version.realm == "Server" and "icon16/Server.png" or "icon16/computer.png")
	local Status = Base:AddLabel("")
	Status:SetText("Status: Unknown (Github API call failed)")
	Status:SetTextColor(Color(255, 255, 100))

	Base:AddLabel("Branch: " .. Version.head)
	Base:AddLabel("Commit: " .. Version.code)

	Base:SetTooltip("Click to copy version info to clipboard")
	function Base:OnMousePressed(Enum)
		if Enum ~= MOUSE_LEFT then return end
		SetClipboardText(Version.code)
	end

	if MostRecentCommit then
		local Outdated = Version.date < MostRecentCommit.date
		Status:SetText("Status: " .. (Outdated and "Outdated" or "Up to Date"))
		Status:SetTextColor(Outdated and Color(255, 100, 100) or Color(100, 255, 100))
		DrawGitCommit(Base, MostRecentCommit)
	end
end

local function CreateMenu(Menu)
	for ExtensionName, ClientExtension in pairs(ACF.Extensions) do
		ServerExtension = ACF.ServerExtensions[ExtensionName]
		DrawGitStatus(Menu, ExtensionName, ClientExtension.Version, ClientExtension.Commit, ClientExtension.Retrieved)
		DrawGitStatus(Menu, ExtensionName, ServerExtension.Version, ServerExtension.Commit, ServerExtension.Retrieved)
	end
end

ACF.AddMenuItem(2, "Updates", "icon16/newspaper.png", CreateMenu, "About", true)