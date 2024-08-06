module("zen", package.seeall)

/*
    Language module

    This module is responsible for managing the language system.

    Easy Use:
    - Insert `local L = language.L` at the top of the file
    - Use L("your_phrase") to get translated phrase
    - Use L("player_info", {1}) to get translated phrase with interpolation
    - Use L("dmg_log", {attack = attacker, victim = victim}) to get translated phrase with interpolation

    Easy Register:
    - Get language table with `local P = language.GetLanguageForEdit("en")`
    - Edit language table with `P["your_phrase"] = "Your phrase"`
    - Use interpolated phrases with `P["player_info"] = "Player ${ply:1} has joined the server"`
 
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


local function InterpolateConfig(message, read_types, phrase_alias, tab, onlyText)
    tab = tab or {}
    message = message:gsub('($%b{})', function(w)
        local value = w:sub(3, -2)

        if phrase_alias[value] then
            return phrase_alias[value]()
        end

        local key, n_value = string.match(value, "(%a+):(.+)")

        do -- Check is number
            local number_value = tonumber(n_value)
            if number_value then
                n_value = number_value
            end
        end


        if read_types[key] then
            return read_types[key](tab[n_value], onlyText)
        else
            return (tab[n_value] and _concat{"${",key, ':"', tostring(tab[n_value]), '"}'} or w)
        end
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
---@return string
function language.GetLanguagePhrase(lang_id, phrase)
    local lang_id = lang_id or language.DEFAULT_LANG


    if !language.mt_Langauges[lang_id] then
        return phrase
    end

    return language.mt_Langauges[lang_id][phrase] or phrase
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

    if translated == nil or translated == phrase then
        translated = language.GetLanguagePhrase(language.DEFAULT_LANG, phrase)
    else
        return phrase
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