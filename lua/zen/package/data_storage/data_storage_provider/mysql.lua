local color_good = Color(0, 255, 0)
local color_bad = Color(255, 0, 0)

local ServerLog = scp_code.data_storage.ServerLog

local PROVIDER_Name = "MySQL"

---@param query string
---@param callback? fun(result: table<string, any>)
---@param failcallback? fun(err: string, query: string)
local function PROVIDER_Query(query, callback, failcallback)
    local debug_trace = debug.traceback()
    MySQLite.query(query, callback, function(err, query)
        ServerLog(color_bad, "||--- SQL Error ---|| (", PROVIDER_Name  , ")", color_white, "\nError: ", err, "\nQuery: ", query, "\n", debug_trace, "\n  ||------------------||")
        if failcallback then
            failcallback(err, query)
        end
    end)
end

---@param query string
---@vararg string|number
local function PROVIDER_FormatQuery(query, ...)
    return string.format(query, ...)
end

---@param value any
---@param bNoQuotes? boolean
local function PROVIDE_SQLStr(value, bNoQuotes)
    return MySQLite.SQLStr(value, bNoQuotes)
end


local color_field = Color(255, 255, 0)


local MYSQL_REPLACE_TYPE_NAME = {
    ["BLOB"] = "BLOB",
    ["TEXT"] = "TINYTEXT",
    ["NUMBER"] = "INT",
    ["BOOLEAN"] = "TINYINT",
    ["ARRAY"] = "BLOB",
    ["TABLE"] = "BLOB",
    ["ANGLE"] = "TINYTEXT",
    ["VECTOR"] = "TINYTEXT",
}

---@param const_type string
function GetConstrainName(OBJECT, const_type)
    return "idx_" .. OBJECT.uniqueID .. "_" .. const_type .. "_datastorage"
end

local function QUERY_CreateIndex(OBJECT)
    local unique_list = {}

    for key, keyInfo in pairs(OBJECT.keys) do
        table.insert(unique_list, '`' .. keyInfo.id .. '`')
    end

    local index_name = GetConstrainName(OBJECT, "main")

    local CREATE_INDEX_QUERY = PROVIDER_FormatQuery(
        "CREATE INDEX %s USING BTREE ON %s (%s);",
        index_name,
        OBJECT.uniqueID,
        table.concat(unique_list, ", ")
    )

    return CREATE_INDEX_QUERY
end



---@param OBJECT scp_code.data_storage.struct
---@param row table<string, any>
---@return table<string, any>
local function ConvertMySQLValuesToLuaVariables(OBJECT, row)
    local result = {}

    for key, value in pairs(row) do
        local field_info = OBJECT.fields[key]
        if !field_info then
            OBJECT:ErrorLog("Field not found: ", key)
            continue
        end

        local field_type = field_info.type

        -- Convert field_type to lua type
        if field_type == "NUMBER" then
            result[key] = tonumber(value)
        elseif field_type == "BOOLEAN" then
            result[key] = tobool(value)
        elseif field_type == "TEXT" then
            result[key] = value
        elseif field_type == "ARRAY" then
            result[key] = util.JSONToTable(value)
        elseif field_type == "TABLE" then
            result[key] = util.JSONToTable(value)
        elseif field_type == "ANGLE" then
            result[key] = util.StringToType(value, "angle")
        elseif field_type == "VECTOR" then
            result[key] = util.StringToType(value, "vector")
        else
            OBJECT:ErrorLog("Invalid field type: ", field_type)
        end
    end

    return result
end

---@param OBJECT scp_code.data_storage.struct
---@param lua_variables table<string, any>
---@return table<string, any>
local function ConvertLuaVariablesToMySQLValues(OBJECT, lua_variables)
    local mysql_variables = {}

    for key, value in pairs(lua_variables) do
        local field_info = OBJECT.fields[key]
        if !field_info then
            OBJECT:ErrorLog("Field not found: ", key)
            continue
        end

        local field_type = field_info.type

        -- Convert field_type to lua type
        if field_type == "NUMBER" then
            mysql_variables[key] = tonumber(value)
        elseif field_type == "BOOLEAN" then
            mysql_variables[key] = value and 1 or 0
        elseif field_type == "TEXT" then
            mysql_variables[key] = PROVIDE_SQLStr(value)
        elseif field_type == "ARRAY" then
            mysql_variables[key] = PROVIDE_SQLStr(util.TableToJSON(value))
        elseif field_type == "TABLE" then
            mysql_variables[key] = PROVIDE_SQLStr(util.TableToJSON(value))
        elseif field_type == "ANGLE" then
            mysql_variables[key] = PROVIDE_SQLStr(util.TypeToString(value))
        elseif field_type == "VECTOR" then
            mysql_variables[key] = PROVIDE_SQLStr(util.TypeToString(value))
        else
            OBJECT:ErrorLog("Invalid field type: ", field_type)
        end
    end

    return mysql_variables
