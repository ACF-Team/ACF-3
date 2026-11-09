local Overlay = ACF.Overlay

local SECTION_SLOTS = 4 -- Data values per section

do -- MARK: Segment bar drawing
    local SECTION_GAP   = 2
    local NUMBER_GAP    = 2
    local ICON_PADDING  = 6

    local FakeScanlines = Material("vgui/gradient_down")
    local Icons         = {}
    local DimColors     = setmetatable({}, {__mode = "k"}) -- Section colors stay the same tables until they change
    local ScanColors    = setmetatable({}, {__mode = "k"})

    local function GetIcon(Path)
        local Icon = Icons[Path]

        if not Icon then
            Icon = Material(Path, "smooth mips")
            Icons[Path] = Icon
        end

        return Icon
    end

    local function GetShade(Cache, Base, Brightness)
        local Shade = Cache[Base]

        if not Shade then
            Shade = Base:Copy()
            Shade:SetBrightness(Brightness)
            Cache[Base] = Shade
        end

        return Shade
    end

    --- Draws straight to the screen with the drawing functions of ACF.Overlay, for panels
    Overlay.SurfacePainter = {
        DrawRect = function(X, Y, W, H, Color)
            surface.SetDrawColor(Color)
            surface.DrawRect(X, Y, W, H)
        end,
        DrawOutlinedRect = function(X, Y, W, H, Color, Thickness)
            surface.SetDrawColor(Color)
            surface.DrawOutlinedRect(X, Y, W, H, Thickness or 1)
        end,
        DrawTexturedRect = function(X, Y, W, H, Color)
            surface.SetDrawColor(Color)
            surface.DrawTexturedRect(X, Y, W, H)
        end,
        DrawTexturedRectUV = function(X, Y, W, H, SU, SV, EU, EV, Color)
            surface.SetDrawColor(Color)
            surface.DrawTexturedRectUV(X, Y, W, H, SU, SV, EU, EV)
        end,
        GetTextSize = function(Font, Text)
            surface.SetFont(Font)

            return surface.GetTextSize(Text)
        end,
        SetMaterial = function(Mat) surface.SetMaterial(Mat) end, -- The server has no surface library
        NoTexture   = function() draw.NoTexture() end,
        SimpleText  = function(...) return draw.SimpleText(...) end,
    }

    --- Draws a bar split into sections in order with Painter, ACF.Overlay itself or Overlay.SurfacePainter.
    --- Data holds the sections from index First on, 4 values each: icon path ("" for none), count, size, color.
    --- Each section takes its size's share of Total and fills by its count, which is written under the bar.
    function Overlay.DrawSegmentBar(Painter, X, Y, W, H, Total, Data, First, Sections, NumberFont, NumberColor)
        if Total > 0 then
            local IconSize = H - ICON_PADDING
            local Start    = 0
            local Now      = RealTime() % 1

            for Section = 1, Sections do
                local Base         = First + (Section - 1) * SECTION_SLOTS
                local Icon         = Data[Base]
                local Count        = Data[Base + 1]
                local Size         = Data[Base + 2]
                local SectionColor = Data[Base + 3]
                local Left         = X + W * Start / Total

                Start = Start + Size

                -- The gap after each section but the last is its divider
                local Width  = X + W * Start / Total - Left - (Section < Sections and SECTION_GAP or 0)
                local Fill   = Width * math.Clamp(Size > 0 and Count / Size or 0, 0, 1)
                local Middle = Left + Width * 0.5
                local Number = tostring(Count)
                local IconX  = Middle - IconSize * 0.5
                local IconY  = Y + (H - IconSize) * 0.5
                local Scan   = GetShade(ScanColors, SectionColor, 0.8)

                Painter.DrawRect(Left, Y, Width, H, GetShade(DimColors, SectionColor, 0.3))
                Painter.DrawRect(Left, Y, Fill, H, SectionColor)
                Painter.SetMaterial(FakeScanlines)
                Painter.DrawTexturedRectUV(Left, Y, Fill, H, 0, Now, 0, Now + 8, Scan)

                if Icon ~= "" and Width >= IconSize + 4 then
                    Painter.SetMaterial(GetIcon(Icon))
                    Painter.DrawTexturedRect(IconX, IconY, IconSize, IconSize, color_white)
                end

                Painter.NoTexture()

                if Painter.GetTextSize(NumberFont, Number) + 4 <= Width then
                    local NumberY = Y + H + NUMBER_GAP

                    Painter.SimpleText(Number, NumberFont, Middle, NumberY, NumberColor, TEXT_ALIGN_CENTER)
                end
            end
        end

        Painter.DrawOutlinedRect(X, Y, W, H, Overlay.COLOR_SECONDARY_COLOR, 2)
    end

    --- Height of a segment bar of height H with its counts under it
    function Overlay.GetSegmentBarHeight(Painter, H, NumberFont)
        local _, NumberH = Painter.GetTextSize(NumberFont, "0")

        return H + NUMBER_GAP + NumberH
    end
end

-- A bar across the overlay drawn by Overlay.DrawSegmentBar, with its label centered above it.
-- Data slots are as follows:
--   [1]: Label
--   [2]: Total the section sizes add up to
--   [3]: Help shown under the bar while the overlay help is open, "" for none
--   Then the sections, 4 slots each as Overlay.DrawSegmentBar takes them
do -- MARK: Segment bar element
    local ELEMENT = {}

    local SECTION_DATA  = 3 -- Slots before the first section
    local LABEL_GAP     = 2
    local BAR_HEIGHT    = 30
    local MIN_BAR_WIDTH = 320
    local BAR_MARGIN    = 20 -- From each side of the overlay

    -- Top of the bar, its height and the total height of label, bar and counts
    local function GetLayout(Label)
        local _, LabelH = Overlay.GetTextSize(Overlay.KEY_TEXT_FONT, Label)
        local BarY      = LabelH + LABEL_GAP
        local BarH      = math.Round(BAR_HEIGHT * Overlay.GetScaleMult())

        return BarY, BarH, BarY + Overlay.GetSegmentBarHeight(Overlay, BarH, Overlay.SUBVALUE_TEXT_FONT)
    end

    function ELEMENT.Render(_, Slot)
        local Label        = Slot.Data[1] .. ":"
        local LabelW       = Overlay.GetTextSize(Overlay.KEY_TEXT_FONT, Label)
        local BarW         = MIN_BAR_WIDTH * Overlay.GetScaleMult()
        local _, _, Height = GetLayout(Label)
        local Help         = Slot.Data[3]

        Overlay.AppendSlotSize(math.max(LabelW, BarW), Height)

        if Help ~= "" and Overlay.RenderInlineHelp then Overlay.RenderInlineHelp(Help, BarW, Height) end
    end

    function ELEMENT.PostRender(_, Slot)
        local TotalW     = Overlay.GetOverlaySize()
        local Label      = Slot.Data[1] .. ":"
        local BarY, BarH = GetLayout(Label)
        local W          = TotalW - BAR_MARGIN * 2
        local Sections   = math.floor((Slot.NumData - SECTION_DATA) / SECTION_SLOTS)
        local Font       = Overlay.SUBVALUE_TEXT_FONT
        local Text       = Overlay.COLOR_TEXT

        Overlay.SimpleText(Label, Overlay.KEY_TEXT_FONT, 0, 0, Text, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        Overlay.DrawSegmentBar(
            Overlay, -W * 0.5, BarY, W, BarH, Slot.Data[2], Slot.Data, SECTION_DATA + 1, Sections, Font, Text
        )
    end

    Overlay.DefineElementType("SegmentBar", ELEMENT)
end
