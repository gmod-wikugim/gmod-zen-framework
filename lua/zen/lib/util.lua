
---@class TYPE
---@field type number|string

---@type table<number|string, number|string>
TYPE = TYPE or {}
TYPE.NIL                            = 0
TYPE.BOOL                           = 1
TYPE.BOOLEAN                        = TYPE.BOOL
TYPE.NUMBER                         = 2
TYPE.STRING                         = 3
TYPE.TABLE                          = 4
TYPE.VECTOR                         = 5
TYPE.ANGLE                          = 6
TYPE.COLOR                          = 7
TYPE.ENTITY                         = 8
TYPE.PLAYER                         = 9
TYPE.BOT                            = 10
TYPE.PLAYERONLY                     = 11
TYPE.WEAPON                         = 12
TYPE.VEHICLE                        = 13
TYPE.NPC                            = 14
TYPE.CEFFECTDATA                    = 15
TYPE.CLUAEMITTER                    = 16
TYPE.CLUAPARTICLE                   = 17
TYPE.CMOVEDATA                      = 18
TYPE.CNAVAREA                       = 19
TYPE.CNEWPARTICLEEFFECT             = 20
TYPE.CONVAR                         = 21
TYPE.CRECIPIENTFILTER               = 22
TYPE.CSENT                          = 23
TYPE.CSOUNDPATCH                    = 24
TYPE.CTAKEDAMAGEINFO                = 25
TYPE.CUSERCMD                       = 26
TYPE.FILE                           = 27
TYPE.IGMODAUDIOCHANNEL              = 28
TYPE.IMATERIAL                      = 29
TYPE.IMESH                          = 30
TYPE.IRESTORE                       = 31
TYPE.ISAVE                          = 32
TYPE.ITEXTURE                       = 33
TYPE.IVIDEOWRITER                   = 34
TYPE.MARKUPOBJECT                   = 35
TYPE.NEXTBOT                        = 36
TYPE.NPC                            = 37
TYPE.PANEL                          = 38
TYPE.PATHFOLLOWER                   = 39
TYPE.PHYSOBJ                        = 40
TYPE.PROJECTEDTEXTURE               = 41
TYPE.SCHUDULE                       = 42
TYPE.STACK                          = 43
TYPE.SURFACEINFO                    = 44
TYPE.TASK                           = 45
TYPE.TOOL                           = 46
TYPE.VMATRIX                        = 47
TYPE.SQLSTRING                      = 48
TYPE.PHYSCOLLIDE                    = 49
TYPE.CLUALOCOMOTION                 = 50
TYPE.CNAVLADDER                     = 51
TYPE.BF_READ                        = 52
TYPE.PIXELVIS_HANDLE_T              = 53
TYPE.DLIGHT_T                       = 54
TYPE.BIT                            = 55
TYPE.DATA                           = 56
TYPE.DOUBLE                         = 57
TYPE.MATRIX                         = 58
TYPE.NORMAL                         = 60
TYPE.ANY                            = 61
TYPE.STEAMID                        = 62
TYPE.STEAMID64                      = 63
TYPE.SID                            = TYPE.STEAMID
TYPE.SID64                          = TYPE.STEAMID64
TYPE.INT                            = 64
TYPE.UINT                           = 65


for k, v in pairs(TYPE) do
    TYPE[v] = k
end

util.mt_convertableType = util.mt_convertableType or {}
local CVTYPE = util.mt_convertableType
CVTYPE["boolean"] = TYPE.BOOLEAN
CVTYPE["number"] = TYPE.NUMBER
CVTYPE["Float"] = TYPE.NUMBER
CVTYPE["string"] = TYPE.STRING
CVTYPE["table"] = TYPE.TABLE
CVTYPE["Vector"] = TYPE.VECTOR
CVTYPE["Angle"] = TYPE.ANGLE
CVTYPE["Color"] = TYPE.COLOR
for k, v in pairs(CVTYPE) do
    CVTYPE[v] = k
end

---@param value any
---@return string|nil result
function util.TYPEToString(value, nType)
    local value_type = type(value)
    nType = nType or CVTYPE[value_type]
    if nType then
        if nType == TYPE.BOOLEAN then
            return value and "true" or "false"
        elseif nType == TYPE.NUMBER then
            return tostring(value)
        elseif nType == TYPE.STRING then
            return tostring(value)
        elseif nType == TYPE.TABLE then
            return util.TableToJSON(value)
        elseif nType == TYPE.VECTOR then
            return value.x .. " " .. value.y .. " " .. value.z
        elseif nType == TYPE.ANGLE then
            return value[1] .. " " .. value[2] .. " " .. value[3]
        elseif nType == TYPE.COLOR then
            return value.r .. " " .. value.g .. " " .. value.b .. " " .. value.a
        elseif nType == TYPE.SQLSTRING then
            return string.format("%q", value)
        end
    else
        return nil
    end
end

local t_BooleanValues = {
    ["1"] = true,
    ["0"] = false,
    ["true"] = true,
    ["false"] = false,
    ["+"] = true,
    ["-"] = false,
    ["*"] = true,
    ["YES"] = true,
    ["yes"] = true,
    ["Y"] = true,
    ["y"] = true,
    ["no"] = false,
    ["NO"] = false,
    ["N"] = false,
    ["n"] = false,
    ["T"] = true,
    ["t"] = true,
    ["f"] = false,
    ["F"] = false,
}

---@param value string
---@return any|nil result
function util.StringToTYPE(value, value_type)
    local nType = isnumber(value_type) and value_type or CVTYPE[value_type]
    if nType then
        if nType == TYPE.BOOLEAN then
            return t_BooleanValues[value]
        elseif nType == TYPE.NUMBER then
            return tonumber(value)
        elseif nType == TYPE.STRING then
            return tostring(value)
        elseif nType == TYPE.TABLE then
            return util.JSONToTable(value)
        elseif nType == TYPE.VECTOR then
            if value == nil or value == "" then return Vector(0, 0, 0) end
            local dat = string.Split(value, " ")
            dat[1] = dat[1] or 0
            dat[2] = dat[2] or 0
            dat[3] = dat[3] or 0
            dat[1] = tonumber(dat[1])
            dat[2] = tonumber(dat[2])
            dat[3] = tonumber(dat[3])
            return Vector( unpack(dat) )
        elseif nType == TYPE.ANGLE then
            if value == nil or value == "" then return Angle(0, 0, 0) end
            local dat = string.Split(value, " ")
            dat[1] = dat[1] or 0
            dat[2] = dat[2] or 0
            dat[3] = dat[3] or 0
            return Angle( unpack(dat) )
        elseif nType == TYPE.COLOR then
            if value == nil or value == "" then return Color(255, 255, 255, 255) end
            local dat = string.Split(value, " ")
            dat[1] = dat[1] or 255
            dat[2] = dat[2] or 255
            dat[3] = dat[3] or 255
            dat[4] = dat[4] or 255
            return Color( unpack(dat) )
        elseif nType == TYPE.STEAMID then
            if util.IsSteamID(value) then return value end
            if util.IsSteamID64(value) then
                return util.SteamIDFrom64(value)
            end
        elseif nType == TYPE.STEAMID64 then
            if util.IsSteamID64(value) then return value end
            if util.IsSteamID(value) then
                return util.SteamIDTo64(value)
            end
        end
    else
        return nil
    end
end

