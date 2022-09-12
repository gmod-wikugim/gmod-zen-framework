izen.permission = izen.permission or {}
zen.permission = izen.permission
iperm = zen.permission

iperm.flags = {}
iperm.flags.BASE = 0
iperm.flags.NO_TARGET = 2 ^ 2
iperm.flags.OFFLINE = 2 ^ 3
iperm.flags.PUBLIC = 2 ^ 4


-- Player targets flags
iperm.pflags_target = {}
iperm.pflags_target.BASE = 0 -- Only for self
iperm.pflags_target.PLAYERS = 2 ^ 2 -- Users, Vips, Premiums
iperm.pflags_target.FUNERS = 2 ^ 3
iperm.pflags_target.ADMINS = 2 ^ 4
iperm.pflags_target.SUPERADMINS =  2 ^ 5
iperm.pflags_target.EVERYONE = 2 ^ 6 -- Should be DESC

iperm.unique_flags = {}
iperm.unique_flags.BASE = 0
iperm.unique_flags.SILENT = 2 ^ 2 -- Can use silent mode
iperm.unique_flags.FUN_ONLY = 2 ^ 3 -- Command avaliable only in fun time
iperm.unique_flags.ABSOLUTE = 2 ^ 4 -- No limits

icfg.net_permUpdate = "iperm.UpdatePlayer"

iperm.mt_PlayerPermissions = iperm.mt_PlayerPermissions or {}
iperm.mt_Permissions = iperm.mt_Permissions or {}

local bit_band = bit.band
local function isFlagSet(flags, flag) return bit_band(flags, flag) == flag end

function iperm.PlayerSetPermission(sid64, perm_name, avaliable, target_flags, unique_flags)
    iperm.mt_PlayerPermissions[sid64] = iperm.mt_PlayerPermissions[sid64] or {}
    local tPlayerPerm = iperm.mt_PlayerPermissions[sid64]
    tPlayerPerm[perm_name] = {
        bAvaliable = avaliable,
        target_flags = target_flags or iperm.pflags_target.BASE,
        unique_flags = unique_flags or iperm.unique_flags.BASE,
    }
end

function iperm.PlayerGetPermission(sid64, perm_name)
    return iperm.mt_PlayerPermissions[sid64] and (iperm.mt_PlayerPermissions[sid64][perm_name] or false) or false
end

function iperm.PlayerCanTargetOffline(w_sid64, t_sid64)
    if icfg.Admins[w_sid64] then return true end
    return false
end

function iperm.PlayerCanTargetPly(w_sid64, iTFlags, t_sid64)
    if isFlagSet(iTFlags, iperm.pflags_target.EVERYONE) then return true end
    if w_sid64 == t_sid64 then return true end

    local target = util.GetPlayerEntity(t_sid64)

    if target then
        local need_flags = iperm.pflags_target.PLAYERS

        if target.zen_IsFun and target:zen_IsFun() then
            need_flags = iperm.pflags_target.FUNERS
            goto check 
        end
        if target:IsSuperAdmin() then 
            need_flags = iperm.pflags_target.SUPERADMINS
            goto check 
        end
        if target:IsAdmin() then 
            need_flags = iperm.pflags_target.ADMINS
            goto check
        end

        ::check::

        return iTFlags >= need_flags
    else
        return iperm.PlayerCanTargetOffline(w_sid64, t_sid64)
    end
end



function iperm.PlayerCanTarget(w_sid64, iTFlags, tTargets)
    for sid64, ply in pairs(tTargets) do
        local bPlyResult = iperm.PlayerCanTargetPly(w_sid64, iTFlags, sid64)
        if bPlyResult != true then
            tTargets[sid64] = nil
        end
    end

    local bResult = next(tTargets) != nil
    return bResult, tTargets
end

