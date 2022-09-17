local iconsole = zen.Import("console")
iconsole.t_Commands = iconsole.t_Commands or {}

local len = string.len
local sub = string.sub
local insert = table.insert
local gmatch = string.gmatch
local match = string.match
local tonumber = tonumber
local remove = table.remove

local REPLACE_ID = "argid_"
local REPLACE_ID_SUB = len(REPLACE_ID)

local gsub = string.gsub
local concat = table.concat
local find = string.find
local rep = string.rep
-- local

local PATTERN_SEARCH_TAGS = [[([%-]+)([%g]+)]]
local PATTERN_SEARCH_ARGS = [[([%g]+)]]


local function getGMatchWithCharIDS(source, pattern, StartChar, EndChar)
    local tResult = {}
    local CharLen = #source
    local StartChar = StartChar or 1

    if EndChar and EndChar != CharLen then
        source = sub(source, StartChar, EndChar)
    end

    while StartChar <= CharLen do
        local find_result = {find(source, pattern, StartChar)}

        local a1, a2 = find_result[1], find_result[2]

        if not a1 then break end

        remove(find_result, 2)
        remove(find_result, 1)

        local text = sub(source, a1, a2)

        StartChar = a2 + 1

        insert(tResult, {a1, a2, text, args = find_result})
    end

    return tResult
end

local function GetClearSource(source, tResult)
    local result_count = #tResult
    local clear_source = source

    if result_count > 0 then
        for k = result_count, 1, -1 do
            local v = tResult[k]
            local StartChar = v[1]
            local EndChar = v[2]
            local Text = v[3]

            local TextLen = #Text

            local PreSource = sub(clear_source, 1, StartChar-1)
            local PostSource = sub(clear_source, EndChar+1)
            clear_source = concat{PreSource, rep("\1", TextLen), PostSource}
        end
    end

    return clear_source
end

local function getQuotasArgs(source)
    local t_QoutasList = getGMatchWithCharIDS(source, [["+]])

    local tResult = {}
    local lastLVL
    local lastV
    for id, v in ipairs(t_QoutasList) do
        local lvl = #v[3]
        if lastLVL == nil then
            lastLVL = lvl
            lastV = v
            continue
        end

        if lastLVL == lvl then
            local startChar = lastV[1]
            local endChar = v[2]
            local phrase = sub(source, startChar, endChar)
            local phrase_trimmed = sub(phrase, 2, #phrase-1)
            insert(tResult, {startChar, endChar, phrase, value = phrase_trimmed})
            lastLVL = nil
        end
    end

    local clear_source = GetClearSource(source, tResult)

    return tResult, clear_source
end


local function getTags(source)
    local t_QoutasList = getGMatchWithCharIDS(source, PATTERN_SEARCH_TAGS)
    
    local tResult = {}
    for k, v in pairs(t_QoutasList) do
        local ignore, tag_name = unpack(v.args)
        if #ignore < 2 then continue end

        v.value = tag_name

        insert(tResult, v)
    end

    local clear_source = GetClearSource(source, tResult)

    return tResult, clear_source
end

local function getSimpleArgs(source)
    local t_QoutasList = getGMatchWithCharIDS(source, PATTERN_SEARCH_ARGS)

    local tResult = {}
    for k, v in pairs(t_QoutasList) do
        local value = unpack(v.args)

        v.value = value

        insert(tResult, v)
    end

    local clear_source = GetClearSource(source, tResult)
    return tResult, clear_source
end

-- PrintTable()


local print_nice = function(what, ...)
    local args = {...}

    if istable(args[1]) then
        tbl = args[1]
    else
        tbl = args
    end

    print(what .. "(" .. concat(tbl,", ") .. ")")
end

local table_ClearKeysAbsolute = function(tbl)
    local values = {}

    for k, v in SortedPairs(tbl) do
        insert(values, v)
        tbl[k] = nil
    end

    for k, v in ipairs(values) do
        tbl[k] = v
    end
end



local t_StringArgsResultCache = setmetatable({}, {__mode = "kv"})
function iconsole.GetStringArgs(source)
    if t_StringArgsResultCache[source] then return unpack(t_StringArgsResultCache[source]) end

    local tStringVars, clear_str = getQuotasArgs(source)
    local tTags, clear_str = getTags(clear_str)
    local tArgs, clear_str = getSimpleArgs(clear_str)


    local tResultArgs = {}
    for _, v in pairs(tStringVars) do tResultArgs[v[1]] = v.value end
    for _, v in pairs(tArgs) do tResultArgs[v[1]] = v.value end

    local tResultTags = {}
    for _, v in pairs(tTags) do tResultTags[v[1]] = v.value end

    table_ClearKeysAbsolute(tResultArgs)
    table_ClearKeysAbsolute(tResultTags)

    t_StringArgsResultCache[source] = {tResultArgs, tResultTags, clear_str}

    return tResultArgs, tResultTags, clear_str
end
--[[
    print "STEAM_0:1:1111111" "Testing go" --gold
        args(print, STEAM_0:1:1111111, Testing go)
        tags(gold)
    admin_mode ban STEAM_0:1:1111111 10d "Very bad Player"
        args(admin_mode, ban, STEAM_0:1:1111111, 10d, Very bad Player)
        tags()
    lua_run ""print("Hello World!") MsgAll("It's works nice :d") ""
        args(lua_run, "print("Hello World!") MsgAll("It's works nice :d") ")
        tags()
]]


function iconsole.OnCommand(str, mode)
    if str == "clear" then iconsole.ServerConsoleLog = "" return end
    if not str or str == "" then str = "zen_null" end
    iconsole.AddConsoleLog(IS_MSGN, ":" .. str)
    if mode == MODE_DEFAULT then
        nt.Send("zen.console.command", {"string"}, {str})
    elseif mode == MODE_SERVER then
        nt.Send("zen.console.server_console", {"string"}, {str})
    elseif mode == MODE_CLIENT then
        local args = str:Split(" ")
        local cmd = args[1]
        table.remove(args, 1)
        RunConsoleCommand(args[1], unpack(args))
    end
end
ihook.Listen("OnFastConsoleCommand", "fast_console_phrase", iconsole.OnCommand)


function iconsole.RegCommand(cmd_name, cmd_callback, cmd_types)
    iconsole.t_Commands[cmd_name] = {
        callback = cmd_callback,
        cmd_types = cmd_types
    }
end

function iconsole.GetAutoComplete(str)
end