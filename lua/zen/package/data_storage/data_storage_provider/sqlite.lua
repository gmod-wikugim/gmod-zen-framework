local color_good = Color(0, 255, 0)
local color_bad = Color(255, 0, 0)

local ServerLog = scp_code.data_storage.ServerLog

local QUERIES = {}

/*
    SQLite Data Provider
    Containts:
        - CreateObject
        - IsObjectExists
        - InspectObject
        - Save
        - Load
    All queries should use SQLite
*/

local PROVIDER_Name = "SQLite"

---@param query string
---@param callback? fun(result: table<string, any>)
---@param failcallback? fun(err: string, query: string)
local function PROVIDER_Query(query, callback, failcallback)
    local debug_trace = debug.traceback()

    local result = sql.Query(query)
    if result == false then
        local err = sql.LastError()
        ServerLog(color_bad, "||--- SQL Error ---|| (", PROVIDER_Name  , ")", color_white, "\nError: ", err, "\nQuery: ", query, "\n", debug_trace, "\n  ||------------------||")
        if failcallback then
            failcallback(err, query)
        end
    else
        if callback then
            callback(result)
        end
    end
end

---@param value any
---@param bNoQuotes? boolean
local function PROVIDE_SQLStr(value, bNoQuotes)
    return sql.SQLStr(value, bNoQuotes)
end

---@param query string
---@return table|nil
local function SQLiteQuery(query)
    local result = sql.Query(query)
    if result == false then
        Error("SQLite Error: " .. sql.LastError())
        return
    end

    return result
end


local color_field = Color(255, 255, 0)


local MYSQL_REPLACE_TYPE_NAME = {
    ["TEXT"] = "VARCHAR",
    ["NUMBER"] = "INT",
    ["BOOLEAN"] = "TINYINT",
    ["ARRAY"] = "BLOB",
    ["TABLE"] = "BLOB",
    ["ANGLE"] = "BLOB",
    ["VECTOR"] = "BLOB",
}


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

---@param const_type string
function GetConstrainName(OBJECT, const_type)
    return "idx_" .. OBJECT.uniqueID .. "_" .. const_type .. "_datastorage"
end

local _lower = string.lower

local function check_string_equal(a, b)
    return _lower(a) == _lower(b)
end


local function ConvertLuaFieldToSQLField(fieldInfo)
    local id = fieldInfo.id
    local name = fieldInfo.name
    local type = fieldInfo.type
    local length = fieldInfo.length

    local nice_type_name = MYSQL_REPLACE_TYPE_NAME[type]
    assert(nice_type_name, "Invalid type: " .. tostring(type))

    local extras = {}

    -- default
    if fieldInfo.default then
        table.insert(extras, "DEFAULT " .. fieldInfo.default)
    end

    local extra_text = #extras > 0 and (" " .. table.concat(extras, " ")) or ""

    if length then
        return string.format("`%s` %s(%d)%s", id, nice_type_name, length, extra_text)
    else
        return string.format("`%s` %s%s", id, nice_type_name, extra_text)
    end
end

local function CheckIndexes_Equal(OBJECT)
    local QE_SHOW_INDEX = string.format("SHOW INDEX FROM `%s`", OBJECT.uniqueID)


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
        else
            local QE_FIX_INDEX = string.format("ALTER TABLE `%s` %s;", OBJECT.uniqueID, table.concat(index_query_to_fix, ", "))

            OBJECT:ServerLog("Indexes is", color_bad, " broken, fixing..")
            PROVIDER_Query(QE_FIX_INDEX, function(data)
                OBJECT:ServerLog("Indexes is", color_good, " fixed")
            end)
        end
    end)
end

