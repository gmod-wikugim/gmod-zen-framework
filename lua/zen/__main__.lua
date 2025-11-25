-- ZEN Library
---@meta

module("zen", function(MODULE)
    --- Init global vartiable
    MODULE._L = MODULE
    MODULE.zen = MODULE
    MODULE.MODULE = MODULE
    MODULE.version = "1.1"

    --- Setup main metatable
    setmetatable(MODULE, {
        __index = _G
    })
end)

-- Init main variables
zen = zen or {}
zen.modules = _L.modules or {}
local _MODULE = zen.modules

---@generic T
---@param name zen.`T`
---@param default? any
---@return zen.`T`
function _GET(name, default)
    assert(type(default) == "table" or default == nil, "`default` not is table")

    if !_MODULE[name] then _MODULE[name] = (default) and (table.Copy(default)) or {} end
    return _MODULE[name]
end


do -- Includes functions
    local SERVER = SERVER
    local CLIENT = CLIENT

    local assert = assert
    local type = type

    ---@param path string
    function zen.INC(path)
        assert(type(path) == "string", "path not is string")

        local res, a1, a2, a3, a4, a5, a6, a7 = xpcall(include, ErrorNoHaltWithStack, path)
        if res then
            return a1, a2, a3, a4, a5, a6, a7
        end
    end


    -- Function to include sh_files with from ...
    ---@param pathes string[]|string
    function zen.IncludeSH(pathes)
        if type(pathes) == "string" then pathes = {pathes} end
        assert(type(pathes) == "table", "zen.IncludeSH expects a table of paths")

        for _, path in ipairs(pathes) do
            AddCSLuaFile(path)
            xpcall(zen.INC, ErrorNoHaltWithStack, path)
        end
    end

    -- Function to include cl_files with from pathes
    ---@param pathes string[]|string
    function zen.IncludeCL(pathes)
        if type(pathes) == "string" then pathes = {pathes} end
        assert(type(pathes) == "table", "zen.IncludeCL expects a table of paths")

        for _, path in ipairs(pathes) do
            AddCSLuaFile(path)
            if CLIENT then
                xpcall(zen.INC, ErrorNoHaltWithStack, path)
            end
        end
    end

    -- Function to include sv_files with from pathes
    ---@param pathes string[]|string
    function zen.IncludeSV(pathes)
        if !SERVER then return end
        if type(pathes) == "string" then pathes = {pathes} end
        assert(type(pathes) == "table", "zen.IncludeSV expects a table of paths")

        for _, path in ipairs(pathes) do
            xpcall(zen.INC, ErrorNoHaltWithStack, path)
        end
    end

    ---@param plugin_name string
    function zen.IncludePlugin(plugin_name)
        return zen.IncludeSH("zen_plugin/" .. plugin_name .. "/browser.lua")
    end


end



------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------

concommand.Add("zen_reload", function(ply)
    if SERVER and IsValid(ply) then return end

    zen.IncludeSH("zen/__main__.lua")
end)

------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------



do -- Global_Variables
    _CFG = _GET("config") --[[@class zen.config]]
    _SOURCE = _GET("source") --[[@class zen.source]]
end

do -- Source variables
    _SOURCE.print = _G.print
end

do -- zen.enum.color : Basic colors
    COLOR = _GET("enum.color") --[[@class zen.enum.color]]
    COLOR.WHITE = Color(255, 255, 255, 255)

    COLOR.main = Color(0, 255, 0, 255)
    COLOR.console_default = Color(200, 200, 200)

    COLOR.client = Color(255, 125, 0)
    COLOR.server = Color(0, 125, 255)
end


do -- Custom print function
    local i, lastcolor
    local MsgC = MsgC
    local IsColor = IsColor
    local _sub = string.sub
    function print(...)
        local args = {...}
        local count = #args

        local text_color = CLIENT and COLOR.client or COLOR.server

        i = 0

        MsgC(text_color, "z> ", COLOR.console_default)
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
        MsgC("\n", COLOR.WHITE)
    end
end


_CFG.OfficialPlugins = table.Flip{
    "fun",
    "map_edit",
    "developer_kit",
    "server_model_viewer",
    "permaprops",
    "tv"
}


zen.IncludeSH("zen/browser.lua")