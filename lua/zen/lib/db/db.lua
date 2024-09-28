local module = {}


-- function check is require module exists

---@param module string
---@return boolean
function module.IsModuleExists(module)
    local prefix = CLIENT and "gmcl_" or "gmsv_"
    local postfix = system.IsLinux() and "_linux.dll" or "_win32.dll"

    local path = "bin/" .. prefix .. module .. postfix
    return file.Exists(path, "LUA")
end

function module.log(...)
    local ActiveProvider = module.GetActiveProvider() or "No Provider"


    MsgN()
    local logStr = table.concat({"[DB][", ActiveProvider, "] ", ...})
    print(logStr)
end

local color_error = Color(255, 0, 0)
function module.error(...)
    local traceback = debug.traceback()
    local ActiveProvider = module.GetActiveProvider() or "No Provider"

    local args = {...}

    MsgN()
    MsgC(color_error, "ERROR [DB][", ActiveProvider, "] ")
    for i, arg in ipairs(args) do
        Msg(arg)
    end
    MsgN()
    Msg(traceback)
    MsgN()
end

---@return string
function module.GetActiveProvider()
    return module.mP_active_provider
end

---@param provider? string
function module.SetActiveProvider(provider)
    module.mP_active_provider = provider
end

local type = type
local tonumber = tonumber
local pairs = pairs

local function convertStringNumbers(tbl)
    if type(tbl) ~= "table" then return end

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            convertStringNumbers(v)
        elseif type(v) == "string" and tonumber(v) then
            tbl[k] = tonumber(v)
        end
    end

end


---@param Queries string[]
---@param onFinish? fun(results:any[])
function module.MultiQuery(Queries, onFinish)
    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider == "mysqloo" then
        local traceback = debug.traceback()

        local results = {}

        local transaction = module.mysqloo_db:createTransaction()

        for i, singleQuery in pairs(Queries) do
            local q = module.mysqloo_db:query(singleQuery)

            transaction:addQuery(q)
        end

        function transaction:onSuccess()
            if onFinish then
                local allQueries = transaction:getQueries()

                for i, query in pairs(allQueries) do
                    local data = query:getData()
                    -- results[i] = data
                    results[i] = data
                end

                if type(results) == "table" then
                    convertStringNumbers(results)
                end

                onFinish(results)
            end
        end

        function transaction:onError(err)
            module.error(err, "\n", traceback, err)

        end

        transaction:start()

        return
    end

    if ActiveProvider == "sqlite" then
        local results = {}

        for i, singleQuery in pairs(Queries) do
            local data = sql.Query(singleQuery)
            results[i] = data

            if data == false then
                local sql_error = sql.LastError()
                local str_args = table.concat({sql_error, "\n", singleQuery})

                module.error(str_args)
                return
            end
        end

        convertStringNumbers(results)
        if onFinish then onFinish(results) end

        return
    end

    module.error("No active provider found")
    return

end

---@param query string
---@param callback? fun(result:any, query:string)
---@param onError? fun(err:string)
function module.Query(query, callback, onError)
    local traceback = debug.traceback()
    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider == "mysqloo" then
        local q = module.mysqloo_db:query(query)

        function q:onSuccess(data)
            convertStringNumbers(data)

            if callback then callback(data, query) end
        end

        function q:onError(err)
            if onError then onError(err) end
            module.error(err, "\n", traceback, query)
            return
        end

        q:start()

        return
    end

    if ActiveProvider == "sqlite" then
        local data = sql.Query(query)
        convertStringNumbers(data)

        if data == false then
            local sql_error = sql.LastError()
            local str_args = table.concat({sql_error, "\n", query})

            if onError then onError(str_args) end
            module.error(str_args)
            return
        else
            if callback then callback(data, query) end
        end

        return
    end

    module.error("No active provider found")
    return
end

---@class db.host_data
---@field host string
---@field username string
---@field password string
---@field database string
---@field port number

