local map_edit = zen.Init("map_edit")
map_edit.t_Panels = map_edit.t_Panels or {}

local ui, draw, draw3d, draw3d2d = zen.Import("ui", "ui.draw", "ui.draw3d", "ui.draw3d2d")
local gui = zen.Import("gui")

map_edit.hookName = "zen.map_edit"

map_edit.t_Mods = map_edit.t_Mods or {}
map_edit.t_ModsNames = map_edit.t_ModsNames or {}
function map_edit.RegisterMode(mode_name)
	if map_edit.t_Mods[mode_name] then return map_edit.t_Mods[mode_name] end
	local new_id = table.Count(map_edit.t_Mods) + 1
	map_edit.t_Mods[mode_name] = new_id
	map_edit.t_ModsNames[new_id] = mode_name
	return new_id
end

local MODE_DEFAULT = map_edit.RegisterMode("Default")

map_edit.ViewData = map_edit.ViewData or {}
local vw = map_edit.ViewData

function map_edit.SetMode(mode)
	local old_mode = vw.mode
	vw.mode = mode
	ihook.Run("zen.map_edit.OnModeChange", vw, old_mode, mode)
end

function map_edit.SetupViewData()
	table.Empty(map_edit.ViewData)

	vw.t_Positions = {}
	vw.BindPressed = {}
	vw.nextOriginUpdate = CurTime()

	local view = render.GetViewSetup()

	vw.angles = view.angles
	vw.origin = view.origin
	vw.StartAngles = Angle(vw.angles)

	map_edit.SetMode(MODE_DEFAULT)
end


ui.CreateFont("map_edit.Button", 6, "Roboto", {underline = true, extended = 300})

function map_edit.GetAngleString(ang)
	return table.concat({math.Round(ang.p, 2), math.Round(ang.y, 2), math.Round(ang.r, 2)}, " ")
end

function map_edit.GetVectorString(vec)
	return table.concat({math.Round(vec.x, 2), math.Round(vec.y, 2), math.Round(vec.z, 2)}, " ")
end

function map_edit.Render(rendermode, priority)
	local origin, normal = util.GetPlayerTraceSource(nil)
	vw.lastTrace = util.TraceLine({start = origin, endpos = origin + normal * 1024})

	vw.hoverEntity = vw.lastTrace.Entity
	vw.hoverOrigin = vw.lastTrace.HitPos

	ihook.Run("zen.map_edit.Render", rendermode, priority, vw)
	return true
end

function map_edit.GenerateGUI(mark_panels)

	if IsValid(map_edit.pnl_Context) then
		map_edit.pnl_Context:Remove()
	end



	map_edit.pnl_Context = vgui.Create("EditablePanel")
	map_edit.pnl_Context:SetSize(ScrW(), ScrH())
	map_edit.pnl_Context:MakePopup()
	map_edit.pnl_Context:SetMouseInputEnabled(true)
	map_edit.pnl_Context:SetKeyboardInputEnabled(true)
	map_edit.pnl_Context:SetVisible(false)


	local nav = gui.SuperCreate(
	{
		{
			{"main", "frame"};
			{size = {300, 400}, "center", sizable = true, parent = map_edit.pnl_Context, "popup", "save_pos", "input"};
			{};
			{
				{"content", "content"};
				{"dock_fill"};
				{};
				{
					{
						{"mode_status", "text"};
						{"dock_top", "auto_size", text = "--Mode Status--"};
					};
					{
						{"config", "mass_input"};
						{"auto_size", "dock_top"}
					},
					{
						{"items", "list"};
						{"dock_fill"};
						{};
						{}
					};
					{
						{"instructions", "text"};
						{"dock_bottom", "auto_size", text = "instructions"};
					};
				}
			}
		}
	}, "map_edit")

	nav.config:Setup({
		{name = "Draw Nearby", value = "cfg_draw_nearbly", type = TYPE.BOOL, default = false},
		{name = "Draw Players", value = "cfg_draw_player", type = TYPE.BOOL, default = false},
	}, function(name, value, isDefault)
		vw[name] = value
	end)
	--nav.config:SizeToChildren(false, true)

	function nav.mode_status:SetMode(mode)
		mode = mode or vw.mode
		local mode_name = map_edit.t_ModsNames[mode] or "unknown"
		nav.mode_status:SetText("--- " .. tostring(mode_name) .. " ---")
	end
	nav.mode_status:SetMode()

	nav.instructions:SetText([[IN_RELOAD - Default Mode]])
	nav.instructions:SizeToContents()
	
	ihook.Listen("zen.map_edit.OnModeChange", "zen.map_edit.setmode", function(vw, old, new)
		if not IsValid(nav.mode_status) then return end
		nav.mode_status:SetMode(new)
	end)


	ihook.Run("zen.map_edit.GenerateGUI", nav, map_edit.pnl_Context, vw)
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

		if IsValid(map_edit.pnl_Context) then map_edit.pnl_Context:Remove() end
		nt.Send("map_edit.status", {"bool"}, {false})
		return
	end

	if not LocalPlayer():zen_HasPerm("map_edit") then return end

	map_edit.SetupViewData()

	map_edit.GenerateGUI()

	for k, val in pairs(HookStateMent) do
		local func = val and map_edit.ReturnTrue or map_edit.ReturnFalse
		ihook.Handler(k, map_edit.hookName, func, HOOK_HIGH)
	end
	ihook.Handler("CalcView", map_edit.hookName, map_edit.CalcView, HOOK_HIGH)
	ihook.Handler("StartCommand", map_edit.hookName, map_edit.StartCommand, HOOK_HIGH)
	ihook.Handler("Render", map_edit.hookName, map_edit.Render, HOOK_HIGH)

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

	if bind_name == "+menu_context" then
		if IsValid(map_edit.pnl_Context) then
			map_edit.pnl_Context:SetVisible(true)
			map_edit.pnl_Context:SetMouseInputEnabled(true)
		end
	end


	if in_key == IN_RELOAD then
		map_edit.SetMode(MODE_DEFAULT)
		return
	end

	ihook.Run("zen.map_edit.OnButtonPress", ply, but, in_key, bind_name, vw)
	return true
end)

ihook.Handler("PlayerButtonUnPress", "zen.map_edit", function(ply, but, in_key, bind_name)
	if not map_edit.IsActive then return end

	if bind_name == "+menu_context" then
		if IsValid(map_edit.pnl_Context) then
			map_edit.pnl_Context:SetVisible(false)
			-- gui.EnableScreenClicker(false)
		end
	end

	if in_key == IN_RELOAD then return end

	ihook.Run("zen.map_edit.OnButtonUnPress", ply, but, in_key, bind_name, vw)
	return true
end)
