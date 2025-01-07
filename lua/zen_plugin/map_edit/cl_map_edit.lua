module("zen")

---@class zen.map_edit
map_edit = _GET("map_edit")

map_edit.hookName = "zen.map_edit"

---@param convar string
---@param string_value string
function map_edit.SetConvarValue(convar, string_value)
	local CONVAR = GetConVar(convar)

	if CONVAR:IsFlagSet(FCVAR_LUA_CLIENT) then
		CONVAR:SetString(string_value)
	else
		RunConsoleCommand(convar, string_value)
	end
end

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

	vw.aspect = view.aspect
	vw.bloomtone = view.bloomtone
	vw.fov = view.fov
	vw.fov_unscaled = view.fov_unscaled
	vw.fovviewmodel = view.fovviewmodel
	vw.fovviewmodel_unscaled = view.fovviewmodel_unscaled
	vw.height = view.height
	vw.subrect = view.subrect
	vw.width = view.width
	vw.x = view.x
	vw.y = view.y
	vw.zfar = view.zfar
	vw.zfarviewmodel = view.zfarviewmodel
	vw.znear = view.znear
	vw.znearviewmodel = view.znearviewmodel


	vw.angles = view.angles
	vw.origin = view.origin
	vw.StartAngles = Angle(vw.angles)
end


local function UpdateView()
	local cursor_origin, cursor_normal = util.GetPlayerTraceSource(nil, false)
	vw.lastTrace_Cursor = util.TraceLine({start = cursor_origin, endpos = cursor_origin + cursor_normal * 1024})

	local nocursor_origin, nocursor_normal = util.GetPlayerTraceSource(nil, true, vw)
	vw.lastTrace_NoCursor = util.TraceLine({start = nocursor_origin, endpos = nocursor_origin + nocursor_normal * 1024})

	vw.hoverEntity = vw.lastTrace_Cursor.Entity
	vw.hoverOrigin = vw.lastTrace_Cursor.HitPos
end


function map_edit.Render(rendermode, priority)
	-- local RT = render.GetRenderTarget()
	-- print(RT == nil, tostring(RT))
	-- render.ClearDepth()
	-- render.Clear( 0, 0, 0, 0 )

	-- local VIEW = render.GetViewSetup()

	-- print(VIEW.znear)

	-- UpdateView()

	ihook.Run("zen.map_edit.Render", rendermode, priority, vw)
	return true
end


map_edit.mt_ConVarSaved = map_edit.mt_ConVarSaved or {}
local ConVar_Ment = {
	["r_3dsky"] = "0" -- Disable 3d Sky Box and Black Screen Blink
}


map_edit.mt_HookCreated = map_edit.mt_HookCreated or {}
local HookStateMent = {
	["PlayerButtonUp.SupperessNext"] = true,
	["PlayerButtonDown.SupperessNext"] = true,

	["RenderScene"] = true,

	["PlayerSwitchWeapon"] = true,
	["CreateMove"] = true,
	["PlayerBindPress"] = true,

	["DrawDeathNotice"] = true,
	["DrawMonitors"] = true,
	["DrawOverlay"] = true,
	["DrawPhysgunBeam"] = true,
	["GetMotionBlurValues"] = true,
	["HUDDrawPickupHistory"] = true,
	["HUDDrawScoreBoard"] = true,
	["HUDDrawTargetID"] = true,
	["HUDPaint"] = true,
	["HUDPaintBackground"] = true,
	["HUDShouldDraw"] = false, -- Disable HUD Elemements
	["NeedsDepthPass"] = true,
	["PostDraw2DSkyBox"] = true,
	["PostDrawEffects"] = true,
	["PostDrawHUD"] = true,
	["PostDrawOpaqueRenderables"] = true,
	["PostDrawPlayerHands"] = true,
	["PostDrawSkyBox"] = true,
	["PostDrawTranslucentRenderables"] = true,
	["PostDrawViewModel"] = true,
	["PostPlayerDraw"] = true,
	["PostRender"] = true,
	["PostRenderVGUI"] = true,
	["PreDrawEffects"] = true,
	["PreDrawHalos"] = true,
	["PreDrawHUD"] = true,
	-- ["PreDrawOpaqueRenderables"] = true, -- Draw Props
	["PreDrawPlayerHands"] = true,
	["PreDrawSkyBox"] = true,
	-- ["PreDrawTranslucentRenderables"] = true,
	["PreDrawViewModel"] = true,
	["PreDrawViewModels"] = true,
	-- ["PrePlayerDraw"] = true, -- Draw Player
	-- ["RenderScene"] = true, -- Draw enable
	["RenderScreenspaceEffects"] = true,
	["SetupSkyboxFog"] = false, -- True to disable
	["SetupWorldFog"] = false, -- True to disable
	["ShouldDrawLocalPlayer"] = true,
}