---@alias db.provider: string
---| '"mysqloo"'
---| '"sqlite"'

---@param provider string
---@param host_data? db.host_data
---@param onConnected? fun()
---@param onDisconnected? fun()
function module.Start(provider, host_data, onConnected, onDisconnected)
    module.SetActiveProvider(nil)

    if provider == "mysqloo" then
        if !module.IsModuleExists("mysqloo") then
            module.error("try to start mysqloo provider, but module not found")
            return
        end

        if host_data == nil then
            module.error("host_data is required for mysqloo provider")
            return
            -- ---@cast host_data db.host_data
            -- return
        end

        require("mysqloo")

        module.mysqloo_db = mysqloo.connect(host_data.host, host_data.username, host_data.password, host_data.database, host_data.port)

        if !module.mysqloo_db then
            module.error("try to start mysqloo provider, but module not found")
            return
        end

        function module.mysqloo_db:onConnected()
            module.SetActiveProvider("mysqloo")
            module.log("mysqloo provider connected")

            if onConnected then onConnected() end
        end

        function module.mysqloo_db:onConnectionFailed(err)
            module.error("mysqloo provider connection failed: ", err)
            return
        end

        module.log("mysqloo provider connecting...")
        module.mysqloo_db:setMultiStatements(true)
        module.mysqloo_db:setAutoReconnect(true)
        module.mysqloo_db:connect()


        return
    end


    if provider == "sqlite" then

        module.SetActiveProvider("sqlite")
        module.log("SQLite provider started")

        if onConnected then onConnected() end

        return
    end

    module.error("Try to start unknown provider: ", provider)
    return
end

---@param callback? function
function module.Close(callback)
    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider == "mysqloo" then
        module.mysqloo_db:disconnect(true)
        module.log("mysqloo provider closed")
        if callback then callback() end
        return
    end

    if ActiveProvider == "sqlite" then
        module.log("SQLite provider closed")
        if callback then callback() end
        return
    end

    module.error("No active provider found")
    return
end

function module.SQLEscape(str)
    local ActiveProvider = module.GetActiveProvider()

    if type(str) == "number" then
        return str
    end

    if ActiveProvider == "mysqloo" then
        return module.mysqloo_db.Escape(str)
    end

    if ActiveProvider == "sqlite" then
        return sql.SQLStr(str)
    end

    module.error("No active provider found")
    return
end


---@param tableName string
---@param callback fun(bExists:boolean)
function module.IsTableExists(tableName, callback)
    local ActiveProvider = module.GetActiveProvider()


    if ActiveProvider == "mysqloo" then
        -- Check Is MySQL table exists

        module.Query("SHOW TABLES LIKE '" .. tableName .. "'", function(result)
            callback(next(result) ~= nil)
        end)

        return
    end

    if ActiveProvider == "sqlite" then
        module.Query("SELECT name FROM sqlite_master WHERE type='table' AND name='" .. tableName .. "'", function(data)
            callback(data ~= nil)
        end)

        return
    end

    module.error("No active provider found")
    return
end

---@param tableName string
---@param callback fun(result:any, query:string)
function module.DeleteTable(tableName, callback)
    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider == "mysqloo" then
        module.Query("DROP TABLE " .. tableName, callback)
        return
    end

    if ActiveProvider == "sqlite" then
        module.Query("DROP TABLE " .. tableName, callback)
        return
    end

    module.error("No active provider found")
    return
end

---@alias db.column_type: string
---| '"INTEGER"'
---| '"TEXT"'
---| '"REAL"'
---| '"BLOB"'
---| '"VARCHAR"'

---@class db.universal_table_struct_column
---@field name string
---@field type db.column_type
---@field length? number
---@field default? string|number
---@field primaryKey? boolean
---@field autoIncrement? boolean
---@field unique? boolean
---@field notNull? boolean