end



local _lower = string.lower

local function check_string_equal(a, b)
    return _lower(a) == _lower(b)
end


local function ConvertKeyToSQLField(keyInfo)
    local id = keyInfo.id
    local name = keyInfo.name
    local type = keyInfo.type
    local length = keyInfo.length

    local nice_type_name = MYSQL_REPLACE_TYPE_NAME[type]
    assert(nice_type_name, "Invalid type: " .. tostring(type))

    local extras = {}

    -- default
    if keyInfo.default then
        table.insert(extras, "DEFAULT " .. keyInfo.default)
    end

    local extra_text = #extras > 0 and (" " .. table.concat(extras, " ")) or ""

    -- if length then
        -- return PROVIDER_FormatQuery("`%s` %s(%d)%s", id, nice_type_name, length, extra_text)
    -- else
        return PROVIDER_FormatQuery("`%s` %s%s", id, nice_type_name, extra_text)
    -- end
end

---@param OBJECT scp_code.data_storage.struct
---@param callback? fun()
local function CheckIndexes_Equal(OBJECT, callback)
    local QE_SHOW_INDEX = PROVIDER_FormatQuery("SHOW INDEX FROM `%s`", OBJECT.uniqueID)


    PROVIDER_Query(QE_SHOW_INDEX, function(data)
        local index_query_to_fix = {}


        local bDataExists = istable(data) and #data > 0

        local unique_list = {}

        for key, keyInfo in pairs(OBJECT.keys) do
            table.insert(unique_list, '`' .. keyInfo.id .. '`')
        end

        if bDataExists then
            local indexes = {}

            for _, row in ipairs(data) do
                local index_name = row.Key_name
                local column_name = row.Column_name

                indexes[index_name] = row
            end

            local index_name = GetConstrainName(OBJECT, "main")

            -- Check index exists
            if not indexes[index_name] then
                table.insert(index_query_to_fix, "ADD UNIQUE INDEX " .. index_name .. " (" .. table.concat(unique_list, ", ") .. ") USING BTREE")
                OBJECT:ServerLog("Index not founded: ", color_field, index_name)
            end

            // TODO: Check if all OBJECT.key exists in index

            -- Check unique_list equal
            if indexes[index_name] then
                local row = indexes[index_name]
                local column_name = row.Column_name

                local column_list = string.Explode(",", column_name)

                local bEqual = true

                local columns = {}

                for _, column in ipairs(column_list) do
                    if OBJECT.keys[column] == nil then
                        bEqual = false
                        break
                    end

                    columns[column] = true
                end


                if not bEqual then
                    table.insert(index_query_to_fix, "DROP INDEX " .. index_name)
                    table.insert(index_query_to_fix, "ADD UNIQUE INDEX " .. index_name .. " (" .. table.concat(unique_list, ", ") .. ") USING BTREE")
                    OBJECT:ServerLog("Index column not equal: ", color_field, index_name)
                end
            end
        else
            local index_name = GetConstrainName(OBJECT, "main")
            table.insert(index_query_to_fix, "ADD UNIQUE INDEX " .. index_name .. " (" .. table.concat(unique_list, ", ") .. ") USING BTREE")
            OBJECT:ServerLog("Index not founded: ", color_field, index_name)
        end

        if #index_query_to_fix == 0 then
            OBJECT:ServerLog("Indexes is ", color_good, "good")
            if callback then callback() end
        else
            local CREATE_INDEX = QUERY_CreateIndex(OBJECT)
            PROVIDER_Query(CREATE_INDEX, function()
                OBJECT:ServerLog("Indexes is ", color_good, "fixed")
                if callback then callback() end
            end)
        end
    end)
end

