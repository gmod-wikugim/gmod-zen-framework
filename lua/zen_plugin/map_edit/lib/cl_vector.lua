module("zen", package.seeall)

vec = _GET("vec")



---@param mdl string
---@return Vector mins, Vector maxs
function vec.GetModelBound(mdl)
    local mins, maxs = util.GetModelMeshBounds(mdl)


    return mins, maxs
end

---@param mins Vector
---@param maxs Vector
---@return Vector center
function vec.GetMinsMaxsCenter(mins, maxs)
    local mins_x = mins.x
    local mins_y = mins.y
    local mins_z = mins.z

    local maxs_x = maxs.x
    local maxs_y = maxs.y
    local maxs_z = maxs.z

    local x_min = math.min(mins_x, maxs_x)
    local y_min = math.min(mins_y, maxs_y)
    local z_min = math.min(mins_z, maxs_z)

    local x_max = math.max(mins_x, maxs_x)
    local y_max = math.max(mins_y, maxs_y)
    local z_max = math.max(mins_z, maxs_z)

    local x_center = (x_min + x_max) / 2
    local y_center = (y_min + y_max) / 2
    local z_center = (z_min + z_max) / 2

    local MinsMaxsCenter = Vector(x_center, y_center, z_center)

    return MinsMaxsCenter
end

local color_wireframe = Color(255,255,255,255)
local angle_zero = Angle(0,0,0)
local point_size = Vector(0.5, 0.5, 0.5)

local function DrawPoint(pos)
    render.DrawBox(pos, angle_zero, -point_size, point_size, color_wireframe)
end


function vec.GetOBBMinsMaxs(mins, maxs, pos)
    local mins_x = mins.x
    local mins_y = mins.y
    local mins_z = mins.z

    local maxs_x = maxs.x
    local maxs_y = maxs.y
    local maxs_z = maxs.z

    local x_min = math.min(mins_x, maxs_x)
    local y_min = math.min(mins_y, maxs_y)
    local z_min = math.min(mins_z, maxs_z)

    local x_max = math.max(mins_x, maxs_x)
    local y_max = math.max(mins_y, maxs_y)
    local z_max = math.max(mins_z, maxs_z)

    -- Calc 8 Points for box corners
    local point_1 = Vector(x_min, y_min, z_min)

end



---@param mins Vector
---@param maxs Vector
---@param pos Vector
---@param ang Angle
---@return Vector OBBMins, Vector OBBMaxs, Vector OBBCenter, table
function vec.GetOBB(mins, maxs, pos, ang)
    local ang = Angle(ang)
    local mins = Vector(mins)
    local maxs = Vector(maxs)

    local rotated_mins = Vector(mins)
    rotated_mins:Rotate(ang)
    local rotated_maxs = Vector(maxs)
    rotated_maxs:Rotate(ang)

    local OBBCenter = vec.GetMinsMaxsCenter(rotated_mins, rotated_maxs)

    local mins_x = mins.x
    local mins_y = mins.y
    local mins_z = mins.z

    local maxs_x = maxs.x
    local maxs_y = maxs.y
    local maxs_z = maxs.z

    local x_min = math.min(mins_x, maxs_x)
    local y_min = math.min(mins_y, maxs_y)
    local z_min = math.min(mins_z, maxs_z)

    local x_max = math.max(mins_x, maxs_x)
    local y_max = math.max(mins_y, maxs_y)
    local z_max = math.max(mins_z, maxs_z)

    local OBBMins = Vector(x_min, y_min, z_min)
    local OBBMaxs = Vector(x_max, y_max, z_max)

    local x_center = (x_min + x_max) / 2
    local y_center = (y_min + y_max) / 2
    local z_center = (z_min + z_max) / 2


    local x_normed = (maxs_x - mins_x) / 2
    local y_normed = (maxs_y - mins_y) / 2
    local z_normed = (maxs_z - mins_z) / 2

    local OBBMinsNorm = Vector(-x_normed, -y_normed, -z_normed)
    local OBBMaxsNorm = Vector(x_normed, y_normed, z_normed)

    vec.GetOBBMinsMaxs(mins, maxs, OBBCenter)

    OBBCenter = OBBCenter + pos


    local OBBPoints = {}
    do
        OBBPoints[1] = Vector(0, 0, mins_z)
        OBBPoints[2] = Vector(0, 0, maxs_z)
    end

    return OBBCenter, OBBMinsNorm, OBBMaxsNorm, OBBPoints
end


-- function vec.
