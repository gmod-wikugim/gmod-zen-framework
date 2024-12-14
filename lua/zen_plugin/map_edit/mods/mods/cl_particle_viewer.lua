module("zen", package.seeall)

--- 

---@class (strict) zen.map_edit_mod.particle_view: zen.map_edit_mod
local MOD = map_edit_mods.Register("particle_view", {
    name = "Particle View",
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

end

function MOD:SearchFile()
end

MOD:SearchFile()

function MOD:CreateFileBrowser()


end