--- Check if the field exists in the table, check key, values with case insensitive, and length separately
---@return boolean bNice
local function InspectFieldsEqual(OBJECT, table_fields)
    local keys = OBJECT.keys
    local values = OBJECT.values

    local fields_dont_exists = {}
    local fields_wrong = {}
    local fields_useless = {}

    for index, sql_info in pairs(table_fields) do
        local fieldInfo = OBJECT.fields[index]

        if not fieldInfo then
            fields_useless[index] = true
            OBJECT:ServerLog("Field is useless: ", color_field, index)
        else
            local sql_type = string.match(sql_info.type, "^(%w+)")
            local sql_length = string.match(sql_info.type, "%((%d+)%)")

            local bMarkToEdit = false
            -- Check length if exists
            if !bMarkToEdit and sql_length then
                if fieldInfo.length then
                    if tonumber(sql_length) ~= fieldInfo.length then
                        fields_wrong[index] = true
                        bMarkToEdit = true
                        OBJECT:ServerLog("Field length not equal: ", color_field, index, " (", sql_length, " != ", fieldInfo.length, ")")
                    end
                end
            end

            local converted_type = MYSQL_REPLACE_TYPE_NAME[fieldInfo.type]
            if not converted_type then
                OBJECT:ErrorLog("Invalid type: ", fieldInfo.type, " for field: ", index)
                return false
            end

            -- Check type
            if !bMarkToEdit and not check_string_equal(sql_type, converted_type) then
                fields_wrong[index] = true
                bMarkToEdit = true
                OBJECT:ServerLog("Field type not equal: ", color_field, index, color_white, " (", sql_type, " != ", fieldInfo.type, ")")
            end

            -- Check default with tostring, skip ""
            if !bMarkToEdit and tostring(sql_info.default) ~= tostring(fieldInfo.default) then
                fields_wrong[index] = true
                bMarkToEdit = true
                OBJECT:ServerLog("Field default not equal: ", color_field, index, color_white, " (", sql_info.default, " != ", fieldInfo.default, ")")
            end
        end
    end

    -- Check All Self Culumns exists in table_fields
    for index, fieldInfo in pairs(OBJECT.fields) do
        if not table_fields[index] then
            fields_dont_exists[index] = true
            OBJECT:ServerLog("Field not found: ", color_field, index)
        end
    end

    local bSQLiteSchemaWrong = next(fields_dont_exists) != nil or next(fields_wrong) != nil or next(fields_useless) != nil


    if bSQLiteSchemaWrong then -- Fixes

        -- Warning: Start fixing
        OBJECT:ServerLog("Columns is ", color_bad, "wrong", color_white, ", fixing..")

        local bNeedFixWrongField = next(fields_wrong) != nil
        local bNeedFixUselessField = next(fields_useless) != nil

        if bNeedFixWrongField or bNeedFixUselessField then
            -- Log SQLITE Edit column not supported, migrating table!
            if bNeedFixWrongField then
                OBJECT:WarningLog("Edit column tags is not supported in SQLITE, migrating table..")
            end

            if bNeedFixUselessField then
                OBJECT:WarningLog("Drop column tags is not supported in SQLITE, migrating table..")
            end

            local QE_FIX_TABLE = QUERIES.CreateTableWithMigrateData(OBJECT)
            PROVIDER_Query(QE_FIX_TABLE, function(data)
                OBJECT:ServerLog("Table migrated", color_good, " successfully")
            end, function(err, query)
                -- Close transaction
                PROVIDER_Query("ROLLBACK;")
            end)
        else
            local bNeedFixDontExistsField = next(fields_dont_exists) != nil
            if bNeedFixDontExistsField then
                -- SQLITE SCHEME for NEW COLUMN with extra: ALTER TABLE table_name ADD COLUMN column_name column_def;
                for index in pairs(fields_dont_exists) do
                    OBJECT:ServerLog("Creating new column: ", color_field, index)

                    local fieldInfo = OBJECT.fields[index]
                    local CREATE_COLUMN_QUERY = string.format("ALTER TABLE `%s` ADD COLUMN %s", OBJECT.uniqueID, ConvertLuaFieldToSQLField(fieldInfo))
                    PROVIDER_Query(CREATE_COLUMN_QUERY, function(data)
                        OBJECT:ServerLog("Field created: ", color_field, index, color_good, " successfully")
                    end)
                end
            end

            /* DROP COLUMN NOT SUPPORTED IN SQLITE

            local bNeedFixUselessField = next(fields_useless) != nil
            if bNeedFixUselessField then
                -- SQLITE SCHEME for DELETE COLUMN: ALTER TABLE table_name DROP COLUMN column_name;
                for index in pairs(fields_useless) do
                    OBJECT:ServerLog("Deleting useless column: ", color_field, index)

                    local DROP_COLUMN_QUERY = string.format("ALTER TABLE `%s` DROP COLUMN %s", OBJECT.uniqueID, index)
                    PROVIDER_Query(DROP_COLUMN_QUERY, function(data)
                        OBJECT:ServerLog("Field deleted: ", color_field, index, color_good, " successfully")
                    end)
                end
            end
            */
        end
    end

    return not bSQLiteSchemaWrong
