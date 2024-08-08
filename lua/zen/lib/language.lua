module("zen", package.seeall)

/*
    Language module

    This module is responsible for managing the language system.

    Links:
        local P = language.GetLanguageForEdit("en")
        local L = language.L

    Examples:
    - Just get translated phrase
        P["welcome"] = "Welcome to Zen Framework!"
        L("welcome") --> Welcome to Zen Framework!

        P["physgun.name"] = "Physgun"
        L("physgun.name") --> Physgun
     - Simple interpolation
        -- numeric index
        P["entity_spawned"] = "Someone spawned $1"
        L("entity_spawned", {ent}) --> Someone spawned Entity [0][worldspawn]

        P["player_info"] = "Info: $1"
        L("player_info", {LocalPlayer()}) --> Info: Player [1][Nick]
        -- string index
        P["entity_spawned"] = "Someone spawned $ent"
        L("entity_spawned", {ent = ent}) --> Someone spawned Entity [0][worldspawn]

        P["player_info"] = "Info: $ply"
        L("player_info", {ply = LocalPlayer()}) --> Info: Player [1][Nick]
    - Advanced interpolation
        P["player_info"] = "Info: ${ply:1}"
        L("player_info", {LocalPlayer()}) --> Info: Nick1

        P["dmg_log"] = "Player ${ply:attacked} has damaged ${ply:victim} for ${n:damage} damage"
        L("dmg_log", {attacked = LocalPlayer(), victim = LocalPlayer(), damage = 1111})
            --> Player Nick1 has damaged Nick2 for 1.111 damage

    Info:
    - If language is not found, it will use default language
    - if interpolated key is string and value not found, it will use key index(number) and try to find value with tab[index]
        !!!! Different schemas use local index_counter !!!!!
        -- Register example:
        P["player_info"] = "Player ${who} has joined the server"
        P["player_info"] = "Player ${s:who} has joined the server"
        -- Usage example:
        L("player_info", {LocalPlayer()}) - Player Player Player [1][Nick] has joined the server
        L("player_info", {who = LocalPlayer()}) - Player Player Player [1][Nick] has joined the server
        -- You can use any combination of keys and indexes and it get same result


    Default interpolation types:
    - ply - Player Name as var:Nick()
    - n - Number with commas
    - s - String
    - arg - Argument as string
    - date|time - Date as os.date("!%H:%M %m.%d.%y", var), example: 12:00 01.01.21

    Usage:
    - language.GetLanguage() - Get current language
    - language.GetLanguagePhrase(lang_id, phrase) - Get phrase from language
    - language.GetTranslatedPhrase(phrase) - Get translated phrase
    - language.GetTranslatedPhraseInterpolate(phrase, tab, onlyText) - Get translated phrase with interpolation

*/

lang = _GET("lang")

lang.mt_Langauges = lang.mt_Langauges or {}
local LL = lang.mt_Langauges

lang.DEFAULT_LANG = "en"

local cvar_lang = GetConVar("gmod_language"):GetString()

