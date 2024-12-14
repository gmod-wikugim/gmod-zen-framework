module("zen", package.seeall)

local mat_user = Material("icon16/user_suit.png")
local mat_wireframe = Material("models/debug/debugwhite")
local mat_wireframe2 = Material("phoenix_storms/stripes")
local gui_MousePos = gui.MousePos
local min, max, abs = math.min, math.max, math.abs


local cir_round = 15

local function distance(cx, cy, x, y)
    local a, b = max(cx, x) - min(cx, x), max(cy, y) - min(cy, y)

    return max(a, b)
end

local color_gray = Color(0,0,0,100)
local color_alpha = Color(255,255,255,20)
local color_hover = Color(255,0,0,20)
local function draw_circle(pos)
    local vis, x, y = draw3d.GetScreenPosition(pos)
    if not vis then return end
    local cx, cy = gui_MousePos()

    
    local dis = distance(cx, cy, x, y)

    if dis > cir_round then
        draw3d.Circle(pos, cir_round, 15, color_alpha)
        draw3d.Circle(pos, cir_round-2, 15, color_gray)
    else
        draw3d.Circle(pos, cir_round, 15, color_alpha)
        draw3d.Circle(pos, cir_round-2, 15, color_hover)
    end



end


ihook.Listen("zen.map_edit.Render", "draw_entities", function(rendermode, priority, vw)
    if not IsValid(vw.ContextHoverEntity) then return end


    if priority == RENDER_POST then
        local pos = vw.ContextHoverEntity:GetPos()
        local pos1 = pos + Vector(25,0,0)
        local pos2 = pos + Vector(0,25,0)
        local pos3 = pos + Vector(0,0,25)


        draw_circle(pos1)
        draw_circle(pos2)
        draw_circle(pos3)

        draw3d.Line(pos, pos1)
        draw3d.Line(pos, pos2)
        draw3d.Line(pos, pos3)
    end




end)