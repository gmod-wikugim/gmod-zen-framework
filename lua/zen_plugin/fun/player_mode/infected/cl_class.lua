module("zen", package.seeall)

local CLASS = player_mode.GetClass("infected")

local color_red = Color(255,0,0,10)
CLASS:HookOwner("HUDPaint", function (self)
    local W, H = ScrW(), ScrH()
    draw.Box(0,0,W,H,color_red)
end)

player_mode.Register(CLASS)