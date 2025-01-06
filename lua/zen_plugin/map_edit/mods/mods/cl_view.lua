module("zen")

---

---@class (strict) zen.map_edit_mod.view: zen.map_edit_mod
local MOD = map_edit_mods.Register("view", {
    name = "View",
    version = "1.0",
})





MOD.VIEW = {}
MOD.VIEW.origin = Vector(0,0,0)
MOD.VIEW.angles = Angle(0,0,0)
MOD.VIEW.CursorX = 0
MOD.VIEW.CursorY = 0

MOD.VIEW.bloomtone	=	true
MOD.VIEW.fov_unscaled	=	100
MOD.VIEW.fov	=	120
MOD.VIEW.fovviewmodel	=	75
MOD.VIEW.fovviewmodel_unscaled	=	60
MOD.VIEW.subrect	=	false
MOD.VIEW.zfar	=	1000
MOD.VIEW.zfarviewmodel	=	90000
MOD.VIEW.znear	= 1
MOD.VIEW.znearviewmodel	= 0
MOD.VIEW.dopostprocess = false
MOD.VIEW.bloomtone = true
MOD.VIEW.drawviewmodel = false


local function GetAngleString(ang)
	return table.concat({math.Round(ang.p, 2), math.Round(ang.y, 2), math.Round(ang.r, 2)}, " ")
end

local function GetVectorString(vec)
	return table.concat({math.Round(vec.x, 2), math.Round(vec.y, 2), math.Round(vec.z, 2)}, " ")
end