end

---@return string[], string[]
local function QUERY_GetCreateTableObjects(OBJECT)
    local array_fields = {}

    for field, fieldInfo in pairs(OBJECT.fields) do
        table.insert(array_fields, ConvertLuaFieldToSQLField(fieldInfo))
    end

    local unique_list = {}

    for key, keyInfo in pairs(OBJECT.keys) do
        table.insert(unique_list, '`' .. keyInfo.id .. '`')
    end

    return array_fields, unique_list
end

function QUERIES.CreateTableWithMigrateData(OBJECT)
    /* Migrating data
        BEGIN TRANSACTION;
        CREATE TEMPORARY TABLE t1_backup(a,c);
        INSERT INTO t1_backup SELECT a,c FROM t1;
        DROP TABLE t1;
        CREATE TABLE t1(a,b, c);
        INSERT INTO t1 SELECT a,c FROM t1_backup;
        DROP TABLE t1_backup;
        COMMIT;
    */

    --- SQLite Last table fields
    local TABLE_INFO = SQLiteQuery(string.format("PRAGMA table_info(%s);", OBJECT.uniqueID))

    if !TABLE_INFO then
        OBJECT:ErrorLog("Table not found: ", OBJECT.uniqueID)
        return
    end

    local table_field_names = {}

    for _, row in ipairs(TABLE_INFO) do
        table_field_names[row.name] = true
    end

    local fields_to_backup = {}


    for field, fieldInfo in pairs(OBJECT.fields) do
        if table_field_names[fieldInfo.id] then
            table.insert(fields_to_backup, fieldInfo.id)
        end
    end

    local array_fields = {}

    for field, fieldInfo in pairs(OBJECT.fields) do
        table.insert(array_fields, ConvertLuaFieldToSQLField(fieldInfo))
    end

    local unique_list = {}

    for key, keyInfo in pairs(OBJECT.keys) do
        table.insert(unique_list, '`' .. keyInfo.id .. '`')
    end


    // TODO: Detect is creating new column for SQLITE works nice
    -- Error No New column supported
    for field, fieldInfo in pairs(OBJECT.fields) do
        if not table_field_names[fieldInfo.id] then
            OBJECT:WarnLog("New column is experimental, not supported yet: ", fieldInfo.id)
        end
    end

    local transaction_queries = {}

    table.insert(transaction_queries, "BEGIN TRANSACTION;")


    table.insert(transaction_queries, string.format("CREATE TEMPORARY TABLE %s_backup(%s);", OBJECT.uniqueID, table.concat(fields_to_backup, ", ")))

    table.insert(transaction_queries, string.format("INSERT INTO %s_backup SELECT %s FROM %s;", OBJECT.uniqueID, table.concat(fields_to_backup, ", "), OBJECT.uniqueID))

    table.insert(transaction_queries, string.format("DROP TABLE %s;", OBJECT.uniqueID))

    table.insert(transaction_queries, string.format("CREATE TABLE %s(%s, UNIQUE(%s));", OBJECT.uniqueID, table.concat(array_fields, ", "), table.concat(unique_list, ", ")))

    table.insert(transaction_queries, string.format("INSERT INTO %s SELECT %s FROM %s_backup;", OBJECT.uniqueID, table.concat(fields_to_backup, ", "), OBJECT.uniqueID))

    table.insert(transaction_queries, string.format("DROP TABLE %s_backup;", OBJECT.uniqueID))

    table.insert(transaction_queries, "COMMIT;")

    local SUPER_QUERY = table.concat(transaction_queries, " ")

    return SUPER_QUERY
end



local function QUERY_CreateTable(OBJECT)

    local array_fields, unique_list = QUERY_GetCreateTableObjects(OBJECT)


    local CREATE_TABLE_QUERY = string.format("CREATE TABLE IF NOT EXISTS `%s` (%s, UNIQUE(%s))", OBJECT.uniqueID, table.concat(array_fields, ", "), table.concat(unique_list, ", "))

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
end