util.mt_TD_TypeConvert = util.mt_TD_TypeConvert or {}
util.mt_TD_TypeConvert["angle"] = TYPE.ANGLE
util.mt_TD_TypeConvert["Angle"] = TYPE.ANGLE
util.mt_TD_TypeConvert["bit"] = TYPE.BIT
util.mt_TD_TypeConvert["boolean"] = TYPE.BOOLEAN
util.mt_TD_TypeConvert["bool"] = TYPE.BOOLEAN
util.mt_TD_TypeConvert["color"] = TYPE.COLOR
util.mt_TD_TypeConvert["data"] = TYPE.DATA
util.mt_TD_TypeConvert["double"] = TYPE.DOUBLE
util.mt_TD_TypeConvert["entity"] = TYPE.ENTITY
util.mt_TD_TypeConvert["player"] = TYPE.PLAYER
util.mt_TD_TypeConvert["matrix"] = TYPE.MATRIX
util.mt_TD_TypeConvert["normal"] = TYPE.NORMAL
util.mt_TD_TypeConvert["string"] = TYPE.STRING
util.mt_TD_TypeConvert["table"] = TYPE.TABLE
util.mt_TD_TypeConvert["vector"] = TYPE.VECTOR
util.mt_TD_TypeConvert["Vector"] = TYPE.VECTOR
util.mt_TD_TypeConvert["int"] = TYPE.INT
util.mt_TD_TypeConvert["uint"] = TYPE.UINT
util.mt_TD_TypeConvert["number"] = TYPE.NUMBER
for i = 1, 32 do
    util.mt_TD_TypeConvert["int" .. i] = TYPE.INT
    util.mt_TD_TypeConvert["uint" .. i] = TYPE.UINT
end

util.mt_TD_TypeConvert["steamid"] = TYPE.STEAMID
util.mt_TD_TypeConvert["steamid64"] = TYPE.STEAMID64
util.mt_TD_TypeConvert["sid"] = TYPE.STEAMID
util.mt_TD_TypeConvert["sid64"] = TYPE.STEAMID64
util.mt_TD_TypeConvert["next"] = TYPE.BOOLEAN
util.mt_TD_TypeConvert["any"] = TYPE.ANY

function util.RegisterTypeConvert(human_type, type_id)
    util.mt_TD_TypeConvert[human_type] = type_id
end


util.mt_TD_TypeList = {}
util.mt_TD_TypeList[TYPE.ANGLE] = "Angle"
util.mt_TD_TypeList[TYPE.BIT] = "number"
util.mt_TD_TypeList[TYPE.BOOLEAN] = "boolean"
util.mt_TD_TypeList[TYPE.COLOR] = "table"
util.mt_TD_TypeList[TYPE.DATA] = "string"
util.mt_TD_TypeList[TYPE.DOUBLE] = "number"
util.mt_TD_TypeList[TYPE.ENTITY] = "Entity"
util.mt_TD_TypeList[TYPE.PLAYER] = "Player"
util.mt_TD_TypeList[TYPE.MATRIX] = "VMatrix"
util.mt_TD_TypeList[TYPE.NORMAL] = "Vector"
util.mt_TD_TypeList[TYPE.STRING] = "string"
util.mt_TD_TypeList[TYPE.TABLE] = "table"
util.mt_TD_TypeList[TYPE.VECTOR] = "Vector"
util.mt_TD_TypeList[TYPE.INT] = "number"
util.mt_TD_TypeList[TYPE.UINT] = "number"
util.mt_TD_TypeList[TYPE.STEAMID] = "string"
util.mt_TD_TypeList[TYPE.STEAMID64] = "string"
util.mt_TD_TypeList[TYPE.ANY] = "any"

util.mt_TD_TypeBase = {}
util.mt_TD_TypeBase[TYPE.PLAYER] = TYPE.ENTITY
util.mt_TD_TypeBase[TYPE.VEHICLE] = TYPE.ENTITY
util.mt_TD_TypeBase[TYPE.WEAPON] = TYPE.ENTITY
util.mt_TD_TypeBase[TYPE.NPC] = TYPE.ENTITY
util.mt_TD_TypeBase[TYPE.CSENT] = TYPE.ENTITY
util.mt_TD_TypeBase[TYPE.NEXTBOT] = TYPE.ENTITY
util.mt_TD_TypeBase[TYPE.INT] = TYPE.NUMBER
util.mt_TD_TypeBase[TYPE.UINT] = TYPE.NUMBER
util.mt_TD_TypeBase[TYPE.STEAMID] = TYPE.STRING
util.mt_TD_TypeBase[TYPE.STEAMID64] = TYPE.STRING

util.mt_TD_CheckTypes = {}
util.mt_TD_CheckTypes[TYPE.STEAMID] = function(v) return util.IsSteamID(v) end
util.mt_TD_CheckTypes[TYPE.STEAMID64] = function(v) return util.IsSteamID64(v) end

function get_typen_check(typen, value)
    local func = util.mt_TD_CheckTypes[typen]

    if func then
        local res = func(value)
        if res == true then
            return true
        else
            return false
        end
    end
end

function get_typen(typeIDorHumanType)
    return isnumber(typeIDorHumanType) and typeIDorHumanType or util.mt_TD_TypeConvert[typeIDorHumanType]
end

function get_humantype(typen)
    return util.mt_TD_TypeList[typen]
end

function get_typen_base(typen)
    return util.mt_TD_TypeBase[typen]
end

function get_not_nil(...)
    local key, value = next({...})
    return value
end

local t_AutoConvertString_Nils = {
    [""] = true,
    [" "] = true,
    ["_"] = true,
}

local _I = table.concat
local insert = table.insert
function util.AutoConvertValueToType(types, data)
    assertTable(types, "types")
    assertTable(data, "data")

    local tResult = {}
    local human_types = {}

    local bResult = true
    local sError

    local id = 0
    for k, type in pairs(types) do
        id = id + 1
        local typen = get_typen(type)
        local value = data[id]

        if typen == nil then
            bResult = false
            sError = _I{"typen not exists for '", tostring(type), "'"}
            break
        end

        local human_type = get_humantype(typen)
        local typen_base = get_typen_base(typen)

        human_types[id] = human_type

        local isNil = value == nil or t_AutoConvertString_Nils[value]

        if type == TYPE.ANY and isNil then
            tResult[id] = nil
            continue
        end

        local new_value = get_not_nil(util.StringToTYPE(value, typen), util.StringToTYPE(value, typen_base))

        if new_value == nil then
            bResult = false
            sError = _I{human_type, " expected (got '", tostring(value), "')"}
            break
        end

        local custom_Check = get_typen_check(typen, new_value)
        if custom_Check == false then
            bResult = false
            sError = _I{TYPE[typen], " expected (got '", tostring(new_value), "')"}
            break
        end

        tResult[id] = new_value
    end

    local tResult2
    if bResult then
        local res, idProcess, sErrorOrCount, tNextResult = util.CheckTypeTableWithDataTable(human_types, tResult)
        if res == false then
            bResult = false
            sError = sErrorOrCount
        end
        tResult2 = tNextResult
    end


    return bResult, id, sError, tResult, tResult2
end



function util.CheckTypeTableWithDataTable(types, data, funcValidate, funcValidCustomType)
    local bSuccess = true
    local sLastError

    local iTypesCount, iDataCount = 0, 0
    local tResult = {}


    local processID = 0

    for k, human_type in ipairs(types) do
        processID = processID + 1
        iTypesCount = iTypesCount + 1
        local dat_value = data[k]

        if human_type != "any" and dat_value == nil then
            bSuccess = false
            sLastError = "Data check id: " .. k .. " (" .. (human_type .. " expected, got nil)")
            break
        end

        iDataCount = iDataCount + 1

        if human_type == "next" and dat_value == false then break end
    end

    if bSuccess then
        if iTypesCount != iDataCount then
            bSuccess = false
            sLastError = "Types amount not equals data amount type:data " .. iTypesCount .. ":" .. iDataCount
        end
    end

    if bSuccess and iTypesCount > 0 then
        local processID = 0
        for id = 1, iTypesCount do
            processID = processID + 1
            local human_type = types[id]
            local value = data[id]


            local type_id = util.mt_TD_TypeConvert[human_type]


            if type_id then
                if type_id != TYPE.ANY then
                    local type_id_alias = util.mt_TD_TypeBase[type_id]
                    local value_type_id = typen(value)
                    if value_type_id != type_id and type_id_alias != type_id_alias then
                        local type_id_owner = util.mt_TD_TypeBase[value_type_id]

                        if type_id_owner then
                            if type_id_owner and type_id_owner == type_id then
                                -- Good
                            else
                                bSuccess = false
                                sLastError = "Type check id owner: " .. id .. " (" .. TYPE[type_id] .. " expected, got " .. TYPE[type_id_owner] .. ") owner_id: "
                                break
                            end
                        else
                            bSuccess = false
                            sLastError = "Type check id: " .. id .. " (" .. TYPE[type_id] .. " expected, got " .. TYPE[value_type_id] .. ")"
                            break
                        end
                    end
                end
            else
                if funcValidCustomType then
                    local res, com = funcValidCustomType(human_type, value, type_id, id)
                    if res == false then
                        bSuccess = false
                        if com then
                            sLastError = "Lua funcValidCustomType error: " .. com
                        else
                            sLastError = "Lua funcValidCustomType not exists for: " .. human_type
                        end
                        break
                    end
                else
                    bSuccess = false
                    sLastError = "Lua Type-Convert not exists for: " .. human_type
                    break
                end
            end

            if funcValidate then
                local res, err = funcValidate(human_type, value, type_id, id)
                if res == false then
                    bSuccess = false
                    sLastError = "ValidateErr: " .. err
                    break
                end
            end

            tResult[id] = value
        end
    end

    if bSuccess then
        return true, iTypesCount, tResult
    else
        return false, processID, sLastError, tResult
    end
