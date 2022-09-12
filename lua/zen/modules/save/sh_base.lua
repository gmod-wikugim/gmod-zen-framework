local save = zen.Init("zen.Save")

local F = string.InterpolateSQL
local F_TYPE = string.InterpolateSQL_Type
local INSERT = table.insert

local F_COLUMN = function(var) return F_TYPE("column", var) end
local F_AUTO = function(var) return F_TYPE("auto", var) end
local F_WHERE = function(var1, var2) return F("${column:1} IS ${auto:2}", {var1, var2}) end
local F_SET = function(var1, var2) return F("${column:1} = ${auto:2}", {var1, var2}) end

sql.QueryErrorLogInterpolate([[
    --DROP TABLE `zen_SaveValue`;
    CREATE TABLE IF NOT EXISTS
        `zen_SaveValue`
    (
        `key1` VARCHAR(255),
        `key2` VARCHAR(255),
        `key3` VARCHAR(255),
        `key4` VARCHAR(255),
        `key5` VARCHAR(255),
        `value1` VARCHAR(255),
        `value2` VARCHAR(255),
        `value3` VARCHAR(255),
        `value4` VARCHAR(255),
        `value5` VARCHAR(255),
        `value1_t` VARCHAR(255),
        `value2_t` VARCHAR(255),
        `value3_t` VARCHAR(255),
        `value4_t` VARCHAR(255),
        `value5_t` VARCHAR(255)
    )
]], {})

function save.SetSaveValue(key1, key2, key3, key4, key5, value1, value2, value3, value4, value5)
    local values = {value1, value2, value3, value4, value5}

    local tSet, tWhere, tColumns, tValues = {}, {}, {}, {}

    for k, v in pairs(values) do
        if not util.mt_convertableType[type(v)] then
            error("type not convertable: " .. type(v) .. " - " .. tostring(v))
        end
    end

    local function checkValue(c_Key, v_Key, c_Value, v_Value, c_ValueType)
        assertStringNice(c_Key, "c_Key")
        assertStringNice(c_Value, "c_Value")

        if v_Key == nil then v_Key = v_Key or "NULL" end
        if v_Value == nil then v_Value = v_Value or "NULL" end

        assertStringNice(v_Key, "v_Key (" .. c_Key .. ")")
        assertStringNice(c_ValueType, "c_ValueType")


        local v_ValueType, v_New_Value
        if v_Value == "NULL" then
            v_ValueType = "NULL"
            v_New_Value = "NULL"
        else
            v_ValueType = util.mt_convertableType[type(v_Value)]
            v_New_Value = util.TYPEToString(v_Value, v_ValueType)
        end



        INSERT(tColumns, F_COLUMN(c_Key) )
        INSERT(tColumns, F_COLUMN(c_Value) )
        INSERT(tColumns, F_COLUMN(c_ValueType) )

        INSERT(tWhere, F_WHERE(c_Key, v_Key))

        INSERT(tValues, F_AUTO(v_Key) )
        INSERT(tValues, F_AUTO(v_New_Value) )
        INSERT(tValues, F_AUTO(v_ValueType) )

        INSERT(tSet, F_SET(c_Value, v_New_Value))
        INSERT(tSet, F_SET(c_ValueType, v_ValueType))
    end

    checkValue("key1", key1, "value1", value1, "value1_t")
    checkValue("key2", key2, "value2", value2, "value2_t")
    checkValue("key3", key3, "value3", value3, "value3_t")
    checkValue("key4", key4, "value4", value4, "value4_t")
    checkValue("key5", key5, "value5", value5, "value5_t")

    
    
    if #tColumns != #tValues then
        print("Column:", unpack(tColumns))
        print("tValues:", unpack(tValues))
        error("columb count not equal value count")
    end

    local sql_set = table.concat(tSet, ", ")

    local sql_columns =  table.concat(tColumns, ", ")
    local sql_values = table.concat(tValues, ", ")

    local sql_where = table.concat(tWhere, " AND ")


    local exists, q1 = sql.QueryErrorLogInterpolate([[
        SELECT
            rowid
        FROM
            `zen_SaveValue`
        WHERE
            ${default:1}
        LIMIT 1
    ]], {sql_where})


    local isDelete = value1 == nil and value2 == nil and value3 == nil and value4 == nil and value5 == nil


    if isDelete then
        sql.QueryErrorLogInterpolate([[
            DELETE FROM
                `zen_SaveValue`
            WHERE
                ${default:1}
        ]], {sql_where})
    else
        local data, query
        if exists != nil then
            data, query = sql.QueryErrorLogInterpolate([[
                UPDATE
                    `zen_SaveValue`
                SET
                    ${default:1}
                WHERE
                    ${default:2}
            ]], {sql_set, sql_where})
        else
            data, query = sql.QueryErrorLogInterpolate([[
                INSERT INTO
                    `zen_SaveValue`
                (
                    ${default:1}
                )
                VALUES
                (
                    ${default:2}
                )
            ]], {sql_columns, sql_values})
        end
    end
end


function save.GetSaveValue_Single(data)
    local tValues = {}

    local tKeys = {}

    local lastKeyTable = tKeys

    for k = 1, 5 do
        local key_name = "key" .. k
        local value_name = "value" .. k
        local value_name_t = value_name .. "_t"
        local key_value = data[key_name]
        local value = data[value_name]
        local value_t = data[value_name_t]

        if key_value != "NULL" then
            lastKeyTable[key_value] = {}
            lastKeyTable = lastKeyTable[key_value]
        end

        if value == "NULL" or value_t == "NULL" then continue end

        value_t = tonumber(value_t)

        local new_value = util.StringToTYPE(value, value_t)
        tValues[k] = new_value
    end

    lastKeyTable.v = tValues

    return tValues, tKeys
end


function save.GetSaveValue(key1, key2, key3, key4, key5, onlyFirst)
    local sql_equal_query = "${column:1} IS ${auto:2}"

    local tResult = {}

    local function checkValue(column_name, column_value)
        if column_value == nil then 
            if onlyFirst then
                column_value = "NULL"
            else
                return
            end
        end

        local add_str = F(sql_equal_query, {column_name, column_value})

        INSERT(tResult, add_str)
    end

    checkValue("key1", key1)
    checkValue("key2", key2)
    checkValue("key3", key3)
    checkValue("key4", key4)
    checkValue("key5", key5)

    local add_values_str = table.concat(tResult, " AND ")

    local data, query = sql.QueryErrorLogInterpolate([[
        SELECT
            rowid, *
        FROM
            `zen_SaveValue`
        WHERE
            ${default:1}
    ]], {add_values_str})


    if data == nil then return nil end

    if onlyFirst then
        local dat = data[1]
        return unpack(save.GetSaveValue_Single(dat))
    else
        local tResult_Values, tResult_ValuesWithKeys = {}, {}
        for k, dat in pairs(data) do
            local tValues, tValuesWithKeys = save.GetSaveValue_Single(dat)
            INSERT(tResult_Values, tValues)

            table.Merge(tResult_ValuesWithKeys, tValuesWithKeys)
        end
        return tResult_Values, tResult_ValuesWithKeys
    end
end
