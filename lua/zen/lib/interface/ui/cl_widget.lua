module("zen", package.seeall)

widget = _GET("widget")

local GetViewSetup = render.GetViewSetup
local AimVector = util.AimVector
local CursorPos = input.GetCursorPos
local IntersectRayWithPlane = util.IntersectRayWithPlane

local VECTOR = FindMetaTable("Vector")
local ANGLE = FindMetaTable("Angle")
local MATRIX = FindMetaTable("VMatrix")

local Vector_Dot = VECTOR.Dot
local Angle_Forward = ANGLE.Forward
local Angle_Right = ANGLE.Right
local Angle_Up = ANGLE.Up

local Matrix = Matrix
local Matrix_Translate = MATRIX.Translate
local Matrix_Scale = MATRIX.Scale

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
