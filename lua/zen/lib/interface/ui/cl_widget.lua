module("zen")

---@class zen.widget
widget = _GET("widget")

local GetViewSetup = render.GetViewSetup
local AimVector = util.AimVector
local CursorPos = input.GetCursorPos
local IntersectRayWithPlane = util.IntersectRayWithPlane

local VECTOR = FindMetaTable("Vector") --[[@class Vector]]
local ANGLE = FindMetaTable("Angle") --[[@class Angle]]
local MATRIX = FindMetaTable("VMatrix") --[[@class VMatrix]]

local Vector_Dot = VECTOR.Dot
local Angle_Forward = ANGLE.Forward
local Angle_Right = ANGLE.Right
local Angle_Up = ANGLE.Up

local Matrix = Matrix
local Matrix_Translate = MATRIX.Translate
local Matrix_Scale = MATRIX.Scale

local Vector = Vector

local cam_PushModelMatrix = cam.PushModelMatrix
local cam_PopModelMatrix = cam.PopModelMatrix


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

function widget.DrawTextLimited(text, font, x, y, w, h, color, xalign, yalign, color_bg)
	local tw, _ = ui.GetTextSize(text, font)
	local scaling = (w-10)/tw
	if scaling > 1 then
		scaling = 1
	end

	local m = Matrix()
	Matrix_Translate(m, Vector( x, y, 0 ) )
	Matrix_Translate(m, Vector( w / 2, h / 2, 0 ) )
	Matrix_Scale(m, Vector(scaling,scaling,0) )

	cam_PushModelMatrix( m, true )
		if color_bg then
			ui.DrawTextShadowed(text, font, 0, 0, color, xalign, yalign, color_bg)
		else
			ui.DrawText(text, font, 0, 0, color, xalign, yalign)
		end
	cam_PopModelMatrix()
end


local PANEL = FindMetaTable("Panel") --[[@class Panel]]

local Panel_LocalToScreen = PANEL.LocalToScreen
local Panel_GetSize = PANEL.GetSize

local surface_DrawRect = surface.DrawRect
local surface_DrawText = surface.DrawText
local surface_GetTextSize = surface.GetTextSize
local surface_SetDrawColor = surface.SetDrawColor
local surface_SetFont = surface.SetFont
local surface_SetTextColor = surface.SetTextColor
local surface_SetTextPos = surface.SetTextPos

local DisableClipping = DisableClipping
local TEXT_ALIGN_CENTER = TEXT_ALIGN_CENTER
local TEXT_ALIGN_RIGHT = TEXT_ALIGN_RIGHT
local TEXT_ALIGN_BOTTOM = TEXT_ALIGN_BOTTOM

local render_PushFilterMin = render.PushFilterMin
local render_PushFilterMag = render.PushFilterMag
local render_PopFilterMin = render.PopFilterMin
local render_PopFilterMag = render.PopFilterMag



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

    surface_SetTextColor(color_bg)
    surface_SetTextPos(x + 1.5, y + 1.5)
    surface_DrawText(text)

    surface_SetTextColor(color)
    surface_SetTextPos(x, y)
    surface_DrawText(text)
end


local function GetTextSize(text, font)
    surface_SetFont(font)
    return surface_GetTextSize(text)
end

local function _DrawTextScaleInPanel(panel, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping)
	local panelX, panelY = Panel_LocalToScreen(panel, x, y)

	-- time to draw our matrix
	local m = Matrix()
	local position = Vector( panelX, panelY, 0 )

	Matrix_Translate(m, position )
	Matrix_Scale(m, Vector(x_scale, y_scale, 0))
	Matrix_Translate(m, -position )

	if disable_clipping then DisableClipping(true) end
	render_PushFilterMin(3)
	render_PushFilterMag(3)
	cam_PushModelMatrix( m)
		if color_bg then
			DrawTextShadowed(text, font, x, y, color, xalign, yalign, color_bg)
		else
			DrawText(text, font, x, y, color, xalign, yalign)
		end
	cam_PopModelMatrix()
	render_PopFilterMin()
	render_PopFilterMag()
	if disable_clipping then DisableClipping(false) end
end

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

	if stenctil_cut_panel then
		stencil_cut_DrawWithSimpleMask(function()
			_DrawTextScaleInPanel(panel, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping)
		end, function()
			local panelW, panelH = Panel_GetSize(panel)
			surface_SetDrawColor(255, 255, 255, 255)
			surface_DrawRect(0, 0, panelW, panelH)
		end)
	else
		_DrawTextScaleInPanel(panel, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping)
	end

end
local DrawTextScaledInPanel = widget.DrawTextScaledInPanel


-- Draw text in a panel, limited to a certain width and height, scale down when width or height not fit
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
function widget.DrawTextScaledLimitInPanel(panel, text, font, x, y, w, h, color, xalign, yalign, color_bg, disable_clipping, stenctil_cut_panel)
	local tw, th = GetTextSize(text, font)

	local x_scale = (tw > w) and (w / tw) or 1
	local y_scale = (th > h) and (h / th) or 1

	DrawTextScaledInPanel(panel, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping, stenctil_cut_panel)
end

-- Draw text in a panel, limited to a certain width and height, automatically scaling to fit both width and height
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
function widget.DrawTextScaledSmartLimitInPanel(panel, text, font, x, y, w, h, color, xalign, yalign, color_bg, disable_clipping, stenctil_cut_panel)
	local tw, th = GetTextSize(text, font)

	local x_scale = math.min(w/h, h/w, (w / tw), (h / th))
	local y_scale = x_scale

	DrawTextScaledInPanel(panel, text, font, x, y, color, xalign, yalign, color_bg, x_scale, y_scale, disable_clipping, stenctil_cut_panel)
end