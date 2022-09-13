
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
TYPE.ANGLE                          = 5
TYPE.COLOR                          = 6
TYPE.ENTITY                         = 7
TYPE.PLAYER                         = 8
TYPE.BOT                            = 9
TYPE.PLAYERONLY                     = 10
TYPE.WEAPON                         = 11
TYPE.VEHICLE                        = 12
TYPE.NPC                            = 13
TYPE.CEFFECTDATA                    = 14
TYPE.CLUAEMITTER                    = 15
TYPE.CLUAPARTICLE                   = 16
TYPE.CMOVEDATA                      = 17
TYPE.CNAVAREA                       = 18
TYPE.CNEWPARTICLEEFFECT             = 19
TYPE.CONVAR                         = 20
TYPE.CRECIPIENTFILTER               = 21
TYPE.CSENT                          = 22
TYPE.CSOUNDPATCH                    = 23
TYPE.CTAKEDAMAGEINFO                = 24
TYPE.CUSERCMD                       = 25
TYPE.FILE                           = 26
TYPE.IGMODAUDIOCHANNEL              = 27
TYPE.IMATERIAL                      = 28
TYPE.IMESH                          = 29
TYPE.IRESTORE                       = 30
TYPE.ISAVE                          = 31
TYPE.ITEXTURE                       = 32
TYPE.IVIDEOWRITER                   = 33
TYPE.MARKUPOBJECT                   = 34
TYPE.NEXTBOT                        = 35
TYPE.NPC                            = 36
TYPE.PANEL                          = 37
TYPE.PATHFOLLOWER                   = 38
TYPE.PHYSOBJ                        = 39
TYPE.PROJECTEDTEXTURE               = 40
TYPE.SCHUDULE                       = 41
TYPE.STACK                          = 42
TYPE.SURFACEINFO                    = 43
TYPE.TASK                           = 44
TYPE.TOOL                           = 45
TYPE.VMATRIX                        = 46
TYPE.SQLSTRING                      = 47
TYPE.PHYSCOLLIDE                    = 48
TYPE.CLUALOCOMOTION                 = 49
TYPE.CNAVLADDER                     = 50
TYPE.BF_READ                        = 51
TYPE.PIXELVIS_HANDLE_T              = 52
TYPE.DLIGHT_T                       = 53
TYPE.BIT                            = 54
TYPE.DATA                           = 55
TYPE.DOUBLE                         = 56
TYPE.MATRIX                         = 57
TYPE.NORMAL                         = 58
TYPE.ANY                            = 59
TYPE.STEAMID                        = 60
TYPE.STEAMID64                      = 61
TYPE.SID                            = TYPE.STEAMID
TYPE.SID64                          = TYPE.STEAMID64
TYPE.INT                            = 62
TYPE.UINT                           = 63


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
            return value.p .. " " .. value.y .. " " .. value.r
        elseif nType == TYPE.COLOR then
            return value.r .. " " .. value.g .. " " .. value.b .. " " .. value.a
        elseif nType == TYPE.SQLSTRING then
            return string.format("%q", value)
        end
    else
        return nil
    end
end

---@param value string
---@return any|nil result
function util.StringToTYPE(value, value_type)
    local nType = isnumber(value_type) and value_type or CVTYPE[value_type]
    if nType then
        if nType == TYPE.BOOLEAN then
            return value == "true" and true or false
        elseif nType == TYPE.NUMBER then
            return tonumber(value)
        elseif nType == TYPE.STRING then
            return tostring(value)
        elseif nType == TYPE.TABLE then
            return util.JSONToTable(value)
        elseif nType == TYPE.VECTOR then
            if value == nil or value == "" then return Vector(0, 0, 0) end
            local dat = string.Explode(" ", value)
            dat[1] = dat[1] or 0
            dat[2] = dat[2] or 0
            dat[3] = dat[3] or 0
            return Vector( unpack(dat) )
        elseif nType == TYPE.ANGLE then
            if value == nil or value == "" then return Angle(0, 0, 0) end
            local dat = string.Explode(" ", value)
            dat[1] = dat[1] or 0
            dat[2] = dat[2] or 0
            dat[3] = dat[3] or 0
            return Angle( unpack(dat) )
        elseif nType == TYPE.COLOR then
            if value == nil or value == "" then return Color(255, 255, 255, 255) end
            local dat = string.Explode(" ", value)
            dat[1] = dat[1] or 255
            dat[2] = dat[2] or 255
            dat[3] = dat[3] or 255
            dat[4] = dat[4] or 255
            return Color( unpack(dat) )
        end
    else
        return nil
    end
end

util.mt_TD_TypeConvert = {}
util.mt_TD_TypeConvert["angle"] = TYPE.ANGLE
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
util.mt_TD_TypeConvert["int"] = TYPE.INT
util.mt_TD_TypeConvert["uint"] = TYPE.UINT
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

