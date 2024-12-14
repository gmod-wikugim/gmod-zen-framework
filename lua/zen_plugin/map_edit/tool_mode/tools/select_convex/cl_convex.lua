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



local color_r = Color(255,255,255,20)
local color_wireframe = Color(255,255,255,255)
local angle_zero = Angle(0,0,0)
local point_size = Vector(0.5, 0.5, 0.5)

local function DrawPoint(pos)
    render.DrawBox(pos, angle_zero, -point_size, point_size, color_wireframe)
end

local function clear_vec(vec)
    return string.format("%d %d %d", vec.x, vec.y, vec.z)
end

function TOOL:Render(rendermode, priority, vw)
    local near_ents = ents.FindInSphere(map_edit.GetViewOrigin(), 1000)

    for k, ent in pairs(near_ents) do
        local mdl = ent:GetModel()
        if !isstring(mdl) or IsUselessModel(mdl) then continue end

        local mins, maxs = vec.GetModelBound(mdl)

        ---@type VMatrix
        local matrix = ent:GetWorldTransformMatrix()

        local pos = matrix:GetTranslation()
        local ang = matrix:GetAngles()


        local right = ang:Right()
        local up = ang:Up()
        local forward = ang:Forward()


        local rotated_mins = Vector(mins)
        rotated_mins:Rotate(ang)
        local rotated_maxs = Vector(maxs)
        rotated_mins:Rotate(ang)

        draw3d.Text(pos, "RMins: " .. clear_vec(rotated_mins), "9:Default", 20, -40, color_white, 0, 1, COLOR.BLACK)
        draw3d.Text(pos, "RMaxs: " .. clear_vec(rotated_maxs), "9:Default", 20, -20, color_white, 0, 1, COLOR.BLACK)

        draw3d.Text(pos, "Mins: " .. clear_vec(mins), "9:Default", 20, 20, color_white, 0, 1, COLOR.BLACK)
        draw3d.Text(pos, "Maxs: " .. clear_vec(maxs), "9:Default", 20, 40, color_white, 0, 1, COLOR.BLACK)

        draw3d.Text(pos, "right: " .. tostring(right) .. "- " .. tostring(math.cos(mins.z)), "9:Default", -20, -40, color_white, 2, 1, COLOR.BLACK)
        draw3d.Text(pos, "up: " .. tostring(up), "9:Default", -20, -20, color_white, 2, 1, COLOR.BLACK)
        draw3d.Text(pos, "forward: " .. tostring(forward), "9:Default", -20, 0, color_white, 2, 1, COLOR.BLACK)
        

        

        local OBBPoints = {}

        OBBPoints[1] = Vector(0, 0, rotated_mins.z)
        OBBPoints[2] = Vector(0, 0, rotated_maxs.z)

        if OBBPoints then
            for k, pos1 in ipairs(OBBPoints) do
                local next_pos = select(2, next(OBBPoints, k)) or OBBPoints[1]

                render.DrawLine(pos + pos1, pos + next_pos, color_wireframe)
            end
        end
    end
end

function TOOL:Reload()

end

function TOOL:OnButtonPress(but, in_key, bind_name, vw)

end

tool.Register(TOOL)