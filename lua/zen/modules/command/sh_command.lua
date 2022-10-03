local icmd, iconsole = zen.Init("command", "console")

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

function icmd.Log(who, ...)
    if CLIENT then
        iconsole.AddConsoleLog(nil, ...)
    elseif SERVER then
        if IsValid(who) then
            who:zen_console_log(...)
        else
            MsgC(...)
            MsgN()
        end
    end
end

local color_info = Color(255,255,0)
local color_err = Color(255,0,0)
local color_succ = Color(0,255,0)
local color_text = Color(255,255,255)

local function getArgs(var)
    if isbool(var) or var == nil then return end
    if isstring(var) then return {var} end
    if table(var) then return var end
    return {var}
end

local function getColor(resOrCom)
    local clr
    if isstring(resOrCom) then
        clr = color_info
    end

    if resOrCom == true then
        clr = color_succ
    elseif resOrCom == false then
        clr = color_err
    elseif resOrCom == nil then
        clr = color_info
    elseif clr == nil then
        clr = color_text
    end

    return clr
end

function icmd.LogArg(who, resOrErr, info, default)
    local clr = getColor(resOrErr)
    local res = getArgs(info) or getArgs(resOrErr)
    if res == nil then
        res = {default or "unknown error zen.command #10"}
    end
    icmd.Log(who, clr, unpack(res))
end

local function niceTags(tags)
    local tResult = {}
    for k, v in pairs(tags) do
        tResult[v] = true
    end
    return tResult
end

function icmd.CreateCommandQuery(cmd, args, tags_clear, who)
    local t_CMD_QUERY = {}
    t_CMD_QUERY.tags_clear = tags_clear
    t_CMD_QUERY.who = who
    t_CMD_QUERY.name = cmd
    t_CMD_QUERY.args = args
    t_CMD_QUERY.meta = {
        startTime = os.time()
    }
    t_CMD_QUERY.tags = niceTags(tags_clear)

    return t_CMD_QUERY
end

function icmd.OnCommandResult(cmd, args, tags_clear, who)
    if not cmd then return end

    local QCMD = icmd.CreateCommandQuery(cmd, args, tags_clear, who)
    local tags = QCMD.tags

    local tCommand = icmd.t_Commands[cmd]
    if tCommand then
        if tags["help"] then
            if tCommand.data.help then
                icmd.LogArg(who, tCommand.data.help)
            else
                icmd.LogArg(who, concat{"No help exists for command: ", cmd})
            end
            return
        end

        local hook_can, hook_com = ihook.Run("zen.icmd.CanRun", tCommand, QCMD, cmd, args, tags, who)

        if hook_can == false then
            icmd.LogArg(who, false, hook_com, "not allowed #1")
            return
        end


        local lua_res, resOrErr, com = pcall(tCommand.callback, QCMD, who, cmd, args, tags)
        if lua_res == false then
            icmd.LogArg(who, false, hook_com, concat{"lua error #1: ", cmd})
            icmd.LogArg(who, false, resOrErr, "unknown lua error #2")
            return
        end

        local skipSuccRunText = CLIENT and tCommand.IsServerCommand

        if resOrErr != false then
            if not skipSuccRunText then
                icmd.LogArg(who, resOrErr, com, concat{"Sucessful runned: ", cmd})
            end
        else
            icmd.LogArg(who, resOrErr, com, concat{"Failed run: ", cmd})
        end
    else
        icmd.LogArg(who, false, concat{"Command not exists: " .. cmd})
    end
end

function icmd.OnCommand(str)
    local cmd, args, tags = icmd.GetCommandArgs(str)
    local who = CLIENT_DLL and LocalPlayer()

    return icmd.OnCommandResult(cmd, args, tags, who)
end
ihook.Listen("OnFastConsoleCommand", "fast_console_phrase", icmd.OnCommand)


function icmd.RegisterData(tCommand)
    tCommand.types_clear = {}
    tCommand.types_names = {}

    for k, v in pairs(tCommand.types) do
        if not v.type then error("cmd_type not exists for: " .. tCommand.name .. ", id: " .. k) end
        local funcWriter = nt.GetTypeWriterFunc(v.type)
        if not funcWriter then error("func writer not exists for: " .. tCommand.name .. ", id: " .. k .. ", type: " .. v.type .. ", name: " .. tostring(v.name) ) end
        table.insert(tCommand.types_clear, v.type)
        table.insert(tCommand.types_names, v.name or "")
    end

    if !tCommand.IsServerCommand and !tCommand.IsClientCommand and !tCommand.IsMenuCommand then
        if SERVER then tCommand.IsServerCommand = true end
        if CLIENT_DLL then tCommand.IsClientCommand = true end
        if MENU_DLL then tCommand.IsMenuCommand = true end
    end

    if tCommand.IsServerCommand then tCommand.ENV = "Server" end
    if tCommand.IsClientCommand then tCommand.ENV = "Client" end
    if tCommand.IsMenuCommand then tCommand.ENV = "Menu" end

    icmd.t_Commands[tCommand.name] = tCommand

    ihook.Run("zen.icmd.Register", tCommand.name, tCommand)

    return tCommand
end

function icmd.Register(name, callback, types, data)
    local tCommand = {
        callback = callback,
        types = types or {},
        data = data or {},
        types_clear = {},
        types_names = {},
        name = name,
    }

    return icmd.RegisterData(tCommand)
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

        local sCommandList = concat{"Commands:", "\n", concat(t_FindCommands, "\n"), "\n"}

        return firstCommand, sCommandList
    else
        local lines = {}
        local t_Types = {}
        if tCommand.types then
            for id, v in pairs(tCommand.types) do
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
    if t_AutoComplatecache[str] then return unpack(t_AutoComplatecache[str]) end
    if str == "" then return false, false end

    local cmd_name, args, tags, clear_str, source, iEditArgID, iEditTagID = icmd.GetCommandArgs(str)
    if cmd_name == nil then return false, false end


    local inputHelpString, helpFullHelp = icmd.AutoCompleteCalc(cmd_name, args, tags, clear_str, source, iEditArgID, iEditTagID)
    t_AutoComplatecache[str] = {inputHelpString, helpFullHelp}

    return inputHelpString, helpFullHelp
end