util.mt_TD_TypeAlias = {}
util.mt_TD_TypeAlias["Player"] = "Entity"
util.mt_TD_TypeAlias["Vehicle"] = "Entity"
util.mt_TD_TypeAlias["Weapon"] = "Entity"
util.mt_TD_TypeAlias["NPC"] = "Entity"
util.mt_TD_TypeAlias["CSEnt"] = "Entity"
util.mt_TD_TypeAlias["NextBot"] = "Entity"



function util.CheckTypeTableWithDataTable(types, data, funcValidate, tExtraTypeConvert)
    local bSuccess = true
    local sLastError

    local iTypesCount, iDataCount = 0, 0
    local tResult = {}

    for k, human_type in ipairs(types) do
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
        for id = 1, iTypesCount do
            local human_type = types[id]
            local value = data[id]

            local original_type = human_type
            if tExtraTypeConvert then
                human_type = tExtraTypeConvert[human_type] or human_type
            end

            local type_id = util.mt_TD_TypeConvert[human_type]
            if not type_id then
                bSuccess = false
                sLastError = "Lua Type-Convert not exists for: " .. human_type
                break
            end
            local sType = util.mt_TD_TypeList[type_id]
            if not sType then
                bSuccess = false
                sLastError = "Lua TYPE not exists for: " .. human_type
                break
            end

            if sType != "any" then
                local sTypeWord = type(value)
                if sTypeWord != sType then
                    local sOwnerTypeWord = util.mt_TD_TypeAlias[sTypeWord]

                    if sOwnerTypeWord then
                        if sOwnerTypeWord and sOwnerTypeWord == sType then
                            -- Good
                        else
                            bSuccess = false
                            sLastError = "Type check id owner: " .. id .. " (" .. sType .. " expected, got " .. sOwnerTypeWord .. ") owner_id: "
                            break
                        end
                    else
                        bSuccess = false
                        sLastError = "Type check id: " .. id .. " (" .. sType .. " expected, got " .. sTypeWord .. ")"
                        break
                    end
                end
            end

            if funcValidate then
                local res, err = funcValidate(human_type, value, type_id, id, original_type)
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
        return false, sLastError, tResult
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
            
                local addPoint = lvl > 0 and "," or ";"
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
COLOR.R, COLOR.G, COLOR.B, COLOR.W, COLOR.B = COLOR.RED, COLOR.GREEN, COLOR.BLUE, COLOR.WHITE, COLOR.BLACK

