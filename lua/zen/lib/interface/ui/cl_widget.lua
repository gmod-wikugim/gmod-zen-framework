module("zen")

widget = _GET("widget") --[[@class zen.widget]]

local MATRIX = FindMetaTable("VMatrix") --[[@class VMatrix]]
local PANEL = FindMetaTable("Panel") --[[@class Panel]]

local Panel_LocalToScreen = PANEL.LocalToScreen
local Panel_GetSize = PANEL.GetSize

local Matrix = Matrix
local Matrix_Translate = MATRIX.Translate
local Matrix_Scale = MATRIX.Scale

local cam_PushModelMatrix = cam.PushModelMatrix
local cam_PopModelMatrix = cam.PopModelMatrix

local surface_SetFont = surface.SetFont
local surface_GetTextSize = surface.GetTextSize
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos
local surface_DrawText = surface.DrawText
local surface_SetMaterial = surface.SetMaterial


local DisableClipping = DisableClipping
local Vector = Vector
local Matrix = Matrix
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
local TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM

local render_PushFilterMin = render.PushFilterMin
local render_PushFilterMag = render.PushFilterMag
local render_PopFilterMin = render.PopFilterMin
local render_PopFilterMag = render.PopFilterMag

local surface_SetDrawColor = surface.SetDrawColor
local surface_DrawRect = surface.DrawRect
local surface_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local surface_DrawOutlinedRect = surface.DrawOutlinedRect


local function GetBestScale(tw, th, w, h)
	local w_scale = tw > w and math.min(tw/w, w/tw) or 1
	local h_scale = th > h and math.min(th/h, h/th) or 1

	local scale = math.min(w_scale, h_scale)

	return scale
end



local function StartMatrix(x, y, scale, multiplyMatrix)
	if multiplyMatrix == nil then multiplyMatrix = true end

	-- time to draw our matrix
	local m = Matrix()

	Matrix_Translate(m, Vector( x, y, 0 ) )
	Matrix_Scale(m, Vector(scale, scale, 0))
	Matrix_Translate(m,  Vector(-x , -y, 0))

	render_PushFilterMin(3)
	render_PushFilterMag(3)
	cam_PushModelMatrix( m, multiplyMatrix)
end

local function EndMatrix()
	cam_PopModelMatrix()
	render_PopFilterMin()
	render_PopFilterMag()
end


local function ApplyPanelTextMargin(panel, x, y, w, h, xalign, yalign)
	local tm = panel["TextMargin"]
	if tm then
		w = w - tm[3] - tm[1]

		if ( xalign == TEXT_ALIGN_CENTER ) then
			x = x + tm[1]/2 - tm[3]/2
		elseif ( xalign == TEXT_ALIGN_RIGHT ) then
			x = w + tm[1]
		else
        	x = x + tm[1]
		end

		if ( yalign == TEXT_ALIGN_CENTER ) then
			y = y + tm[2]/2 - tm[4]/2
		elseif ( yalign == TEXT_ALIGN_BOTTOM ) then
			y = y - tm[2] - tm[4]
		else
			y = y + tm[2] + tm[4]
		end
		h = h - tm[4] - tm[2]
    end

	return tm, x, y, w, h
end

local function DrawText(text, font, x, y, color, xalign, yalign)
    surface_SetFont(font)
    surface_SetTextColor(color)
    local w, h = surface_GetTextSize(text)

	if ( xalign == TEXT_ALIGN_CENTER ) then
		x = x - w / 2
	elseif ( xalign == TEXT_ALIGN_RIGHT ) then
		x = x - w
	end

	if ( yalign == TEXT_ALIGN_CENTER ) then
		y = y - h / 2
	elseif ( yalign == TEXT_ALIGN_BOTTOM ) then
		y = y - h
	end

    surface_SetTextPos(x, y)
    surface_DrawText(text)

	return w, h
end

local function DrawTextShadowed(text, font, x, y, color, xalign, yalign, color_bg)
    surface_SetFont(font)
    local w, h = surface_GetTextSize(text)

	if ( xalign == TEXT_ALIGN_CENTER ) then
		x = x - w / 2
	elseif ( xalign == TEXT_ALIGN_RIGHT ) then
		x = x - w
	end

	if ( yalign == TEXT_ALIGN_CENTER ) then
		y = y - h / 2
	elseif ( yalign == TEXT_ALIGN_BOTTOM ) then
		y = y - h
	end

	if color_bg then
		surface_SetTextColor(color_bg)
		surface_SetTextPos(x + 1.5, y + 1.5)
		surface_DrawText(text)
	end

    surface_SetTextColor(color)
    surface_SetTextPos(x, y)
    surface_DrawText(text)

	return w, h