function MOD:DrawHitPoint(VIEW)

    local y = 0
    y = y - 5
    draw3d2d.Text(VIEW.TRACE_WITH_CURSOR.HitPos, nil, 0.01, true, "v", 1000, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

    y = y - 35
    draw3d2d.Text(VIEW.TRACE_WITH_CURSOR.HitPos, nil, 0.1, true, GetVectorString(VIEW.TRACE_WITH_CURSOR.HitPos), 30, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

    local ent = VIEW.TRACE_WITH_CURSOR.Entity

    if IsValid(ent) then
        local ent_id = ent:EntIndex()

        y = y - 35
        draw3d2d.Text(VIEW.TRACE_WITH_CURSOR.HitPos, nil, 0.1, true, tostring(ent:GetClass()) .. "[" .. ent_id .. "]", 30, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

        local name = ent.GetName and ent:GetName()

        if name then
            y = y - 35
            draw3d2d.Text(VIEW.TRACE_WITH_CURSOR.HitPos, nil, 0.1, true, tostring(ent:GetName()), 30, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)
        end
    end
end


function MOD:DrawTraceHitEntityWireframeBox(VIEW)

    if VIEW.TRACE_NO_CURSOR then
        local HitPos = VIEW.TRACE_NO_CURSOR.HitPos

        render.DrawLine(VIEW.origin - Vector(0,0,10), HitPos, color_white)
    end


    if VIEW.TRACE_WITH_CURSOR then
        local HitPos = VIEW.TRACE_WITH_CURSOR.HitPos

        render.DrawLine(VIEW.origin - Vector(0,0,10), HitPos, COLOR_YELLOW)
    end

    if VIEW.ME then
        local HitPos = VIEW.ME:GetPos()

        render.DrawLine(VIEW.origin - Vector(0,0,10), HitPos, COLOR_GREEN)
    end

    if !VIEW.TRACE_WITH_CURSOR then return end

    local Entity = VIEW.TRACE_WITH_CURSOR.Entity


    if !IsValid(Entity) then return end
    if Entity:IsWorld() then return end


    local origin = Entity:GetPos()
    local angles = Entity:GetAngles()

    local mins, maxs = Entity:GetRenderBounds()

    if mins and maxs then
        render.DrawWireframeBox(origin, angles, mins, maxs, color_white)
    end
end

function MOD:CalcMove(VIEW)

    do -- Mouse Stuff
        local add_x = 0 // -(cmd:GetMouseX() * 0.03)
        local add_y = 0 // -(cmd:GetMouseY() * 0.03)

        local cx, cy = VIEW.LocalCursorX, VIEW.LocalCursorY

        VIEW.CursorX = cx
        VIEW.CursorY = cy

        if input.IsKeyPressed(MOUSE_RIGHT) or input.IsKeyPressed(KEY_LALT) then
            VIEW.lastCX = VIEW.lastCX or cx
            VIEW.lastCY = VIEW.lastCY or cy

            add_x = (cx - VIEW.lastCX) * 0.1
            add_y = (cy - VIEW.lastCY) * 0.1

            -- Inverting
            add_x = -add_x
            add_y = -add_y

            VIEW.lastCX = cx
            VIEW.lastCY = cy


            if cx < 0 then
                VIEW.NextCX = VIEW.w
                VIEW.lastCX = VIEW.w
            end
            if cx > VIEW.w then
                VIEW.NextCX = 0
                VIEW.lastCX = 0
            end
            if cy < 0 then
                VIEW.NextCY = VIEW.h
                VIEW.lastCY = VIEW.h
            end
            if cy > VIEW.h then
                VIEW.NextCY = 0
                VIEW.lastCY = 0
            end
        else
            VIEW.lastCX = cx
            VIEW.lastCY = cy
        end

        if add_x != 0 then
            if VIEW.angles.p < -90 or VIEW.angles.p > 90 then
                VIEW.angles.y = VIEW.angles.y - add_x
            else
                VIEW.angles.y = VIEW.angles.y + add_x
            end
        end

        if add_y != 0 then
            VIEW.angles.p = VIEW.angles.p - add_y
        end


        VIEW.angles:Normalize()
        VIEW.angles.r = 0
    end


	-- local bPreventMouseMove = ihook.Run("map_edit.MouseMove", add_x, add_y)
	-- local bPreventButtonMove = ihook.Run("map_edit.ButtonMove")

	local isMoveActive = true //!vgui.CursorVisible() and !bPreventButtonMove

	if isMoveActive then

		local speed = 2
		if input.IsButtonPressedIN(IN_SPEED) then
			speed = 10
		elseif input.IsButtonPressedIN(IN_DUCK) then
			speed = 0.1
		end

		local add_origin = Vector()

		if input.IsButtonPressedIN(IN_FORWARD) then
			add_origin = add_origin + VIEW.angles:Forward() * speed
		end

		if input.IsButtonPressedIN(IN_MOVERIGHT) then
			add_origin = add_origin + VIEW.angles:Right() * speed
		end

		if input.IsButtonPressedIN(IN_BACK) then
			add_origin = add_origin - VIEW.angles:Forward() * speed
		end

		if input.IsButtonPressedIN(IN_MOVELEFT) then
			add_origin = add_origin - VIEW.angles:Right() * speed
		end

		if input.IsButtonPressedIN(IN_JUMP) then
			add_origin = add_origin + Vector(0,0,1) * speed
		end

		VIEW.origin = VIEW.origin + add_origin
	end

	if not VIEW.lastOrigin then VIEW.lastOrigin = VIEW.origin end
	if not VIEW.lastAngles then VIEW.lastAngles = VIEW.angles end

	-- if VIEW.lastOrigin != VIEW.origin and VIEW.nextOriginUpdate <= CurTime() then
	-- 	VIEW.nextOriginUpdate = VIEW.nextOriginUpdate + 0.5
	-- 	VIEW.lastOrigin = VIEW.origin
	-- 	nt.Send("map_edit.update.pos", {"vector"}, {VIEW.lastOrigin})
	-- end

	if VIEW.lastAngles != VIEW.angles then
		VIEW.lastAngles = VIEW.angles
	end


    do --Tracers
        VIEW.TRACE_NO_CURSOR = util.TraceLine({
            start = VIEW.origin,
            endpos = VIEW.origin + VIEW.angles:Forward() * 99999,
            hitclientonly = true
        })


        local normal = util.AimVector(VIEW.angles, VIEW.fov, VIEW.LocalCursorX, VIEW.LocalCursorY, VIEW.w, VIEW.h)
        VIEW.TRACE_WITH_CURSOR = util.TraceLine({
            start = VIEW.origin,
            endpos = VIEW.origin + normal * 99999,
            hitclientonly = true
        })
    end

    if VIEW.lastOrigin != VIEW.origin and (VIEW.nextOriginUpdate or 0) <= CurTime() then
		VIEW.nextOriginUpdate = (VIEW.nextOriginUpdate or 0) + 0.5
		VIEW.lastOrigin = VIEW.origin
		nt.Send("map_edit.update.pos", {"vector"}, {VIEW.lastOrigin})
	end


    cam.Start3D()
        self:DrawHitPoint(VIEW)
        self:DrawTraceHitEntityWireframeBox(VIEW)
    cam.End3D()

end


--- Called when menu should be initialized
---@param workspaceUpper zen.panel.zpanelbase
---@param workspaceContent zen.panel.zpanelbase
function MOD:Start(workspaceUpper, workspaceContent)
    CurrentMode = self
    self.workspaceUpper = workspaceUpper
    self.workspaceContent = workspaceContent

    local VIEW = self.VIEW

    function workspaceContent:PaintOnce(w, h)
        draw.BoxRounded(5, 0, 0, w, h, "161616")
    end
    workspaceContent:CalcPaintOnce_Internal()


    workspaceContent.pnlRender = vgui.Create("EditablePanel", workspaceContent)
    workspaceContent.pnlRender:Dock(FILL)
    workspaceContent.pnlRender:DockMargin(20, 20, 20, 20)

    local view = render.GetViewSetup()
    VIEW.origin = view.origin
    VIEW.angles = view.angles

    function workspaceContent.pnlRender:Paint(w, h)
        VIEW.LocalCursorX, VIEW.LocalCursorY = self:LocalCursorPos()

        local x, y = vgui.GetWorldPanel():GetChildPosition(self)

        local old = DisableClipping( true ) -- Avoid issues introduced by the natural clipping of Panel rendering


        VIEW.x = x
        VIEW.y = y

        VIEW.width = w
        VIEW.height = h
        VIEW.w = w
        VIEW.h = h

        VIEW.ME = LocalPlayer()

        VIEW.aspect = w / h // Don't touch, used for normal aspect calc, also for cursor 3D position
        VIEW.subrect = false

        render.RenderView( VIEW )
        CurrentMode:CalcMove(VIEW)
        DisableClipping( old )

        CurrentMode:Draw2D(VIEW, w, h)


        if VIEW.NextCX or VIEW.NextCY then
            local cx, cy = input.GetCursorPos()
            local NX = (VIEW.NextCX) and (VIEW.NextCX + VIEW.x) or (cx)
            local NY = (VIEW.NextCY) and (VIEW.NextCY + VIEW.y) or (cy)

            VIEW.NextCX = nil
            VIEW.NextCY = nil

            input.SetCursorPos(NX, NY)

        end
    end
end

---@param w number
---@param h number
function MOD:Draw2D(VIEW, w, h)
    if VIEW.LocalCursorX and VIEW.LocalCursorY then
        draw.Text("X:Y> " .. VIEW.LocalCursorX .. " : " .. VIEW.LocalCursorY, "12:DejaVu Sans", 10, 10, color_white)

        draw.Box(VIEW.LocalCursorX, VIEW.LocalCursorY, 2, 2, color_white)
    end

    if VIEW.w and VIEW.h then
        draw.Text("W:H> " .. VIEW.w .. " : " .. VIEW.h, "12:DejaVu Sans", 10, 30, color_white)
    end

    do -- FpS
        VIEW.FPS  = ( 1 / FrameTime() )
        VIEW.AVGA = (VIEW.AVGA or 0) + 1
        VIEW.AVGS = (VIEW.AVGS or 0) + VIEW.FPS
        VIEW.AVG = VIEW.AVGS / VIEW.AVGA
        draw.Text("FPS> " .. VIEW.FPS, "12:DejaVu Sans", 10, 50, color_white)
        draw.Text("A FPS> " .. math.floor(VIEW.AVG), "12:DejaVu Sans", 10, 70, color_white)

        if VIEW.AVGA > 100 then
            VIEW.AVGA = 0
            VIEW.AVGS = 0
        end
    end
end

function MOD:SearchFile()
end

MOD:SearchFile()

function MOD:CreateFileBrowser()


end
