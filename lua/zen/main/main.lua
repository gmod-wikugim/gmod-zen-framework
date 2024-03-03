module("zen", package.seeall)

-- Stable

zen = (istable(zen) and zen.__zenLOADED) and zen or {}
zen.__zenLOADED = true
zen.config = {}
zen.modules = {}
imodules = zen.modules
icfg = zen.config
icfg.colors = icfg.colors or {}
iclr = icfg.colors

iclr.main = Color(0, 255, 0, 255)
iclr.console_default = Color(200, 200, 200)

icfg.console_space = " "

local string_Split = string.Split

_print = _print or print

local i
function print(...)
    local args = {...}
    local count = #args

    i = 0

    MsgC(iclr.main, "z> ", iclr.console_default)
    if count > 0 then
        while i < count do
            i = i + 1
            MsgC(args[i])
        end
    end
    MsgC("\n", COLOR.WHITE)
end


function zen.Init(...)
    local to_init = {...}
    local tResult = {}
    for _, module_name in ipairs(to_init) do
        local last_module = "zen"
        local module_table = imodules
        local modules_arg = string_Split(module_name, ".")
        for i, sub_module_name in ipairs(modules_arg) do
            last_module = last_module .. "." .. sub_module_name
            module_table[sub_module_name] = module_table[sub_module_name] or {}
            module_table = module_table[sub_module_name]
            assert(istable(module_table), "\"" .. sub_module_name .. "\" name is taken \"" .. (last_module) .. "\"")
        end

        if not module_table or module_table == imodules then
            error("Module not exists")
        end

        table.insert(tResult, module_table)
    end

    return unpack(tResult)
end


function zen.Import(...)
    local to_import = {...}
    local tResult = {}
    for _, module_name in ipairs(to_import) do
        local last_module = "zen"
        local module_table = imodules
        local modules_arg = string_Split(module_name, ".")
        for i, sub_module_name in ipairs(modules_arg) do
            last_module = last_module .. "." .. sub_module_name
            module_table = module_table[sub_module_name]
            assert(module_table != nil, "\"" .. sub_module_name .. "\" not exists in \"" .. (last_module) .. "\"")
        end

        if not module_table or module_table == imodules then
            error("Module not exists")
        end

        table.insert(tResult, module_table)
    end

    return unpack(tResult)
end

function zen.Include(fl_path)
    return include(fl_path)
end

function zen.IncludeSh(fl_path) AddCSLuaFile(fl_path) return zen.Include(fl_path) end
function zen.IncludeSv(fl_path) if SERVER then return zen.Include(fl_path) end end
function zen.IncludeCl(fl_path) AddCSLuaFile(fl_path) if CLIENT then return zen.Include(fl_path) end end
zen.IncludeSH = zen.IncludeSh
zen.IncludeSV = zen.IncludeSv
zen.IncludeCL = zen.IncludeCl


zen.IncludeSH("zen/browser.lua")