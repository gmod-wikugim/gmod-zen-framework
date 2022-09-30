local icmd = zen.Init("command")
local iconsole = zen.Init("console")

icmd.t_Commands = icmd.t_Commands or {}

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

    local isNotClosed = lastLVL != nil
    local iEditChar

    if isNotClosed then
        local startChar = lastV[1]
        local endChar = #source
        local phrase = sub(source, startChar, endChar)
        local phrase_trimmed = sub(phrase, 2, #phrase)
        iEditChar = endChar
        insert(tResult, {startChar, endChar, phrase, value = phrase_trimmed})
    end


    local clear_source = GetClearSource(source, tResult)

    return tResult, clear_source, iEditChar
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

    local iEditChar
    if #source == tResult[#tResult][2] then
        iEditChar = #source
    end

    local clear_source = GetClearSource(source, tResult)

    return tResult, clear_source, iEditChar
end

local function getSimpleArgs(source)
    local t_QoutasList = getGMatchWithCharIDS(source, PATTERN_SEARCH_ARGS)

    local tResult = {}
    for k, v in pairs(t_QoutasList) do
        local value = unpack(v.args)

        v.value = value

        insert(tResult, v)
    end

    local iEditChar
    if #source == tResult[#tResult][2] then
        iEditChar = #source
    end

    local clear_source = GetClearSource(source, tResult)
    return tResult, clear_source, iEditChar
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

local check_Table = function(tbl, iEditChar, clearKeys)
    local values = {}

    local iEditID

    for k, v in SortedPairs(tbl) do
        local newid = insert(values, v.value)

        if iEditChar and iEditChar >= v[1] and iEditChar <= v[2] then
            iEditID = newid
        end

        if clearKeys then
            tbl[k] = nil
        end
    end

    if clearKeys then
        for k, v in ipairs(values) do
            tbl[k] = v
        end
    end

    return iEditID
end



function icmd.GetStringArgs(source)
    local tStringVars, clear_str, iEditChar1 = getQuotasArgs(source)
    local tTags, clear_str, iEditChar2 = getTags(clear_str)
    local tArgs, clear_str, iEditChar3 = getSimpleArgs(clear_str)

    local iEditChar = iEditChar1 or iEditChar2 or iEditChar3


    local tResultArgs = {}
    for _, v in pairs(tStringVars) do tResultArgs[v[1]] = v end
    for _, v in pairs(tArgs) do tResultArgs[v[1]] = v end

    local tResultTags = {}
    for _, v in pairs(tTags) do tResultTags[v[1]] = v end

    local iEditArgID = check_Table(tResultArgs, iEditChar, true)
    local iEditTagID = check_Table(tResultTags, iEditChar, true)

    return tResultArgs, tResultTags, clear_str, source, iEditArgID, iEditTagID
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


function icmd.GetCommandArgs(source)
    source = source or icmd.phrase
    local args, tags, clear_str, source, iEditArgID, iEditTagID = icmd.GetStringArgs(source)
    local cmd = args[1]
    remove(args, 1)

    return cmd, args, tags, clear_str, source, iEditArgID, iEditTagID
end

function icmd.ServerCommand(str)
    nt.Send("zen.console.command", {"string"}, {str})
end

function icmd.ServerConsole(str)
    nt.Send("zen.console.server_console", {"string"}, {str})
end

function icmd.Log(...)
    iconsole.AddConsoleLog(nil, ...)
    MsgC(...)
    MsgN()
end

function icmd.OnCommand(str, who)
    local cmd, args, tags = icmd.GetCommandArgs(str)
    who = who or LocalPlayer()

    icmd.Log("=" .. str)

    local tCommand = icmd.t_Commands[cmd]
    if tCommand then
        if tags["help"] then
            if tCommand.cmd_data.help then
                icmd.Log(tCommand.cmd_data.help)
            else
                icmd.Log("No help exists for command: " .. cmd)
            end
        end

        local lua_res, resOrErr, com = pcall(tCommand.callback, who, cmd, args, tags)

        if lua_res then
            if resOrErr != false then
                if isstring(resOrErr) then
                    icmd.Log("command information: " .. cmd, Color(255,255,0))
                    icmd.Log(resOrErr or com, COLOR.W)
                else
                    icmd.Log(com or ("Sucessful runned: " .. cmd), COLOR.G)
                end
            else
                icmd.Log(com or ("Failed run: " .. cmd), Color(255,255,0))
            end
        else
            local errtext = resOrErr .. "\n\t" .. debug.traceback()
            icmd.Log(("Error run: " .. cmd), COLOR.R)
            icmd.Log(errtext, COLOR.R)
        end
    else
        icmd.Log("Command not exists: " .. cmd, COLOR.R)
    end
end
ihook.Listen("OnFastConsoleCommand", "fast_console_phrase", icmd.OnCommand)


function icmd.Register(cmd_name, cmd_callback, cmd_types, cmd_data)
    local tCommand = {
        callback = cmd_callback,
        cmd_types = cmd_types or {},
        cmd_data = cmd_data or {},
    }
    if SERVER then tCommand.IsServerCommand = true tCommand.ENV = "Server" end
    if CLIENT then tCommand.IsClientCommand = true tCommand.ENV = "Client" end
    if MENU then tCommand.IsMenuCommand = true tCommand.ENV = "Menu" end

    icmd.t_Commands[cmd_name] = tCommand
end

local COLOR_AUTOCOMPLE_SELECT_ARG = Color(125, 125, 255)

local function font_text(text, font)
    if font == nil then return text end
	local color_start = concat{"<font=",font,">"}
	local color_end = "</font>"
	return concat{color_start,text,color_end}
end

local function color_text(text, color)
    if color == nil then return text end
	local color_start = concat{"<color=",color.r,",",color.g,",",color.b,",",color.a,">"}
	local color_end = "</color>"
	return concat{color_start,text,color_end}
end

local function text_selected(text)
    return color_text(text, COLOR_AUTOCOMPLE_SELECT_ARG)
end

local function text_editing(text)
    return font_text(text, icmd.DrawFont_UnderLine)
end


function icmd.AutoCompleteCalc(cmd_name, args, tags, clear_str, source, iEditArgID, iEditTagID)
    local iArgIDEdit = iEditArgID and (iEditArgID-1) or (!iEditTagID and (#args+1))

    local tCommand = icmd.t_Commands[cmd_name]
    if tCommand == nil then
        local firstCommand
        local t_FindCommands = {}
        for name in pairs(icmd.t_Commands) do
            if find(name, cmd_name) then
                insert(t_FindCommands, name)
                if not firstCommand then
                    firstCommand = name
                end
            end
        end

        local sCommandList = concat{"Commands:", "\n", concat(t_FindCommands), "\n"}

        return firstCommand, sCommandList
    else
        local lines = {}
        local t_Types = {}
        if tCommand.cmd_types then
            for id, v in pairs(tCommand.cmd_types) do
                local str = concat({"[", v.type, " ", v.name, "]"})

                if id == iArgIDEdit then
                    str = text_selected(str)
                end

                insert(t_Types, str)
            end
        end
        lines[1] = "Command Info:"
        lines[2] = concat{cmd_name, " ", concat(t_Types, " ")}

        local t_Args = {}
        for id, value in pairs(args) do
            if id == iArgIDEdit then
                value = text_editing(value)
            end
            insert(t_Args, value)
        end
        lines[3] = concat{text_selected(":= ["), concat(t_Args, text_selected("][")), text_selected("]")}

        local t_Tags = {}
        for id, tag in pairs(tags) do
            if id == iEditTagID then
                tag = text_editing(tag)
            end
            insert(t_Tags, tag)
        end

        if next(t_Tags) then
            insert(lines, concat{text_selected("tags: ["), concat(t_Tags, text_selected("][")), text_selected("]")})
        end

        local fullInfo = concat(lines, "\n")


        return nil, fullInfo
    end
end

local t_AutoComplatecache = setmetatable({}, {__mode = "kv"})
function icmd.GetAutoComplete(str)
    --if t_AutoComplatecache[str] then return unpack(t_AutoComplatecache[str]) end
    if str == "" then return false, false end

    local cmd_name, args, tags, clear_str, source, iEditArgID, iEditTagID = icmd.GetCommandArgs(str)
    if cmd_name == nil then return false, false end


    local inputHelpString, helpFullHelp = icmd.AutoCompleteCalc(cmd_name, args, tags, clear_str, source, iEditArgID, iEditTagID)
    t_AutoComplatecache[str] = {inputHelpString, helpFullHelp}

    return inputHelpString, helpFullHelp
end