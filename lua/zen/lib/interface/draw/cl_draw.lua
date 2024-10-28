module("zen", package.seeall)

---@class zen.draw
draw = _GET("draw", draw)

local s_SetDrawColor = surface.SetDrawColor
local s_DrawRect = surface.DrawRect
local s_DrawText = surface.DrawText
local s_SetTextPos = surface.SetTextPos
local s_SetFont = surface.SetFont
local s_GetTextSize = surface.GetTextSize
local s_SetTextColor = surface.SetTextColor
local s_SetMaterial = surface.SetMaterial
local s_DrawTexturedRect = surface.DrawTexturedRect
local s_DrawTexturedRectRotated = surface.DrawTexturedRectRotated
local s_DrawLine = surface.DrawLine
local s_DrawPoly = surface.DrawPoly
local s_DrawOutlinedRect = surface.DrawOutlinedRect

local rad = math.rad
local sin = math.sin
local cos = math.cos
local math_ceil = math.ceil
local tostring = tostring
local math_pow = math.pow

local CVAR_GAMMA = GetConVar("mat_monitorgamma")

local function gammaCorrect(value, gamma)

    return math_pow(value, 1 / gamma)

end


-- Function to apply gamma correction to RGB values

local function applyGammaCorrection(r, g, b)

    -- Retrieve the gamma value from the console variable

    local gamma = CVAR_GAMMA:GetFloat()


    -- Normalize RGB values (0-255) to (0-1)

    r = r / 255

    g = g / 255

    b = b / 255


    -- Apply gamma correction

    r = gammaCorrect(r, gamma) * 255

    g = gammaCorrect(g, gamma) * 255

    b = gammaCorrect(b, gamma) * 255


    return r, g, b

end

local function applyGammaCorrectionColor(clr)
    clr.r, clr.g, clr.b, clr.a = applyGammaCorrection(clr.r, clr.g, clr.b)
end

function draw.Line(x1, y1, x2, y2, clr)
    if clr then
        s_SetDrawColor(clr.r, clr.g, clr.b, clr.a)
    else
        s_SetDrawColor(255, 255, 255, 255)
    end
    s_DrawLine(x1, y1, x2, y2)
end

function draw.Box(x, y, w, h, clr)
    if clr then
        s_SetDrawColor(clr.r, clr.g, clr.b, clr.a)
    else
        s_SetDrawColor(255, 255, 255, 255)
    end
    s_DrawRect(x, y, w, h)
end

function draw.BoxOutlined(t, x, y, w, h, clr)
    if clr then
        s_SetDrawColor(clr.r, clr.g, clr.b, clr.a)
    else
        s_SetDrawColor(255, 255, 255, 255)
    end
    s_DrawOutlinedRect(x, y, w, h, t)
end

function draw.Texture(mat, x, y, w, h, clr)
    if clr then
        s_SetDrawColor(clr.r, clr.g, clr.b, clr.a)
    else
        s_SetDrawColor(255, 255, 255, 255)
    end
    s_SetMaterial(mat)
    s_DrawTexturedRect(x, y, w, h)
end


local mat_pp_blue = Material("pp/motionblur")
function draw.Blur(x, y, w, h, alpha)
    s_SetDrawColor(255, 255, 255, alpha or 255)
    s_SetMaterial(mat_pp_blue)
    s_DrawTexturedRect(x, y, w, h)
end

function draw.WhiteBGAlpha(x, y, w, h, alpha)
    draw.NoTexture()
    s_SetDrawColor(255, 255, 255, alpha or 255)
    s_DrawTexturedRect(x, y, w, h)
end

function draw.TextureRotated(mat, rotate, x, y, w, h, clr)
    if clr then
        s_SetDrawColor(clr.r, clr.g, clr.b, clr.a)
    else
        s_SetDrawColor(255, 255, 255, 255)
    end
    s_SetMaterial(mat)
    s_DrawTexturedRectRotated(x, y, w, h, rotate)
end

function draw.Text(text, font, x, y, clr, xalign, yalign, clrbg)
	text	= tostring( text )
	font	= ui.ffont(font)
	x		= x			        or 0
	y		= y			        or 0
	xalign	= xalign	        or 0
	yalign	= yalign	        or 3

	s_SetFont( font )
	local w, h = s_GetTextSize( text )

    if xalign or yalign then
        if ( xalign == 1 ) then
            x = x - w / 2
        elseif ( xalign == 2 ) then
            x = x - w
        end

        if ( yalign == 1 ) then
            y = y - h / 2
        elseif ( yalign == 4 ) then
            y = y - h
        end

        x = math_ceil( x )
        y = math_ceil( y )
    end

    if clrbg then
        s_SetTextPos(x+1, y+1)
        s_SetTextColor( clrbg.r, clrbg.g, clrbg.b, clrbg.a )
        s_DrawText( text )
    end

    s_SetTextPos(x, y)

    if clr then
	    s_SetTextColor( clr.r, clr.g, clr.b, clr.a )
    else
        s_SetTextColor( 255, 255, 255, 255 )
    end

	s_DrawText( text )

	return w, h, x, y
end

function draw.TextArray_Size(data, inheritLast)
    return draw.TextArray(0,0, data, inheritLast, true)
end

