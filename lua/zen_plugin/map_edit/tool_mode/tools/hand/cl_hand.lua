module("zen", package.seeall)

---@class zen_TOOL
local TOOL = {}
TOOL.id = "hand"
TOOL.Name = "Hand"
TOOL.Icon = "zen/map_edit/hand.png"
TOOL.Description = "Hand"

function TOOL:Init()
end


tool.Register(TOOL)