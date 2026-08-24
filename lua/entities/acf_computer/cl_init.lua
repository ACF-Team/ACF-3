DEFINE_BASECLASS("acf_base_simple") -- Required to get the local BaseClass

include("shared.lua")

language.Add("Cleanup_acf_computer", "ACF Computers")
language.Add("Cleaned_acf_computer", "Cleaned up all ACF Computers")
language.Add("SBoxLimit__acf_computer", "You've reached the ACF Computer limit!")

local ACF        = ACF
local Classes    = ACF.Classes
local Clock      = ACF.Utilities.Clock

-- Components are V2 classes (ACF.Components.*) with no CLASS.ID; addressed by FQN suffix.
local function GetComponentClass(ID)
	local Direct = Classes.GetSubtypeByName("ACF.Components.BaseComponent", ID)
	if Direct then return Direct end

	for _, Class in ipairs(Classes.GetSubtypesAsList("ACF.Components.BaseComponent")) do
		if Classes.GetTypeName(Class):match("[^.]+$") == ID then return Class end
	end
end

function ENT:Initialize(...)
	BaseClass.Initialize(self, ...)

	self:Update()
end

function ENT:Update()
	local Id = self:GetNW2String("ID")
	local Data = GetComponentClass(Id)
	if not Data then return end

	local Class = Classes.GetBaseClass(Data)

	if self.OnLast then
		self:OnLast()
	end

	self.OnUpdate = Data.OnUpdateCL
	self.OnLast = Data.OnLastCL
	self.OnThink = Data.OnThinkCL
	self.OnDraw = Data.OnDrawCL

	if self.OnUpdate then
		self:OnUpdate(Class, Data)
	end
end

function ENT:Draw(...)
	BaseClass.Draw(self, ...)

	if self.OnDraw then
		self:OnDraw()
	end
end

function ENT:Think(...)
	self:NextThink(Clock.CurTime)

	if self.OnThink then
		self:OnThink()
	end

	BaseClass.Think(self, ...)

	return true
end
