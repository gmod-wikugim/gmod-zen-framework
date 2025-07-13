module("zen")

zen.permission = zen.permission or {}
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

_CFG.net_permUpdate = "iperm.UpdatePlayer"

---@type table<string, table<string, zen.iperm.perm_info>>
iperm.mt_PlayerPermissions = iperm.mt_PlayerPermissions or {}
iperm.mt_Permissions = iperm.mt_Permissions or {}

local bit_band = bit.band
local function isFlagSet(flags, flag) return bit_band(flags, flag) == flag end

function iperm.PlayerSetPermission(sid64, perm_name, avaliable, target_flags, unique_flags, extra)
    extra = extra or {}
    iperm.mt_PlayerPermissions[sid64] = iperm.mt_PlayerPermissions[sid64] or {}
    local tPlayerPerm = iperm.mt_PlayerPermissions[sid64]
    tPlayerPerm[perm_name] = {
        allowed = avaliable,
        target_flags = target_flags or iperm.pflags_target.BASE,
        unique_flags = unique_flags or iperm.unique_flags.BASE,
        extra = {},
        perm_name = perm_name,
    }

    if SERVER then
        local ply = util.GetPlayerEntity(sid64)
        if ply then
            nt.SendToChannel("player_permissions", ply, perm_name, avaliable, target_flags, unique_flags, extra)
        end
    end
end

---@param sid64 string
---@param perm_list table<string, zen.iperm.perm_info>
function iperm.SetPlayerPermissions(sid64, perm_list)
    local t_Changed = {}


    if !iperm.mt_PlayerPermissions[sid64] then iperm.mt_PlayerPermissions[sid64] = {} end
    local ACTUAL_PERMS = iperm.mt_PlayerPermissions[sid64]

    for perm_name, PERM in pairs(perm_list) do
        local actual_value = ACTUAL_PERMS[perm_name]
        if util.Equal(PERM, actual_value) then continue end

        t_Changed[perm_name] = true
        ACTUAL_PERMS[perm_name] = PERM
    end

    for k, v in pairs(ACTUAL_PERMS) do
        if perm_list[k] == nil then
            ACTUAL_PERMS[k] = nil
            t_Changed[k] = true
        end
    end

    if SERVER then
        for perm_name in pairs(t_Changed) do
            local PERM = ACTUAL_PERMS[perm_name]


            if PERM then
                nt.SendToChannel("player_permissions", nil, sid64, perm_name, PERM.allowed, 0, 0, {})
            else
                nt.SendToChannel("player_permissions", nil, sid64, perm_name, false, 0, 0, {})
            end
        end
    end
end

---@return zen.iperm.perm_info|false
function iperm.PlayerGetPermission(sid64, perm_name)
    return iperm.mt_PlayerPermissions[sid64] and (iperm.mt_PlayerPermissions[sid64][perm_name] or false) or false
end

function iperm.PlayerCanTargetOffline(w_sid64, t_sid64)
    if _CFG.Admins[w_sid64] then return true end
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

---@param sid64 string
---@param perm_name string
---@param target Player|"CRecipientFilter"| table<Player>
---@param isSilent boolean?
function iperm.PlayerHasPermission(sid64, perm_name, target, isSilent)
    local sError = "unknown"

    if util.CheckSpam("PermCheck", 5, 5) then
        sError = "Stop spamming. "
        goto error
    end
        

    if perm_name == nil then
        sError = "Failed to check permission, perm_name is nil, ask developer to fix it\n " .. debug.traceback()
        goto error
    end



    if perm_name == "public" then goto success end
    if _CFG.Admins[sid64] then goto success end
    if iperm.PlayerGetPermission(sid64, "ROOT") then goto success end

    do -- Advanced Check
        local tPlayerPerm = iperm.PlayerGetPermission(sid64, perm_name)
        local tPermission = iperm.mt_Permissions[perm_name]
        local who = util.GetPlayerEntity(sid64)
        local iUniqueFlags = tPlayerPerm and tPlayerPerm.unique_flags or iperm.unique_flags.BASE
        local iPermissionFlags = tPermission and tPermission.flags or iperm.flags.BASE

        -- Personal block checking
        do
            if tPlayerPerm and tPlayerPerm.allowed == false then
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
                sError = Format("You don't has permission for '%s'", perm_name)
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
    end

    do return false, "End of code" end
    ::success::
    do return true, target end
    ::error::
    do return false, sError end
end

---@param perm_name string
function iperm.IsPermissionExists(perm_name)
    return iperm.mt_Permissions[perm_name] != nil