function map_edit.CreateWorkspace(workspacename, data)
	local INFO = map_edit.INFO

	assert(IsValid(INFO.pnlUpper), "INFO.pnlUpper not Valid")

	data = data or {}

	map_edit.WORKSPACES[workspacename] = data

	local WORKSPACE = map_edit.WORKSPACES[workspacename]

	WORKSPACE.editorContentPanel = INFO.AddContentPanel()
	WORKSPACE.editorHeaderButton = INFO.AddHeaderButton(workspacename, function()
		WORKSPACE:OnEnabled()
	end)

	WORKSPACE.headerPanel = gui.Create("zpanelbase", WORKSPACE.editorContentPanel)
	WORKSPACE.headerPanel:SDock(TOP, 35)

	WORKSPACE.contentPanel = gui.Create("zpanelbase", WORKSPACE.editorContentPanel)
	WORKSPACE.contentPanel:DockMargin(2,2,2,2)
	WORKSPACE.contentPanel:SFill()

	WORKSPACE.modSelect = gui.Create("zdrop_select", WORKSPACE.headerPanel)

	WORKSPACE.CurrentModeName = "Select Mode"
	WORKSPACE.bModeSelected = false

	function WORKSPACE.modSelect:PaintOnce(w, h)
		draw.BoxRounded(2, 0,0,w,h,"181818")

		draw.Text(WORKSPACE.CurrentModeName, "20:DejaVu Sans", w/2, h/2, color_white, 1, 1, color_black)
	end

	WORKSPACE.modSelect:SDock(LEFT, 120)
	WORKSPACE.modSelect:DockMargin(2,2,2,0)

	---@param MOD zen.map_edit_mod
	function WORKSPACE:SetMod(MOD)
		self.contentPanel:Clear()

		WORKSPACE.bModeSelected = true

		if type(MOD.Start) == "function" then
			MOD:Start(WORKSPACE.headerPanel, WORKSPACE.contentPanel)
		end

		WORKSPACE.CurrentModeName = MOD.name or MOD.iden
		WORKSPACE.modSelect:CalcPaintOnce_Internal( )
	end

	function WORKSPACE:OnEnabled()
		if IsValid(INFO.pnlActiveContentPanel) then
			INFO.pnlActiveContentPanel:Hide()
		end

		INFO.pnlActiveContentPanel = WORKSPACE.editorContentPanel
		INFO.pnlActiveHeaderButton = WORKSPACE.editorHeaderButton

		if map_edit.ACTIVE_WORKSPACE then
			map_edit.ACTIVE_WORKSPACE:OnDisabled()
		end

		WORKSPACE.editorContentPanel:Show()

		if !WORKSPACE.bModeSelected and data.defaultMod then
			WORKSPACE:SetModeByName(data.defaultMod)
		end

		map_edit.ACTIVE_WORKSPACE = WORKSPACE
	end

	function WORKSPACE:OnDisabled()
	end

	function WORKSPACE.modSelect:GenerateSelectBoxContent(pnlContent)
		local MOD_LIST = map_edit_mods.GetListForEdit()

		for k, MOD in pairs(MOD_LIST) do
			local pnlText = gui.Create("zlabel", pnlContent)
			pnlText:SetSize(200, 30)
			pnlText:SetText(MOD.name or MOD.iden)
			pnlText:SetFont(ui.ffont("20:DejaVu Sans"))
			pnlText:SizeToContentsX(25)

			pnlText:AddPaintOncePreFunction(function (w, h)
				draw.Box(0,0,w,h,"323232")
			end)

			function pnlText:DoClick()
				WORKSPACE:SetMod(MOD)
				pnlContent:Remove()
			end
		end
	end

	function WORKSPACE:SetModeByName(modName)
		local MOD = map_edit_mods.GetCopy(modName)

		WORKSPACE:SetMod(MOD)
	end

	if !map_edit.ACTIVE_WORKSPACE then
		WORKSPACE:OnEnabled()
	end
end

function map_edit.CleanupMenu()
	map_edit.ACTIVE_WORKSPACE = nil
end


