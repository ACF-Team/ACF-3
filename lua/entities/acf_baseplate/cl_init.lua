include("shared.lua")

function ENT:Update() end

local HideInfo = ACF.HideInfoBubble

local ColorBlack = Color(0, 0, 0)
local ColorRed   = Color(255, 96, 87)
local ColorGreen = Color(119, 255, 92)
local ColorBlue  = Color(108, 184, 255)
local ColorOrange = Color(255, 127, 0)
local VectorZ    = Vector(0, 0, 16)
local North      = Vector(0, 1, 0)

function ENT:DrawGizmos()
    cam.IgnoreZ(true)

    local Pos = self:GetPos()
    local Size = self.Size

    render.SetColorMaterial()

    render.DrawBeam(Pos, self:LocalToWorld(Vector(Size.x / 2, 0, 0)), 1.25, 0, 1, ColorBlack)
    render.DrawBeam(Pos, self:LocalToWorld(Vector(Size.x / 2, 0, 0)), .5, 0, 1, ColorRed)

    render.DrawBeam(Pos, self:LocalToWorld(Vector(0, -Size.y / 2, 0)), 1.25, 0, 1, ColorBlack)
    render.DrawBeam(Pos, self:LocalToWorld(Vector(0, -Size.y / 2, 0)), .5, 0, 1, ColorGreen)

    render.DrawBeam(Pos, self:LocalToWorld(VectorZ), 1.25, 0, 1, ColorBlack)
    render.DrawBeam(Pos, self:LocalToWorld(VectorZ), .5, 0, 1, ColorBlue)

    local NorthPos = Pos + North * Size.x
    render.DrawBeam(Pos, NorthPos, 0.25, 0, 1, ColorOrange)

    cam.Start2D()
        local NP = NorthPos:ToScreen()
        draw.SimpleTextOutlined("NORTH", "ACF_Title", NP.x, NP.y, ColorOrange, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, ColorBlack)
    cam.End2D()

    cam.IgnoreZ(false)
end

local function Vertex(X, Y, Z, F, S, VT, U, V)
    return {
        pos = Vector(X, Y, Z),
        normal = Vector(F, S, VT),
        u = U,
        v = V
    }
end

