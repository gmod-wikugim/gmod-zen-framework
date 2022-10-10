local icmd = zen.Import("command")
local save = zen.Init("zen.Save")

local map = game.GetMap()

icmd.Register("go", function(QCMD, who, cmd, args, tags)
    local pos, ang = save.GetSaveValue("go.point", map, QCMD:Get("go.point"), nil, nil, true)
    if !pos then return {"go.point don't exists: ", QCMD:Get("go.point")} end

    -- who:SetPos(pos)
    -- if ang then
    --     who:SetAngles(ang)
    -- end

    return {"Success teleported to: ", QCMD:Get("go.point")}
end, {
    {type = "string_id", name = "go.point"},
}, {
    perm = "go",
    help = "Teleport to point"
})

icmd.Register("go.set", function(QCMD, who, cmd, args, tags)
    save.SetSaveValue("go.point", map, QCMD:Get("go.point"), nil, nil, QCMD:Get("position"), QCMD:Get("angle"))

    return {"Sucess added new point: ", QCMD:Get("go.point")}
end, {
    {type = "string_id", name = "go.point"},
    {type = "vector", name = "position"},
    {type = "angle", name = "angle"},
}, {
    perm = "go.set",
    help = "Teleport to point"
})

