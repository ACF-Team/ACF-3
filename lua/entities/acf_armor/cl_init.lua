include("shared.lua")

DEFINE_BASECLASS("acf_base_scalable")

local Armors = ACF.Classes.ArmorTypes

function ENT:Initialize()
    self.ClassData = self:GetNWString("Class", "RHA")
    self:SetNWVarProxy("Class", function(Ent, _, _, Val)
        Ent.Class = Armors[Val]
    end)

    BaseClass.Initialize(self)
end