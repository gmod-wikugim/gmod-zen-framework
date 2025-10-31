module("zen")

if SERVER then
    resource.AddWorkshop("3273399038") -- zen fun content
end

zen.IncludeCL("cl_draw_fun.lua")
zen.IncludeSV("sv_activity.lua")

-- zen.IncludeSH("zombie/sh_zombie.lua")
-- zen.IncludeCL("zombie/cl_zombie.lua")
-- zen.IncludeSV("zombie/sv_zombie.lua")
zen.IncludeSV("zombie/sv_jump.lua")
-- zen.IncludeSV("zombie/sv_push.lua")

zen.IncludeSH("player_mode/zombie/sh_class.lua")

zen.IncludeSH("player_mode/infected/sh_class.lua")
zen.IncludeCL("player_mode/infected/cl_class.lua")
zen.IncludeSV("player_mode/infected/sv_class.lua")

zen.IncludeSV("meetings/sv_invasion.lua")