end

_R = debug.getregistry()
META = META or {}
META.ENTITY                 = _R.Entity or {}
META.PLAYER                 = _R.Player or {}
META.WEAPON                 = _R.Weapon or {}
META.VEHICLE                = _R.Vehicle or {}
META.NPC                    = _R.NPC or {}
META.PHYSCOLLIDE            = _R.PhysCollide or {}
META.PHYSOBJ                = _R.PhysObj or {}
META.IMATERIAL              = _R.IMaterial or {}
META.SURFACEINFO            = _R.SurfaceInfo or {}
META.PATHFOLLOWER           = _R.PathFollower or {}
META.CLUALOCOMOTION         = _R.CLuaLocomotion or {}
META.ISAVE                  = _R.ISave or {}
META.CUSERCMD               = _R.CUserCmd or {}
META.CSOUNDPATCH            = _R.CSoundPatch or {}
META.FILE                   = _R.File or {}
META.VECTOR                 = _R.Vector or {}
META.CMOVEDATA              = _R.CMoveData or {}
META.VMATRIX                = _R.VMatrix or {}
META.CRECIPIENTFILTER       = _R.CRecipientFilter or {}
META.ITEXTURE               = _R.ITexture or {}
META.CNAVAREA               = _R.CNavArea or {}
META.CTAKEDAMAGEINFO        = _R.CTakeDamageInfo or {}
META.CEFFECTDATA            = _R.CEffectData or {}
META.CONVAR                 = _R.ConVar or {}
META.CNAVLADDER             = _R.CNavLadder or {}
META.COLOR                  = _R.Color or {}
META.ANGLE                  = _R.Angle or {}
META.NEXTBOT                = _R.NextBot or {}

META.IGMODAUDIOCHANNEL      = _R.IGModAudioChannel or {}
META.CSENT                  = _R.CSEnt or {}
META.BF_READ                = _R.bf_read or {}
META.IVIDEOWRITER           = _R.IVideoWriter or {}
META.CLUAEMITTER            = _R.CLuaEmitter or {}
META.PANEL                  = _R.Panel or {}
META.CLUAPARTICLE           = _R.CLuaParticle or {}
META.PIXELVIS_HANDLE_T      = _R.pixelvis_handle_t or {}
META.IRESTORE               = _R.IRestore or {}
META.MARKUPOBJECT           = _R.MarkupObject or {}
META.PROJECTEDTEXTURE       = _R.ProjectedTexture or {}
META.DLIGHT_T               = _R.dlight_t or {}
META.CNEWPARTICLEEFFECT     = _R.CNewParticleEffect or {}
META.IMESH                  = _R.IMesh or {}

local get_jit_info = jit.util.funcinfo
local get_info = debug.getinfo
local getlocal = debug.getlocal

local get_up_values = function(func, info, jit_info)
    local tResult = {}

    local k = 0
	while true do
		k = k + 1
		local param = getlocal( func, k )
        if param == nil then break end
        table.insert(tResult, param)
	end

    if jit_info.isvararg or info.isvararg then
        table.insert(tResult, "...")
    end

    return "(" .. table.concat(tResult, ", ") .. ")"
end

do
    local object = function() end
    local res, meta =  pcall(function()
        local meta = debug.getmetatable(object)
        if meta then return meta end

        meta = {}
        debug.setmetatable(object, meta)
        return meta
    end)

    META.FUNCTION = res and meta or {}
    META.FUNCTION.__index = META.FUNCTION
    META.FUNCTION.__tostring = function(self)
        local info = get_info(self)
        local jit_info = get_jit_info(self)

        local func_name = info.name

        local name = func_name and func_name .. " " or ""

        if jit_info.addr then
            return "C_Function: " .. name .. jit_info.addr .. get_up_values(self, info, jit_info)
        else
            return "function: " .. name .. jit_info.source .. ":" ..  jit_info.currentline .. get_up_values(self, info, jit_info)
        end
    end
end

do
    local object = ""
    local res, meta =  pcall(function()
        local meta = debug.getmetatable(object)
        if meta then return meta end

        meta = {}
        debug.setmetatable(object, meta)
        return meta
    end)

    META.STRING = res and meta or {}
    META.STRING.__index = function(self, key)
        local val = rawget(META.STRING, key)

        if val then
            return val
        else
            local val = string[ key ]
            if ( val ~= nil ) then
                return val
            elseif ( tonumber( key ) ) then
                return self:sub( key, key )
            end
        end
    end
end

do
    local object = 0
    local res, meta =  pcall(function()
        local meta = debug.getmetatable(object)
        if meta then return meta end

        meta = {}
        debug.setmetatable(object, meta)
        return meta
    end)

    META.NUMBER = res and meta or {}
    META.NUMBER.__index = META.NUMBER
end

do
    local object = true
    local res, meta =  pcall(function()
        local meta = debug.getmetatable(object)
        if meta then return meta end

        meta = {}
        debug.setmetatable(object, meta)
        return meta
    end)

    META.BOOLEAN = res and meta or {}
    META.BOOLEAN.__index = META.BOOLEAN
end

do
    local object = nil
    local res, meta =  pcall(function()
        local meta = debug.getmetatable(object)
        if meta then return meta end

        meta = {}
        debug.setmetatable(object, meta)
        return meta
    end)

    META.NIL = res and meta or {}
    META.NIL.__index = META.NIL
end


META.NIL._typen_                                = TYPE.NIL
META.BOOLEAN._typen_                            = TYPE.BOOLEAN
META.NUMBER._typen_                             = TYPE.NUMBER
META.STRING._typen_                             = TYPE.STRING
META.FUNCTION._typen_                           = TYPE.FUNCTION

META.VECTOR._typen_                             = TYPE.VECTOR
META.COLOR._typen_                              = TYPE.COLOR
META.ANGLE._typen_                              = TYPE.ANGLE
META.NEXTBOT._typen_                            = TYPE.NEXTBOT
META.ENTITY._typen_                             = TYPE.ENTITY
META.PLAYER._typen_                             = TYPE.PLAYER
META.WEAPON._typen_                             = TYPE.WEAPON
META.VEHICLE._typen_                            = TYPE.VEHICLE
META.NPC._typen_                                = TYPE.NPC

META.PHYSCOLLIDE._typen_                        = TYPE.PHYSCOLLIDE
META.PHYSOBJ._typen_                            = TYPE.PHYSOBJ
META.IMATERIAL._typen_                          = TYPE.IMATERIAL
META.SURFACEINFO._typen_                        = TYPE.SURFACEINFO
META.PATHFOLLOWER._typen_                       = TYPE.PATHFOLLOWER
META.CLUALOCOMOTION._typen_                     = TYPE.CLUALOCOMOTION
META.ISAVE._typen_                              = TYPE.ISAVE
META.CUSERCMD._typen_                           = TYPE.CUSERCMD
META.CSOUNDPATCH._typen_                        = TYPE.CSOUNDPATCH
META.FILE._typen_                               = TYPE.FILE
META.CMOVEDATA._typen_                          = TYPE.CMOVEDATA
META.VMATRIX._typen_                            = TYPE.VMATRIX
META.CRECIPIENTFILTER._typen_                   = TYPE.CRECIPIENTFILTER
META.ITEXTURE._typen_                           = TYPE.ITEXTURE
META.CNAVAREA._typen_                           = TYPE.CNAVAREA
META.CTAKEDAMAGEINFO._typen_                    = TYPE.CTAKEDAMAGEINFO
META.CEFFECTDATA._typen_                        = TYPE.CEFFECTDATA
META.CONVAR._typen_                             = TYPE.CONVAR
META.CNAVLADDER._typen_                         = TYPE.CNAVLADDER

