local Overlay = ACF.Overlay
do
    local ELEMENT = {}

    function ELEMENT.Render(_, Slot)
        Overlay.KeyValueRenderMode = 1
        Overlay.BasicKeyValueRender(Slot)
    end

    function ELEMENT.PostRender(_, Slot)
        Overlay.KeyValueRenderMode = 1
        Overlay.BasicKeyValuePostRender(Slot)
    end

    Overlay.DefineElementType("KeyValue", ELEMENT)
end

do
    local ELEMENT = {}

    function ELEMENT.Render(_, Slot)
        Overlay.KeyValueRenderMode = 2
        Overlay.BasicKeyValueRender(Slot)
    end

    function ELEMENT.PostRender(_, Slot)
        Overlay.KeyValueRenderMode = 2
        Overlay.BasicKeyValuePostRender(Slot)
    end

    Overlay.DefineElementType("SubKeyValue", ELEMENT)
end