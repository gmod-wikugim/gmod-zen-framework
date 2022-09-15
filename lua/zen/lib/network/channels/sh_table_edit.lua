local TABLE_KEY_NUMBER = 1
local TABLE_KEY_STRING = 2
local TABLE_KEY_ENTITY = 3

nt.mt_listReader["table_key"] = function()
    local key_type = net.ReadUInt(2)

    if key_type == TABLE_KEY_NUMBER then
        local positive = net.ReadBool()

        local numb = net.ReadUInt(32)

        if positive then
            return numb
        else
            return -numb
        end
    elseif key_type == TABLE_KEY_STRING then
        return nt.Read({"string_id"})
    elseif key_type == TABLE_KEY_ENTITY then
        return net.ReadEntity()
    end
end

nt.mt_listWriter["table_key"] = function(var)
    local type_id = typen(var)

    type_id = util.mt_TD_TypeBase[type_id] or type_id

    if type_id == TYPE.NUMBER then
        net.WriteBool(var > -1)
        net.WriteUInt(var, 32)
    elseif type_id == TYPE.STRING then
        return nt.Write({"string_id"}, {var})
    elseif type_id == TYPE.ENTITY then
        return net.WriteEntity(var)
    end
end

util.RegisterTypeConvert("table_key", TYPE.ANY)