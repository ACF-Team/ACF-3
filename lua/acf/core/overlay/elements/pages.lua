local Overlay = ACF.Overlay

-- Splits the slots after it into pages, PageBreak starts the next one and PageEnd closes them.
-- Data is the title, page count and header number
do
    local ELEMENT = { PageMarker = "Header" }

    local BUTTON_GAP     = 12
    local BUTTON_PADDING = 4

    -- A square button of the given size centered at X, vertically centered on a header of height H
    local function DrawArrowButton(Target, Title, Pages, Delta, Glyph, X, H, Size, GlyphH)
        local Left, Top = X - Size * 0.5, (H - Size) * 0.5
        local GlyphY    = Top + (Size - GlyphH) * 0.5
        local Font      = Overlay.BOLD_TEXT_FONT

        Overlay.DrawRect(Left, Top, Size, Size, Overlay.COLOR_SECONDARY_COLOR)
        Overlay.DrawOutlinedRect(Left, Top, Size, Size, Overlay.COLOR_PRIMARY_COLOR, 1)
        Overlay.SimpleText(Glyph, Font, X, GlyphY, Overlay.COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
        Overlay.AddPageArrow(Target, Title, Pages, Delta, Left, Top, Size, Size)
    end

    function ELEMENT.Render(Target, Slot)
        local Title     = Slot.Data[1]
        local Pages     = Slot.Data[2] or 1
        local HeaderNum = Slot.Data[3] or 1

        if Pages < 2 then
            Overlay.DrawHeaderText(Title, HeaderNum)

            return
        end

        local Page      = Overlay.GetShownPage(Target, Title, Pages)
        local _, W, H   = Overlay.DrawHeaderText(Title .. " " .. Page .. "/" .. Pages, HeaderNum)
        local _, GlyphH = Overlay.GetTextSize(Overlay.BOLD_TEXT_FONT, "<")
        local Size      = GlyphH + BUTTON_PADDING
        local Offset    = W * 0.5 + BUTTON_GAP + Size * 0.5

        DrawArrowButton(Target, Title, Pages, -1, "<", -Offset, H, Size, GlyphH)
        DrawArrowButton(Target, Title, Pages, 1, ">", Offset, H, Size, GlyphH)

        Overlay.AppendSlotSize((Offset + Size * 0.5) * 2, H)
    end

    Overlay.DefineElementType("PageHeader", ELEMENT)
end

Overlay.DefineElementType("PageBreak", { PageMarker = "Break" })
Overlay.DefineElementType("PageEnd", { PageMarker = "End" })
