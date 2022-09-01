local worldclick = zen.worldclick

worldclick.tLastTrace = worldclick.tLastTrace or {}
worldclick.objLastEntity = worldclick.objLastEntity or NULL
function worldclick.CheckHover()
    local tr = worldclick.Trace()

    worldclick.tLastTrace = tr

    if worldclick.objLastEntity != tr.Entity then
        worldclick.objLastEntity = tr.Entity
        hook.Run("zen.worldclick.onHoverEntity", worldclick.objLastEntity, tr)
    end
end

function worldclick.CheckClick(code)
    if not LocalPlayer():izen_HasPerm("zen.worldclick") then return end

    local hover_pnl = vgui.GetHoveredPanel()
    if not IsValid(hover_pnl) or not hover_pnl:IsWorldClicker() then return end

    hook.Run("zen.worldclick.onPress", code, worldclick.tLastTrace)
    if IsValid(worldclick.objLastEntity) then
        hook.Run("zen.worldclick.onPressEntity", worldclick.objLastEntity, code, worldclick.tLastTrace)
    end
end
hook.Add( "GUIMousePressed", "zen.worldclick", worldclick.CheckClick)

function worldclick.CheckUnClick(code)
    if not LocalPlayer():izen_HasPerm("zen.worldclick") then return end

    local hover_pnl = vgui.GetHoveredPanel()
    if not IsValid(hover_pnl) or not hover_pnl:IsWorldClicker() then return end

    hook.Run("zen.worldclick.onRelease", code, worldclick.tLastTrace)
    if IsValid(worldclick.objLastEntity) then
        hook.Run("zen.worldclick.onReleaseEntity", worldclick.objLastEntity, code, worldclick.tLastTrace)
    end
end
hook.Add( "GUIMouseReleased", "zen.worldclick", worldclick.CheckUnClick)

hook.Add( "PreventScreenClicks", "zen.worldclick", function()
    local hover_pnl = vgui.GetHoveredPanel()
    if not IsValid(hover_pnl) or not hover_pnl:IsWorldClicker() then return end

    return LocalPlayer():izen_HasPerm("zen.worldclick")
end)

local color_hover = Color(255, 0, 0)
hook.Add( "PreDrawEffects", "zen.variable_edit", function()
    local hover_pnl = vgui.GetHoveredPanel()
    if not IsValid(hover_pnl) or not hover_pnl:IsWorldClicker() then return end

    worldclick.CheckHover()

    local ent = worldclick.objLastEntity
    if ( !IsValid( ent ) ) then return end


    local pos = ent:WorldSpaceCenter()
    local ang = ((pos) - LocalPlayer():EyePos()):Angle()
    ang.p = 0
    ang.r = 90
    ang.y = ang.y - 90

    cam.Start3D2D(pos, ang, 0.5)
        cam.IgnoreZ(true)
        draw.SimpleText(ent:GetClass(), "DebugOverlay", 0, 0, color_white, 1,1)
        cam.IgnoreZ(false)
    cam.End3D2D()


    hook.Run("zen.worldclick.DrawEntityInfo", ent, pos, ang)
end)

hook.Add("zen.worldclick.onPress", "zen.nt", function(code, tr) nt.Send("zen.worldclick.onPress", {"uint7", "vector", "vector"}, {code, tr.StartPos, tr.Normal}) end)
hook.Add("zen.worldclick.onRelease", "zen.nt", function(code, tr) nt.Send("zen.worldclick.onRelease", {"uint7", "vector", "vector"}, {code, tr.StartPos, tr.Normal}) end)