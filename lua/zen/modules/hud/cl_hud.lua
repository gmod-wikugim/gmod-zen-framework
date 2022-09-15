RENDER_3D = 1
RENDER_2D = 2

RENDER_PRE = 1
RENDER_DEFAULT = 2
RENDER_POST = 3

ihook.Listen("DrawTranslucentRenderables", "zen.hud", function()
    ihook.Run("Render", RENDER_3D, RENDER_PRE)
end)

ihook.Run("PreDrawEffects", "zen.hud", function()
    ihook.Run("Render", RENDER_3D, RENDER_DEFAULT)
end)

ihook.Listen("PreDrawHUD", "zen.hud", function()
    ihook.Run("Render", RENDER_2D, RENDER_DEFAULT)
end)

ihook.Listen("PostDrawEffects", "zen.hud", function()
    ihook.Run("Render", RENDER_2D, RENDER_PRE)
end)

ihook.Listen("PostRender", "zen.hud", function()
    cam.Start3D()
        ihook.Run("Render", RENDER_3D, RENDER_POST)
    cam.End3D()

    cam.Start2D()
        ihook.Run("Render", RENDER_2D, RENDER_POST)
    cam.End2D()
end)

local draw, draw3d2d = zen.Import("ui.draw", "ui.draw3d2d")

ihook.Listen("PostDrawOpaqueRenderables", "zen.hud", function()
    local view = render.GetViewSetup()
    local lp = LocalPlayer()


    local ent_list = ents.FindInSphere(view.origin, 500)

    for k, ent in ipairs(ent_list) do
        if not IsValid(ent) then continue end
        if ent:IsWeapon() then continue end



        local name_3d2d = ent:zen_GetVar("3d2d.name")
        if name_3d2d then
            local min, max = ent:GetModelBounds()
            local pos = ent:GetPos()
            pos.z = pos.z + max.z * 1.2

            local clr = ent:zen_GetVar("3d2d.name.color") or color_white

            local ang = (ent:GetPos() - lp:EyePos()):Angle()
            ang.p = 0
            ang.r = 90
            ang.y = ang.y - 90

            cam.Start3D2D(pos, ang, 0.3)
                cam.IgnoreZ(true)
                draw.Text(name_3d2d, 8, 0, 0, clr, 1,1)
                cam.IgnoreZ(false)
            cam.End3D2D()
        end


        local tsDrawArray = ent:zen_GetVar("3d2d.text.draw.array")
        if tsDrawArray then
            local ang = draw3d2d.NiceAngle(hitpos)
            local pos = ent:GetPos()

            local w, h = draw.TextArray_Size(tsDrawArray)


            cam.Start3D2D(pos, ang, 0.1)
                draw.TextArray(100, -h/2, tsDrawArray)
            cam.End3D2D()
        end


        local outlines_color = ent:zen_GetVar("rp.outlines.color")
        if outlines_color then
            rp.outlines.Add(ent, outlines_color)
        end
    end
end)