function ENT:GetCachedMesh()
    if not self:NeedsRecache() then return self.MeshUnion end

    local CurrentMaterialPath = self:GetMaterial()
    if CurrentMaterialPath == nil or CurrentMaterialPath == "" then
        -- Try to prevent crash here with multicored shaderapidx9.
        -- CurrentMaterialPath will return "" if the material has been reset
        -- this then causes Material("") which equals nil which results in a no-op
        -- at best without mcore and a crash with mcore enabled.
        CurrentMaterialPath = "hunter/myplastic"
    end

    if not self.CachedMaterial or self.LastMaterialPath ~= CurrentMaterialPath then
        self.CachedMaterial = Material(CurrentMaterialPath)
        -- REALLY make sure we don't crash from what I said above!!!
        if self.CachedMaterial == nil then return self.MeshUnion end
        self.LastMaterialPath = CurrentMaterialPath
    end

    local NewMesh = IsValid(self.CachedMesh) and self.CachedMesh or Mesh(self.CachedMaterial)
    local Width, Length, Height = self.Size[2], self.Size[1], self.Size[3]
    local CubeSize = 36 * 2

    -- MARCH: I tried to do this with the mesh library, but it really didn't want to work.
    -- Someone else can feel free to recode this if they want and feel like throwing up, but
    -- considering this only runs once per baseplate, it's worth my sanity
    NewMesh:BuildFromTriangles {
        -- Up quad
        Vertex(-Width / 2, Length / 2, Height / 2,      0, 0, 1,    -Width / CubeSize,  Length / CubeSize),
        Vertex(Width / 2,  Length / 2, Height / 2,      0, 0, 1,     Width / CubeSize,  Length / CubeSize),
        Vertex(Width / 2, -Length / 2, Height / 2,      0, 0, 1,     Width / CubeSize, -Length / CubeSize),

        Vertex(Width / 2,  -Length / 2, Height / 2,      0, 0, 1,     Width / CubeSize, -Length / CubeSize),
        Vertex(-Width / 2, -Length / 2, Height / 2,      0, 0, 1,    -Width / CubeSize, -Length / CubeSize),
        Vertex(-Width / 2,  Length / 2, Height / 2,      0, 0, 1,    -Width / CubeSize,  Length / CubeSize),

        -- Down quad
        Vertex(Width / 2, -Length / 2, -Height / 2,      0, 0, -1,     Width / CubeSize, -Length / CubeSize),
        Vertex(Width / 2,  Length / 2, -Height / 2,      0, 0, -1,     Width / CubeSize,  Length / CubeSize),
        Vertex(-Width / 2, Length / 2, -Height / 2,      0, 0, -1,    -Width / CubeSize,  Length / CubeSize),

        Vertex(-Width / 2,  Length / 2, -Height / 2,      0, 0, -1,    -Width / CubeSize,  Length / CubeSize),
        Vertex(-Width / 2, -Length / 2, -Height / 2,      0, 0, -1,    -Width / CubeSize, -Length / CubeSize),
        Vertex(Width / 2, - Length / 2, -Height / 2,      0, 0, -1,     Width / CubeSize, -Length / CubeSize),



        -- Right quad
        Vertex(Width / 2, -Length / 2, Height / 2,      1, 0, 0,     Height / CubeSize, -Length / CubeSize),
        Vertex(Width / 2,  Length / 2, Height / 2,      1, 0, 0,     Height / CubeSize,  Length / CubeSize),
        Vertex(Width / 2, Length / 2, -Height / 2,      1, 0, 0,    -Height / CubeSize,  Length / CubeSize),

        Vertex(Width / 2,  Length / 2, -Height / 2,      1, 0, 0,    -Height / CubeSize,  Length / CubeSize),
        Vertex(Width / 2, -Length / 2, -Height / 2,      1, 0, 0,    -Height / CubeSize, -Length / CubeSize),
        Vertex(Width / 2,  -Length / 2, Height / 2,      1, 0, 0,     Height / CubeSize, -Length / CubeSize),

        -- Left quad
        Vertex(-Width / 2, Length / 2, -Height / 2,      -1, 0, 0,    -Height / CubeSize,  Length / CubeSize),
        Vertex(-Width / 2,  Length / 2, Height / 2,      -1, 0, 0,     Height / CubeSize,  Length / CubeSize),
        Vertex(-Width / 2, -Length / 2, Height / 2,      -1, 0, 0,     Height / CubeSize, -Length / CubeSize),

        Vertex(-Width / 2, -Length / 2, Height / 2,      -1, 0, 0,     Height / CubeSize, -Length / CubeSize),
        Vertex(-Width / 2, -Length / 2, -Height / 2,      -1, 0, 0,   -Height / CubeSize, -Length / CubeSize),
        Vertex(-Width / 2,  Length / 2, -Height / 2,      -1, 0, 0,   -Height / CubeSize,  Length / CubeSize),



        -- Back quad
        Vertex(Width / 2, Length / 2, -Height / 2,      0, 1, 0,    -Height / CubeSize,  Width / CubeSize),
        Vertex(Width / 2,  Length / 2, Height / 2,      0, 1, 0,     Height / CubeSize,  Width / CubeSize),
        Vertex(-Width / 2, Length / 2, Height / 2,      0, 1, 0,     Height / CubeSize, -Width / CubeSize),

        Vertex(-Width / 2,  Length / 2, Height / 2,      0, 1, 0,     Height / CubeSize, -Width / CubeSize),
        Vertex(-Width / 2, Length / 2, -Height / 2,      0, 1, 0,    -Height / CubeSize, -Width / CubeSize),
        Vertex(Width / 2,  Length / 2, -Height / 2,      0, 1, 0,    -Height / CubeSize,  Width / CubeSize),

        -- Front quad
        Vertex(-Width / 2, -Length / 2, Height / 2,      0, -1, 0,     Height / CubeSize, -Width / CubeSize),
        Vertex(Width / 2,  -Length / 2, Height / 2,      0, -1, 0,     Height / CubeSize,  Width / CubeSize),
        Vertex(Width / 2, -Length / 2, -Height / 2,      0, -1, 0,    -Height / CubeSize,  Width / CubeSize),

        Vertex(Width / 2, -Length / 2, -Height / 2,      0, -1, 0,    -Height / CubeSize,  Width / CubeSize),
        Vertex(-Width / 2, -Length / 2, -Height / 2,      0, -1, 0,   -Height / CubeSize, -Width / CubeSize),
        Vertex(-Width / 2, -Length / 2, Height / 2,      0, -1, 0,     Height / CubeSize, -Width / CubeSize),
    }

    self.CachedMesh = NewMesh


    self.MeshUnion = {Mesh = self.CachedMesh, Material = self.CachedMaterial}
    self.LastSize = self.Size
    return self.MeshUnion
end

function ENT:NeedsRecache()
    if not self.Size then return false end
    if self.LastSize ~= self.Size then return true end
    if not self.CachedMaterial then return true end
    if self.LastMaterialPath ~= self:GetMaterial() then return true end
    if not IsValid(self.CachedMesh) then return true end
    if not self.MeshUnion then return true end

    return false
end

local OneScale = Matrix()
OneScale:Identity()
OneScale:Scale(Vector(1, 1, 1))

function ENT:Draw()
    -- Partial from base_wire_entity, need the tooltip but without the model drawing since we're drawing our own
    local LocalPlayer = LocalPlayer()
    local Weapon      = LocalPlayer:GetActiveWeapon()
    local LookedAt    = self:BeingLookedAtByLocalPlayer() and not LocalPlayer:InVehicle()

    if LookedAt then
        self:DrawEntityOutline()
    end

    self:EnableMatrix("RenderMultiply", OneScale)
    self:DrawModel()

    if not LookedAt then return end
    if HideInfo() then return end

    self:AddWorldTip()

    if LocalPlayer:InVehicle() then return end
    if not IsValid(Weapon) then return end

    local class = Weapon:GetClass()
    if class ~= "weapon_physgun" and (class ~= "gmod_tool" or Weapon.current_mode ~= "acf_menu") then return end

    self:DrawGizmos()
end

function ENT:GetRenderMesh()
    return self:GetCachedMesh()
end

function ENT:OnRemove()
    if IsValid(self.CachedMesh) then
        self.CachedMesh:Destroy()
    end
end

ACF.Classes.Entities.Register()