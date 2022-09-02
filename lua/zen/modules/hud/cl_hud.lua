RENDER_3D = 1
RENDER_2D = 2

RENDER_PRE = 1
RENDER_DEFAULT = 2
RENDER_POST = 3

hook.Add("DrawTranslucentRenderables", "zen.hud", function()
    hook.Run("Render", RENDER_3D, RENDER_PRE)
end)

hook.Run("PreDrawEffects", "zen.hud", function()
    hook.Run("Render", RENDER_3D, RENDER_DEFAULT)
end)

hook.Add("PreDrawHUD", "zen.hud", function()
    hook.Run("Render", RENDER_2D, RENDER_DEFAULT)
end)

hook.Add("PostDrawEffects", "zen.hud", function()
    hook.Run("Render", RENDER_2D, RENDER_PRE)
end)

hook.Add("PostRender", "zen.hud", function()
    cam.Start3D()
        hook.Run("Render", RENDER_3D, RENDER_POST)
    cam.End3D()

    cam.Start2D()
        hook.Run("Render", RENDER_2D, RENDER_POST)
    cam.End2D()
end)


hook.Add("PostDrawOpaqueRenderables", "zen.hud", function()
    local lp = LocalPlayer()
    local lp_pos = lp:GetPos()
    local tr = lp:GetEyeTraceNoCursor()

    local hitpos = tr.HitPos
    local ent = tr.Entity

    if not IsValid(ent) then return end

    if lp_pos:DistToSqr(hitpos) > 200000 then return end


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
			draw.SimpleText(name_3d2d, "DebugOverlay", 0, 0, clr, 1,1)
            cam.IgnoreZ(false)
		cam.End3D2D()
	end

    local outlines_color = ent:zen_GetVar("rp.outlines.color")
    if outlines_color then
        rp.outlines.Add(ent, outlines_color)
    end
end)
