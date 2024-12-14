module("zen", package.seeall)

---@class zen.map_edit.reader.lumps.LUMP_ENTITIES
---@field entity_count number
---@field counter number item counter
---@field err_counter number 
---@field keyvalues_table table<number, table>
---@field classname_counter table<string, number>
---@field entity_list_table table


local string_gmatch = string.gmatch
local rawset = rawset
local rawget = rawget
local istable = istable

---@param source_string string
---@return table<string, string>
local function import_hammer_table(source_string)
    local new_table = {}

    for key, value in string_gmatch(source_string, '"([^"]+)" "([^"]+)"') do
        rawset(new_table, key, value)
    end

    return new_table
end

local function read_source(source)

    ---@type zen.map_edit.reader.lumps.LUMP_ENTITIES
    local MAP = {}
    MAP.keyvalues_table = {}
    MAP.classname_counter = {}
    MAP.entity_list_table = {}
    MAP.counter = 0
    MAP.err_counter = 0
    MAP.entity_count = 0

    do -- Readed
        local keyvalues_tables = MAP.keyvalues_table
        local classname_counter = MAP.classname_counter
        local entity_list_table = MAP.entity_list_table

        local entity_count = 0
        local icounter = 0
        local errcounter = 0

        for string_hammer_data in string_gmatch(source, "\n({\n\"[^}]+})") do
            icounter = icounter + 1

            local ITEM = import_hammer_table(string_hammer_data)
            if !ITEM or !istable(ITEM) then
                errcounter = errcounter + 1
                continue
            end

            ITEM._icounter = icounter

            rawset(keyvalues_tables, icounter, ITEM)

            local ITEM_classname = rawget(ITEM, "classname")

            if ITEM_classname then
                entity_count = entity_count + 1
                local class_count = rawget(classname_counter, ITEM_classname) or 0
                rawset(classname_counter, ITEM_classname, class_count + 1)

                local entity_list = rawget(entity_list_table, ITEM_classname)
                if !entity_list then
                    entity_list = {}
                    rawset(entity_list_table, ITEM_classname, entity_list)
                end

                entity_list[class_count] = ITEM
            end
        end

        MAP.entity_count = entity_count
        MAP.counter = 0
    end

    return MAP
end

map_reader.RegisterLumpRead("LUMP_ENTITIES", function (source)
    return read_source(source)
end)