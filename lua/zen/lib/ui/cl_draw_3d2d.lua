local ui = zen.Init("ui")
local draw = ui.Init("draw")
local draw3d2d = ui.Init("draw3d2d")

local cam_Start3D2D = cam.Start3D2D
local cam_End3D2D = cam.End3D2D
local cam_IgnoreZ = cam.IgnoreZ

function draw3d2d.NiceAngle(pos)
    local origin = util.GetPlayerTraceSource(nil, true)

    local ang = (pos - origin):Angle()
    ang.p = 0
    ang.r = 90
    ang.y = ang.y - 90
    return ang
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