end


local function GetTextSize(text, font, x_scale, y_scale)
	x_scale = x_scale or 1
	y_scale = y_scale or 1

    surface_SetFont(font)
    local tw, th = surface_GetTextSize(text)
	return tw * x_scale, th * y_scale
end

local function _DrawTextScaled(multiply, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping)

	if multiply == nil then multiply = true end

	-- time to draw our matrix
	local m = Matrix()

	Matrix_Translate(m, Vector( x, y, 0 ) )
	Matrix_Scale(m, Vector(x_scale, y_scale, 0))
	Matrix_Translate(m,  Vector(-x , -y, 0))

	local tw, th

	local oldDisableClipping
	if disable_clipping then oldDisableClipping = DisableClipping(true) end
	render_PushFilterMin(3)
	render_PushFilterMag(3)
	cam_PushModelMatrix( m, multiply)
		if color_bg then
			tw, th = DrawTextShadowed(text, font, x, y, color, xalign, yalign, color_bg)
		else
			tw, th = DrawText(text, font, x, y, color, xalign, yalign)
		end
	cam_PopModelMatrix()
	render_PopFilterMin()
	render_PopFilterMag()
	if disable_clipping then DisableClipping(oldDisableClipping) end

	return tw * x_scale, th * y_scale
end


local function _DrawTextScaleInPanel(panel, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping)
	local panelX, panelY = Panel_LocalToScreen(panel, x, y)

	-- time to draw our matrix
	local m = Matrix()
	local position = Vector( panelX, panelY, 0 )

	Matrix_Translate(m, position )
	Matrix_Scale(m, Vector(x_scale, y_scale, 0))
	Matrix_Translate(m, -position )

	local tw, th

	local oldDisableClipping
	if disable_clipping then oldDisableClipping = DisableClipping(true) end
	render_PushFilterMin(3)
	render_PushFilterMag(3)
	cam_PushModelMatrix( m)
		if color_bg then
			tw, th = DrawTextShadowed(text, font, x, y, color, xalign, yalign, color_bg)
		else
			tw, th = DrawText(text, font, x, y, color, xalign, yalign)
		end
	cam_PopModelMatrix()
	render_PopFilterMin()
	render_PopFilterMag()
	if disable_clipping then DisableClipping(oldDisableClipping) end

	return tw, th
end

local DEBUG = CreateClientConVar("debug_widget_text", 0, false, nil, "Draw text bounds for widget", 0, 1)

local DEBUGING = DEBUG:GetBool()

cvars.AddChangeCallback("debug_widget_text", function (convar, oldValue, newValue)
	DEBUGING = tobool(newValue)
end)


local stencil_cut_DrawWithSimpleMask = stencil_cut.DrawWithSimpleMask

-- Draw scaled text in a panel
---@param panel Panel
---@param text string
---@param font string
---@param x number
---@param y number
---@param color Color
---@param xalign number?
---@param yalign number?
---@param color_bg Color?
---@param x_scale number
---@param y_scale number
---@param disable_clipping boolean?
---@param stenctil_cut_panel boolean? -- If set, will use panel bounds for stencil cutting
function widget.DrawTextScaledInPanel(panel, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping, stenctil_cut_panel)

	local tw, th
	if stenctil_cut_panel then
		stencil_cut_DrawWithSimpleMask(function()
			tw, th = _DrawTextScaleInPanel(panel, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping)
		end, function()
			local panelW, panelH = Panel_GetSize(panel)
			surface_SetDrawColor(255, 255, 255, 255)
			surface_DrawRect(0, 0, panelW, panelH)
		end)
	else
		tw, th = _DrawTextScaleInPanel(panel, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping)
	end

	return tw, th
end
local DrawTextScaledInPanel = widget.DrawTextScaledInPanel

local string_Explode = string.Explode

-- Draw text in a panel, limited to a certain width and height
---@param panel Panel
---@param text string
---@param font string
---@param x number
---@param y number
---@param w number
---@param h number
---@param color Color
---@param xalign number?
---@param yalign number?
---@param color_bg Color?
---@param disable_clipping boolean?
---@param stenctil_cut_panel boolean? -- If set, will use panel bounds for stencil cutting
---@param new_line boolean? -- If set, will break text into multiple lines to fit width
function widget.DrawTextScaledLimitInPanel(panel, text, font, x, y, w, h, color, xalign, yalign, color_bg, disable_clipping, stenctil_cut_panel, new_line)
	local tw, th = GetTextSize(text, font)

	local x_scale = (tw > w) and (w / tw) or 1
	local y_scale = (th > h) and (h / th) or 1

	if new_line then
		local lines = string_Explode("\n", text)
		local line_height = th / #lines
		for i, line in ipairs(lines) do
			local line_y = y + (i - 1) * line_height * y_scale
			if line_y + line_height * y_scale > y + h then
				break
			end
			DrawTextScaledInPanel(panel, line, font, x, line_y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping, stenctil_cut_panel)
		end
	else
		DrawTextScaledInPanel(panel, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping, stenctil_cut_panel)
	end

	return tw, th
