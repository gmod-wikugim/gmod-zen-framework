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

    local logStr = table.concat({"[DB][", ActiveProvider, "] ", ...})
    print(logStr)
end

function module.error(...)
    local ActiveProvider = module.GetActiveProvider() or "No Provider"

    local errorStr = table.concat({"[DB][", ActiveProvider, "] ", ...})
    error(errorStr, 0)
end

---@return string
function module.GetActiveProvider()
    return module.mP_active_provider
end

---@param provider string
function module.SetActiveProvider(provider)
    module.mP_active_provider = provider
end

---@param query string
---@param callback? fun(result:any, query:string)
---@param onError? fun(err:string)
function module.Query(query, callback, onError)
    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider == "tmysql4" then
        local db, err = tmysql.initialize(
            zen.db.config.host,
            zen.db.config.username,
            zen.db.config.password,
            zen.db.config.database,
            zen.db.config.port
        )

        if not db then
            module.error("tmysql4: " .. err)
        end

        db:Query(query, function(result)
            if onError and result[1].status == false then
                onError(result[1].error)
                return
            end

            if callback then callback(result, query) end
        end)

        return
    end

    if ActiveProvider == "mysqloo" then
        local db = mysqloo.connect(
            zen.db.config.host,
            zen.db.config.username,
            zen.db.config.password,
            zen.db.config.database,
            zen.db.config.port
        )

        db:connect()

        local q = db:query(query)
        function q:onSuccess(data)
            if callback then callback(data, query) end
        end

        function q:onError(err)
            if onError then onError(err) end
            module.error("mysqloo: " .. err)
        end

        q:start()

        return
    end

    if ActiveProvider == "sqlite" then
        local data = sql.Query(query)

        if data == false then
            local sql_error = sql.LastError()
            local str_args = table.concat({sql_error, "\n", query})

            if onError then onError(str_args) end
            module.error(str_args)
        else

            if callback then callback(data, query) end
        end

        return
    end

    module.error("No active provider found")
end

function module.Start(provider)
    if provider == "mysqloo" then
        if !module.IsModuleExists("mysqloo") then
            module.error("try to start mysqloo provider, but module not found")
        end

        module.mysqloo = require("mysqloo")

        module.SetActiveProvider(name)
        module.log("mysqloo provider started")

        return
    end

    if provider == "tmysql4" then
        if  !module.IsModuleExists("tmysql4") then
            module.error("try to start tmysql4 provider, but module not found")
        end

        module.tmysql = require("tmysql4")

        module.SetActiveProvider(name)
        module.log("tmysql4 provider started")

        return
    end

    if provider == "sqlite" then

        module.SetActiveProvider("sqlite")
        module.log("SQLite provider started")

        return
    end

    module.error("Try to start unknown provider: ", provider)
end


module.Start("sqlite")


function module.SQLEscape(str)
    local ActiveProvider = module.GetActiveProvider()

    if type(str) == "number" then
        return str
    end

    if ActiveProvider == "tmysql4" then
        return module.tmysql.escape(str)
    end

    if ActiveProvider == "mysqloo" then
        return module.mysqloo.Escape(str)
    end

    if ActiveProvider == "sqlite" then
        return sql.SQLStr(str)
    end

    module.error("No active provider found")
end