---@class db.universal_table_struct
---@field columns db.universal_table_struct_column[]

---@param type db.column_type
function module.ConvertLuaToType(type)
    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider == "mysqloo" then
        if type == "INTEGER" then
            return "INT"
        elseif type == "TEXT" then
            return "TINYTEXT"
        elseif type == "REAL" then
            return "FLOAT"
        elseif type == "BLOB" then
            return "LONGBLOB"
        elseif type == "VARCHAR" then
            return "VARCHAR"
        end
    end

    if ActiveProvider == "sqlite" then
        if type == "INTEGER" then
            return "INTEGER"
        elseif type == "TEXT" then
            return "TEXT"
        elseif type == "REAL" then
            return "REAL"
        elseif type == "BLOB" then
            return "BLOB"
        elseif type == "VARCHAR" then
            return "VARCHAR"
        end
    end

    module.error("No active provider found")
    return
end

-- Accociative array of database types to lua types
module.DATABASE_TYPES = {
    ["BIGINT"] = "INTEGER",
    ["BINARY"] = "BLOB",
    ["BIT"] = "INTEGER",
    ["BLOB"] = "BLOB",
    ["BOOL"] = "INTEGER",
    ["BOOLEAN"] = "INTEGER",
    ["CHAR"] = "TEXT",
    ["DATE"] = "INTEGER",
    ["DATETIME"] = "INTEGER",
    ["DEC"] = "REAL",
    ["DECIMAL"] = "REAL",
    ["DOUBLE PRECISION"] = "REAL",
    ["DOUBLE"] = "REAL",
    ["ENUM"] = "TEXT",
    ["FIXED"] = "REAL",
    ["FLOAT"] = "REAL",
    ["GEOMETRY"] = "TEXT",
    ["GEOMETRYCOLLECTION"] = "TEXT",
    ["INT"] = "INTEGER",
    ["INTEGER"] = "INTEGER",
    ["JSON"] = "TEXT",
    ["LINESTRING"] = "TEXT",
    ["LONGBLOB"] = "BLOB",
    ["LONGTEXT"] = "TEXT",
    ["MEDIUMBLOB"] = "BLOB",
    ["MEDIUMINT"] = "INTEGER",
    ["MEDIUMTEXT"] = "TEXT",
    ["MULTILINESTRING"] = "TEXT",
    ["MULTIPOINT"] = "TEXT",
    ["MULTIPOLYGON"] = "TEXT",
    ["NUMERIC"] = "REAL",
    ["POINT"] = "TEXT",
    ["POLYGON"] = "TEXT",
    ["REAL"] = "REAL",
    ["SERIAL"] = "INTEGER",
    ["SET"] = "TEXT",
    ["SMALLINT"] = "INTEGER",
    ["TEXT"] = "TEXT",
    ["TIME"] = "INTEGER",
    ["TIMESTAMP"] = "INTEGER",
    ["TINYBLOB"] = "BLOB",
    ["TINYINT"] = "INTEGER",
    ["TINYTEXT"] = "TEXT",
    ["VARBINARY"] = "BLOB",
    ["VARCHAR"] = "VARCHAR",
    ["XML"] = "TEXT",
    ["YEAR"] = "INTEGER",
}

---@param type string
---@return db.column_type, number
function module.ConvertTypeToLua(type)
    local type_name = string.match(type, "([%a]+)")
    local type_length = string.match(type, "%((%d+)%)")

    local type = string.upper(type_name)
    local LuaType = module.DATABASE_TYPES[type]

    if LuaType then
        return LuaType, type_length
    end

    module.error("Unknown type: ", type)
    return
end

