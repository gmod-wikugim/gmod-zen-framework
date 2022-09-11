local ui, draw = zen.Init("ui", "ui.draw")

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

function draw.DrawLine(x1, y1, x2, y2, clr)
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

function draw.TextArray(x, y, data)
    for k, v in ipairs(data) do
        local text, font, ax, ay, clr, xalign, yalign, clrbg = unpack(v)
        local w, h = ui.GetTextSize(text, font)

        y = (y + h/2)
        draw.TextN(text, font, x+ax, y+ay, clr, xalign, yalign, clrbg)
        y = (y + h/2)
    end
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
hook.Add("HUDPaint", "test", function()
    
    draw.TextArray(100, 100, {
        {"Sucess", 10, 0, 0, COLOR.G, TEXT_ALIGN_LEFT, 1, COLOR.BLACK},
        {"testing\n10\n20\n30\n40", 6, 20, 0, COLOR.W, TEXT_ALIGN_LEFT, 1, COLOR.BLACK},
        {"testing", 6, 20, 0, COLOR.W, TEXT_ALIGN_LEFT, 1, COLOR.BLACK},
        {"Fail\n1000", 10, 0, 0, COLOR.R, TEXT_ALIGN_LEFT, 1, COLOR.BLACK},
        {"testing", 6, 20, 0, COLOR.W, TEXT_ALIGN_LEFT, 1, COLOR.BLACK},
        {"testing", 6, 20, 0, COLOR.W, TEXT_ALIGN_LEFT, 1, COLOR.BLACK},
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