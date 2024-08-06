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

language = _GET("language", language)

language.mt_Langauges = language.mt_Langauges or {}
local LL = language.mt_Langauges

language.DEFAULT_LANG = "en"

language.CVAR_LANGUAGE = GetConVar("gmod_language")

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

local _concat = table.concat
local _match = string.match
local _gsub = string.gsub
local _tostring = tostring
local _tonumber = tonumber

local function InterpolateConfig(message, read_types, phrase_alias, tab, onlyText)
    tab = tab or {}

    local iInterpolateCounter = 0
    -- Simple interpolation
    message = _gsub(message, "($[%w_-]+)", function(w)
        iInterpolateCounter = iInterpolateCounter + 1

        local value = w:sub(2)

        if tab[value] then
            return _tostring(tab[value])
        else
            local counter_value = tab[iInterpolateCounter]
            if counter_value then
                return _tostring(counter_value)
            end
        end
    end)

    -- Advanced interpolation
    message = _gsub(message, '($%b{})', function(w)
        iInterpolateCounter = iInterpolateCounter + 1

        local value = w:sub(3, -2)

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
                value = tab[iInterpolateCounter]
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

    return message
end


---@param lang_id string
---@return table<string, string>
function language.GetLanguageForEdit(lang_id)
    if !language.mt_Langauges[lang_id] then
        language.mt_Langauges[lang_id] = {}
    end

    return language.mt_Langauges[lang_id]
end

---@return string
function language.GetLanguage()
    -- if CLIENT then
        if language.CVAR_LANGUAGE then
            return language.CVAR_LANGUAGE:GetString()
        end
    -- end

    return language.DEFAULT_LANG
end

---@param lang_id string
---@param phrase string
---@return string|nil
function language.GetLanguagePhrase(lang_id, phrase)
    local lang_id = lang_id or language.DEFAULT_LANG

    local translated = LL[lang_id] and LL[lang_id][phrase]

    if !translated then
        translated = LL[language.DEFAULT_LANG] and LL[language.DEFAULT_LANG][phrase]
    end

    return translated
end

-- PrintTable(language.mt_Langauges)

---@param phrase string
---@return string
function language.GetTranslatedPhrase(phrase)
    local lang_id = language.GetLanguage()

    -- Remove # prefix
    if string.StartWith(phrase, "#") then
        phrase = string.sub(phrase, 2)
    end

    local translated = language.GetLanguagePhrase(lang_id, phrase)

    if !translated then
        translated = phrase
    end

    return translated
end

---@param phrase string
---@param tab? table
---@param onlyText? boolean?
---@return string
function language.GetTranslatedPhraseInterpolate(phrase, tab, onlyText)
    local translated = language.GetTranslatedPhrase(phrase)

    local interpolated = InterpolateConfig(translated, read_types, phrase_alias, tab, onlyText)

    return interpolated
end
language.L = language.GetTranslatedPhraseInterpolate


if CLIENT then
    local translated = language.L("welcome_player", {LocalPlayer()})
    _print(translated)
end