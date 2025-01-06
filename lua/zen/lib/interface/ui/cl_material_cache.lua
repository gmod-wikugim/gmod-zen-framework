module("zen")

---@class zen.material_cache
material_cache = _GET("material_cache")

local GetViewSetup = render.GetViewSetup
local AimVector = util.AimVector
local CursorPos = input.GetCursorPos
local IntersectRayWithPlane = util.IntersectRayWithPlane

local VECTOR = FindMetaTable("Vector")
local ANGLE = FindMetaTable("Angle")

local Vector_Dot = VECTOR.Dot
local Angle_Forward = ANGLE.Forward
local Angle_Right = ANGLE.Right
local Angle_Up = ANGLE.Up

--- Return cursor pos for Matrix
---@param Mat VMatrix
---@return boolean Visibility, number CursorX, number CursorY
function material_cache.GetCursorMatrix(Mat, useCursor)
    local view = GetViewSetup()

    local rayPosition = view.origin
    local rayAngles = view.angles

    local rayDirection
    if useCursor then
        local cx, cy = CursorPos()
        rayDirection = AimVector(rayAngles, view.fov, cx, cy, view.width, view.height)
    else
        rayDirection = Angle_Forward(rayAngles)
    end

    local MatrixAngles = Mat:GetAngles()

    local planePosition = Mat:GetTranslation()
    local planeNormal = Angle_Up(MatrixAngles)

    local vecIntersect = IntersectRayWithPlane(rayPosition, rayDirection, planePosition, planeNormal)

    if !vecIntersect then return false, 0, 0 end

    local diff = (vecIntersect - planePosition)

    local xx = Vector_Dot(diff, Angle_Forward(MatrixAngles))
    local yy = Vector_Dot(diff, Angle_Right(MatrixAngles))

    local MatrixScale = Mat:GetScale()

    assert(MatrixScale.x != 0, "MatrixScale.x == 0")
    assert(MatrixScale.y != 0, "MatrixScale.y == 0")
    assert(MatrixScale.z != 0, "MatrixScale.z == 0")

    local CX = xx * (1/MatrixScale.x)
    local CY = yy * -(1/MatrixScale.y)

    return true, CX, CY
end

--- Return cursor position for current view Matrix
---@param useCursor boolean
---@return boolean Visibility, number CursorX, number CursorY
function material_cache.GetCurrentMatrixCursor(useCursor)
    local Matrix = cam.GetModelMatrix()

    return material_cache.GetCursorMatrix(Matrix, useCursor)
end

--- Return cursor position for 3d2d
---@param pos Vector
---@param ang Angle
---@param size number
---@param useCursor boolean
---@return boolean Visibility, number CursorX, number CursorY
function material_cache.GetCursor3D2D(pos, ang, size, useCursor)
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
		local newy = yy*-scale

		return true, newx, newy
	else
		return false, 0, 0
	end
end


material_cache.iMatCounter = material_cache.iMatCounter or 0


--- Generate Material from draw_func and mask_func
---@param width number
---@param height number
---@param draw_func fun(w: number, h:number)
---@param mask_func fun(w:number, h:number)?
---@return IMaterial Material, string PNG, number width, number height
/*
    ```
    ---> Example usage: Generate box with text as material
    local mat_result = material_cache.Generate2DMaterial(512, 512, 
    function(w, h)
        surface.SetDrawColor(255,255,255)
        surface.DrawRect(0,0,w,h)

        draw.SimpleText("Hello World", "Roboto", w/2, h/2, color_white, 1, 1)
    end)

    ---> Example usage: Generate box with text as material and cut this to 50%
    local mat_result = material_cache.Generate2DMaterial(512, 512, 
    function(w, h)
        surface.SetDrawColor(255,255,255)
        surface.DrawRect(0,0,w,h)

        draw.SimpleText("Hello World", "Roboto", w/2, h/2, color_white, 1, 1)
    end,
    function(w,h)
        surface.SetDrawColor(255,255,255)
        surface.DrawRect(0,0,w/2,0)
    end)
*/

