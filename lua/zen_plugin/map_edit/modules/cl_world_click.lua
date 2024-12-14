module("zen", package.seeall)

zen.worldclick = zen.worldclick or {}
local worldclick = zen.worldclick

function worldclick.Trace(ply, eye_pos, eye_normal)
    local filter = {}

    if SERVER then
        assertPlayer(ply, "ply")
    end

    ply = ply or LocalPlayer()
    local origin, normal = util.GetPlayerTraceSource(ply)
    origin = eye_pos or origin
    normal = eye_normal or normal

    table.insert(filter, ply)
    table.insert(filter, ply:GetViewEntity())
    table.insert(filter, ply:GetActiveWeapon())
    table.insert(filter, ply:GetVehicle())

    local trace = util.TraceLine( {
        start = origin,
        endpos = origin + normal * 1024,
        filter = filter
    } )

    -- Hit COLLISION_GROUP_DEBRIS and stuff
    if not trace.Hit or not IsValid( trace.Entity ) then
        trace = util.TraceLine( {
            start = origin,
            endpos = origin + normal * 1024,
            filter = filter,
            mask = MASK_ALL
        } )
    end

    return trace
end

worldclick.tLastTrace = worldclick.tLastTrace or {}
worldclick.objLastEntity = worldclick.objLastEntity or NULL
function worldclick.CheckHover()
    local tr = worldclick.Trace()

    worldclick.tLastTrace = tr

    if worldclick.objLastEntity != tr.Entity then
        worldclick.objLastEntity = tr.Entity
        ihook.Run("zen.worldclick.onHoverEntity", worldclick.objLastEntity, tr)
    end
end

function worldclick.CheckClick(ply, code)
    if code < MOUSE_FIRST or code > MOUSE_LAST then return end
    if not ply:zen_HasPerm("zen.worldclick") then return end
    if not vgui.CursorVisible() then return end

    local hover_pnl = vgui.GetHoveredPanel()
    if IsValid(hover_pnl) and hover_pnl != vgui.GetWorldPanel() and hover_pnl != g_ContextMenu then
        if hover_pnl:IsWorldClicker() then
            ihook.Run("zen.worldclick.onPress", code, worldclick.tLastTrace)
            if IsValid(worldclick.objLastEntity) then
                ihook.Run("zen.worldclick.onPressEntity", worldclick.objLastEntity, code, worldclick.tLastTrace)
            end
        else
            ihook.Run("zen.worldclick.panel.onPress", code)
        end
    else
        ihook.Run("zen.worldclick.nopanel.onPress", code)
    end
end
ihook.Listen( "PlayerButtonPress", "zen.worldclick", worldclick.CheckClick)

function worldclick.CheckUnClick(ply, code)
    if code < MOUSE_FIRST or code > MOUSE_LAST then return end
    if not ply:zen_HasPerm("zen.worldclick") then return end
    if not vgui.CursorVisible() then return end


    local hover_pnl = vgui.GetHoveredPanel()
    if IsValid(hover_pnl) and hover_pnl != vgui.GetWorldPanel() and hover_pnl != g_ContextMenu then
        if hover_pnl:IsWorldClicker() then
            ihook.Run("zen.worldclick.onRelease", code, worldclick.tLastTrace)
            if IsValid(worldclick.objLastEntity) then
                ihook.Run("zen.worldclick.onReleaseEntity", worldclick.objLastEntity, code, worldclick.tLastTrace)
            end
        else
            ihook.Run("zen.worldclick.panel.onRelease", code)
        end
    else
        ihook.Run("zen.worldclick.nopanel.onRelease", code)
    end
end
ihook.Listen( "PlayerButtonUnPress", "zen.worldclick", worldclick.CheckUnClick)