end

-- Draw text in a panel, limited to a certain width and height
---@param panel Panel
---@param text string
---@param font string
---@param x number
---@param y number
---@param w number
---@param h number
---@param color Color
---@param xalign number?
---@param yalign number?
---@param color_bg Color?
---@param disable_clipping boolean?
---@param stenctil_cut_panel boolean? -- If set, will use panel bounds for stencil cutting
---@param new_line boolean? -- If set, will break text into multiple lines to fit width
function widget.DrawTextScaledSmartLimitInPanel(panel, text, font, x, y, w, h, color, xalign, yalign, color_bg, disable_clipping, stenctil_cut_panel, new_line)
	local tw, th = GetTextSize(text, font)

	local tm, x, y, w, h = ApplyPanelTextMargin(panel, x, y, w, h, xalign, yalign)

	local scale = GetBestScale(tw, th, w, h)


	if DEBUGING then
		local ex, ey = x, y

		if ( xalign == TEXT_ALIGN_CENTER ) then
			ex = x - w / 2
		elseif ( xalign == TEXT_ALIGN_RIGHT ) then
			ex = x - w
		end

		if ( yalign == TEXT_ALIGN_CENTER ) then
			ey = y - h / 2
		elseif ( yalign == TEXT_ALIGN_BOTTOM ) then
			ey = y - h
		end

		if tm then
			surface.SetDrawColor(255,255,255,50)
			surface.DrawOutlinedRect(ex - tm[1], ey - tm[2], w + tm[3] + tm[1], h + tm[4] + tm[2])
		end

		draw.RoundedBox(0, ex, ey, w, h, Color(255,255,255,20))
	end

	if new_line then
		local lines = string_Explode("\n", text)
		local line_height = th / #lines
		for i, line in ipairs(lines) do
			local line_y = y + (i - 1) * line_height * scale
			if line_y + line_height * scale > y + h then
				break
			end
			DrawTextScaledInPanel(panel, line, font, x, line_y, color, xalign, yalign, color_bg, scale, scale, disable_clipping, stenctil_cut_panel)
		end
	else
		DrawTextScaledInPanel(panel, text, font, x, y, color, xalign, yalign, color_bg, scale, scale, disable_clipping, stenctil_cut_panel)
	end

	return tw, th
end

-- Draw scaled text on hud
---@param text string
---@param font string
---@param x number
---@param y number
---@param color Color
---@param xalign number?
---@param yalign number?
---@param color_bg Color?
---@param x_scale number
---@param y_scale number
---@param disable_clipping boolean?
function widget.DrawTextScaled(text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping)
	return _DrawTextScaled(nil, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping)
end

-- Draw text on hud, limited to a certain width and height
---@param text string
---@param font string
---@param x number
---@param y number
---@param w number
---@param h number
---@param color Color
---@param xalign number?
---@param yalign number?
---@param color_bg Color?
---@param disable_clipping boolean?
---@param new_line boolean? -- If set, will break text into multiple lines to fit width
function widget.DrawTextScaledSmart(text, font, x, y, w, h, color, xalign, yalign, color_bg, disable_clipping, new_line)
	local tw, th = GetTextSize(text, font)

	local w_scale = tw > w and math.min(tw/w, w/tw) or 1
	local h_scale = th > h and math.min(th/h, h/th) or 1

	local x_scale = math.min(w_scale, h_scale)

	local y_scale = x_scale


	if DEBUGING then
		local ex, ey = x, y

		if ( xalign == TEXT_ALIGN_CENTER ) then
			ex = x - w / 2
		elseif ( xalign == TEXT_ALIGN_RIGHT ) then
			ex = x - w
		end

		if ( yalign == TEXT_ALIGN_CENTER ) then
			ey = y - h / 2
		elseif ( yalign == TEXT_ALIGN_BOTTOM ) then
			ey = y - h
		end

		draw.RoundedBox(0, ex, ey, w, h, Color(255,255,255,20))
	end

	if new_line then
		local lines = string_Explode("\n", text)
		local line_height = th / #lines
		for i, line in ipairs(lines) do
			local line_y = y + (i - 1) * line_height * y_scale
			if line_y + line_height * y_scale > y + h then
				break
			end
			_DrawTextScaled( nil, line, font, x , line_y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping)
		end
	else
		_DrawTextScaled( nil, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping)
	end

	return tw, th
