local menu = ACF.Tool:AddToolMenu("Entities/Baseplates", "icon16/shape_square.png", 0)

function menu:Build(Panel) end
function menu:Deploy()     end
function menu:Holster()    end
function menu:Render2D()   end

-- menu:Build() (def clientside, shared? probably doesnt need to be shared though)
--     Called when the tool is selected for the first time.

-- menu:Deploy() (def clientside, shared? probably doesnt need to be shared though)
--     Called when the tool is selected, auto-calls SetStage(0) before calling this

-- menu:Retract() (def clientside, shared? probably doesnt need to be shared though)
--     Called when the tool is unselected

-- Possible methods for the API?
--[[ 

menu:GetStage()
menu:SetStage(v)

menu:AddUserInput({keys...}, stage, function()

end)


ex.

menu:AddUserInput({input.IsShiftDown, MOUSE_LEFT}, 0, function()
    
end)
(which could automatically build to the instructions table too, because we could just parse the keys table and get something like...)
ACF.Tool.Information[#ACF.Tool.Information + 1] = {
    {Type = "input", Combo = {"SHIFT", "lmb"}}, 
    {Type = "text", Text = "Select an option from the spawnmenu."}
}
]]