function draw.TextArray(x, y, data, inheritLast, noDraw)
    local fw, fh = 0, 0
    local l_font, l_COLOR, l_ax, l_ay, l_xalign, l_yalign, l_COLORbg
    for k, v in ipairs(data) do
        local text, font, ax, ay, clr, xalign, yalign, clrbg = unpack(v)

        if inheritLast then
            l_font = font or l_font
            l_COLOR = clr or l_COLOR
            l_ax = ax or l_ax
            l_ay = l_ay or l_ay
            l_xalign = xalign or l_xalign
            l_yalign = yalign or l_yalign
            l_COLORbg = clrbg or l_COLORbg

            font = l_font
            clr = l_COLOR
            ax = l_ax
            ay = l_ay
            xalign = l_xalign
            yalign = l_yalign
            clrbg = l_COLORbg
        end

        local w, h = ui.GetTextSize(text, font)

        if k == 1 then y = y - h/2 end

        ax = ax or 0
        ay = ay or 0

        fw = math.max(fw, w+ax)
        fh = fh + h

        if text == nil or text == "" or noDraw then continue end

        y = (y + h/2)
        draw.Text(text, font, x+ax, y+ay, clr, xalign, yalign, clrbg)
        y = (y + h/2)
    end

    return fw, fh, x, y
end

function draw.TextN(text, font, x, y, clr, xalign, yalign, clrbg)
    local text_args = string.Explode("%c", text, true)
    local args_n = #text_args

    if args_n == 1 then
        draw.Text(text, font, x, y, clr, xalign, yalign, clrbg)
        return
    end


    local w, h = ui.GetTextSize(text, font)
    local addh = h/args_n
    for k, v in ipairs(text_args) do
        local ly = y - h/2 - addh/2 + addh*k
        draw.Text(v, font, x, ly, clr, xalign, yalign, clrbg)
    end

    return w, h, x, y
end

--[[
local tfTitle = {nil, 10, 0, 0, COLOR.G, TEXT_ALIGN_LEFT, 1, COLOR.BLACK}
local tfValue = {nil, 6, 20, 0, COLOR.W, TEXT_ALIGN_LEFT, 1, COLOR.BLACK}

ihook.Listen("HUDPaint", "test", function()
    
    draw.TextArray(100, 100, {
        tfTitle,
        {"Sucess"},
        tfValue,
        {"testing1"},
        {"testing2"},
        tfTitle,
        {"Fail"},
        tfValue,
        {"testing3"},
        {"testing4"},
        {"testing5"},
        {"testing6"},
        {"Ending", 10, 0, 0, COLOR.R, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, COLOR.BLACK}
    }, true)

    draw.TextArray(100, 80, {
        {"Start", 8, 0, 0, COLOR.G, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, COLOR.BLACK}
    })

end)
]]--

local mat_vgui_white = Material("vgui/white")
function draw.NoTexture()
    s_SetMaterial(mat_vgui_white)
end

function draw.DrawPoly(poly, clr, mat)
    if mat then
        s_SetMaterial(mat)
    else
        s_SetMaterial(mat_vgui_white)
    end

    if clr then
        s_SetDrawColor(clr.r,clr.g,clr.b,clr.a)
    else
        s_SetDrawColor(255, 255, 255, 255)
    end

    s_DrawPoly(poly)
end




function draw.Circle(x, y, radius, seg, clr, mat)
	local cir = {}

	table.insert(cir, {
		x = x,
		y = y,
        u = 0.5,
        v = 0.5,
	})

	for i = 0, seg do
		local a = rad((i / seg) * -360)

		table.insert(cir, {
			x = x + sin(a) * radius,
			y = y + cos(a) * radius,
            u = sin(a)/2+0.5,
            v = cos(a)/2+0.5
		})
	end

	local a = rad(0)

	table.insert(cir, {
		x = x + sin(a) * radius,
		y = y + cos(a) * radius,
        u = sin(a)/2+0.5,
        v = cos(a)/2+0.5
	})

    draw.DrawPoly(cir, clr, mat)
end

---@param radius number
---@param x number
---@param y number
---@param w number
---@param h number
---@param clr Color?
---@param tl boolean?
---@param tr boolean?
---@param bl boolean?
---@param br boolean?
function draw.BoxRoundedEx(radius, x, y, w, h, clr, tl, tr, bl, br)
    local poly = {}

    local pi = math.pi

    local function add_point(x, y)
        table.insert(poly, {x = x, y = y})
    end

    -- Left Middle
    add_point(x, y + h/2)

    -- Left Top
    if tl then
        add_point(x, y+radius)

        -- My Stuff

        for i = 1, 90 do
            local deg = i * pi / 180
            add_point(x + radius - math.sin(deg) * radius, y + radius - math.cos(deg) * radius)
        end

        -- End Stuff

        add_point(x + radius, y)

    else
        add_point(x, y)
    end


    -- Top Middle
    add_point(x + w/2, y)

    -- Top Right
    if tr then
        add_point(x + w - radius, y)

        for i = 1, 90 do
            local deg = i * pi / 180
            add_point(x + w - radius + math.sin(deg) * radius, y + radius - math.cos(deg) * radius)
        end

        add_point(x + w, y + radius)
    else
        add_point(x + w, y)
    end

    -- Right Middle
    add_point(x + w, y + h/2)

    -- Right Bottom
    if br then
        add_point(x + w, y + h - radius)

        for i = 1, 90 do
            local deg = i * pi / 180
            add_point(x + w - radius + math.sin(deg) * radius, y + h - radius + math.cos(deg) * radius)
        end

        add_point(x + w - radius, y + h)
    else
        add_point(x + w, y + h)
    end

    -- Bottom Middle
    add_point(x + w/2, y + h)

    -- Bottom Left
    if bl then
        add_point(x + radius, y + h)

        for i = 1, 90 do
            local deg = i * pi / 180
            add_point(x + radius - math.sin(deg) * radius, y + h - radius + math.cos(deg) * radius)
        end

        add_point(x, y + h - radius)
    else
        add_point(x, y + h)
    end

    -- draw.NoTexture()

    if clr then
        s_SetDrawColor(clr.r,clr.g,clr.b,clr.a)
    else
        s_SetDrawColor(255, 255, 255, 255)
    end

    surface.DrawPoly(poly)
end