---@param tableName string
---@param callback fun(bExists:boolean)
function module.IsTableExists(tableName, callback)
    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider == "tmysql4" then
        module.Query("SHOW TABLES LIKE '" .. tableName .. "'", function(result)
            callback(result[1].data[1] ~= nil)
        end)

        return
    end

    if ActiveProvider == "mysqloo" then
        module.Query("SHOW TABLES LIKE '" .. tableName .. "'", function(result)
            callback(result[1].data[1] ~= nil)
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
end

---@param tableName string
---@param callback fun(result:any, query:string)
function module.DeleteTable(tableName, callback)
    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider == "tmysql4" then
        module.Query("DROP TABLE " .. tableName, callback)
        return
    end

    if ActiveProvider == "mysqloo" then
        module.Query("DROP TABLE " .. tableName, callback)
        return
    end

    if ActiveProvider == "sqlite" then
        module.Query("DROP TABLE " .. tableName, callback)
        return
    end

    module.error("No active provider found")
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
function module.ConvertType(type)
    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider == "tmysql4" then
        if type == "INTEGER" then
            return "INT"
        elseif type == "TEXT" then
            return "TEXT"
        elseif type == "REAL" then
            return "FLOAT"
        elseif type == "BLOB" then
            return "BLOB"
        elseif type == "VARCHAR" then
            return "VARCHAR"
        end
    end

    if ActiveProvider == "mysqloo" then
        if type == "INTEGER" then
            return "INT"
        elseif type == "TEXT" then
            return "TEXT"
        elseif type == "REAL" then
            return "FLOAT"
        elseif type == "BLOB" then
            return "BLOB"
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
end

---@param tableName string
---@param tableStruct db.universal_table_struct
---@param callback? fun(res:any, query:string)
function module.CreateTable(tableName, tableStruct, callback)
    assert(type(tableName) == "string", "tableName must be string")
    assert(type(tableStruct) == "table", "tableStruct must be table")

    local ActiveProvider = module.GetActiveProvider()

    if ActiveProvider == "tmysql4" then
        local query = "CREATE TABLE `" .. tableName .. "` \n("

        for i, column in ipairs(tableStruct.columns) do
            local columnType = module.ConvertType(column.type)
            query = query .. "\t `" .. column.name .. "` " .. columnType

            if column.length then
                if columnType == "VARCHAR" then
                    query = query .. "(" .. column.length .. ")"
                else
                    module.error("column.length is not supported for type " .. columnType)
                end
            end

            if columnType == "VARCHAR" and !column.length then
                module.error("column.length is required for type " .. columnType)
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
                query = query .. ", "
            end
        end

        query = query .. ")"

        module.Query(query, callback)
        return
    end

    if ActiveProvider == "mysqloo" then
        local query = "CREATE TABLE `" .. tableName .. "` \n("

        for i, column in ipairs(tableStruct.columns) do
            local columnType = module.ConvertType(column.type)
            query = query .. "\t `" .. column.name .. "` " .. columnType

            if column.length then
                if columnType == "VARCHAR" then
                    query = query .. "(" .. column.length .. ")"
                else
                    module.error("column.length is not supported for type " .. columnType)
                end
            end

            if columnType == "VARCHAR" and !column.length then
                module.error("column.length is required for type " .. columnType)
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
                query = query .. ", "
            end
        end

        query = query .. ")"

        module.Query(query, callback)
        return
    end

    if ActiveProvider == "sqlite" then
        local query = "CREATE TABLE `" .. tableName .. "` \n(\n"

        for i, column in ipairs(tableStruct.columns) do
            local columnType = module.ConvertType(column.type)
            query = query .. "\t `" .. column.name .. "` " .. columnType

            if column.length then
                if columnType == "VARCHAR" then
                    query = query .. "(" .. column.length .. ")"
                else
                    module.error("column.length is not supported for type " .. columnType)
                end
            end

            if columnType == "VARCHAR" and !column.length then
                module.error("column.length is required for type " .. columnType)
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
end

module.IsTableExists("db_test", function(bExists)
    if bExists then
        module.log("Table exists db_test")

        module.DeleteTable("db_test", function()
            module.log("Table db_test deleted")
        end)
    else
        module.log("Table not exists db_test, creating...")

        module.CreateTable("db_test", {
            columns = {
                {
                    name = "id",
                    type = "INTEGER",
                    primaryKey = true,
                    autoIncrement = true
                },
                {
                    name = "steamid",
                    type = "TEXT",
                    notNull = true
                },
                {
                    name = "name",
                    type = "TEXT",
                    notNull = true
                },
                {
                    name = "money",
                    type = "INTEGER",
                    default = 0
                },
                {
                    name = "created_at",
                    type = "INTEGER",
                }
            }
        }, function(res, query)
            print("Table zen_users created", res, query)
        end)

    end
end)