function map_edit.OpenMainEditor()
	gui.EnableScreenClicker(true)

	if GetConVar("developer"):GetInt() >= 1 then
		if IsValid(map_edit.pnlMainEditor) then
			map_edit.pnlMainEditor:Remove()
			map_edit.CleanupMenu()
		end
	else
		if IsValid(map_edit.pnlMainEditor) then
			map_edit.pnlMainEditor:SetVisible(true)
			return
		end
	end

	map_edit.INFO = {}
	local INFO = map_edit.INFO

	map_edit.WORKSPACES =  {}


	map_edit.pnlMainEditor = gui.Create("zpanelbase")
	function map_edit.pnlMainEditor:PaintOnce(w, h)
		draw.Box(0,0,w, h, "181818")
	end

	map_edit.pnlMainEditor:SetSize(ScrW(), ScrH())
	local pnlFrame = map_edit.pnlMainEditor
	-- pnlFrame:SFill()

	INFO.pnlUpper = gui.Create("zpanelbase",  pnlFrame)
	INFO.pnlUpper:DockMargin(5,2,5,2)
	INFO.pnlUpper:SDock(TOP,40)

	INFO.pnlWorkshopHolder = gui.Create("zpanelbase", pnlFrame)

	INFO.pnlWorkshopHolder:DockMargin(5,0,5,5)
	INFO.pnlWorkshopHolder:SFill()

	---@param text string
	---@param doClick fun()?
	---@param zpos number?
	function INFO.AddHeaderButton(text, doClick, zpos)
		local pnlHeaderButton = gui.Create("zpanelbase", INFO.pnlUpper)

		local text_width = ui.GetTextSize(text, "14:DejaVu Sans")

		pnlHeaderButton:SetMouseInputEnabled(true)
		pnlHeaderButton:DockMargin(5,2,2,2)

		function pnlHeaderButton:PaintOnce(w, h)
			draw.BoxRoundedEx(2, 0,0, w, h, "1d1d1d", true, true, true, true)

			if self:IsHovered() then
				draw.BoxRoundedEx(2, 0, 0, w, h, "303030", true, true, true, true)
			end

			draw.Text(text, "14:DejaVu Sans", w/2, h/2, color_white, 1, 1)
		end

		pnlHeaderButton:SetCursor("hand")
		pnlHeaderButton:SDock(LEFT, text_width + 15)

		if zpos then
			pnlHeaderButton:SetZPos(999)
		end

		function pnlHeaderButton:DoClick()
			if type(doClick) == "function" then
				doClick()
			end
		end

		return pnlHeaderButton
	end

	function INFO.AddContentPanel()
		local pnlContent = gui.Create("zpanelbase",  INFO.pnlWorkshopHolder)

		function pnlContent:PaintOnce(w, h)
			draw.BoxRoundedEx(4, 0, 0, w, h, "353535", true, true, true ,true)
		end
		pnlContent:SFill()

		pnlContent:Hide()

		return pnlContent
	end

	INFO.AddHeaderButton("+", function()
		map_edit.CreateWorkspace("New workspace")
	end, 999)

	local closeBut = INFO.AddHeaderButton("X", function()
		map_edit.OnDisabled()
	end, 999)
	closeBut:SDock(RIGHT)

	map_edit.LoadWorkspaces()
end

function map_edit.LoadWorkspaces()
	map_edit.CreateWorkspace("Overview", {defaultMod = "view"})
	map_edit.CreateWorkspace("Essentials", {defaultMod = "essentials"})
	map_edit.CreateWorkspace("Particle View", {defaultMod = "particle_view"})
end

function map_edit.CloseMainEditor()
	if GetConVar("developer"):GetInt() >= 1 then
		if IsValid(map_edit.pnlMainEditor) then
			map_edit.pnlMainEditor:Remove()
			map_edit.CleanupMenu()
		end
	else
		if IsValid(map_edit.pnlMainEditor) then
			map_edit.pnlMainEditor:SetVisible(false)
		end
	end

	gui.EnableScreenClicker(false)
end

function map_edit.OnEnabled()
	map_edit.SetupViewData()

	if ConVar_Ment then
		for convar, string_value in pairs(ConVar_Ment) do
			map_edit.mt_ConVarSaved[convar] = cvars.String(convar, "")
			map_edit.SetConvarValue(convar, string_value)
		end
	end

	for k, val in pairs(HookStateMent) do
		local func = val and map_edit.ReturnTrue or map_edit.ReturnFalse
		ihook.Handler(k, map_edit.hookName, func, HOOK_HIGH)
		map_edit.mt_HookCreated[k] = true
	end


	ihook.Handler("CalcView", map_edit.hookName, map_edit.CalcView, HOOK_HIGH)
	ihook.Handler("StartCommand", map_edit.hookName, map_edit.StartCommand, HOOK_HIGH)
	ihook.Handler("Render", map_edit.hookName, map_edit.Render, HOOK_HIGH)

	map_edit.ScrW = map_edit.ScrW or ScrW()
	map_edit.ScrH = map_edit.ScrH or ScrH()

	-- render.SetViewPort(-1, -1, 100, 100)

	-- local customRt = GetRenderTarget( "some_unique_render_target_nameeeee", 1000, 500, true )

	-- render.SetRenderTarget(customRt)


	ihook.Run("zen.map_edit.OnEnabled")

	nt.Send("map_edit.status", {"bool"}, {true})

	map_edit.OpenMainEditor()
