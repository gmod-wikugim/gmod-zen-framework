local ui = zen.Init("ui")
local draw = ui.Init("draw")

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

local math_ceil = math.ceil
local tostring = tostring


function draw.Box(x, y, w, h, clr)
    if clr then
        s_SetDrawColor(clr.r, clr.g, clr.b, clr.a)
    else
        s_SetDrawColor(255, 255, 255, 255)
    end
    s_DrawRect(x, y, w, h)
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
	font	= ui_fonts[font] or ui.ffont(font)
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

	return w, h
end