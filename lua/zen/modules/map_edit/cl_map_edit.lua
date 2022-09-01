local map_edit = zen.Init("map_edit")

map_edit.hookName = "zen.map_edit"
map_edit.ViewData = map_edit.ViewData or {}
local viewdata = map_edit.ViewData

function map_edit.HUDPaint()



	if viewdata.IsDrawPlayers then
		
	end

end

function map_edit.HUDShouldDraw()
	return false
end

function map_edit.GenerateGUI(pnlContext)
	local pnlFrame = pnlContext:Add("DFrame")
	pnlFrame:SetSize(300, 400)
	pnlFrame:SetPos(100, 100)
	pnlFrame:SetSizable(true)
	pnlFrame:SetTitle("MapEdit")


	local pnlList = pnlFrame:Add("EditablePanel")
	pnlList:Dock(FILL)
	pnlList:InvalidateParent(true)


	local addButton = function(tall)
		local pnlButton = pnlList:Add("EditablePanel")
		pnlButton:SetTall(tall or 50)
		pnlButton:Dock(TOP)
		pnlButton:InvalidateParent(true)

		return pnlButton
	end

	do
		local pnlDrawEntities = addButton(20)
		local pnl = pnlDrawEntities:Add("DCheckBoxLabel")
		pnl:SetText("DrawPlayer")
		pnl:Dock(FILL)
		pnl.OnChange = function(self, value)
			viewdata.IsDrawPlayers = value
		end


	end
end


function map_edit.Toggle()
	local ply = LocalPlayer()
	map_edit.IsActive = not map_edit.IsActive
	
	if not map_edit.IsActive then
		hook.Remove("CalcView", map_edit.hookName)
		hook.Remove("StartCommand", map_edit.hookName)
		hook.Remove("PlayerSwitchWeapon", map_edit.hookName)
		hook.Remove("map_edit.HUDPaint", map_edit.hookName)
		hook.Remove("HUDShouldDraw", map_edit.hookName)

		if IsValid(map_edit.pnlContext) then
			map_edit.pnlContext:Remove()
		end
		return
	end


	map_edit.pnlContext = g_ContextMenu:Add("EditablePanel")
	map_edit.pnlContext:SetSize(ScrW(), ScrH())
	map_edit.pnlContext:SetPos(0, 0)
	map_edit.pnlContext:SetWorldClicker(true)
	map_edit.pnlContext:SetMouseInputEnabled(true)

	map_edit.GenerateGUI(map_edit.pnlContext)
	
	
	hook.Add("CalcView", map_edit.hookName, map_edit.CalcView)
	hook.Add("StartCommand", map_edit.hookName, map_edit.StartCommand)
	hook.Add("PlayerSwitchWeapon", map_edit.hookName, map_edit.PlayerSwitchWeapon)
	hook.Add("map_edit.HUDPaint", map_edit.hookName, map_edit.HUDPaint)
	hook.Add("HUDShouldDraw", map_edit.hookName, map_edit.HUDShouldDraw)
	
	viewdata.Angle = ply:EyeAngles()
	viewdata.Origin = ply:EyePos()
	viewdata.StartAngles = ply:EyeAngles()
end

function map_edit.PlayerSwitchWeapon(ply, wep)
	return true
end

function map_edit.CalcView(ply, origin, angles, fov, znear, zfar)
	local new_view = {
		origin = viewdata.Origin,
		angles = viewdata.Angle,
		fov = 80,
		drawviewer = true,
	}
	
	return new_view
end

function map_edit.StartCommand(ply, cmd)
	local add_x = -(cmd:GetMouseX() * 0.03)
	local add_y = -(cmd:GetMouseY() * 0.03)

	if add_x != 0 then
		viewdata.Angle.y = viewdata.Angle.y + add_x
	end
	
	if add_y != 0 then
		viewdata.Angle.p = viewdata.Angle.p - add_y
	end

	viewdata.Angle.r = 0


	local speed = cmd:KeyDown(IN_SPEED) and 5 or 2

	local add_origin = Vector()

	if cmd:KeyDown(IN_FORWARD) then
		add_origin = add_origin + viewdata.Angle:Forward() * speed
	end

	if cmd:KeyDown(IN_MOVERIGHT) then
		add_origin = add_origin + viewdata.Angle:Right() * speed
	end

	if cmd:KeyDown(IN_BACK) then
		add_origin = add_origin - viewdata.Angle:Forward() * speed
	end

	if cmd:KeyDown(IN_MOVELEFT) then
		add_origin = add_origin - viewdata.Angle:Right() * speed
	end

	if cmd:KeyDown(IN_JUMP) then
		add_origin = add_origin + Vector(0,0,1) * speed
	end

	if cmd:KeyDown(IN_DUCK) then
		add_origin = add_origin + Vector(0,0,1) * -speed
	end

	viewdata.Origin = viewdata.Origin + add_origin

	cmd:SetImpulse(0)
	cmd:ClearButtons()
	cmd:ClearMovement()
	cmd:SetViewAngles(viewdata.StartAngles)
end

hook.Add("PlayerButtonPress", "zen.map_edit", function(ply, but)
	if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_LALT) and but == KEY_APOSTROPHE then
		map_edit.Toggle()
	end
	
	if not map_edit.IsActive then return end
	
	if but == MOUSE_LEFT then
		local pos = viewdata.Origin
		local ang = viewdata.Angle
		local trace = util.TraceLine({
			start = pos,
			endpos = pos + ang:Forward()*1000
		})
	end
end)