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

local function Correct1(r, g, b)
    r = r < 90 and (0.916 * r + 7.8252) or r
    g = g < 90 and (0.916 * g + 7.8252) or g
    b = b < 90 and (0.916 * b + 7.8252) or b
    return r, g, b
end

local tCorrectTable = {
    [0] = 0,   5,    8,   10,    12,   13,   14,  15, 16,
    17,   18,   19,  20,    21,   22,   22,  23,  24,
    25,   26,   27,   28,   28,   29,   30,  31,
    32,   33,   34,   35,   35,   36,   37,  38,
    39,   40,   41,   42,   42,   43,   44,  45,
    46,   47,   48,   49,   50,   51,   51,  52,
    53,   54,   55,   56,   57,   58,   59,  60,
    60,   61,   62,   63,   64,   65,   66,  67,
    68,   69,   70,   71,   72,   73,   73,  74,
    75,   76,   77,   78,   79,   80,   81,   82,
    83,   84,   85,   86,   87,   88,   88,   89,
    90,   91,   92,   93,   94,   95,   96,   97,
    98,   99,   100,  101,  102,  103,  104,  105,
    106,  107,  108,  109,  109,  111,  111,  113,
    113,  114,  115,  116,  117,  118,  119,  120,
    121,  122,  123,  124,  125,  126,  127,  128,
    129,  130,  131,  132,  133,  134,  135,  136,
    137,  138,  139,  140,  141,  142,  143,  144,
    145,  146,  147,  148,  149,  150,  151,  152,
    153,  154,  155,  156,  157,  157,  158,  159,
    160,  162,  163,  164,  165,  165,  167,  168,
    168,  170,  170,  172,  172,  174,  174,  176,
    177,  177,  178,  180,  181,  182,  183,  184,
    185,  186,  187,  188,  189,  190,  191,  192,
    193,  194,  195,  196,  197,  198,  199,  200,
    201,  202,  203,  204,  205,  206,  207,  208,
    209,  210,  211,  212,  213,  214,  215,  216,
    217,  218,  219,  220,  221,  222,  223,  224,
    225,  226,  227,  228,  229,  230,  231,  232,
    233,  234,  236,  237,  237,  238,  239,  241,
    242,  243,  244,  245,  246,  247,  248,  249,
    250,  251,  252,  253,  254,  255
}

local floor = math.floor

---@param r number
---@param g number
---@param b number
local function Correct2(r, g, b)
    r = floor(r)
    g = floor(g)
    b = floor(b)

    r = tCorrectTable[r]
    g = tCorrectTable[g]
    b = tCorrectTable[b]

    return r, g, b
end


local t_CacheHEX = {}
local function hexToRGBA(hex)
    local cached = t_CacheHEX[hex]
    if (cached != nil) then return unpack(cached) end

    -- Remove the '#' character if it exists
    hex = hex:gsub('#', '')

    -- Convert the hex color to RGBA
    local r, g, b, a = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), 255

    -- If the hex code includes an alpha value
    if #hex == 8 then
        a = tonumber(hex:sub(7, 8), 16)
    end

    t_CacheHEX[hex] = {r,g,b,a}

    return r, g, b, a
end


---@alias zColor
---| Color
---| string


---@param r number|Color|string
---@param b number?
---@param g number?
---@param a number?
local function SetDrawColor(r, g, b, a)
    if type(r) == "table" then
        g = r.r
        b = r.g
        a = r.a or 255
        r = r.r
        ---@cast r number
    elseif type(r) == "string" then
        r, g, b, a = hexToRGBA(r)
        ---@cast r number
    end

    a = a or 255
    assert(isnumber(r), "r is not number")
    assert(isnumber(g), "g is not number")
    assert(isnumber(b), "b is not number")
    assert(isnumber(a), "a is not number")

    -- r, g, b = Correct1(r, g, b)
    r, g, b = Correct2(r, g, b)

    -- r = gammaCorrect(r)
    -- g = gammaCorrect(g)
    -- b = gammaCorrect(b)

    s_SetDrawColor(r, g, b, a)
end
draw.SetDrawColor = SetDrawColor

function draw.Line(x1, y1, x2, y2, clr)
    if clr then
        SetDrawColor(clr.r, clr.g, clr.b, clr.a)
    else
        SetDrawColor(255, 255, 255, 255)
    end
    s_DrawLine(x1, y1, x2, y2)
end

function draw.Box(x, y, w, h, clr)
    if clr then
        SetDrawColor(clr)
    else
        SetDrawColor(255, 255, 255, 255)
    end
    s_DrawRect(x, y, w, h)
end

function draw.BoxOutlined(t, x, y, w, h, clr)
    if clr then
        SetDrawColor(clr)
    else
        SetDrawColor(255, 255, 255, 255)
    end
    s_DrawOutlinedRect(x, y, w, h, t)
end

function draw.Texture(mat, x, y, w, h, clr)
    if clr then
        SetDrawColor(clr)
    else
        SetDrawColor(255, 255, 255, 255)
    end
    s_SetMaterial(mat)
    s_DrawTexturedRect(x, y, w, h)
end


local mat_pp_blue = Material("pp/motionblur")
function draw.Blur(x, y, w, h, alpha)
    SetDrawColor(255, 255, 255, alpha or 255)
    s_SetMaterial(mat_pp_blue)
    s_DrawTexturedRect(x, y, w, h)
end

function draw.WhiteBGAlpha(x, y, w, h, alpha)
    draw.NoTexture()
    SetDrawColor(255, 255, 255, alpha or 255)
    s_DrawTexturedRect(x, y, w, h)
end

function draw.TextureRotated(mat, rotate, x, y, w, h, clr)
    if clr then
        SetDrawColor(clr)
    else
        SetDrawColor(255, 255, 255, 255)
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
	    s_SetTextColor( clr )
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
        SetDrawColor(clr.r,clr.g,clr.b,clr.a)
    else
        SetDrawColor(255, 255, 255, 255)
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
---@param clr zColor?
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

    draw.Box(0,0,w,h,clr)
end

---@param radius number
---@param x number
---@param y number
---@param w number
---@param h number
---@param clr zColor?
function draw.BoxRounded(radius, x, y, w, h, clr)
    return draw.BoxRoundedEx(radius, x, y, w, h, clr, true, true, true, true)
end