end

/*
hook.Add("HUDPaint", "widget.DebugTextBounds", function()
	if not DEBUGING then return end

	-- Just a test to see if it works
	widget.DrawTextScaledSmart("This is a test string.", "DermaDefault", 300, 200, 300, 100, Color(255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, Color(0,0,0))
end)
*/

-- -- Draw text on hud, limited to a certain width and height
-- ---@param text string
-- ---@param font string
-- ---@param x number
-- ---@param y number
-- ---@param w number
-- ---@param h number
-- ---@param color Color
-- ---@param xalign number?
-- ---@param yalign number?
-- ---@param color_bg Color?
-- ---@param disable_clipping boolean?
-- ---@param stenctil_cut_panel boolean? -- If set, will use panel bounds for stencil cutting
-- ---@param new_line boolean? -- If set, will break text into multiple lines to fit width
-- function widget.DrawTextScaled(text, font, x, y, w, h, color, xalign, yalign, color_bg, disable_clipping, stenctil_cut_panel, new_line)
-- 	return widget.DrawTextScaledSmartLimitInPanel(GetHUDPanel(), text, font, x, y, w, h, color, xalign, yalign, color_bg, disable_clipping, stenctil_cut_panel, new_line)
-- end


local GetViewSetup = render.GetViewSetup

local ANGLE = FindMetaTable("Angle") --[[@class Angle]]
local Angle_Forward = ANGLE.Forward
local Angle_Right = ANGLE.Right
local Angle_Up = ANGLE.Up

local AimVector = util.AimVector
local CursorPos = input.GetCursorPos
local IntersectRayWithPlane = util.IntersectRayWithPlane

local VECTOR = FindMetaTable("Vector") --[[@class Vector]]
local Vector_Dot = VECTOR.Dot




---@param pos Vector
---@param ang Angle
---@param size number
---@param useCursor boolean?
function widget.GetCursor3D2D(pos, ang, size, useCursor)
	local view = GetViewSetup()

	local scale = 1/size

	local eye_ang = view.angles
    local direction = Angle_Forward(eye_ang)

    if useCursor then
        local cx, cy = CursorPos()
        direction = AimVector(eye_ang, view.fov, cx, cy, view.width, view.height)
    end

	local res = IntersectRayWithPlane( view.origin, direction, pos, Angle_Up(ang) )

	if res then
		local diff = (res - pos)

		local xx = Vector_Dot(diff, Angle_Forward(ang))
		local yy = Vector_Dot(diff, Angle_Right(ang))


		local newx = xx*scale
		local newy = yy*scale

		return true, newx, newy
	else
		return false, 0, 0
	end
end



local function PrepareAdvanced(item_array, x, y, x_align, y_align)
	local FullWidth = 0
	local FullHeight = 0

	local LastTextHeight = 0

	local AddX = 0
	local AddY = 0

	for _, item in ipairs(item_array) do
		if item.type == "text" then
			local tw, th = GetTextSize(item.text, item.font, item.x_scale, item.y_scale)
			FullWidth = FullWidth + tw
			FullHeight = math.max(FullHeight, th)
			LastTextHeight = th

			item.DrawX = AddX
			item.DrawY = 0

			AddX = AddX + tw
		elseif item.type == "image" then
			local image_width = item.w or LastTextHeight or 15
			local image_height = item.h or LastTextHeight or 15
			FullWidth = FullWidth + image_width
			FullHeight = math.max(FullHeight, image_height)

			item.DrawX = AddX + image_width / 2
			item.DrawY = (LastTextHeight or 0)/2
			item.DrawW = image_width
			item.DrawH = image_height

			AddX = AddX + image_width
		end
	end

	-- Adjust starting x and y based on alignment
	if x_align == TEXT_ALIGN_CENTER then
		x = x - FullWidth / 2
	elseif x_align == TEXT_ALIGN_RIGHT then
		x = x - FullWidth
	end

	if y_align == TEXT_ALIGN_CENTER then
		y = y - FullHeight / 2
	elseif y_align == TEXT_ALIGN_BOTTOM then
		y = y - FullHeight
	end


	return x, y, FullWidth, FullHeight
end


