module("zen", package.seeall)

local ui, gui, map_edit = zen.Init("ui", "gui", "map_edit")

---@class zen_TOOL
local TOOL = {}
TOOL.id = "delete"
TOOL.Name = "Delete"
TOOL.Icon = "zen/map_edit/delete.png"
TOOL.Description = "Delete entity"

function TOOL:Init()
    
end

local color_r = Color(255,0,0,100)
function TOOL:HUDDraw()
    local tr = map_edit.GetViewTrace()
    local ent = tr.Entity

    if IsValid(ent) then
        local model = ent:GetModel()

        if util.IsValidModel(model) and !IsUselessModel(model) then
            local mins, maxs = ent:OBBMins(), ent:OBBMaxs()
            local pos = ent:GetPos()
            local ang = ent:GetAngles()
            render.DrawBox(pos, ang, mins, maxs, color_r)
        end
    end
end

function TOOL:LeftClick()
    print("OnLeftClick")
    local tr = map_edit.GetViewTrace()
    local ent = tr.Entity

    if IsValid(ent) then
        self:CallServerAction({ent=ent})
    end
end

map_edit.tool_mode.Register(TOOL)