function material_cache.Generate2DMaterial(width, height, draw_func, mask_func, bCapturePNG, texture_name)
    assert(type(texture_name) == "string" or texture_name == nil, "texture_name not is string")

    if texture_name == nil then
        material_cache.iMatCounter = material_cache.iMatCounter + 1
        texture_name = "material_cache/auto_generated/" .. material_cache.iMatCounter
    end

    -- local texture = GetRenderTarget(texture_name, width, height)
    -- local texture = GetRenderTargetEx(texture_name, width, height, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 1 + 256, 0, IMAGE_FORMAT_BGRA8888)
    local texture = GetRenderTargetEx(texture_name,
        width, height,
        RT_SIZE_NO_CHANGE, -- Just no touch anything
        MATERIAL_RT_DEPTH_SHARED, -- Alpha use multiply alpha object. If any bags then change to --> MATERIAL_RT_DEPTH_SEPARATE --> MATERIAL_RT_DEPTH_ONLY
        1 + 256, -- Best Combo to enable high-equility screenshot
        0, -- Dont tested
        IMAGE_FORMAT_RGBA16161616 -- Allow use more colors in game. Default game colors is restricted!
    )

    render.PushRenderTarget(texture)

    render.Clear(0, 0, 0, 0, true, true)
        cam.Start2D()


            if mask_func then
                stencil_cut.StartStencil()
                stencil_cut.FilterStencil(mask_func, width, height)
            end
            draw_func(width, height)

            if mask_func then
                stencil_cut.EndStencil()
            end
        cam.End2D()


        local PNG
        if bCapturePNG then
            PNG = render.Capture{
                format = "png",
                w = width,
                h = height,
                quality = 100,
                x = 0,
                y = 0
            }
        end

    render.PopRenderTarget()

	local result_material = CreateMaterial(texture_name, "UnlitGeneric", {
        ["$basetexture"] = texture_name,
        ["$translucent"] = 1,        // Set to "1" if you want it to be translucent
        ["$vertexcolor"] = 1,        // Use vertex colors if needed
        ["$vertexalpha"] = 1,        // Use vertex alpha if needed
        -- ["$nolod"] = 1,              // Prevents LOD issues
        -- ["$ignorez"] = 1,
        -- ["$nomip"] = 1,
        -- ["$additive"] = 0,
        -- ["$nocull"] = 1,
        -- ["$model"] = 1,
	})

    return result_material, PNG, width, height
end



--- Generate new material with text
---@param text string
---@param font string
---@param color Color
---@param color_bg Color
/*
    ```
    --> Example usage. Generate material with server rules
    local SERVER_RULES = [[
    1. Don't be a duck
    2. Don't be a dog
    ]]

    local mat_rules = material_cache.GenerateTextAsMaterial(SERVER_RULES, "Roboto", color_white, color_black)
*/
function material_cache.GenerateTextAsMaterial(text, font, color, color_bg)
    surface.SetFont(font)
    local text_width, text_height = surface.GetTextSize(text)

    local text_material = material_cache.Generate2DMaterial(text_width, text_height, function()
        surface.SetFont(font)

        if color_bg then
			local bg_out = text_height * 0.04
            surface.SetTextPos(bg_out, bg_out)
            surface.SetTextColor(color_bg)
            surface.DrawText(text)
        end

        surface.SetTextPos(0, 0)
        surface.SetTextColor(color)
        surface.DrawText(text)
    end)

	return text_material
end







--- Generate new material from another materialIndex and cut it
/*
    ```
    --> Example usage. Cut 10 pixels from each side
    local mat_white = Material("debug/white")
    local mat_white_cut = material_cache.CutMaterial(mat_white, function(w, h)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawRect(10, 10, w-20, h-20)
    end)
*/
---@param mat_base IMaterial
---@param mask_func fun(w: number, h:number)
---@return IMaterial
function material_cache.CutMaterial(mat_base, mask_func)

    local mat = material_cache.Generate2DMaterial(512, 512, function(w, h)
        surface.SetMaterial(mat_base)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect(0, 0, w, h)
    end, mask_func)

    return mat
end