---@param tableName string
---@param tableStruct db.universal_table_struct
---@param callback? fun(res:any, query:string)
function module.CreateTable(tableName, tableStruct, callback)
    assert(type(tableName) == "string", "tableName must be string")
    assert(type(tableStruct) == "table", "tableStruct must be table")

    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider != nil then
        -- Check autoIncrement and not INTEGER
        for i, column in ipairs(tableStruct.columns) do
            if column.autoIncrement and column.type != "INTEGER" then
                module.error("autoIncrement can be used only with INTEGER type")
                return
            end
        end
    end

    if ActiveProvider == "mysqloo" then
        local query = "CREATE TABLE `" .. tableName .. "` \n(\n"

        for i, column in ipairs(tableStruct.columns) do

            if (column.unique or column.primaryKey) and (column.type == "TEXT" or column.type == "BLOB") then
                module.error("Column type TEXT/BLOB can't be unique or primary key, use VARCHAR(n) instead")
                return
            end


            local columnType = module.ConvertLuaToType(column.type)
            query = query .. "\t `" .. column.name .. "` " .. columnType

            if column.length then
                if columnType == "VARCHAR" then
                    query = query .. "(" .. column.length .. ")"
                else
                    module.error("column.length is not supported for type " .. columnType)
                    return
                end
            end

            if columnType == "VARCHAR" and !column.length then
                module.error("column.length is required for type " .. columnType)
                return
            end

            if column.notNull then
                query = query .. " NOT NULL"
            end

            if column.autoIncrement then
                query = query .. " AUTO_INCREMENT"
            end

            if column.primaryKey then
                query = query .. " PRIMARY KEY"
            end

            if column.unique then
                query = query .. " UNIQUE"
            end

            if column.default then
                query = query .. " DEFAULT " .. module.SQLEscape(column.default)
            end

            if i ~= #tableStruct.columns then
                query = query .. ", \n"
            end
        end

        query = query .. "\n)"

        module.Query(query, callback)
        return
    end

    if ActiveProvider == "sqlite" then
        local query = "CREATE TABLE `" .. tableName .. "` \n(\n"

        for i, column in ipairs(tableStruct.columns) do
            local columnType = module.ConvertLuaToType(column.type)
            query = query .. "\t `" .. column.name .. "` " .. columnType

            if column.autoIncrement then
                if column.type != "INTEGER" then
                    module.error("autoIncrement can be used only with INTEGER type")
                    return
                end

                if !column.primaryKey then
                    module.error("autoIncrement can be used only with primaryKey")
                    return
                end
            end

            if column.length then
                if columnType == "VARCHAR" then
                    query = query .. "(" .. column.length .. ")"
                else
                    module.error("column.length is not supported for type " .. columnType)
                    return
                end
            end

            if columnType == "VARCHAR" and !column.length then
                module.error("column.length is required for type " .. columnType)
                return
            end

            if column.notNull then
                query = query .. " NOT NULL"
            end

            if column.primaryKey then
                query = query .. " PRIMARY KEY"
            end

            if column.unique then
                query = query .. " UNIQUE"
            end

            if column.default then
                query = query .. " DEFAULT " .. module.SQLEscape(column.default)
            end

            if column.autoIncrement then
                query = query .. " AUTOINCREMENT"
            end

            if i ~= #tableStruct.columns then
                query = query .. ", \n"
            end
        end

        query = query .. "\n)"

        module.Query(query, callback)
        return
    end

    module.error("No active provider found")
    return
end