function iperm.PlayerHasPermission(sid64, perm_name, target, isSilent)
    if perm_name == "public" then goto success end
    if icfg.Admins[sid64] then goto success end
    local tPlayerPerm = iperm.PlayerGetPermission(sid64, perm_name)
    local sError = "unknown"
    local tPermission = iperm.mt_Permissions[perm_name]
    local who = util.GetPlayerEntity(sid64)
    local iUniqueFlags = tPlayerPerm and tPlayerPerm.unique_flags or iperm.unique_flags.BASE
    local iPermissionFlags = tPermission and tPermission.flags or iperm.flags.BASE

    -- Personal block checking
    do
        if tPlayerPerm and tPlayerPerm.bAvaliable == false then
            sError = "This action was blocked for you"
            goto error
        end
    end

    -- Check Basics
    do
        if isFlagSet(iPermissionFlags, iperm.flags.PUBLIC) then 
            goto success
        end

        if not tPlayerPerm then
            sError = "This action not avaliable for you. Don't have permission"
            goto error
        end
    end

    -- Check Unique Flags
    do
        if isSilent and not isFlagSet(iUniqueFlags, iperm.unique_flags.SILENT) then
            sError = "You can't use this command as silent"
            goto error
        end

        if isFlagSet(iUniqueFlags, iperm.unique_flags.FUN_ONLY) then
            local who = util.GetPlayerEntity(sid64)
            if who then
                local inFunMode = (target.zen_IsFun and target:zen_IsFun())
                if not inFunMode then
                    sError = "You can use this command only in fun mode"
                    goto error
                end
            else
                sError = "You need be online for use this action in fun mode"
                goto error
            end

        end
    end

    -- Check Target Flags
    do
        if target then
            if isFlagSet(iPermissionFlags, iperm.flags.NO_TARGET) then
                target = {}
                goto success
            end
            local tTargets = {}
            if not istable(target) then target = {target} end
            if istable(target) then
                for k, v in pairs(target) do
                    local ply
                    if isnumber(k) and isnumber(v) then continue end

                    local ent = isentity(k) and k or (isentity(v) and v or false)
                    
                    if isentity(ent) and IsValid(ent) and ent:IsPlayer() then
                        tTargets[ent:SteamID64()] = ent
                        continue
                    end

                    local str = isstring(k) and k or (isstring(v) and v or false)

                    local ply = util.GetPlayerEntity(str)
                    if ply then
                        tTargets[ply:SteamID64()] = ply
                        continue
                    end
                end
            end

            if next(tTargets) == nil then
                sError = "Target is not found or corrupted"
                goto error
            end

            target = tTargets


            local iTFlags = tPlayerPerm and tPlayerPerm.target_flags

            local res
            res, target = iperm.PlayerCanTarget(sid64, iTFlags, target)
            if res == false then
                sError = "You can't target this person"
                goto error
            elseif res == true then
                goto success
            end

        else
            goto success
        end
    end

    do return false, "End of code" end
    ::success::
    do return true, target end
    ::error::
    do return false, sError end
end

function iperm.RegisterPermission(perm_name, flags, description)
    flags = flags or iperm.flags.BASE
    if iperm.mt_Permissions[perm_name] and iperm.mt_Permissions[perm_name].flags == flags then return end
    local perms_point = string.Split(perm_name, ".")
    
    local old_data = iperm.mt_Permissions[perm_name]
    local isEditing = old_data and old_data.flags != flags
    
    if isEditing then -- OnlyEdit
        old_data.flags = flags 
        return 
    end 

    local last_perm = ""
    local perm = ""
    for k, perm_cat in ipairs(perms_point) do
        perm = (perm == "") and (perm_cat) or (perm .. "." .. perm_cat)
        local perm_data = iperm.mt_Permissions[perm]
        
        if perm_data then continue end
        
        local new_flags = (perm_name == perm) and (flags) or (iperm.flags.BASE)
		
        iperm.mt_Permissions[perm] = {
            parent = (last_perm == "") and perm or last_perm,
            flags = new_flags,
            description = description,
        }
        last_perm = perm
    end
end

function META.PLAYER:zen_HasPerm(perm, target)
    if perm == "public" then return true end
    if SERVER and not self:IsFullyAuthenticated() then return false end
    if self:zen_GetVar("auth") != true then return false end
    return iperm.PlayerHasPermission(self:SteamID64(), perm, target)
end

iperm.RegisterPermission("zen.view")