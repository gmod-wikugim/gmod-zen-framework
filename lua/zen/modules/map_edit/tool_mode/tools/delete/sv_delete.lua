module("zen", package.seeall)

local ui, gui, map_edit = zen.Init("ui", "gui", "map_edit")

---@class zen_TOOL
local TOOL = {}
TOOL.id = "delete"
TOOL.name = "Delete"
TOOL.Description = "Delete entity"

function TOOL:Init()

end

function TOOL:ServerAction(data)
    local ent = data.ent
    if IsValid(ent) then
        SafeRemoveEntity(ent)
    end
end