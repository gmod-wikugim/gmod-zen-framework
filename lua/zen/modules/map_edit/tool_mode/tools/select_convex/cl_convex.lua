module("zen", package.seeall)

---@class zen_TOOL
local TOOL = {}
TOOL.id = "convex_creator"
TOOL.Name = "Convex"
TOOL.Icon = "zen/map_edit/activity_zone.png"
TOOL.Description = "Convex creator"

function TOOL:Init()
    self.iStage = "base"
    print("Init")
end

local color_r = Color(255,0,0,100)
function TOOL:Render(rendermode, priority, vw)


end

function TOOL:Reload()
    
end

function TOOL:OnButtonPress(but, in_key, bind_name, vw)
 
end

map_edit.tool_mode.Register(TOOL)