--- Get table schemas and convert this to universal format
--- Convert NULL to nil
---@param tableName string
---@param callback fun(data:db.universal_table_struct)
function module.GetTableStruct(tableName, callback)
    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider == "mysqloo" then

        module.MultiQuery({
            "SHOW COLUMNS FROM `" .. tableName .. "`",
            "SHOW INDEXES FROM `" .. tableName .. "`",
        }, function(results)
            local table_info = results[1]
            local indexes = results[2]

            local columns = {}

            local unique_columns = {}

            if type(indexes) == "table" then
                for i, row in ipairs(indexes) do
                    if row.Key_name == "PRIMARY" then continue end

                    if row.Non_unique == 0 and row.Index_type == "BTREE" then
                        unique_columns[row.Column_name] = true
                    end
                end
            end

            for i, row in ipairs(table_info) do
                local ColumnType, length = module.ConvertTypeToLua(row.Type)
                local column_is_unique = unique_columns[row.Field] == true

                local column = {
                    name = row.Field,
                    type = ColumnType,
                    default = row.Default,
                    primaryKey = row.Key == "PRI",
                    autoIncrement = row.Extra == "auto_increment",
                    unique = column_is_unique,
                    notNull = row.Null == "NO" and row.Key != "PRI",
                    length = length
                }

                if column.default == "NULL" then
                    column.default = nil
                end

                if column.notNull == false then
                    column.notNull = nil
                end

                if column.unique == false then
                    column.unique = nil
                end

                if column.primaryKey == false then
                    column.primaryKey = nil
                end

                if column.autoIncrement == false then
                    column.autoIncrement = nil
                end

                table.insert(columns, column)
            end

            callback({
                columns = columns
            })

        end)



        return
    end

    if ActiveProvider == "sqlite" then
        module.MultiQuery(
        {
            "PRAGMA table_info(`" .. tableName .. "`)",
            "PRAGMA index_list(`" .. tableName .. "`)",
        },
        function(results)
            local table_info_pragma = results[1]
            local index_list_pragma = results[2]

            local index_list = {}

            if index_list_pragma then
                for i, row in ipairs(index_list_pragma) do
                    table.insert(index_list, "PRAGMA index_info('" .. row.name .. "')")
                end
            end

            module.MultiQuery(index_list, function(index_info_pragma)
                local unique_columns = {}

                if index_info_pragma then
                    for i, indexes in ipairs(index_info_pragma) do
                        for i2, row in ipairs(indexes) do
                            unique_columns[row.cid] = true
                        end
                    end
                end

                local columns = {}

                for i, row in ipairs(table_info_pragma) do
                    local ColumnType = module.ConvertTypeToLua(row.type)

                    local column_is_unique = unique_columns[row.cid] == true

                    local column = {
                        name = row.name,
                        type = ColumnType,
                        length = row.length,
                        default = row.dflt_value,
                        primaryKey = row.pk == 1,
                        autoIncrement = row.pk == 1 and ColumnType == "INTEGER",
                        unique = column_is_unique,
                        notNull = row.notnull == 1,
                    }

                    if column.default == "NULL" then
                        column.default = nil
                    end

                    if column.notNull == false then
                        column.notNull = nil
                    end

                    if column.unique == false then
                        column.unique = nil
                    end

                    if column.primaryKey == false then
                        column.primaryKey = nil
                    end

                    if column.autoIncrement == false then
                        column.autoIncrement = nil
                    end

                    table.insert(columns, column)
                end

                callback({
                    columns = columns
                })
            end)
        end)

        return
    end

    module.error("No active provider found")
    return
end


module.Start("mysqloo", {
    host = "localhost",
    username = "root",
    password = "root",
    database = "gmod",
    port = 3306
}, function()

    module.IsTableExists("db_test", function(bExists)
        if bExists then
            module.DeleteTable("db_test", function()
                module.log("Table deleted")
            end)
        end
        if !bExists then
            module.CreateTable("db_test", {
                columns = {
                    {
                        name = "id",
                        type = "INTEGER",
                        primaryKey = true,
                    },
                    {
                        name = "name",
                        type = "VARCHAR",
                        length = 255,
                        unique = true
                    },
                    {
                        name = "age",
                        type = "INTEGER",
                    },
                    {
                        name = "created_at",
                        type = "INTEGER",
                        notNull = true,
                    }
                }
            }, function()
                module.log("Table exists, inspecting..")

                module.GetTableStruct("db_test", function(data)
                    -- PrintTable(data)
                end)

            end)
        end
    end)



    timer.Simple(5, function()
        module.Close()
    end)

end)