end


---@param perm_name string
---@param flags? number
---@param description? string
function iperm.RegisterPermission(perm_name, flags, description)
    assertString(perm_name, "perm_name")

    flags = flags or iperm.flags.BASE
    description = description or "base"

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
            name = perm_name,
            parent = (last_perm == "") and perm or last_perm,
            flags = new_flags,
            description = description,
        }
        last_perm = perm
    end

    iperm.Count = table.Count(iperm.mt_Permissions)

    nt.SendToChannel("permission_info", nil, perm_name, flags, description)
end


function META.PLAYER:zen_HasPerm(perm, target, noCheckAuth)
    if game.SinglePlayer() then return true end // Force-Allow single-player
    if zen.SERVER_SIDE_ACTIVATED == false then return true end // Give you full access, if server hasn't ZEN
    if perm == "public" then return true end
    if SERVER and not self:IsFullyAuthenticated() then return false, "You are not fully authenticated" end
    if !noCheckAuth and self:zen_GetVar("auth") != true then return false, "You are not login as admin (auth)" end
    return iperm.PlayerHasPermission(self:SteamID64(), perm, target)
end

function META.PLAYER:zen_HasPermNotify(perm, target, noCheckAuth)
    local hasPerm, comment = self:zen_HasPerm(perm, target, noCheckAuth)
    if hasPerm != true and type(comment) == "string" then
        msg.Error(self, comment)
    end

    return hasPerm, comment
end

ihook.Handler("zen.icmd.CanRun", "zen.permission", function(tCommand, QCMD, cmd, args, tags, who)
    if not IsValid(who) then return end
    if tCommand.data.perm == nil then return end
    if tCommand.data.perm == "public" then return end

    local hasAccess, com = who:zen_HasPerm(tCommand.perm)
    if hasAccess == false then
        return false, com
    end
end)

nt.RegisterChannel("player_permissions", nt.t_ChannelFlags.PUBLIC, {
    types = {"string", "string", "boolean", "uint32", "uint32", "table"},
    OnRead = function(self, target, sid64, perm_name, allowed, target_flags, unique_flags, extra)
        if CLIENT then
            iperm.PlayerSetPermission(sid64, perm_name, allowed, allowed, target_flags, unique_flags, extra)
        end
    end,
    WritePull = function(self, who)
        if SERVER then
            local count = table.Count(iperm.mt_PlayerPermissions)
            net.WriteUInt(count, 16)

            for sid64, PERMS in pairs(iperm.mt_PlayerPermissions) do
                local count2 = table.Count(PERMS)
                net.WriteString(sid64)
                net.WriteUInt(count2, 16)

                for perm_name, PERM in pairs(PERMS) do
                    nt.Write({"string", "boolean", "uint32", "uint32", "table"}, {PERM.perm_name, PERM.allowed, PERM.target_flags, PERM.unique_flags, PERM.extra})
                end
            end
        end
    end,
    ReadPull = function(self, addResult)
        if CLIENT then
            local count = net.ReadUInt(16)
            for k = 1, count do
                local sid64 = net.ReadString()
                local count2 = net.ReadUInt(16)
                for k = 1, count2 do
                    local perm_name, allowed, target_flags, unique_flags, extra = nt.Read({"string", "boolean", "uint32", "uint32", "table"})

                    addResult(sid64, perm_name, allowed, target_flags, unique_flags, extra)
                end
            end
        end
    end,
})

nt.RegisterChannel("permission_info", nt.t_ChannelFlags.PUBLIC, {
    types = {"string", "uint32", "string"},
    OnRead = function(self, target, perm_name, flags, description)
        if CLIENT then
            iperm.RegisterPermission(perm_name, flags, description)
        end
    end,
    WritePull = function(self, who)
        if SERVER then
            local count = iperm.Count
            net.WriteUInt(count, 16)

            for perm_name, PERM in pairs(iperm.mt_Permissions) do
                net.WriteString(perm_name)
                net.WriteUInt(PERM.flags, 32)
                net.WriteString(PERM.description)
            end
        end
    end,
    ReadPull = function(self, addResult)
        if CLIENT then
            self.iCounter = net.ReadUInt(16)
            for k = 1, self.iCounter do
                local perm_name = net.ReadString()
                local flags = net.ReadUInt(32)
                local description = net.ReadString()

                addResult(perm_name, flags, description)
            end
        end
    end,
})

iperm.RegisterPermission("zen.view")