---@param callback fun(bExists: boolean)
function PROVIDER:IsObjectExists(callback)
    self:ServerLog("Check object exists..")

    -- SELECT name FROM sqlite_master WHERE type='table' AND name='{table_name}';
    local QUERY = string.format("SELECT name FROM sqlite_master WHERE type='table' AND name='%s';", self.uniqueID)

    PROVIDER_Query(QUERY, function(data)
        callback(istable(data) and #data > 0)
    end)
end

---@param inspectTarget? string
---@param callback? fun()
function PROVIDER:InspectObject(inspectTarget, callback)

    -- PRAGMA table_info(table_name);
    local GET_TABLE_INFO_QUERY = string.format("PRAGMA table_info(%s);", self.uniqueID)

    PROVIDER_Query(GET_TABLE_INFO_QUERY, function(data)
        self:ServerLog("Inspecting..")

        local table_fields = {}

        -- SQLITE
        for _, row in ipairs(data) do
            table_fields[row.name] = {
                type = row.type,
                null = row.notnull,
                key = row.pk,
                extra = row.dflt_value,
                id = row.name,
                default = row.dflt_value
            }

            -- Remove default NULL
            if row.dflt_value == "NULL" then
                table_fields[row.name].default = nil
            end
        end

        InspectFieldsEqual(self, table_fields)
        if callback then callback() end

        -- CheckIndexes_Equal(self)
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

    local DELETE_QUERY = string.format("DELETE FROM `%s` WHERE %s;", self.uniqueID, table.concat(array_keys, " AND "))
    PROVIDER_Query(DELETE_QUERY, callback)
end

-- Remove all
---@param callback? fun()
function PROVIDER:RemoveAll(callback)
    local DELETE_QUERY = string.format("DELETE FROM `%s`;", self.uniqueID)
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

    local where_keys = {}

    for key, value in pairs(mysql_keys) do
        table.insert(where_keys, "`" .. key .. "` = " .. value)
    end

    /*

        INSERT OR IGNORE INTO my_table (name, age) VALUES ('Karen', 34)
        UPDATE my_table SET age = 34 WHERE name='Karen'

    */
    local QUERY_INSERT_OR_IGNORE_UPDATE_SET = string.format("INSERT OR IGNORE INTO `%s` (%s) VALUES (%s); UPDATE `%s` SET %s WHERE %s;", self.uniqueID, table.concat(array_keys, ", "), table.concat(array_values, ", "), self.uniqueID, table.concat(mysql_duplicate_update, ", "), table.concat(where_keys, " AND "))
    PROVIDER_Query(QUERY_INSERT_OR_IGNORE_UPDATE_SET, callback)
    -- print(QUERY_INSERT_OR_IGNORE_UPDATE_SET)
end

---@param keys table<string, any>
---@param callback fun(values: table<string, any>|nil)
function PROVIDER:Load(keys, callback)
    -- Convert keys to MySQL Select Query
    local array_keys = {}

    for key, value in pairs(keys) do
        table.insert(array_keys, "`" .. key .. "` = " .. PROVIDE_SQLStr(value))
    end

    local SELECT_QUERY = string.format("SELECT * FROM `%s` WHERE %s;", self.uniqueID, table.concat(array_keys, " AND "))
    PROVIDER_Query(SELECT_QUERY, function(data)
        if istable(data) and #data > 0 then
            -- Convert MySQL types to Lua types
            local row = data[1]
            local result = ConvertMySQLValuesToLuaVariables(self, row)

            callback(result)
        else
            if callback then callback(nil) end
        end
    end)
end

---@param keys table<string, any>
---@param callback fun(values: table<string, any>|nil)
function PROVIDER:LoadMass(keys, callback)
    -- Convert keys to MySQL Select Query
    local array_keys = {}

    for key, value in pairs(keys) do
        table.insert(array_keys, "`" .. key .. "` = " .. PROVIDE_SQLStr(value))
    end

    local SELECT_QUERY = string.format("SELECT * FROM `%s` WHERE %s;", self.uniqueID, table.concat(array_keys, " AND "))
    PROVIDER_Query(SELECT_QUERY, function(data)
        if istable(data) and #data > 0 then
            -- Convert MySQL types to Lua types

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

scp_code.data_storage.RegisterProvider("SQLite", PROVIDER)