end


function map_edit.OnDisabled()
	for k, val in pairs(map_edit.mt_HookCreated) do
		ihook.Remove(k, map_edit.hookName)
	end

	-- render.SetViewPort(-1, -1, -1, -1)
	-- render.SetRenderTarget()

	ihook.Remove("CalcView", map_edit.hookName)
	ihook.Remove("StartCommand", map_edit.hookName)
	ihook.Remove("Render", map_edit.hookName)


	ihook.Run("zen.map_edit.OnDisabled")


	nt.Send("map_edit.status", {"bool"}, {false})

	if map_edit.mt_ConVarSaved then
		for convar, string_value in pairs(map_edit.mt_ConVarSaved) do
			map_edit.SetConvarValue(convar, string_value)

		end
	end

	map_edit.CloseMainEditor()
end

function map_edit.Toggle()
	map_edit.IsActive = not map_edit.IsActive

	if not map_edit.IsActive then
		map_edit.OnDisabled()

		return
	end

	if not LocalPlayer():zen_HasPerm("map_edit") then return end

	map_edit.OnEnabled()
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


	local bPreventMouseMove = ihook.Run("map_edit.MouseMove", add_x, add_y)
	local bPreventButtonMove = ihook.Run("map_edit.ButtonMove")

	local isMoveActive = !vgui.CursorVisible() and !bPreventButtonMove

	do -- MouseMove
		if !bPreventMouseMove then

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
		end
	end

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

ihook.Handler("PlayerButtonPress", "zen.map_edit", function(ply, but, in_key, bind_name, char, isKeyFree)
	if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_LALT) and but == KEY_APOSTROPHE then
		map_edit.Toggle()
	end

	if not map_edit.IsActive then return end
	ihook.Run("zen.map_edit.OnButtonPress", ply, but, in_key, bind_name, char, isKeyFree)

	if map_edit.ACTIVE_WORKSPACE and type(map_edit.ACTIVE_WORKSPACE.OnButtonPress) == "function" then
		map_edit.ACTIVE_WORKSPACE:OnButtonPress(ply, but, in_key, bind_name, char, isKeyFree)
	end

	return true
end)

ihook.Handler("PlayerButtonUnPress", "zen.map_edit", function(ply, but, in_key, bind_name, char, isKeyFree)
	if not map_edit.IsActive then return end

	ihook.Run("zen.map_edit.OnButtonUnPress", ply, but, in_key, bind_name, char, isKeyFree)

	if map_edit.ACTIVE_WORKSPACE and type(map_edit.ACTIVE_WORKSPACE.OnButtonUnPress) == "function" then
		map_edit.ACTIVE_WORKSPACE:OnButtonUnPress(ply, but, in_key, bind_name, char, isKeyFree)
	end

	return true
end)



local IsVisible = META.PANEL.IsVisible
ihook.Listen("zen.map_edit.OnEnabled", "Fix mouse focus", function()
	map_edit.mt_HidenPanels = {}
	ihook.Listen("Think", "zen_KillPanelsVisibility", function()
		local WorldPanel = vgui.GetWorldPanel()

		for k, pnl in pairs(WorldPanel:GetChildren()) do
			if !IsValid(pnl) then continue end
			if pnl.zenCreated or pnl.zenSecure then continue end
			if !IsVisible(pnl) then continue end

			map_edit.mt_HidenPanels[pnl] = true
			pnl:SetVisible(false)
			pnl:KillFocus()
		end

		local HUDPanel = GetHUDPanel()
		HUDPanel:SetVisible(false)
		HUDPanel:KillFocus()
	end)

	gui.EnableScreenClicker(false)
end)

ihook.Listen("zen.map_edit.OnDisabled", "Fix mouse focus", function()
	ihook.Remove("Think", "zen_KillPanelsVisibility")
	GetHUDPanel():SetVisible(true)
	if istable(map_edit.mt_HidenPanels) then
		for pnl in pairs(map_edit.mt_HidenPanels) do
			if !IsValid(pnl) then continue end
			pnl:SetVisible(true)
		end
	end
end)
