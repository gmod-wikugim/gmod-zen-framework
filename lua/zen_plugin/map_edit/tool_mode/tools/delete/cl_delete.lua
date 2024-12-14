module("zen", package.seeall)

---@class zen_TOOL
local TOOL = {}
TOOL.id = "delete"
TOOL.Name = "Delete"
TOOL.Icon = "zen/map_edit/delete.png"
TOOL.Description = "Delete entity"

function TOOL:Init()
    
end

local color_r = Color(255,0,0,100)
function TOOL:Render(rendermode, priority, vw)
    local ent = map_edit.GetHoverEntity()

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

function TOOL:OnButtonPress(but, in_key, bind_name, vw)
    
    if bind_name == "+attack" then
        local ent = map_edit.GetHoverEntity()

        if IsValid(ent) then
            self:CallServerAction({ent=ent})
        end
    end
 
end

tool.Register(TOOL)