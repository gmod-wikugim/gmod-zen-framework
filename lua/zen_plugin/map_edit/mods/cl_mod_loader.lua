module("zen", package.seeall)

---@class zen.map_edit_mods
map_edit_mods = _GET("map_edit_mods")

---@type table<string, zen.map_edit_mod>
map_edit_mods.mt_ModsList = map_edit_mods.mt_ModsList or {}
local MOD_LIST = map_edit_mods.mt_ModsList

---@class (strict) zen.map_edit_mod
---@field name string
---@field version string
---@field iden? string
---@field icon_path? string
---@fields INFO? table



---@generic T: zen.map_edit_mod
---@param iden zen.map_edit_mod.`T`
---@param MOD zen.map_edit_mod
---@return zen.map_edit_mod.`T`
function map_edit_mods.Register(iden, MOD)
    assert(isstring(iden), "MOD.iden not is string")
    assert(istable(MOD), "MOD not is table")
    assert(isstring(MOD.name), "MOD.name not is string")
    assert(isstring(MOD.version), "MOD.version not is string")
    -- assert(isstring(MOD.icon_path), "MOD.icon_path not is string")

    MOD.iden = iden

    ---@diagnostic disable-next-line: inject-field
    MOD.INFO = {}

    MOD_LIST[MOD.iden] = MOD

    setmetatable({}, {
        __index = MOD
    })

    return MOD
end

---@generic T: zen.map_edit_mod
---@param iden zen.map_edit_mod.`T`
---@return zen.map_edit_mod.`T` MOD?
function map_edit_mods.GetCopy(iden)
    assert(isstring(iden), "iden not is string")

    return table.Copy(MOD_LIST[iden])
end

function map_edit_mods.GetListForEdit()
    return map_edit_mods.mt_ModsList
end