--- Check if the field exists in the table, check key, values with case insensitive, and length separately
---@return boolean bNice, string? QE_ALTER
local function CheckField_Equal(OBJECT, table_fields)
    local keys = OBJECT.keys
    local values = OBJECT.values
    local fields = OBJECT.fields

    local alter_query_to_fix = {}

    for index, sql_info in pairs(table_fields) do
        local self_info = fields[index]

        if not self_info then
            table.insert(alter_query_to_fix, "DROP COLUMN " .. sql_info.id)
            OBJECT:ServerLog("Field not found: ", color_field, index)
        else
            local sql_type = string.match(sql_info.type, "^(%w+)")
            local sql_length = string.match(sql_info.type, "%w+%((%d+)%)")

            local bMarkToEdit = false
            -- Check length if exists
            if !bMarkToEdit and sql_length and self_info.length then
                if self_info.length then
                    if tonumber(sql_length) ~= self_info.length then
                        table.insert(alter_query_to_fix, "MODIFY COLUMN " .. ConvertKeyToSQLField(self_info))
                        bMarkToEdit = true
                        OBJECT:ServerLog("Field length not equal: ", color_field, index, " (", sql_length, " != ", self_info.length, ")")
                    end
                end
            end

            local converted_type = MYSQL_REPLACE_TYPE_NAME[self_info.type]
            if not converted_type then
                OBJECT:ErrorLog("Invalid type: ", self_info.type, " for field: ", index)
                return false
            end

            -- Check type
            if !bMarkToEdit and not check_string_equal(sql_type, converted_type) then
                table.insert(alter_query_to_fix, "MODIFY COLUMN " .. ConvertKeyToSQLField(self_info))
                bMarkToEdit = true
                OBJECT:ServerLog("Field type not equal: ", color_field, index, color_white, " (", sql_type, " != ", self_info.type, ")")
            end

            -- Check default with tostring, skip ""
            if !bMarkToEdit and tostring(sql_info.default) ~= tostring(self_info.default) then
                table.insert(alter_query_to_fix, "MODIFY COLUMN " .. ConvertKeyToSQLField(self_info))
                bMarkToEdit = true
                OBJECT:ServerLog("Field default not equal: ", color_field, index, color_white, " (", sql_info.default, " != ", self_info.default, ")")
            end
        end
    end

    -- Check All Self Culumns exists in table_fields
    for index, self_info in pairs(keys) do
        if not table_fields[index] then
            table.insert(alter_query_to_fix, "ADD COLUMN " .. ConvertKeyToSQLField(self_info))
            OBJECT:ServerLog("Field not found: ", color_field, index)
        end
    end

    for index, self_info in pairs(values) do
        if not table_fields[index] then
            table.insert(alter_query_to_fix, "ADD COLUMN " .. ConvertKeyToSQLField(self_info))
            OBJECT:ServerLog("Field not found: ", color_field, index)
        end
    end

    if #alter_query_to_fix == 0 then
        return true
    else
        local ALTER_QUERY = PROVIDER_FormatQuery("ALTER TABLE `%s` %s;", OBJECT.uniqueID, table.concat(alter_query_to_fix, ", "))
        return false, ALTER_QUERY
    end
end


local function QUERY_CreateTable(OBJECT)
    local field_list = {}

    for key, fieldInfo in pairs(OBJECT.fields) do
        table.insert(field_list, ConvertKeyToSQLField(fieldInfo))
    end

    local unique_list = {}

    for key, keyInfo in pairs(OBJECT.keys) do
        table.insert(unique_list, '`' .. keyInfo.id .. '`')
    end

    local CREATE_TABLE_QUERY = PROVIDER_FormatQuery(
        "CREATE TABLE IF NOT EXISTS `%s` (%s);",
        OBJECT.uniqueID,
        table.concat(field_list, ", ")
    )


    return CREATE_TABLE_QUERY
end


local PROVIDER = {}


---@param callback? fun()
function PROVIDER:CreateObject(callback)
    local CREATE_TABLE = QUERY_CreateTable(self)

    PROVIDER_Query(CREATE_TABLE, function(data)
        if callback then callback() end
        self:ServerLog("Created SQL table: " .. self.uniqueID)
    end)

    local CREATE_INDEX = QUERY_CreateIndex(self)
    PROVIDER_Query(CREATE_INDEX, function(data)
        self:ServerLog("Created SQL index: " .. self.uniqueID)
    end)
end