local function DrawAdvanced(item_array, StartX, StartY)


	for _, item in ipairs(item_array) do
		if item.type == "text" then
			if DEBUGING then
				local tw, th = GetTextSize(item.text, item.font, item.x_scale, item.y_scale)
				surface_SetDrawColor(255, 255, 255, 50)
				surface_DrawRect(StartX + item.DrawX, StartY + item.DrawY, tw, th)
				surface_DrawOutlinedRect(StartX + item.DrawX, StartY + item.DrawY, tw, th)
			end

			DrawTextShadowed(item.text, item.font, StartX + item.DrawX, StartY + item.DrawY, item.color, nil, nil, item.color_bg)
		elseif item.type == "image" then
			if DEBUGING then
				surface_SetDrawColor(255, 255, 255, 50)
				surface_DrawRect(StartX + item.DrawX - item.DrawW / 2, StartY + item.DrawY - item.DrawH / 2, item.DrawW, item.DrawH)
				surface_DrawOutlinedRect(StartX + item.DrawX - item.DrawW / 2, StartY + item.DrawY - item.DrawH / 2, item.DrawW, item.DrawH)
			end

			surface_SetDrawColor(255, 255, 255, 255)
			surface_SetMaterial(item.material)
			surface_DrawTexturedRectRotated(StartX + item.DrawX, StartY + item.DrawY, item.DrawW, item.DrawH, 0)
		end
	end
end

function widget.DrawAdvanced(item_array, x, y, x_align, y_align)
	local StartX, StartY, FullWidth, FullHeight = PrepareAdvanced(item_array, x, y, x_align, y_align)

	DrawAdvanced(item_array, StartX, StartY)
end

function widget.DrawAdvancedInPanel(panel, item_array, x, y, x_align, y_align)
	local panelX, panelY = Panel_LocalToScreen(panel, x, y)

	widget.DrawAdvanced(item_array, x, y, x_align, y_align)
end

function widget.DrawSmartAdvanced(item_array, x, y, w, h, x_align, y_align, disable_clipping, multiplyMatrix)

	-- Calculate full width and height
	local StartX, StartY, FullWidth, FullHeight = PrepareAdvanced(item_array,x, y, x_align, y_align)

	local scale = GetBestScale(FullWidth, FullHeight, w, h)

	StartMatrix(x, y, scale, multiplyMatrix)

		local oldDisableClipping
		if disable_clipping then oldDisableClipping = DisableClipping(true) end
			DrawAdvanced(item_array, StartX, StartY)
		if disable_clipping then DisableClipping(oldDisableClipping) end

	EndMatrix()

end


function widget.DrawSmartAdvancedInPanel(panel, item_array, x, y, w, h, x_align, y_align, disable_clipping, multiplyMatrix)

	-- Calculate full width and height
	local panelX, panelY = Panel_LocalToScreen(panel, x, y)

	local x, y, FullWidth, FullHeight = PrepareAdvanced(item_array,x, y, x_align, y_align)

	local scale = GetBestScale(FullWidth, FullHeight, w, h)

	StartMatrix(panelX, panelY, scale, multiplyMatrix)

		local oldDisableClipping
		if disable_clipping then oldDisableClipping = DisableClipping(true) end
			DrawAdvanced(item_array, x, y)
		if disable_clipping then DisableClipping(oldDisableClipping) end

	EndMatrix()

end


/*
-- HUDPaint widget.DrawAdvanced
hook.Remove("HUDPaint", "widget.DrawAdvanced", function()
	-- Example usage
	widget.DrawAdvanced({
		{type="text", text="Hello, You are great ", font="es_cases.Font_Item_NPC_MenuTitle", x=10, y=10, color=Color(255,255,255), x_scale=1, y_scale=1},
		{type="image", material=Material("icon16/star.png")},
		-- {type="text", text=" Hello world ", font="es_cases.Font_Item_NPC_MenuTitle", x=10, y=10, color=Color(255,255,255), x_scale=1, y_scale=1},
	},
		200, 200, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER
	)
end)
*/

/*
-- HUDPaint widget.DrawSmartAdvanced
hook.Add("HUDPaint", "widget.DrawSmartAdvanced", function()
	-- Example usage
	widget.DrawSmartAdvanced({
		{type="text", text="Hello, You are great ", font="es_cases.Font_Item_NPC_MenuTitle", x=10, y=10, color=Color(255,255,255), x_scale=1, y_scale=1},
		{type="image", material=Material("icon16/star.png")},
		-- {type="text", text=" Hello world ", font="es_cases.Font_Item_NPC_MenuTitle", x=10, y=10, color=Color(255,255,255), x_scale=1, y_scale=1},
	},
		300, 300, 200, 100, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, true
	)
end)
*/