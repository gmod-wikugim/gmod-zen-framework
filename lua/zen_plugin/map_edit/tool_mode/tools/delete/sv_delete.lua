module("zen", package.seeall)

---@class zen_TOOL
local TOOL = {}
TOOL.id = "delete"
TOOL.Name = "Delete"
TOOL.Description = "Delete entity"

function TOOL:Init()

end

function TOOL:ServerAction(data)
    local ent = data.ent
    if IsValid(ent) then
        SafeRemoveEntity(ent)
    end
end

tool.Register(TOOL)