---@param value string
---@return boolean IsSteamID64
function util.IsSteamID64(value)
    if tonumber(value) and value:sub(1, 7) == "7656119" and (#value == 17 or #value == 18) then
        return true
    end
end

---@param value string
---@return boolean IsSteamID
function util.IsSteamID(value)
    if value:match("^STEAM_[0-5]:[0-1]:[0-9]+$") ~= nil then
		return true
	else
		return false
	end
end

util.mt_PlayerList_Entity = {}
util.mt_PlayerList_SID64 = {}
util.mt_PlayerList_SID = {}
util.mt_PlayerList_UserID = {}
function util.PlayerList_Remove(ply)
    local sid64 = ply.zen_sSteamID64 or ply:SteamID64()
    local sid64_n = tonumber(sid64)
    local sid = ply.zen_sSteamID or ply:SteamID()
    local userid = ply.zen_iUserID or ply:UserID()
    local userid_str = "#" .. userid

    -- Entity
    util.mt_PlayerList_Entity[ply] = nil
    util.mt_PlayerList_SID64[ply] = nil
    util.mt_PlayerList_SID[ply] = nil
    util.mt_PlayerList_UserID[ply] = nil

    -- Sids
    if not ply:IsBot() then
        util.mt_PlayerList_Entity[sid64] = nil
        util.mt_PlayerList_Entity[sid64_n] = nil
        util.mt_PlayerList_Entity[sid] = nil

        util.mt_PlayerList_SID64[sid64] = nil
        util.mt_PlayerList_SID64[sid64_n] = nil
        util.mt_PlayerList_SID64[sid] = nil

        util.mt_PlayerList_SID[sid64] = nil
        util.mt_PlayerList_SID[sid64_n] = nil
        util.mt_PlayerList_SID[sid] = nil

        util.mt_PlayerList_UserID[sid64] = nil
        util.mt_PlayerList_UserID[sid64_n] = nil
        util.mt_PlayerList_UserID[sid] = nil
    end

    -- UserID
    util.mt_PlayerList_Entity[userid] = nil
    util.mt_PlayerList_Entity[userid_str] = nil

    util.mt_PlayerList_SID64[userid] = nil
    util.mt_PlayerList_SID64[userid_str] = nil

    util.mt_PlayerList_SID[userid] = nil
    util.mt_PlayerList_SID[userid_str] = nil

    util.mt_PlayerList_UserID[userid] = nil
    util.mt_PlayerList_UserID[userid_str] = nil
end


function util.PlayerList_Add(ply)
    local sid64 = ply:SteamID64()
    local sid64_n = tonumber(sid64)
    local sid = ply:SteamID()
    local userid = ply:UserID()
    local userid_str = "#" .. userid

    -- Entity
    util.mt_PlayerList_Entity[ply] = ply
    util.mt_PlayerList_UserID[ply] = userid

    if not ply:IsBot() then
        util.mt_PlayerList_SID64[ply] = sid64
        util.mt_PlayerList_SID[ply] = sid


        util.mt_PlayerList_Entity[sid64] = ply
        util.mt_PlayerList_Entity[sid64_n] = ply
        util.mt_PlayerList_Entity[sid] = ply

        util.mt_PlayerList_SID64[sid64] = sid64
        util.mt_PlayerList_SID64[sid64_n] = sid64
        util.mt_PlayerList_SID64[sid] = sid64

        util.mt_PlayerList_SID[sid64] = sid
        util.mt_PlayerList_SID[sid64_n] = sid
        util.mt_PlayerList_SID[sid] = sid

        util.mt_PlayerList_UserID[sid64] = userid
        util.mt_PlayerList_UserID[sid64_n] = userid
        util.mt_PlayerList_UserID[sid] = userid

        ply.zen_sSteamID64 = sid64
        ply.zen_sSteamID = sid

        util.mt_PlayerList_SID64[userid] = sid64
        util.mt_PlayerList_SID64[userid_str] = sid64
    
        util.mt_PlayerList_SID[userid] = sid
        util.mt_PlayerList_SID[userid_str] = sid
    end
    ply.zen_iUserID = userid

    -- UserID
    util.mt_PlayerList_UserID[userid] = userid
    util.mt_PlayerList_UserID[userid_str] = userid

    util.mt_PlayerList_Entity[userid] = ply
    util.mt_PlayerList_Entity[userid_str] = ply
end

function util.UpdatePlayerList()
    util.mt_PlayerList_Entity = {}
    for k, v in pairs(player.GetAll()) do
        util.PlayerList_Add(v)
    end
end
util.UpdatePlayerList()

if SERVER then
    ihook.Listen("PlayerInitialSpawn", "zen.util.PlayerList", function(ply)
        util.PlayerList_Add(ply)
    end)
    ihook.Listen("PlayerDisconnected", "zen.util.PlayerList", function(ply)
        util.PlayerList_Remove(ply)
    end)
end

if CLIENT then
    ihook.Listen("OnEntityCreated", "zen.util.PlayerList", function(ent)
        if ent:IsPlayer() then util.PlayerList_Add(ent) end
    end)
    ihook.Listen("EntityRemoved", "zen.util.PlayerList", function(ent)
        if ent:IsPlayer() then util.PlayerList_Remove(ent) end
    end)
end

function util.GetPlayerEntity(plyOrSid)
    return util.mt_PlayerList_Entity[plyOrSid]
end

function util.GetPlayerSteamID64(plyOrSid)
    return util.mt_PlayerList_SID64[plyOrSid]
end

function util.GetPlayerSteamID(plyOrSid)
    return util.mt_PlayerList_SID[plyOrSid]
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

---@param value any
---@param variableName? string
function assertValid(value, variableName)
    assert(IsValid(value), (variableName or "variable") .. " not is valid")
end

---@param value any
---@param variableName? string
function assertNumber(value, variableName)
    assert(isnumber(value), (variableName or "variable") .. " not is number")
end

---@param value any
---@param variableName? string
function assertString(value, variableName)
    assert(isstring(value), (variableName or "variable") .. " not is string")
end

---@param value any
---@param variableName? string
function assertStringNice(value, variableName)
    assert(isstring(value), (variableName or "variable") .. " not is string")
    assert(value != "" and value != " ", (variableName or "variable") .. " not is empty")
    assert(string.format(value, "%w+"), (variableName or "variable") .. " not has words or numbers")
end

---@param value any
---@param variableName? string
function assertTable(value, variableName)
    assert(istable(value), (variableName or "variable") .. " not is table")
end

---@param value any
---@param variableName? string
function assertTableNice(value, variableName)
    assert(istable(value), (variableName or "variable") .. " not is table")
    assert(next(value), (variableName or "variable") .. " is empty")
end

---@param value any
---@param variableName? string
function assertEntity(value, variableName)
    assert(isentity(value) and IsValid(value), (variableName or "variable") .. " not is entity")
end

---@param value any
---@param variableName? string
function assertPlayer(value, variableName)
    assert(isentity(value) and IsValid(value) and value:IsPlayer(), (variableName or "variable") .. " not is player")
end

---@param value any
---@param variableName? string
function assertFunction(value, variableName)
    assert(isfunction(value), (variableName or "variable") .. " not is player")
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
            
                local addPoint = lvl > 0 and "," or ";"
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