META.PANEL._typen_                              = TYPE.PANEL
META.IGMODAUDIOCHANNEL._typen_                  = TYPE.IGMODAUDIOCHANNEL
META.CSENT._typen_                              = TYPE.CSENT
META.BF_READ._typen_                            = TYPE.BF_READ
META.IVIDEOWRITER._typen_                       = TYPE.IVIDEOWRITER
META.CLUAEMITTER._typen_                        = TYPE.CLUAEMITTER
META.CLUAPARTICLE._typen_                       = TYPE.CLUAPARTICLE
META.PIXELVIS_HANDLE_T._typen_                  = TYPE.PIXELVIS_HANDLE_T
META.IRESTORE._typen_                           = TYPE.IRESTORE
META.MARKUPOBJECT._typen_                       = TYPE.MARKUPOBJECT
META.PROJECTEDTEXTURE._typen_                   = TYPE.PROJECTEDTEXTURE
META.DLIGHT_T._typen_                           = TYPE.DLIGHT_T
META.CNEWPARTICLEEFFECT._typen_                 = TYPE.CNEWPARTICLEEFFECT
META.IMESH._typen_                              = TYPE.IMESH


function typen(any)
    return any._typen_ or CVTYPE[type(any)]
end

local _I = table.concat
function util.PrintTableInfo(tbl, lvl, done)
    lvl = lvl or 0
    done = done or {}
    local add = string.rep("    ", lvl)
    done[tbl] = true
    local addPoint = lvl != 0 and "," or ""

    local keys = table.GetKeys( tbl )

	table.sort( keys, function( a, b )
		if ( isnumber( a ) && isnumber( b ) ) then return a < b end
		return tostring( a ) < tostring( b )
	end )


    local tbl_len = #keys
    for i = 1, tbl_len do
        local k = keys[i]
        local v = tbl[k]

        local sTypeK, sTypeV = type(k), type(v)
        local key, value, bSkip, bTable

        if done[v] then continue end
        -- bSkip = done[v] and true or nil
        -- bSkip = bSkip or (sTypeK == "number")

        -- if bSkip != true then -- value
        do
            if sTypeV == "table" then
                local iTableCount = table.Count(v)
                local sEndTable = iTableCount == 0 and (lvl > 0 and "}," or "}") or ""

                if iTableCount > 0 then
                    bTable = true
                end

                value = _I{ "{", sEndTable, " --(", iTableCount, ")", ":"}
            elseif sTypeV == "function" then
                local info = debug.getinfo(v)
                local sKeyFunction = ""
                if info.nparams > 0 then
                    for ii = 1, info.nparams do
                        local sKeyName = debug.getlocal(v, ii)
                        if sKeyName != nil then
                            if sKeyFunction == "" then
                                sKeyFunction = sKeyName
                            else
                                sKeyFunction = _I{sKeyFunction, ", ", sKeyName}
                            end
                        end
                    end
                end
                if info.isvararg then
                    if sKeyFunction == "" then
                        sKeyFunction = "..."
                    else
                        sKeyFunction = _I{sKeyFunction, ", ..."}
                    end
                end

                local funcInfo = ""

                if info.what == "C" then
                    funcInfo = _I{"C:func:", string.match(string.format("%q", v), "function: (.+)")}
                else
                    funcInfo = _I{"Lua:func:", info.source, ":", info.linedefined}
                end


                value = _I{"function(", sKeyFunction, ") end", addPoint,  " -- ", funcInfo}
            elseif sTypeV == "string" then
                v = string.Replace(v, "\n", "\\n")
                v = string.Replace(v, "\t", "\\t")
                v = string.Replace(v, "\r", "\\r")
                value = _I{'"', v, '"', addPoint}
            elseif sTypeV == "number" then
                value = _I{v, addPoint}
            elseif sTypeV == "boolean" then
                value = _I{tostring(v), addPoint}
            elseif sTypeV == "Vector" then
                value = _I{"Vector(", v.x, ", ", v.y, ", ", v.z, ")", addPoint}
            elseif sTypeV == "Angle" then
                value = _I{"Angle(", v.p, ", ", v.y, ", ", v.r, ")", addPoint}
            elseif sTypeV == "Color" then
                value = _I{"Color(", v.r, ", ", v.g, ", ", v.b, ", ", v.a, ")", addPoint}
            else
                value = _I{'[[_', tostring(v), '_]]', addPoint}
            end
        end



        -- if bSkip != true then -- key
        do
            key = k

            if sTypeK == "string" then
                if lvl > 0 then key = _I{'["', k, '"]'} end
            elseif sTypeK == "number" then
                key = _I{"[", k, "]"}
            else
                key = _I{'[[_', tostring(v), '_]]'}
            end
            Msg(_I{add, key, " = ", value, "\n"})
        end

        do -- end of table
            if bTable then
                util.PrintTableInfo(v, lvl + 1, done)

                local addPoint = lvl > 0 and "," or ""
                Msg(_I{add, "}", addPoint, "\n"})
            end
        end
    end
end
PrintTableInfo = util.PrintTableInfo



function util.IsBoxFree(pos, min, max, filter)
    local Ents = ents.FindInBox( pos + min, pos + max )

    if isstring(filter) then
        for k, ent in pairs(Ents) do
            if ent:GetClass() == filter then
                return false
            end
        end
    elseif istable(filter) then
        local key_filter = table.Switch(filter)
        for k, ent in pairs(Ents) do
            if key_filter[ent:GetClass()] then
                return false
            end
        end
    elseif isfunction(filter) then
        for k, ent in pairs(Ents) do
            local res = pcall(filter, ent, ent:GetClass())
            if res != nil then return res end
        end
    elseif filter == nil then
        for k, ent in pairs(Ents) do
            if not IsValid(ent) then continue end
            if ent:IsSolid() and ent:GetSolid() != SOLID_NONE and ent:GetCollisionGroup() != COLLISION_GROUP_WORLD then return false end
        end
    end


    return true
end

function util.GetModelBoundsFixed(ent, dropZero)
	local min, max = ent:GetModelBounds()
	local minn, maxx = Vector(min), Vector(max)
    if min.x != -max.x then
		local md_x = max.x - min.x
		minn.x = -md_x/2
		maxx.x = md_x/2
	end
	if min.y != -max.y then
		local md_y = max.y - min.y
		minn.y = -md_y/2
		maxx.y = md_y/2
	end
	if min.z != -max.z then
		local md_z = max.z - min.z
		minn.z = -md_z/2
		maxx.z = md_z/2
	end
    if dropZero then
        maxx.z = minn.z + maxx.z
        minn.z = 0
    end
    return minn, maxx
end

META.ENTITY.GetModelBoundsFixed = util.GetModelBoundsFixed

COLOR = COLOR or {}
COLOR.WHITE = Color(255,255,255)
COLOR.BLACK = Color(0,0,0)
COLOR.RED = Color(255,0,0)
COLOR.GREEN = Color(0,255,0)
COLOR.BLUE = Color(0,0,255)
COLOR.R, COLOR.G, COLOR.B = COLOR.RED, COLOR.GREEN, COLOR.BLUE
COLOR.ERROR = Color(255,0,0)
COLOR.WARN = Color(255,125,0)

