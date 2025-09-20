---@meta
module("zen")

---@class zen.mysql_client
mysql_client = _GET("mysql_client")

---@type table <string, mysql_client.Client>
mysql_client.mt_ClientList = mysql_client.mt_ClientList or {}

mysql_client.iClientID = mysql_client.iClientID or 0


---@class mysql_host_settings
---@field enable boolean? Default true
---@field address string
---@field user string
---@field password string
---@field database string
---@field port number? Default 3306
---@field module string? Default "mysqloo"


---@class mysql_client.Client

/*
Example setup configurations with file (garrysmod/database_settings.txt):
```
local DB_CLIENT = mysql_client.NewClient("client_name", "database_settings.txt")
```

`garrysmod/database_settings.txt` (example):
```
database
{
    address "127.0.0.1"
    port 3306
    user "root"
    password ""
    database "database_name"
    module "mysqloo"
}
```
*/
---@param client_name string
---@param mysql_host_settings mysql_host_settings|string If string, then load as keyvalues from file path, relative to garrysmod/ (mean don't add garrysmod/ prefix)
---@return mysql_client.Client
function mysql_client.NewClient(client_name, mysql_host_settings)
    assert(type(client_name) == "string", "mysql_client.NewClient() client_name must be a string")
    assert(type(mysql_host_settings) == "table" or type(mysql_host_settings) == "string", "mysql_client.NewClient() mysql_host_settings must be a table or string")

    if type(mysql_host_settings) == "string" then

        -- Load settings from file
        local FileData = file.Read(mysql_host_settings, "GAME")
        assert(FileData, "mysql_client.NewClient() mysql_host_settings file not found: " .. mysql_host_settings)
        local data = util.KeyValuesToTable(FileData)
        assert(type(data) == "table", "mysql_client.NewClient() mysql_host_settings file is not a valid keyvalues file: " .. mysql_host_settings)

        mysql_host_settings = {
            address = data.address or data.host,
            user = data.user or data.username,
            password = data.password or data.pass,
            database = data.database or data.db or data.dbname,
            port = tonumber(data.port),
            module = data.module,
        }
    end

    assert(type(mysql_host_settings.address) == "string", "mysql_client.NewClient() mysql_host_settings.address must be a string")
    assert(type(mysql_host_settings.user) == "string", "mysql_client.NewClient() mysql_host_settings.user must be a string")
    assert(type(mysql_host_settings.password) == "string", "mysql_client.NewClient() mysql_host_settings.password must be a string")
    assert(type(mysql_host_settings.database) == "string", "mysql_client.NewClient() mysql_host_settings.database must be a string")
    assert(type(mysql_host_settings.module) == "string" or mysql_host_settings.module == nil, "mysql_client.NewClient() mysql_host_settings.module must be a string or nil")
    assert(type(mysql_host_settings.port) == "number" or mysql_host_settings.port == nil, "mysql_client.NewClient() mysql_host_settings.port must be a number or nil")
    assert(mysql_host_settings.module == "mysqloo", "mysql_client.NewClient() mysql_host_settings.module must be 'mysqloo'")
    assert(mysql_host_settings.address ~= "", "mysql_client.NewClient() mysql_host_settings.address must not be empty")
    assert(mysql_host_settings.user ~= "", "mysql_client.NewClient() mysql_host_settings.user must not be empty")
    assert(mysql_host_settings.password ~= "", "mysql_client.NewClient() mysql_host_settings.password must not be empty")
    assert(mysql_host_settings.database ~= "", "mysql_client.NewClient() mysql_host_settings.database must not be empty")
    assert(mysql_host_settings.module ~= "", "mysql_client.NewClient() mysql_host_settings.module must not be empty")

    -- Check address is not localhost
    assert(mysql_host_settings.address ~= "localhost", "mysql_client.NewClient() mysql_host_settings.address must not be 'localhost', use ip address instead (example: 127.0.0.1 or 0.0.0.0)")



    -- Kill old client if exists
    local PREV_CLIENT = mysql_client.mt_ClientList[client_name]
    if PREV_CLIENT then
        PREV_CLIENT.Log("Killing old client")
        PREV_CLIENT.Kill()
        mysql_client.mt_ClientList[client_name] = nil
    end

    local format = string.format


    local MYSQL_CLIENT = {} --[[@class mysql_client.Client]]

    mysql_client.mt_ClientList[client_name] = MYSQL_CLIENT

    mysql_client.iClientID = mysql_client.iClientID + 1
    MYSQL_CLIENT.name = client_name
    MYSQL_CLIENT.id = mysql_client.iClientID
    MYSQL_CLIENT.full_name = format("%s-#%s", client_name, MYSQL_CLIENT.id)

    -- Autoreconnecting
    MYSQL_CLIENT.CheckConnectionEach = 5 -- seconds
    MYSQL_CLIENT.LastCheckConnection = 0


    MYSQL_CLIENT.MySQL = table.Copy(mysql_host_settings)
    if MYSQL_CLIENT.MySQL.enable == nil then MYSQL_CLIENT.MySQL.enable = true end



    local color_prefix = Color(255, 255, 0)
    local color_text = Color(255, 255, 255)

    local MsgC = MsgC
    local MsgN = MsgN

    function MYSQL_CLIENT.Log(...)
        MsgC(color_prefix, format("[MySQL-%s] ", MYSQL_CLIENT.full_name))
        MsgC(color_text, ...)
        MsgN()
    end

    --- Alias to hook.Run, but with client_name prefix
    ---@param name string
    ---@param ... any
    function MYSQL_CLIENT.HookRun(name, ...)
        if MYSQL_CLIENT.MySQL.enable then
            local hook_name = format("MySQL_%s__%s", MYSQL_CLIENT.full_name, name)
            hook.Run(hook_name, ...)
        end
    end

    --- Alias to hook.Add, but with client_name prefix
    ---@param name string
    ---@param identifier string
    ---@param func function
    function MYSQL_CLIENT.HookAdd(name, identifier, func)
        if MYSQL_CLIENT.MySQL.enable then
            local hook_name = format("MySQL_%s__%s", MYSQL_CLIENT.full_name, name)
            hook.Add(hook_name, identifier, func)
        end
    end

    --- Alias to hook.Remove, but with client_name prefix
    ---@param name string
    ---@param identifier string
    function MYSQL_CLIENT.HookRemove(name, identifier)
        if MYSQL_CLIENT.MySQL.enable then
            local hook_name = format("MySQL_%s__%s", MYSQL_CLIENT.full_name, name)
            hook.Remove(hook_name, identifier)
        end
    end

    MYSQL_CLIENT.mt_WaitConnnectCallback = {}

    --- Called when MySQL is connected
    ---@param identifier string
    ---@param func function
    ---@param bCallIfConnected boolean?
    function MYSQL_CLIENT.OnConnect(identifier, func, bCallIfConnected)
        MYSQL_CLIENT.mt_WaitConnnectCallback[identifier] = func

        if bCallIfConnected and MYSQL_CLIENT.IsConnected() then
            if func then func() end
        end
    end

    -- Open connection to MySQL
    ---@param onConnect function?
    ---@param onError function?
    function MYSQL_CLIENT.Connect(onConnect, onError)
        if not MYSQL_CLIENT.MySQL.enable then
            MYSQL_CLIENT.Log("MySQL is disabled")
            MYSQL_CLIENT.HookRun("db.onConnect")
            if onConnect then onConnect() end

            -- call alls MYSQL_CLIENT.mt_WaitConnnectCallback with xpcall and ErrorNoHaltWithStack
            for identifier, func in pairs(MYSQL_CLIENT.mt_WaitConnnectCallback) do
                local success, err = xpcall(func, ErrorNoHaltWithStack)
                if not success then
                    MYSQL_CLIENT.Log("Error in MYSQL_CLIENT.OnConnect callback: ", identifier, " - ", err)
                end
            end
            return
        end

        if not MYSQL_CLIENT.IsModuleExists(MYSQL_CLIENT.MySQL.module) then
            MYSQL_CLIENT.Log("MySQL module `", MYSQL_CLIENT.MySQL.module, "` not found, please install it")
            if onError then onError("MySQL module not found") end
            return
        end

        -- Support only mysqloo
        if MYSQL_CLIENT.MySQL.module ~= "mysqloo" then
            MYSQL_CLIENT.Log("MySQL module `", MYSQL_CLIENT.MySQL.module, "` not supported, please use mysqloo")
            if onError then onError("MySQL module not supported") end
            return
        end

        -- Check already connected
        if MYSQL_CLIENT.IsConnected() then
            MYSQL_CLIENT.Log("MySQL already connected")
            MYSQL_CLIENT.HookRun("db.onConnect")
            if onConnect then onConnect() end
            return
        end

        -- Block creating multiple connections
        if MYSQL_CLIENT.db then
            MYSQL_CLIENT.Log("Session already exists, please wait DB will auto reconnect")
            if onError then onError("Session already exists, please wait DB will auto reconnect") end
            return
        end

        require(MYSQL_CLIENT.MySQL.module)

        -- Create database for mysqloo
        MYSQL_CLIENT.db = mysqloo.connect(
            MYSQL_CLIENT.MySQL.address,
            MYSQL_CLIENT.MySQL.user,
            MYSQL_CLIENT.MySQL.password,
            MYSQL_CLIENT.MySQL.database,
            MYSQL_CLIENT.MySQL.port
        )

        local COLOR_GOOD = Color(0, 255, 0)
        local COLOR_ERROR = Color(255, 0, 0)

        function MYSQL_CLIENT.db:onConnected()
            if MYSQL_CLIENT.IsConnected() then
                MYSQL_CLIENT.Log("Connecting stabilized: ", COLOR_GOOD, "Success")
            else
                MYSQL_CLIENT.Log("Connecting stabilized: ", COLOR_ERROR, "Failed. Database not connected")
                MYSQL_CLIENT.HookRun("db.onDisconnect")
            end

            MYSQL_CLIENT.HookRun("db.onConnect")
            if onConnect then onConnect() end
        end

        function MYSQL_CLIENT.db:onConnectionFailed(err)
            MYSQL_CLIENT.Log("MySQL connection failed: " .. err)
            if onError then onError(err) end
            MYSQL_CLIENT.db = nil
        end

        function MYSQL_CLIENT.db:onError(err)
            MYSQL_CLIENT.Log("MySQL error: " .. err)
            if onError then onError(err) end
        end

        function MYSQL_CLIENT.db:onDisconnected()
            MYSQL_CLIENT.Log("MySQL disconnected")
            MYSQL_CLIENT.HookRun("db.onDisconnect")
        end

        MYSQL_CLIENT.db:setAutoReconnect(true)
        MYSQL_CLIENT.db:connect()
    end

    -- Check Database is connected
    function MYSQL_CLIENT.IsConnected()
        if not MYSQL_CLIENT.MySQL.enable then
            return true
        end

        if MYSQL_CLIENT.db == nil then return false end

        return MYSQL_CLIENT.db:ping()
    end

    -- Disconnect from MySQL
    function MYSQL_CLIENT.Disconnect(should_kill)
        MYSQL_CLIENT.bDisconnected = true

        if MYSQL_CLIENT.IsConnected() then
            MYSQL_CLIENT.Log("Disconnecting from MySQL")
            MYSQL_CLIENT.db:disconnect(true)
            if should_kill then
                MYSQL_CLIENT.bMarkedForDeletion = true
            end
        end
    end

    -- Kill MySQL connection
    function MYSQL_CLIENT.Kill()
        MYSQL_CLIENT.Log("Killing MySQL connection")
        MYSQL_CLIENT.Disconnect(true)
    end

    -- On

    ---@param module string
    ---@return boolean
    function MYSQL_CLIENT.IsModuleExists(module)
        /*
            gmsv_example_win32.dll 	Server 	example 	Windows x32
            gmcl_example_win32.dll 	Client 	example 	Windows x32
            gmsv_example_win64.dll 	Server 	example 	Windows x64 (x86-64 branch is required)
            gmcl_example_win64.dll 	Client 	example 	Windows x64 (x86-64 branch is required)
            gmsv_example_osx.dll 	Server 	example 	OSX (actually a .so file, just renamed)
            gmcl_example_osx.dll 	Client 	example 	OSX (actually a .so file, just renamed)
            gmsv_example_linux.dll 	Server 	example 	Linux x32 (actually a .so file, just renamed)
            gmcl_example_linux.dll 	Client 	example 	Linux x32 (actually a .so file, just renamed)
            gmsv_example_linux64.dll 	Server 	example 	Linux x64 (actually a .so file, just renamed; x86-64 branch is required)
            gmcl_example_linux64.dll 	Client 	example 	Linux x64 (actually a .so file, just renamed; x86-64 branch is required)
        */
        local prefix = CLIENT and "gmcl_" or "gmsv_"

        local system_name = "osx"
        if system.IsLinux() then system_name = "linux" end
        if system.IsWindows() then system_name = "win32" end

        if BRANCH == "x86-64" then
            if system_name == "linux" then
                system_name = "linux64"
            elseif system_name == "win" then
                system_name = "win64"
            end
        end

        local postfix = "_" .. system_name .. ".dll"

        local path = "lua/bin/" .. prefix .. module .. postfix

        return file.Exists(path, "GAME")
    end


    -- MySQLite query with success and error callback
    ---@param query string
    ---@param success function?
    ---@param err_callback function?
    function MYSQL_CLIENT.Query(query, success, err_callback)
        assert(type(query) == "string", "MYSQL_CLIENT.QueryFormat() query must be a string")
        assert(type(success) == "function" or success == nil, "MYSQL_CLIENT.QueryFormat() success must be a function")
        assert(type(err_callback) == "function" or err_callback == nil, "MYSQL_CLIENT.QueryFormat() err_callback must be a function")

        if not MYSQL_CLIENT.IsConnected() then
            MYSQL_CLIENT.Log("MySQL is not connected")
            if err_callback then err_callback("MySQL is not connected") end
            return
        end

        -- Make AUTO_INCREMENT available for SQLite and MySQL
        if MYSQL_CLIENT.MySQL.enable then
            query = string.gsub(query, "AUTOINCREMENT", "AUTO_INCREMENT")
        else
            if string.find(query, "AUTO_INCREMENT") then
                query = string.gsub(query, "AUTO_INCREMENT", "PRIMARY KEY")
            end
        end

        local MYSQL_QUERY = MYSQL_CLIENT.db:query(query)

        function MYSQL_QUERY:onSuccess(data)
            if success then success(data) end
        end

        local COLOR_ERROR = Color(255, 0, 0)
        local COLOR_TEXT = Color(255, 0, 255)
        function MYSQL_QUERY:onError(err)
            MYSQL_CLIENT.Log(
                COLOR_ERROR,
                "MySQL Error: ",
                err,
                COLOR_TEXT,
                "\n------------------------------------Query------------------------------------\n",
                query,
                "\n-----------------------------------------------------------------------------"
            )
            ErrorNoHaltWithStack(err)
            if err_callback then err_callback(err) end
        end

        MYSQL_QUERY:start()
    end


    -- MySQLite query with string.format, and success and error callback
    ---@param query string
    ---@param vars table?
    ---@param success function?
    ---@param err_callback function?
    function MYSQL_CLIENT.QueryFormat(query, vars, success, err_callback)
        assert(type(query) == "string", "MYSQL_CLIENT.QueryFormat() query must be a string")
        assert(type(vars) == "table" or vars == nil, "MYSQL_CLIENT.QueryFormat() vars must be a table")
        assert(type(success) == "function" or success == nil, "MYSQL_CLIENT.QueryFormat() success must be a function")
        assert(type(err_callback) == "function" or err_callback == nil, "MYSQL_CLIENT.QueryFormat() err_callback must be a function")

        if vars == nil then vars = {} end

        -- Secure all vars
        for i = 1, #vars do
            if type(vars[i]) == "string" then
                vars[i] = MYSQL_CLIENT.db:escape(vars[i])
            elseif type(vars[i]) == "number" then
                vars[i] = tonumber(vars[i])
            elseif type(vars[i]) == "boolean" then
                vars[i] = vars[i] and 1 or 0
            else
                MYSQL_CLIENT.Log("MYSQL_CLIENT.QueryFormat() vars[" .. i .. "] is not a string, number or boolean")
                if err_callback then err_callback("MYSQL_CLIENT.QueryFormat() vars[" .. i .. "] is not a string, number or boolean") end
                return
            end
        end

        -- Add quotas to strings
        for i = 1, #vars do
            if type(vars[i]) == "string" then
                vars[i] = "'" .. vars[i] .. "'"
            end
        end

        -- Remove ' from '%s' and remove ` from `%s`
        query = string.gsub(query, "'[^']*%%s[^']*'", "%%s")

        local format_query = string.format(query, unpack(vars))

        MYSQL_CLIENT.Query(format_query, success, err_callback)
    end

    function MYSQL_CLIENT.SetupConnection()
        if !MYSQL_CLIENT.IsConnected() then
            MYSQL_CLIENT.Log("Setup connection...")
            MYSQL_CLIENT.Connect()
        end
    end

    function MYSQL_CLIENT.Escape(str)
        assert(type(str) == "string", "MYSQL_CLIENT.Escape() str must be a string")
        return MYSQL_CLIENT.db:escape(str)
    end

    function MYSQL_CLIENT.OnPingFailed()
        if not MYSQL_CLIENT.IsConnected() then
            MYSQL_CLIENT.Log("MySQL ping failed, reconnecting...")
            MYSQL_CLIENT.SetupConnection()
        end
    end

    hook.Add("InitPostEntity", format("MySQL_%s", MYSQL_CLIENT.full_name), MYSQL_CLIENT.SetupConnection)


    hook.Add("Tick", format("MySQL_%s_CheckConnection", MYSQL_CLIENT.full_name), function()
        if MYSQL_CLIENT.bDisconnected then return end
        if MYSQL_CLIENT.bMarkedForDeletion then
            hook.Remove("Tick", format("MySQL_%s_CheckConnection", MYSQL_CLIENT.full_name))
        end
        if MYSQL_CLIENT.LastCheckConnection + MYSQL_CLIENT.CheckConnectionEach > SysTime() then return end

        MYSQL_CLIENT.LastCheckConnection = SysTime()

        MYSQL_CLIENT:OnPingFailed()
    end)

    MYSQL_CLIENT.SetupConnection()

    return MYSQL_CLIENT
end

local COLOR_GOOD = Color(0, 255, 0)
local COLOR_ERROR = Color(255, 0, 0)

-- Concommand to dump status for all MySQL clients, with stable connection, last check time and full name
concommand.Add("mysql_client_dump", function(ply, cmd, args)
    if not IsValid(ply) or ply:IsSuperAdmin() then
        for client_name, client in pairs(mysql_client.mt_ClientList) do
            local status = client:IsConnected() and COLOR_GOOD or COLOR_ERROR
            local last_check = client.LastCheckConnection or 0
            local time_since_last_check = SysTime() - last_check

            client.Log(
                status,
                string.format(
                    "[MySQL-%s] Status: %s, Last Check: %.2f seconds ago\n",
                    client.full_name,
                    client:IsConnected() and "Connected" or "Disconnected",
                    time_since_last_check
                )
            )
        end
    end
end)

hook.Run("MySQL_ClientLoaded")