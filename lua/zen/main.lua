zen = (istable(zen) and zen.__zenLOADED) and zen or {}
zen.__zenLOADED = true
izen = (istable(izen) and izen.__izenLOADED) and izen or {}
izen.__zenLOADED = true
izen = istable(izen) and izen or {}
izen.config = {}
icfg = izen.config
icfg.colors = icfg.colors or {}
iclr = icfg.colors

iclr.main = Color(125, 0, 0, 255)
iclr.console_default = Color(200, 200, 200)

icfg.console_space = " "


local i
function izen.print(...)
    local args = {...}
    local count = #args

    i = 0

    MsgC(iclr.main, "[izen]", iclr.console_default)
    if count > 0 then
        while i < count do
            i = i + 1
            MsgC(args[i])
        end
    end
    MsgC("\n", COLOR.WHITE)
end
zen.print = izen.print

function izen.Init(module_name)
    if izen[module_name] then return izen[module_name] end
    izen[module_name] = izen[module_name] or {}
    zen[module_name] = izen[module_name]

    return zen[module_name]
end
zen.Init = izen.Init

function izen.Include(fl_path)
    return include(fl_path)
end
zen.Include = izen.Include

function zen.IncludeSh(fl_path) AddCSLuaFile(fl_path) return zen.Include(fl_path) end
function zen.IncludeSv(fl_path) if SERVER then return zen.Include(fl_path) end end
function zen.IncludeCl(fl_path) AddCSLuaFile(fl_path) if CLIENT then return zen.Include(fl_path) end end
zen.IncludeSH = zen.IncludeSh
zen.IncludeSV = zen.IncludeSv
zen.IncludeCL = zen.IncludeCl


zen.IncludeSH("zen/browser.lua")