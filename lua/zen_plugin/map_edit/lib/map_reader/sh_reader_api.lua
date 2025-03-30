module("zen")


function map_reader.GetMapEntities()
    local HEADER = map_reader.CreateMapLumps()

    ---@type zen.map_edit.reader.lumps.LUMP_ENTITIES
    local MAP = HEADER.LUMPS["LUMP_ENTITIES"].data

    local EntityList = MAP.entity_list_table


    if EntityList then
        for classname, list_entity in pairs(EntityList) do
            if list_entity then
                for counter, ITEM in pairs(list_entity) do
                    ITEM.origin = Vector(ITEM.origin)
                    ITEM.angles = Angle(ITEM.angles)
                    ITEM.mins = Vector(ITEM.mins)
                    ITEM.maxs = Vector(ITEM.maxs)
                end
            end
        end
    end

    return EntityList
end