---@param callback fun(bExists: boolean)
function PROVIDER:IsObjectExists(callback)
    self:ServerLog("Check object exists..")

    local QUERY = PROVIDER_FormatQuery("SHOW TABLES LIKE '%s'", self.uniqueID)

    PROVIDER_Query(QUERY, function(data)
        callback(istable(data) and #data > 0)
    end)
end

---@param inspectTarget? string
---@param callback? fun()
function PROVIDER:InspectObject(inspectTarget, callback)
    local DESCRIBE_TABLE = PROVIDER_FormatQuery("DESCRIBE `%s`", self.uniqueID)
    PROVIDER_Query(DESCRIBE_TABLE, function(data)
        self:ServerLog("Inspecting..")

        local table_fields = {}

        for _, row in ipairs(data) do
            table_fields[row.Field] = {
                type = row.Type,
                null = row.Null,
                key = row.Key,
                extra = row.Extra,
                id = row.Field,
                default = row.Default
            }
        end

        local bNice, QE_ALTER_TABLE = CheckField_Equal(self, table_fields)

        if bNice then
            self:ServerLog("Columns is ", color_good, "good")
        else
            self:ServerLog("Columns is ", color_bad, "broken", color_white, ", fixing..")
            PROVIDER_Query(QE_ALTER_TABLE, function(data)
                self:ServerLog("Columns is ", color_good, "fixed")
            end)
        end

        CheckIndexes_Equal(self, callback)
    end)
end

-- Remove
---@param keys table<string, any>
---@param callback? fun()
function PROVIDER:Remove(keys, callback)
    local array_keys = {}

    for key, value in pairs(keys) do
        table.insert(array_keys, "`" .. key .. "` = " .. PROVIDE_SQLStr(value))
    end

    local DELETE_QUERY = PROVIDER_FormatQuery("DELETE FROM `%s` WHERE %s;", self.uniqueID, table.concat(array_keys, " AND "))
    PROVIDER_Query(DELETE_QUERY, callback)
end

-- Remove All
---@param callback? fun()
function PROVIDER:RemoveAll(callback)
    local DELETE_QUERY = PROVIDER_FormatQuery("DELETE FROM `%s`;", self.uniqueID)
    PROVIDER_Query(DELETE_QUERY, callback)
end

---@param keys table<string, any>
---@param values table<string, any>
---@param callback? fun()
function PROVIDER:Save(keys, values, callback)
    -- Convert keys and values to MYSQL Replace Query
    local array_keys = {}
    local array_values = {}

    -- Convert keys and values lua variables to MySQL variables
    local mysql_keys = ConvertLuaVariablesToMySQLValues(self, keys)
    local mysql_values = ConvertLuaVariablesToMySQLValues(self, values)


    for key, value in pairs(mysql_keys) do
        table.insert(array_keys, "`" .. key .. "`")
        table.insert(array_values, value)
    end

    for key, value in pairs(mysql_values) do
        table.insert(array_keys, "`" .. key .. "`")
        table.insert(array_values, value)
    end

    local mysql_duplicate_update = {}

    for key, value in pairs(mysql_values) do
        table.insert(mysql_duplicate_update, "`" .. key .. "` = " .. value)
    end

    local INSERT_ON_DUPLICATE_UPDATE_QUERY = PROVIDER_FormatQuery("INSERT INTO `%s` (%s) VALUES (%s) ON DUPLICATE KEY UPDATE %s;", self.uniqueID, table.concat(array_keys, ", "), table.concat(array_values, ", "), table.concat(mysql_duplicate_update, ", "))
    PROVIDER_Query(INSERT_ON_DUPLICATE_UPDATE_QUERY, callback)
end

---@param keys table<string, any>
---@param callback fun(values: table<string, any>|nil)
function PROVIDER:Load(keys, callback)
    -- Convert keys to MySQL Select Query
    local array_keys = {}

    for key, value in pairs(keys) do
        table.insert(array_keys, "`" .. key .. "` = " .. PROVIDE_SQLStr(value))
    end

    local SELECT_QUERY = PROVIDER_FormatQuery("SELECT * FROM `%s` WHERE %s;", self.uniqueID, table.concat(array_keys, " AND "))
    PROVIDER_Query(SELECT_QUERY, function(data)
        if istable(data) and #data > 0 then
            -- Convert MySQL types to Lua types
            local row = data[1]
            local result = ConvertMySQLValuesToLuaVariables(self, row)

            callback(result)
        else
            if callback then callback() end
        end
    end)
end

---@param keys table<string, any>
---@param callback fun(values: table<string, any>|nil)
function PROVIDER:LoadMass(keys, callback)
    local array_keys = {}

    for key, value in pairs(keys) do
        table.insert(array_keys, "`" .. key .. "` = " .. PROVIDE_SQLStr(value))
    end

    local SELECT_QUERY = PROVIDER_FormatQuery("SELECT * FROM `%s` WHERE %s;", self.uniqueID, table.concat(array_keys, " AND "))
    PROVIDER_Query(SELECT_QUERY, function(data)
        if istable(data) and #data > 0 then
            local converted_data = {}

            for _, row in ipairs(data) do
                local result = ConvertMySQLValuesToLuaVariables(self, row)
                table.insert(converted_data, result)
            end

            callback(converted_data)
        else
            if callback then callback(nil) end
        end
    end)
end


scp_code.data_storage.RegisterProvider("MySQL", PROVIDER)