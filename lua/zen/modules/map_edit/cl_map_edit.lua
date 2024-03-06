module("zen", package.seeall)

map_edit = _GET("map_edit")

map_edit.hookName = "zen.map_edit"


map_edit.ViewData = map_edit.ViewData or {}
local vw = map_edit.ViewData

function map_edit.GetViewOrigin()
	return vw.lastOrigin
end

function map_edit.GetViewAngles()
	return vw.lastAngles
end

function map_edit.GetViewTrace()
	return vw.lastTrace_Cursor
end

function map_edit.GetViewTraceNoCursor()
	return vw.lastTrace_NoCursor
end

function map_edit.GetViewHitPos()
	return vw.lastTrace_Cursor.HitPos
end

function map_edit.GetViewHitPosNoCursor()
	return vw.lastTrace_NoCursor.HitPos
end

function map_edit.GetHoverEntity()
	return vw.hoverEntity
end

function map_edit.GetHoverOrigin()
	return vw.hoverOrigin
end



function map_edit.SetupViewData()
	table.Empty(map_edit.ViewData)

	vw.nextOriginUpdate = CurTime()

	local view = render.GetViewSetup()

	vw.angles = view.angles
	vw.origin = view.origin
	vw.StartAngles = Angle(vw.angles)
end


function map_edit.GetAngleString(ang)
	return table.concat({math.Round(ang.p, 2), math.Round(ang.y, 2), math.Round(ang.r, 2)}, " ")
end
local GetAngleString = map_edit.GetAngleString

function map_edit.GetVectorString(vec)
	return table.concat({math.Round(vec.x, 2), math.Round(vec.y, 2), math.Round(vec.z, 2)}, " ")
end
local GetVectorString = map_edit.GetVectorString

local function UpdateView()
	local cursor_origin, cursor_normal = util.GetPlayerTraceSource(nil)
	vw.lastTrace_Cursor = util.TraceLine({start = cursor_origin, endpos = cursor_origin + cursor_normal * 1024})

	local nocursor_origin, nocursor_normal = util.GetPlayerTraceSource(nil, true)
	vw.lastTrace_NoCursor = util.TraceLine({start = nocursor_origin, endpos = nocursor_origin + nocursor_normal * 1024})

	vw.hoverEntity = vw.lastTrace_Cursor.Entity
	vw.hoverOrigin = vw.lastTrace_Cursor.HitPos
end


