module("zen")

-- Initialize zen submodules
zen.config = {}
zen.modules = {}

-- Alises
_MODULE = zen.modules
_CFG = zen.config

_CFG.colors = _CFG.colors or {}
_COLOR = _CFG.colors
_COLOR.WHITE = color_white

_COLOR.main = Color(0, 255, 0, 255)
_COLOR.console_default = Color(200, 200, 200)

_COLOR.client = Color(255, 125, 0)
_COLOR.server = Color(0, 125, 255)

_CFG.console_space = " "

local string_Split = string.Split

local _sub = string.sub
_print = _L._print or print
do
    local i, lastcolor
    local MsgC = MsgC
    local IsColor = IsColor
    function print(...)
        local args = {...}
        local count = #args

        local text_color = CLIENT and _COLOR.client or _COLOR.server

        i = 0

        MsgC(text_color, "z> ", _COLOR.console_default)
        if count > 0 then
            while i < count do
                i = i + 1
                local dat = args[i]
                if type(dat) == "string" and _sub(dat, 1, 1) == "#" and lang and lang.L then
                    dat = lang.L(dat)
                end
                if IsColor(dat) then
                    lastcolor = dat
                    continue
                end
                if lastcolor then
                    MsgC(lastcolor, dat)
                    lastcolor = nil
                else
                    MsgC(dat)
                end
            end
        end
        MsgC("\n", _COLOR.WHITE)
    end
end

---@generic T
---@param name zen.`T`
---@param default? any
---@return zen.`T`
function zen.module(name, default)
    assert(type(default) == "table" or default == nil, "`default` not is table")

    if !_MODULE[name] then _MODULE[name] = (default) and (table.Copy(default)) or {} end
    return _MODULE[name]
end
_GET = zen.module


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

function zen.IncludePlugin(plugin_name)
    print("include plugin: ", plugin_name)
    return zen.IncludeSHU("zen_plugin/" .. plugin_name .. "/browser.lua")
end

function zen.IncludeFolderRecursive(folder)
    local files, folders = file.Find(folder .. "/*", "LUA")

    if !files then return end

    for _, file_name in pairs(files) do
        local fl_path = folder .. "/" .. file_name

        local prefix = string.sub(file_name, 1, 3)
        if prefix == "cl_" then
            zen.IncludeCL(fl_path)
        elseif prefix == "sv_" then
            zen.IncludeSV(fl_path)
        elseif prefix == "sh_" then
            zen.IncludeSH(fl_path)
        else
            zen.IncludeSH(fl_path)
        end
    end

    if !folders then return end

    for _, sub_folder in pairs(folders) do
        zen.IncludeFolderRecursive(folder .. "/" .. sub_folder)
    end
end

zen.IncludeSHU("zen/browser.lua")