lang.ACTIVE_LANG = (#cvar_lang > 0) and cvar_lang or lang.DEFAULT_LANG

local read_types = {
    ["ply"] = function(var) return isentity(var) and var.Nick and (var:Nick() or "NIL") or tostring(var) end,
    ["n"] = function(var) return string.Comma(tostring(var)) end,
    ["s"] = function(var) return tostring(var) end,
    ["arg"] = function(var, onlyText)
        var = tostring(var)
        return var
    end,
    ["date"] = function(var) return os.date("!%H:%M %m.%d.%y", var) end,
}

local phrase_alias = {
    ["time"] = function() return os.date("!%H:%M %m.%d.%y", os.time()) end,
}

local _sub = string.sub
local _concat = table.concat
local _match = string.match
local _gsub = string.gsub
local _tostring = tostring
local _tonumber = tonumber
local _find = string.find

local CHECK_SIMPLE_INTERPOLATE_PATTERN = "$"
local SIMPLE_INTERPOLATE_PATTERN = "($[%w_-]+)"

local CHECK_ADVANCED_INTERPOLATE_PATTERN = "${"
local ADVANCED_INTERPOLATE_PATTERN = "($%b{})"
local function InterpolateConfig(message, read_types, phrase_alias, tab, onlyText)
    tab = tab or {}

    local iSharedCounter = 0

    -- Advanced interpolation
    if _find(message, CHECK_ADVANCED_INTERPOLATE_PATTERN, 1, true) then
        local iLocalCounter = 0
        message = _gsub(message, ADVANCED_INTERPOLATE_PATTERN, function(w)
            iLocalCounter = iLocalCounter + 1
            iSharedCounter = iSharedCounter + 1
            local value = _sub(w, 3, -2)

            if phrase_alias[value] then
                return phrase_alias[value]()
            end

            local strict_type, tab_key = _match(value, "(%a+):(.+)")

            if strict_type and tab_key then
                local isNumberic
                local number_value = _tonumber(tab_key)
                if number_value then
                    tab_key = number_value
                    isNumberic = true
                end

                local value = tab[tab_key]

                if !value and !isNumberic then
                    value = tab[iLocalCounter]
                end

                if read_types[strict_type] then
                    value = read_types[strict_type](value, onlyText)
                end

                if !value then
                    return _concat{"${",strict_type, ':"', tostring(tab_key), '"}'}
                end

                return value
            end

            return w
        end)
    end


    -- Simple interpolation
    if _find(message, CHECK_SIMPLE_INTERPOLATE_PATTERN, 1, true) then
        local iLocalCounter = 0
        message = _gsub(message, SIMPLE_INTERPOLATE_PATTERN, function(w)
            iLocalCounter = iLocalCounter + 1

            local value = _sub(w, 2)

            if tab[value] then
                return _tostring(tab[value])
            else
                local counter_value = tab[iLocalCounter]
                if counter_value then
                    return _tostring(counter_value)
                end
            end
        end)
    end

    return message
end


---@param lang_id string
---@return table<string, string>
function lang.GetLanguageForEdit(lang_id)
    if !lang.mt_Langauges[lang_id] then
        lang.mt_Langauges[lang_id] = {}
    end

    local mPhrases = lang.mt_Langauges[lang_id]

    setmetatable(mPhrases, {
        __index = function(t, k)
            return k
        end,
        __newindex = function(t, k, v)
            rawset(t, k, v)

            if lang_id == lang.GetLanguage() then
                language.Add(k, v)
            end
        end
    })

    return lang.mt_Langauges[lang_id]
end

---@return string
function lang.GetLanguage()
    return lang.ACTIVE_LANG
end

function lang.Update()
    local phrases = lang.mt_Langauges[lang.GetLanguage()]

    if phrases then
        for k, v in pairs(phrases) do
            language.Add(k, v)
        end
    end
end

if CLIENT then
    cvars.AddChangeCallback("gmod_language", function(_, _, value)
        if value and #value > 0 then
            lang.ACTIVE_LANG = value
        end

        lang.Update()
    end, "language.update")
    if !lang.bInitialized then
        lang.Update()
        lang.bInitialized = true
    end
end



---@param lang_id string
---@param phrase string
---@return string|nil
function lang.GetLanguagePhrase(lang_id, phrase)
    local lang_id = lang_id or lang.DEFAULT_LANG

    local translated = LL[lang_id] and LL[lang_id][phrase]

    if !translated then
        translated = LL[lang.DEFAULT_LANG] and LL[lang.DEFAULT_LANG][phrase]
    end

    return translated
end

-- PrintTable(language.mt_Langauges)

---@param phrase string
---@return string
function lang.GetTranslatedPhrase(phrase)
    local lang_id = lang.GetLanguage()

    -- Remove # prefix
    if string.StartWith(phrase, "#") then
        phrase = string.sub(phrase, 2)
    end

    local translated = lang.GetLanguagePhrase(lang_id, phrase)

    if !translated then
        translated = phrase
    end

    return translated
end

---@param phrase string
---@param tab? table
---@param onlyText? boolean?
---@return string
function lang.GetTranslatedPhraseInterpolate(phrase, tab, onlyText)
    local translated = lang.GetTranslatedPhrase(phrase)

    if _find(translated, "$", 1, true) then
        if !tab then
            return translated .. "-[ERROR: NO TAB]"
        end

        return InterpolateConfig(translated, read_types, phrase_alias, tab, onlyText)
    else
        return translated
    end
end
lang.L = lang.GetTranslatedPhraseInterpolate

-- Check CPU time
/*
local SysTime = SysTime
local _L = lang.L
local start = SysTime()

for i = 1, 1000000 do
    _L("welcome_player", {text = "player1"})
end

print("Time:", SysTime() - start)
*/