local function RenderHitPoint()
	local y = 0
	y = y - 5
	draw3d2d.Text(vw.lastTrace_Cursor.HitPos, nil, 0.01, true, "v", 100, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

	y = y - 35
	draw3d2d.Text(vw.lastTrace_Cursor.HitPos, nil, 0.1, true, GetVectorString(vw.lastTrace_Cursor.HitPos), 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

	local ent = vw.lastTrace_Cursor.Entity

	if IsValid(ent) then
		local ent_id = ent:EntIndex()

		y = y - 35
		draw3d2d.Text(vw.lastTrace_Cursor.HitPos, nil, 0.1, true, tostring(ent:GetClass()) .. "[" .. ent_id .. "]", 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)

		local name = ent.GetName and ent:GetName()

		if name then
			y = y - 35
			draw3d2d.Text(vw.lastTrace_Cursor.HitPos, nil, 0.1, true, tostring(ent:GetName()), 10, 0, y, COLOR.WHITE, 1, 1, COLOR.BLACK)
		end
	end
end

function map_edit.Render(rendermode, priority)
	UpdateView()

	RenderHitPoint()

	ihook.Run("zen.map_edit.Render", rendermode, priority, vw)
	return true
end


local HookStateMent = {
	["HUDPaint"] = true,
	["HUDPaintBackground"] = true,
	["PlayerButtonUp.SupperessNext"] = true,
	["PlayerButtonDown.SupperessNext"] = true,
	["HUDShouldDraw"] = false,
	["PlayerSwitchWeapon"] = true,
	["CreateMove"] = true,
	["PlayerBindPress"] = true,
}

function map_edit.Toggle()
	map_edit.IsActive = not map_edit.IsActive

	if not map_edit.IsActive then
		for k, val in pairs(HookStateMent) do
			ihook.Remove(k, map_edit.hookName)
		end

		ihook.Remove("CalcView", map_edit.hookName)
		ihook.Remove("StartCommand", map_edit.hookName)
		ihook.Remove("Render", map_edit.hookName)

		ihook.Run("zen.map_edit.OnDisabled")

		nt.Send("map_edit.status", {"bool"}, {false})
		return
	end

	if not LocalPlayer():zen_HasPerm("map_edit") then return end

	map_edit.SetupViewData()

	for k, val in pairs(HookStateMent) do
		local func = val and map_edit.ReturnTrue or map_edit.ReturnFalse
		ihook.Handler(k, map_edit.hookName, func, HOOK_HIGH)
	end
	ihook.Handler("CalcView", map_edit.hookName, map_edit.CalcView, HOOK_HIGH)
	ihook.Handler("StartCommand", map_edit.hookName, map_edit.StartCommand, HOOK_HIGH)
	ihook.Handler("Render", map_edit.hookName, map_edit.Render, HOOK_HIGH)

	ihook.Run("zen.map_edit.OnEnabled")

	nt.Send("map_edit.status", {"bool"}, {true})
end

function map_edit.ReturnTrue() return true end
function map_edit.ReturnFalse() return false end

function map_edit.CalcView(ply, origin, angles, fov, znear, zfar)
	local new_view = {
		origin = vw.origin,
		angles = vw.angles,
		fov = 80,
		drawviewer = true,
	}

	return new_view
end


function map_edit.StartCommand(ply, cmd)
	local add_x = -(cmd:GetMouseX() * 0.03)
	local add_y = -(cmd:GetMouseY() * 0.03)

	local isMoveActive = !vgui.CursorVisible()

	if add_x != 0 then
		if vw.angles.p < -90 or vw.angles.p > 90 then
			vw.angles.y = vw.angles.y - add_x
		else
			vw.angles.y = vw.angles.y + add_x
		end
	end

	if add_y != 0 then
		vw.angles.p = vw.angles.p - add_y
	end


	vw.angles:Normalize()
	vw.angles.r = 0

	if isMoveActive then

		local speed = 2
		if input.IsButtonPressedIN(IN_SPEED) then
			speed = 10
		elseif input.IsButtonPressedIN(IN_DUCK) then
			speed = 0.1
		end

		local add_origin = Vector()

		if input.IsButtonPressedIN(IN_FORWARD) then
			add_origin = add_origin + vw.angles:Forward() * speed
		end

		if input.IsButtonPressedIN(IN_MOVERIGHT) then
			add_origin = add_origin + vw.angles:Right() * speed
		end

		if input.IsButtonPressedIN(IN_BACK) then
			add_origin = add_origin - vw.angles:Forward() * speed
		end

		if input.IsButtonPressedIN(IN_MOVELEFT) then
			add_origin = add_origin - vw.angles:Right() * speed
		end

		if input.IsButtonPressedIN(IN_JUMP) then
			add_origin = add_origin + Vector(0,0,1) * speed
		end

		vw.origin = vw.origin + add_origin
	end

	if not vw.lastOrigin then vw.lastOrigin = vw.origin end
	if not vw.lastAngles then vw.lastAngles = vw.angles end

	if vw.lastOrigin != vw.origin and vw.nextOriginUpdate <= CurTime() then
		vw.nextOriginUpdate = vw.nextOriginUpdate + 0.5
		vw.lastOrigin = vw.origin
		nt.Send("map_edit.update.pos", {"vector"}, {vw.lastOrigin})
	end

	if vw.lastAngles != vw.angles then
		vw.lastAngles = vw.angles
	end


	cmd:SetImpulse(0)
	cmd:ClearButtons()
	cmd:ClearMovement()
	cmd:SetViewAngles(vw.StartAngles)
	return true
end

ihook.Handler("PlayerButtonPress", "zen.map_edit", function(ply, but, in_key, bind_name)
	if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_LALT) and but == KEY_APOSTROPHE then
		map_edit.Toggle()
	end
	if not map_edit.IsActive then return end
	ihook.Run("zen.map_edit.OnButtonPress", ply, but, in_key, bind_name, vw)
	return true
end)

ihook.Handler("PlayerButtonUnPress", "zen.map_edit", function(ply, but, in_key, bind_name)
	if not map_edit.IsActive then return end

	ihook.Run("zen.map_edit.OnButtonUnPress", ply, but, in_key, bind_name, vw)
	return true
end)