---@param value string
---@return boolean IsSteamID64
function util.IsSteamID64(value)
    if !isstring(value) then return false end
    if tonumber(value) and value:sub(1, 7) == "7656119" and (#value == 17 or #value == 18) then
        return true
    end
end

---@param value string
---@return boolean IsSteamID
function util.IsSteamID(value)
    if !isstring(value) then return false end
    if value:match("^STEAM_[0-5]:[0-1]:[0-9]+$") ~= nil then
		return true
	else
		return false
	end
end


util.mt_PlayerList_Browse = util.mt_PlayerList_Browse or {}
function util.GetPlayerTBrowse(pid, forceCreate)
    if forceCreate and not util.mt_PlayerList_Browse[pid] then
        util.mt_PlayerList_Browse[pid] = {
            _aliases = {}
        }
    end
    return util.mt_PlayerList_Browse[pid]
end

function util.GetPlayerTBrowseKey(pid, key)
    return util.mt_PlayerList_Browse[pid] and util.mt_PlayerList_Browse[pid][key]
end


function util.OnPlayerTBrowserUpdate(tBrowse, pid, key, value)
    if key == "userid" then
        util.SetPlayetTBrowseKey(pid, "userid_str", "#" .. value, true)
    elseif key == "sid64" then
        util.SetPlayetTBrowseKey(pid, "sid64_n", tonumber(value), true)
    elseif key == "networkid" then
        util.SetPlayetTBrowseKey(pid, "sid64", util.SteamIDTo64(value), true)
        util.SetPlayetTBrowseKey(pid, "sid", value, true)
    elseif key == "entity" then
        util.SetPlayetTBrowseKey(pid, "userid", value:UserID(), true)
        util.SetPlayetTBrowseKey(pid, "nick", value:Nick())
        util.SetPlayetTBrowseKey(pid, "ent_index", value:EntIndex())

        if SERVER then
            if tBrowse.userid then
                local hammer_name = "zen_player_" .. tBrowse.userid
                META.ENTITY.SetName(value, hammer_name)
                util.SetPlayetTBrowseKey(pid, "hammen_name", hammer_name)
            end
        end

        if not value:IsBot() then
            if SERVER then
                util.SetPlayetTBrowseKey(pid, "address", value:IPAddress(), true)
            end
            util.SetPlayetTBrowseKey(pid, "networkid", value:SteamID(), true)
        end
    end
end


function util.SetPlayetTBrowseKey(pid, key, value, useAsAlias)
    if value == "none" or value == "BOT" then return end

    local tBrowse = util.GetPlayerTBrowse(pid, true)
    tBrowse[key] = value
    if useAsAlias then
        tBrowse._aliases[value] = true
        util.mt_PlayerList_Browse[value] = tBrowse
    end

    util.OnPlayerTBrowserUpdate(tBrowse, pid, key, value)
end

function util.RemovePlayerTBrowser(pid)
    local tBrowse = util.mt_PlayerList_Browse[pid]
    if not tBrowse then return end
    timer.Simple(1, function()
        for key in pairs(tBrowse._aliases) do
            util.mt_PlayerList_Browse[key] = nil
        end
    end)
end

function util.UpdatePlayerList()
    for k, v in pairs(player.GetAll()) do
        util.SetPlayetTBrowseKey(v, "entity", v, true)
    end
end
util.UpdatePlayerList()
ihook.Listen("InitPostEntity", "zen.util.PlayerList", function()
    util.UpdatePlayerList()
end)

if SERVER then
    ihook.Listen("PlayerInitialSpawn", "zen.util.PlayerList", function(ply)
        util.SetPlayetTBrowseKey(ply, "entity", ply, true)
    end)
    ihook.Listen("PlayerDisconnected", "zen.util.PlayerList", function(ply)
        util.RemovePlayerTBrowser(ply)
    end)

    gameevent.Listen("player_connect")
    ihook.Listen("player_connect", "zen.util.PlayerList", function(tbl)
        local userid = tbl.userid
        util.SetPlayetTBrowseKey(userid, "userid", userid, true)
        util.SetPlayetTBrowseKey(userid, "ent_index", tbl.index + 1)
        util.SetPlayetTBrowseKey(userid, "name", tbl.name)

        if tbl.networkid then
            util.SetPlayetTBrowseKey(userid, "networkid", tbl.networkid, true)
        end
        if tbl.address then
            util.SetPlayetTBrowseKey(userid, "address", tbl.address, true)
        end
    end, HOOK_HIGH)

    gameevent.Listen("player_disconnect")
    ihook.Listen("player_disconnect", "zen.util.PlayerList", function(tbl)
        util.RemovePlayerTBrowser(tbl.userid)
    end, HOOK_HIGH)
end

if CLIENT then
    gameevent.Listen("player_connect_client")
    ihook.Listen("player_connect_client", "zen.util.PlayerList", function(tbl)
        local userid = tbl.userid
        util.SetPlayetTBrowseKey(userid, "userid", userid, true)
        util.SetPlayetTBrowseKey(userid, "ent_index", tbl.index + 1)
        util.SetPlayetTBrowseKey(userid, "name", tbl.name)
        if tbl.networkid then
            util.SetPlayetTBrowseKey(userid, "networkid", tbl.networkid, true)
        end
    end, HOOK_HIGH)

    ihook.Listen("OnEntityCreated", "zen.util.PlayerList", function(ent)
        if ent:IsPlayer() then util.SetPlayetTBrowseKey(ent, "entity", ent, true) end
    end)
    ihook.Listen("EntityRemoved", "zen.util.PlayerList", function(ent)
        if ent:IsPlayer() then util.RemovePlayerTBrowser(ent) end
    end)
end

function util.GetPlayerEntity(plyOrSid)
    return util.GetPlayerTBrowseKey(plyOrSid, "entity")
end

function util.GetPlayerSteamID64(plyOrSid)
    return util.GetPlayerTBrowseKey(plyOrSid, "sid64")
end

function util.GetPlayerSteamID(plyOrSid)
    return util.GetPlayerTBrowseKey(plyOrSid, "sid")
end

function util.GetPlayerUserID(plyOrSid)
    return util.GetPlayerTBrowseKey(plyOrSid, "userid")
end

function util.GetPlayerAddress(plyOrSid)
    return util.GetPlayerTBrowseKey(plyOrSid, "address")
end

function util.GetPlayerNick(plyOrSid)
    return util.GetPlayerTBrowseKey(plyOrSid, "nick")
end

function util.GetPlayerHammerName(plyOrSid)
    return util.GetPlayerTBrowseKey(plyOrSid, "hammer_name")
end

local self_tags = {
    ["^"] = true,
    ["@me"] = true,
    ["@self"] = true,
    ["@yourself"] = true,
}

local function getPlayerListFromEntList(ent_list)
    local tResult = {}
    for k, ent in pairs(ent_list) do
        if IsValid(ent) and ent:IsPlayer() then
            table.insert(tResult, ent)
        end
    end

    return tResult
end

function util.FindPlayerEntity(str, who)
    local ply = util.GetPlayerEntity(str)

    local res = {}

    if ply then res = {ply} goto result end

    if CLIENT and who == nil then
        who = LocalPlayer()
    end

    if IsValid(who) then
        local who_origin = util.GetPlayerTraceSource(who)
        if self_tags[str] then
            res = {who}
            goto result
        end

        local sub1 = str:sub(1,1)


        if sub1 == "@" then
            if str == "@" then
                local trace, ent = who:zen_GetEyeTrace()

                if IsValid(ent) and ent:IsPlayer() then
                    res = {ent}
                    goto result
                end
            end
            if str == "@we" then
                res = getPlayerListFromEntList( ents.FindInSphere(who_origin, 400) )
                goto result
            end
            if SERVER then
                if str == "@pvs" then
                    res = getPlayerListFromEntList( ents.FindInPVS(who_origin) )
                    goto result
                end
            end
            if str == "@all" then
                res = player.GetAll()
                goto result
            end
            if str == "@humans" then
                res = player.GetHumans()
                goto result
            end

            goto result
        end
    end

    do -- By Nicks
        local tResult = {}

        for k, ply in pairs(player.GetAll()) do
            if string.find(ply:GetName(), str) then
                table.insert(tResult, ply)
            end
        end

        res = tResult
        goto result
    end


    ::result::
    if table.IsEmpty(res) then return nil end

    if #res == 1 then return res[1] end

    return res
end


---@param func function
---@return boolean sucess, string? err
function pcallNoHalt(func,...)
    local succ, err = pcall(func, ...)
    if not succ then ErrorNoHalt(err) end
    return succ, err
end

local _I = table.concat

function assertConcat(value, ...)
    assert(value, _I{...})
end

---@param value any
---@param variableName? string
function assertValid(value, variableName)
    assert(IsValid(value), (variableName or "variable") .. " not is valid")
end

---@param value any
---@param variableName? string
function assertNumber(value, variableName)
    assert(isnumber(value), "bad argument: " .. (variableName or "variable") .. ", expected number (got " .. type(value) .. ")")
end

---@param value any
---@param variableName? string
function assertString(value, variableName)
    assert(isstring(value), "bad argument: " .. (variableName or "variable") .. ", expected string (got " .. type(value) .. ")")
end

---@param value any
---@param variableName? string
function assertStringNice(value, variableName)
    assert(isstring(value), "bad argument: " .. (variableName or "variable") .. ", expected string (got " .. type(value) .. ")")
    assert(value != "" and value != " ", "bad argument: " .. (variableName or "variable") .. ", expected string (got empty string)")
    assert(string.format(value, "%w+"), (variableName or "variable") .. " not has words or numbers")
end

---@param value any
---@param variableName? string
function assertTable(value, variableName)
    assert(istable(value), "bad argument: " .. (variableName or "variable") .. ", expected table (got " .. type(value) .. ")")
end

---@param value any
---@param variableName? string
function assertTableNice(value, variableName)
    assert(istable(value), "bad argument: " .. (variableName or "variable") .. ", expected table (got " .. type(value) .. ")")
    assert(next(value), (variableName or "variable") .. " is empty")
end

---@param value any
---@param variableName? string
function assertEntity(value, variableName)
    assert(isentity(value) and IsValid(value), "bad argument: " .. (variableName or "variable") .. ", expected entity (got " .. type(value) .. ")")
end

---@param value any
---@param variableName? string
function assertPlayer(value, variableName)
    assert(isentity(value) and IsValid(value) and value:IsPlayer(), "bad argument: " .. (variableName or "variable") .. ", expected player (got " .. type(value) .. ")")
end

---@param value any
---@param variableName? string
function assertFunction(value, variableName)
    assert(isfunction(value), "bad argument: " .. (variableName or "variable") .. ", expected function (got " .. type(value) .. ")")
end

local _I = table.concat
function util.PrintTableInfo(tbl, lvl, done)
    lvl = lvl or 0
    done = done or {}
    local add = string.rep("    ", lvl)
    done[tbl] = true
    local addPoint = lvl != 0 and "," or ""

    local keys = table.GetKeys( tbl )

	table.sort( keys, function( a, b )
		if ( isnumber( a ) && isnumber( b ) ) then return a < b end
		return tostring( a ) < tostring( b )
	end )


    local tbl_len = #keys
    for i = 1, tbl_len do
        local k = keys[i]
        local v = tbl[k]

        local sTypeK, sTypeV = type(k), type(v)
        local key, value, bSkip, bTable

        if done[v] then continue end
        -- bSkip = done[v] and true or nil
        -- bSkip = bSkip or (sTypeK == "number")

        -- if bSkip != true then -- value
        do
            if sTypeV == "table" then
                local iTableCount = table.Count(v)
                local sEndTable = iTableCount == 0 and (lvl > 0 and "}," or "}") or ""

                if iTableCount > 0 then
                    bTable = true
                end

                value = _I{ "{", sEndTable, " --(", iTableCount, ")", ":"}
            elseif sTypeV == "function" then
                local info = debug.getinfo(v)
                local sKeyFunction = ""
                if info.nparams > 0 then
                    for ii = 1, info.nparams do
                        local sKeyName = debug.getlocal(v, ii)
                        if sKeyName != nil then
                            if sKeyFunction == "" then
                                sKeyFunction = sKeyName
                            else
                                sKeyFunction = _I{sKeyFunction, ", ", sKeyName}
                            end
                        end
                    end
                end
                if info.isvararg then
                    if sKeyFunction == "" then
                        sKeyFunction = "..."
                    else
                        sKeyFunction = _I{sKeyFunction, ", ..."}
                    end
                end

                local funcInfo = ""

                if info.what == "C" then
                    funcInfo = _I{"C:func"}
                else
                    funcInfo = _I{"Lua:func:", info.source, ":", info.linedefined}
                end


                value = _I{"function(", sKeyFunction, ") end", addPoint,  " -- ", funcInfo}
            elseif sTypeV == "string" then
                v = string.Replace(v, "\n", "\\n")
                v = string.Replace(v, "\t", "\\t")
                v = string.Replace(v, "\r", "\\r")
                value = _I{'"', v, '"', addPoint}
            elseif sTypeV == "number" then
                value = _I{v, addPoint}
            elseif sTypeV == "boolean" then
                value = _I{tostring(v), addPoint}
            elseif sTypeV == "Vector" then
                value = _I{"Vector(", v.x, ", ", v.y, ", ", v.z, ")", addPoint}
            elseif sTypeV == "Angle" then
                value = _I{"Angle(", v.p, ", ", v.y, ", ", v.r, ")", addPoint}
            elseif sTypeV == "Color" then
                value = _I{"Color(", v.r, ", ", v.g, ", ", v.b, ", ", v.a, ")", addPoint}
            else
                value = _I{'[[_', tostring(v), '_]]', addPoint}
            end
        end



        -- if bSkip != true then -- key
        do
            key = k

            if sTypeK == "string" then
                if lvl > 0 then key = _I{'["', k, '"]'} end
            elseif sTypeK == "number" then
                key = _I{"[", k, "]"}
            else
                key = _I{'[[_', tostring(v), '_]]'}
            end
            Msg(_I{add, key, " = ", value, "\n"})
        end

        do -- end of table
            if bTable then
                util.PrintTableInfo(v, lvl + 1, done)

                local addPoint = lvl > 0 and "," or ""
                Msg(_I{add, "}", addPoint, "\n"})
            end
        end
    end
end
PrintTableInfo = util.PrintTableInfo



function util.IsBoxFree(pos, min, max, filter)
    local Ents = ents.FindInBox( pos + min, pos + max )

    if isstring(filter) then
        for k, ent in pairs(Ents) do
            if ent:GetClass() == filter then
                return false
            end
        end
    elseif istable(filter) then
        local key_filter = table.Switch(filter)
        for k, ent in pairs(Ents) do
            if key_filter[ent:GetClass()] then
                return false
            end
        end
    elseif isfunction(filter) then
        for k, ent in pairs(Ents) do
            local res = pcall(filter, ent, ent:GetClass())
            if res != nil then return res end
        end
    elseif filter == nil then
        for k, ent in pairs(Ents) do
            if not IsValid(ent) then continue end
            if ent:IsSolid() and ent:GetSolid() != SOLID_NONE and ent:GetCollisionGroup() != COLLISION_GROUP_WORLD then return false end
        end
    end


    return true
end

function util.GetModelBoundsFixed(ent, dropZero)
	local min, max = ent:GetModelBounds()
	local minn, maxx = Vector(min), Vector(max)
    if min.x != -max.x then
		local md_x = max.x - min.x
		minn.x = -md_x/2
		maxx.x = md_x/2
	end
	if min.y != -max.y then
		local md_y = max.y - min.y
		minn.y = -md_y/2
		maxx.y = md_y/2
	end
	if min.z != -max.z then
		local md_z = max.z - min.z
		minn.z = -md_z/2
		maxx.z = md_z/2
	end
    if dropZero then
        maxx.z = minn.z + maxx.z
        minn.z = 0
    end
    return minn, maxx
end

META.ENTITY.GetModelBoundsFixed = util.GetModelBoundsFixed

local Vector = Vector

local cached_bounds = {}
function util.GetModelMeshBounds(model)
    if cached_bounds[model] then return Vector(cached_bounds[model][1]), Vector(cached_bounds[model][2]) end

	local meshes = util.GetModelMeshes(model)

	local min1, max1

	local count = 0
	for mesh_id, mesh_data in ipairs(meshes) do
		for k, dat in ipairs(mesh_data.triangles) do
			count = count + 1
			local pos = dat.pos
			if min1 == nil then min1 = Vector(pos) end
			if max1 == nil then max1 = Vector(pos) end


			if min1 then
				min1.x = math.min(min1.x, pos.x)
				min1.y = math.min(min1.y, pos.y)
				min1.z = math.min(min1.z, pos.z)
			end

			if max1 then
				max1.x = math.max(max1.x, pos.x)
				max1.y = math.max(max1.y, pos.y)
				max1.z = math.max(max1.z, pos.z)
			end
		end
	end

    cached_bounds[model] = {min1, max1}

	return min1, max1
end

local cached_bounds_fixed = {}
function util.GetModelMeshBoundsFixed(model)
    if cached_bounds_fixed[model] then return Vector(cached_bounds_fixed[model][1]), Vector(cached_bounds_fixed[model][2]) end

	local min, max = util.GetModelMeshBounds(model)
	local minn, maxx = Vector(min), Vector(max)
    if min.x != -max.x then
		local md_x = max.x - min.x
		minn.x = -md_x/2
		maxx.x = md_x/2
	end
	if min.y != -max.y then
		local md_y = max.y - min.y
		minn.y = -md_y/2
		maxx.y = md_y/2
	end
	if min.z != -max.z then
		local md_z = max.z - min.z
		minn.z = -md_z/2
		maxx.z = md_z/2
	end

    cached_bounds_fixed[model] = {minn, maxx}
    return minn, maxx
end

function util.GetModelCenter(model)
    local min1 = util.GetModelMeshBounds(model)
    local min2 = util.GetModelMeshBoundsFixed(model)

    -- Без понятия как это работает, но оно помогает
    min1 = Vector(min1)
    min2 = Vector(min2)

    return Vector(0,0,0) + min1 - min2
end

function util.GetModelOffsetCenter(model)
    local pos = util.GetModelCenter(model)

    -- Без понятия как это работает, но оно помогает
    pos = Vector(pos)

    return Vector(0,0,0) - pos
end

function util.GetEntityCenter(ent)
    local min1 = util.GetModelMeshBounds(ent:GetModel())
    local min2 = util.GetModelMeshBoundsFixed(ent:GetModel())

    -- Без понятия как это работает, но оно помогает
    min1 = Vector(min1)
    min2 = Vector(min2)

    local ang = ent:GetAngles()

    min1:Rotate(ang)
    min2:Rotate(ang)

    local pos = ent:GetPos() + min1 - min2

    return pos
end


function debug.getupvalues(func)
    local info = debug.getinfo( func, "uS" )
    local variables = {}

    -- Upvalues can't be retrieved from C functions
    if ( info != nil && info.what == "Lua" ) then
        local upvalues = info.nups

        for i = 1, upvalues do
            local key, value = debug.getupvalue( func, i )
            variables[ key ] = value
        end
    end

    return variables
end

local DOOR_CLOSED = 1
local DOOR_OPENING = 2
local DOOR_OPENED = 0
local DOOR_CLOSING = 3

local E_DOOR_CLOSED = 0
local E_DOOR_OPENING = 1
local E_DOOR_OPENED = 2
local E_DOOR_CLOSING = 3

local doors_class = {}
doors_class["func_door"] = true
doors_class["func_door_rotating"] = true
doors_class["prop_door_rotating"] = true
doors_class["func_door"] = true
doors_class["func_door"] = true


function util.IsDoor(ent)
    return doors_class[ent:GetClass()]
end

function util.IsDoorOpen(ent)
    local iDoorState = ent:GetInternalVariable("m_toggle_state")
    local iEDoorState = ent:GetInternalVariable("m_eDoorState")

    local isOpened

    if iDoorState then
        if iDoorState == DOOR_CLOSED then
            isOpened = false
        elseif iDoorState == DOOR_OPENING then
            isOpened = true
        elseif iDoorState == DOOR_OPENED then
            isOpened = true
        elseif iDoorState == DOOR_CLOSING then
            isOpened = false
        end
    elseif iEDoorState then
        if iEDoorState == E_DOOR_CLOSED then
            isOpened = false
        elseif iEDoorState == E_DOOR_OPENING then
            isOpened = true
        elseif iEDoorState == E_DOOR_OPENED then
            isOpened = true
        elseif iEDoorState == E_DOOR_CLOSING then
            isOpened = false
        end
    end

    return isOpened
end
util.IsDoorOpened = util.IsDoorOpen
function util.IsDoorClose(ent)
    return not util.IsDoorOpen(ent)
end
util.IsDoorClosed = util.IsDoorClose

function util.IsDoorLock(ent)
    return ent:GetInternalVariable("m_bLocked")
end
util.IsDoorLocked = util.IsDoorLock

function util.IsDoorUnlock(ent)
    return not util.IsDoorLock(ent)
end
util.IsDoorUnlocked = util.IsDoorUnlock
util.IsDoorUnLock = util.IsDoorUnlock
util.IsDoorUnLocked = util.IsDoorUnlock

local bit_band = bit.band
function util.IsFlagSet(flags, flag)
    return bit_band(flags, flag) == flag
end

-- flags_table = <string name, number flag>
-- result = <name flag|boolean exists>
function util.GetFlagsTable(flags_table, flags)
    local tResult = {}
    for k, v in pairs(flags_table) do
        if util.IsFlagSet(flags, v) then
            tResult[k] = true
        end
    end
    return tResult
end

function util.GetPlayerTraceSource(ply, noCursor)
    if CLIENT and (ply == nil or ply == LocalPlayer()) then
        local view_data = render.GetViewSetup()
        local origin = view_data.origin
        local normal

        if not noCursor then
            local mx, my = input.GetCursorPos()
            normal = util.AimVector(view_data.angles, view_data.fov, mx, my, view_data.width, view_data.height)
        else
            normal = view_data.angles:Forward()
        end

        return origin, normal
    else
        assertPlayer(ply, "ply")

        local origin = ply:EyePos()
        local normal

        if not noCursor then
            normal = ply:GetAimVector()
        else
            normal = ply:EyeAngles():Forward()
        end

        return ply:EyePos(), ply:GetAimVector()
    end
end

function util.GetPlayerEyeTrace(ply, noCursor)
    local origin, dir = util.GetPlayerTraceSource(ply, noCursor)

    local trace = util.TraceLine({
        start = origin,
        endpos = origin + dir*9999999,
        filter = ply,
        mask = MASK_SOLID
    })

    if trace.Hit and not trace.HitWorld and IsValid(trace.Entity) then
        return trace, trace.Entity
    end

    local trace = util.TraceLine({
        start = origin,
        endpos = origin + dir*9999999,
        filter = ply,
        mask = MASK_ALL
    })

    return trace, trace.Entity
end

function META.PLAYER:zen_GetEyeTrace(noCursor)
    return util.GetPlayerEyeTrace(self, noCursor)
end

cleanup.Register("zen")


local lastCalcX = {}
local lastCalcY = {}
local lastCalcZ = {}
local lastMin = Vector(0,0,0)
local lastMax = Vector(0,0,0)

local Angles = {
	Vector(0,0,1),Vector(0,0,-1),
	Vector(1,0,0),Vector(-1,0,0),Vector(0,1,0),Vector(0,-1,0),Vector(1,1,0),Vector(-1,-1,0),
	Vector(1,-1,0),Vector(-1,1,0),Vector(1,0,1),Vector(-1,0,1),Vector(0,1,1),Vector(0,-1,1),
	Vector(1,1,1),Vector(-1,-1,1),Vector(1,-1,1),Vector(-1,1,1),Vector(1,0,-1),Vector(-1,0,-1),
	Vector(0,1,-1),Vector(0,-1,-1),Vector(1,1,-1),Vector(-1,-1,-1),Vector(1,-1,-1),Vector(-1,1,-1),
}


local min = math.min
local max = math.max


local floor = math.floor
local function vector_equal(vec1, vec2)
	return floor(vec1.x) == floor(vec2.x) or floor(vec1.y) == floor(vec2.y) or floor(vec1.z) == floor(vec2.z)
end

local insert = table.insert
local function TraceRoom(pos, tResult, loop, filter)
	if loop > 3 then return end

	loop = loop + 1


	for k, dir in pairs(Angles) do
		local new_pos = pos + dir*1000

		local trace = util.TraceLine{
			start = pos,
			endpos = new_pos,
			mask = MASK_SOLID,
            filter = filter,
		}

		local hitpos = trace.HitPos
		if not trace.Hit then continue end

		local hitPosX = floor(hitpos.x)
		local hitPosY = floor(hitpos.y)
		local hitPosZ = floor(hitpos.z)

		insert(tResult, {hitpos, trace.HitNormal})

		if lastCalcX[hitPosX] and lastCalcY[hitPosY] and lastCalcZ[hitPosZ] then continue end

		lastCalcX[hitPosX] = true
		lastCalcY[hitPosY] = true
		lastCalcZ[hitPosZ] = true

		local lastMinX = floor(lastMin.x)
		local lastMinY = floor(lastMin.y)
		local lastMinZ = floor(lastMin.z)

		local lastMaxX = floor(lastMax.x)
		local lastMaxY = floor(lastMax.y)
		local lastMaxZ = floor(lastMax.z)


		lastMin.x = min(lastMinX, hitPosX)
		lastMin.y = min(lastMinY, hitPosY)
		lastMin.z = min(lastMinZ, hitPosZ)

		lastMax.x = max(lastMaxX, hitPosX)
		lastMax.y = max(lastMaxY, hitPosY)
		lastMax.z = max(lastMaxZ, hitPosZ)

		if vector_equal(pos, Vector(hitPosX, hitPosY, hitPosZ)) then continue end

		TraceRoom(hitpos, tResult, loop)
	end
end

function util.GetRoomBounds(pos, filter)
    assert(isvector(pos), "pos not is vector")

    lastCalcX = {}
    lastCalcY = {}
    lastCalcZ = {}
    lastMin = Vector(pos)
    lastMax = Vector(pos)

    TraceRoom(pos, {}, 0, filter)

    return lastMin, lastMax
end


function util.GetRoomEntities(pos, filter)
    local min, max = util.GetRoomBounds(pos, filter)

    return ents.FindInBox(min, max)
end

function util.GetRoomPlayers(pos, filter)
    local min, max = util.GetRoomBounds(pos, filter)

    local tResult = {}

    local ent_list = ents.FindInBox(min, max)
    for k, v in pairs(ent_list) do
        if v:IsPlayer() then
            insert(tResult, v)
        end
    end

    return tResult
end

local symbols_lower = {
	{97, 122}, -- en
	{1072, 1103}, -- ru
}

local symbols_upper = {
	{65, 90}, -- en
	{1040, 1071}, -- ru
}

local single_lower = {
	{261,263,281,322,324,243,347,378,380,1118,1110,1111}, -- Slovak ąćęłńóśźżўії
	{1241,1171,1179,1187,1257,1201,1199,1211}, -- Slovak әғқңөұүһ
}

local single_upper = {
	{260,262,280,321,323,211,346,377,379,1038,1030,1031}, -- Slovak ĄĆĘŁŃÓŚŹŻЎІЇ
	{1240,1170,1178,1186,1256,1200,1198,1210}, -- Slovak ӘҒҚҢӨҰҮҺ
}


local upper_chars = {}
local lower_chars = {}

local utf8_codepoint = utf8.codepoint
local utf8_char = utf8.char
local ipairs = ipairs
local unpack = unpack


for k, vl in pairs(symbols_lower) do
	local vu = symbols_upper[k]

	local vl_min, vl_max = vl[1], vl[2]
	local vu_min, vu_max = vu[1], vu[2]

	local i = 0
	for cl = vl_min, vl_max do
		local cu = vu_min + i

		upper_chars[cl] = cu
		lower_chars[cu] = cl
		i = i + 1
	end
end

for k, vl in pairs(single_lower) do
	local vu = single_upper[k]

	local i = 0
	for _, cl in pairs(vl) do
		i = i + 1
		local cu = vu[i]
		upper_chars[cl] = cu
		lower_chars[cu] = cl
	end
end

local upper_cache = setmetatable({}, {__mode = "kv"})
function util.StringUpper(str)
	if upper_cache[str] then return upper_cache[str] end

	local tResult = {utf8_codepoint(str, 1, -1)}
	for id, char in ipairs(tResult) do
		char = upper_chars[char] or char
		tResult[id] = char
	end

	upper_cache[str] = utf8_char(unpack(tResult))

	return upper_cache[str]
end

local lower_cache = setmetatable({}, {__mode = "kv"})
function util.StringLower(str)
	if lower_cache[str] then return lower_cache[str] end

	local tResult = {utf8_codepoint(str, 1, -1)}
	for id, char in ipairs(tResult) do
		char = lower_chars[char] or char
		tResult[id] = char
	end

	lower_cache[str] = utf8_char(unpack(tResult))

	return lower_cache[str]
end

function util.GetIcoSphereVertex(radius, subdivisions)

    local phi = (1 + math.sqrt(5)) / 2

    local vertices = {
    { -1,  phi, 0 },
    {  1,  phi, 0 },
    { -1, -phi, 0 },
    {  1, -phi, 0 },

    { 0, -1,  phi },
    { 0,  1,  phi },
    { 0, -1, -phi },
    { 0,  1, -phi },

    {  phi, 0, -1 },
    {  phi, 0,  1 },
    { -phi, 0, -1 },
    { -phi, 0,  1 }
    }

    local indices = {
    1, 12, 6,
    1, 6, 2,
    1, 2, 8,
    1, 8, 11,
    1, 11, 12,

    2, 6, 10,
    6, 12, 5,
    12, 11, 3,
    11, 8, 7,
    8, 2, 9,

    4, 10, 5,
    4, 5, 3,
    4, 3, 7,
    4, 7, 9,
    4, 9, 10,

    5, 10, 6,
    3, 5, 12,
    7, 3, 11,
    9, 7, 8,
    10, 9, 2
    }

    -- Cache vertex splits to avoid duplicates
    local splits = {}

    -- Splits vertices i and j, creating a new vertex and returning the index
    local function split(i, j)
    local key = i < j and (i .. ',' .. j) or (j .. ',' .. i)

    if not splits[key] then
        local x = (vertices[i][1] + vertices[j][1]) / 2
        local y = (vertices[i][2] + vertices[j][2]) / 2
        local z = (vertices[i][3] + vertices[j][3]) / 2
        table.insert(vertices, { x, y, z })
        splits[key] = #vertices
    end

    return splits[key]
    end

    -- Subdivide
    for _ = 1, subdivisions or 0 do
        for i = #indices, 1, -3 do
            local v1, v2, v3 = indices[i - 2], indices[i - 1], indices[i - 0]
            local a = split(v1, v2)
            local b = split(v2, v3)
            local c = split(v3, v1)

            table.insert(indices, v1)
            table.insert(indices, a)
            table.insert(indices, c)

            table.insert(indices, v2)
            table.insert(indices, b)
            table.insert(indices, a)

            table.insert(indices, v3)
            table.insert(indices, c)
            table.insert(indices, b)

            table.insert(indices, a)
            table.insert(indices, b)
            table.insert(indices, c)

            table.remove(indices, i - 0)
            table.remove(indices, i - 1)
            table.remove(indices, i - 2)
        end
    end


    local vertes = {}
    -- Normalize
    for i, v in ipairs(vertices) do
        local x, y, z = unpack(v)
        local length = math.sqrt(x * x + y * y + z * z)
        v[1], v[2], v[3] = x / length, y / length, z / length

        table.insert(vertes, Vector(v[1], v[2], v[3])*radius)
    end

    return vertes
end