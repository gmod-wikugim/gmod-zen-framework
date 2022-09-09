local ui, draw, draw3d2d = zen.Init("ui", "ui.draw", "ui.draw3d2d")

local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D
local cam_IgnoreZ = cam.IgnoreZ

function draw3d2d.NiceAngle(pos)
    local view = render.GetViewSetup()

    
    local ang = Angle(view.angles)

    local new_ang = Angle(0,0,0)

    
    new_ang.p = 0
    new_ang.y = ang.y - 90
    new_ang.r = ang.r + 90
    new_ang.r = new_ang.r - ang.p + 30

    if ang.p < -90 or ang.p > 90 then
        -- new_ang.y = new_ang.y + 180
        -- new_ang.p = 180
        -- new_ang.r = new_ang.r + 180
    end
    -- new_ang.r = new_ang.r + ang.p + 180

    new_ang:Normalize()


    return new_ang
end

local function getCam3d2dBase(pos, ang, scale, ignorez)
    ang = ang or draw3d2d.NiceAngle(pos)
    scale = scale or 0.1
    return pos, ang, scale, ignorez
end

local lastIgnoreZ
local function start3d2d(pos, ang, scale, ignorez)
    cam_Start3D2D(pos, ang, scale, ignorez)
    if ignorez then lastIgnoreZ = cam_IgnoreZ(true) end
end

local function end3d2d(ignorez)
    if ignorez then cam_IgnoreZ(lastIgnoreZ) end
    cam_End3D2D()
end

local v1, v2, v3, v4, v5

function draw3d2d.Line(pos, ang, scale, ignorez, ...)
    pos, ang, scale, ignorez = getCam3d2dBase(pos, ang, scale, ignorez)
    start3d2d(pos, ang, scale, ignorez)
        v1, v2, v3, v4, v5 = draw.DrawLine(...)
    end3d2d(ignorez)
    return v1, v2, v3, v4, v5
end


function draw3d2d.Box(pos, ang, scale, ignorez, ...)
    pos, ang, scale, ignorez = getCam3d2dBase(pos, ang, scale, ignorez)
    start3d2d(pos, ang, scale, ignorez)
        v1, v2, v3, v4, v5 = draw.Box(...)
    end3d2d(ignorez)
    return v1, v2, v3, v4, v5
end

function draw3d2d.Texture(pos, ang, scale, ignorez, ...)
    pos, ang, scale, ignorez = getCam3d2dBase(pos, ang, scale, ignorez)
    start3d2d(pos, ang, scale, ignorez)
        v1, v2, v3, v4, v5 = draw.Texture(...)
    end3d2d(ignorez)
    return v1, v2, v3, v4, v5
end

function draw3d2d.TextureRotated(pos, ang, scale, ignorez, ...)
    pos, ang, scale, ignorez = getCam3d2dBase(pos, ang, scale, ignorez)
    start3d2d(pos, ang, scale, ignorez)
        v1, v2, v3, v4, v5 = draw.TextureRotated(...)
    end3d2d(ignorez)
    return v1, v2, v3, v4, v5
end

function draw3d2d.Text(pos, ang, scale, ignorez, ...)
    pos, ang, scale, ignorez = getCam3d2dBase(pos, ang, scale, ignorez)
    start3d2d(pos, ang, scale, ignorez)
        v1, v2, v3, v4, v5 = draw.Text(...)
    end3d2d(ignorez)
    return v1, v2, v3, v4, v5
end
