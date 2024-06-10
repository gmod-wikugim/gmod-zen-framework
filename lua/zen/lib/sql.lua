module("zen", package.seeall)

sql = _GET("sql", sql)

--- @param qe string SQL_QUERY
--- @return boolean result, string query
function sql.QueryErrorLogFormat(qe, ...)
    local qe = string.format(qe, ...)
    local res = sql.Query(qe)

    if res == false then
        print(qe)
        error("SQL Error: " .. sql.LastError())
    end
    
    return res, qe
end

local sql_no_quotas = {
    ["NULL"] = true,
    ["null"] = true,
}

local sql_types = {
    ["default"] = function(var) return tostring(var) end,
    ["column"] = function(var) return "`" .. sql.SQLStr(var, true) .. "`" end,
    ["sql_string"] = function(var) return sql_no_quotas[var] and var or sql.SQLStr(var) end,
    ["sql_string_noquotas"] = function(var) return sql.SQLStr(var, true) end,
    ["auto"] = function(var)
        if isnumber(var) then
            return var
        elseif isstring(var) then
            return sql_no_quotas[var] and var or sql.SQLStr(var)
        else
            error("incorrent type: " .. type(var))
        end
    end,
}

local phrase_alias = {
    ["os_time"] = function() return os.time() end,
}

sql_types["int"] = sql_types["default"]
sql_types["number"] = sql_types["default"]
sql_types["n"] = sql_types["default"]

sql_types["string"] = sql_types["sql_string"]
sql_types["str"] = sql_types["sql_string"]
sql_types["s"] = sql_types["sql_string"]

sql_types["noq"] = sql_types["sql_string_noquotas"]
sql_types["nq"] = sql_types["sql_string_noquotas"]
sql_types["noq"] = sql_types["sql_string_noquotas"]
sql_types["string_nq"] = sql_types["sql_string_noquotas"]
sql_types["str_nq"] = sql_types["sql_string_noquotas"]
sql_types["s_nq"] = sql_types["sql_string_noquotas"]

--- @param self string
function string.InterpolateSQL(self, tab, onlyText)
    return string.InterpolateConfig(self, sql_types, phrase_alias, tab, onlyText)
end

function string.InterpolateSQL_Type(type, value)
    return sql_types[type](value)
end

--- -  Use `nq_`ArgsKey for disable auto SQLStr
--- @param query string
--- @param args table<number,string>
--- @return boolean result, string query
function sql.QueryErrorLogInterpolate(query, args)
	if not args then args = {} end
    local new_qe = string.InterpolateSQL(query, args)
    local res = sql.Query(new_qe)

    if res == false then
        print(new_qe)
        error("SQL Error: " .. sql.LastError())
    end

    return res, new_qe
end