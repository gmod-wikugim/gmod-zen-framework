module("zen", package.seeall)

--- 

---@class (strict) zen.map_edit_mod.essentials: zen.map_edit_mod
local MOD = map_edit_mods.Register("essentials", {
    name = "Essentials",
    version = "1.0",
})




--- Called when menu should be initialized
---@param workspaceUpper zen.panel.zpanelbase
---@param workspaceContent zen.panel.zpanelbase
function MOD:Start(workspaceUpper, workspaceContent)
    self.workspaceUpper = workspaceUpper
    self.workspaceContent = workspaceContent

    function workspaceContent:PaintOnce(w, h)
        draw.BoxRounded(5, 0, 0, w, h, "161616")
    end
    workspaceContent:CalcPaintOnce_Internal()


    local pnlCommandsList = gui.Create("zpanelbase", workspaceContent, {dock = FILL})
    pnlCommandsList:SetLayoutScheme(false, 20)

    for k = 1, 100 do
        local pnlExample = gui.Create("zlabel", pnlCommandsList)
        pnlExample:SetFont(ui.ffont("20:Roboto"))
        pnlExample:SetText(k)
    end

    hook.Run("zen_map_edit.mod.essentials.ModStart", MOD)

    for k, BUT in pairs(self.mt_Buttons) do
        local pnlButton = gui.Create("zlabel", pnlCommandsList)
        pnlButton:SetText(BUT.id)

        function pnlButton:DoClick()
            BUT.bActivated = !BUT.bActivated

            if BUT.bActivated then
                BUT.onActivate()
                self:SetEnabled(true)
            else
                BUT.onDeactivate()
                self:SetEnabled(false)
            end
        end
    end
end

---@param button_id string
---@param onActivate function
---@param onDeactivate function
function MOD:AddButtonState(button_id, onActivate, onDeactivate)
    self.mt_Buttons = self.mt_Buttons or {}

    self.mt_Buttons[button_id] = {
        id = button_id,
        onActivate = onActivate,
        onDeactivate = onDeactivate,
        bActivated = false
    }
end

function MOD:SearchFile()
end

MOD:SearchFile()

function MOD:CreateFileBrowser()


end



MOD:AddButtonState("print_hello_world", function()
    print("Hello world!")
end,
function()
    print("Good bay, world!")
end)